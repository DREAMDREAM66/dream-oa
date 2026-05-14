import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/constants/checkin_enums.dart';
import '../models/response.dart';
import '../models/auth.dart';
import '../models/location.dart';
import '../models/checkin.dart';
import '../models/approval.dart';
import 'checkin_utils.dart';
import 'user_manager.dart';
import 'dio_client.dart';

const _kAccessTokenKey = 'access_token';
const _kRefreshTokenKey = 'refresh_token';
const _kAccessTokenExpiryKey = 'access_token_expiry';

class TokenManager {
  static final TokenManager _instance = TokenManager._internal();
  factory TokenManager() => _instance;
  TokenManager._internal();

  late SharedPreferences _prefs;
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> saveToken({
    required String accessToken,
    required String refreshToken,
    required String accessTokenExpiry,
  }) async {
    await _prefs.setString(_kAccessTokenKey, accessToken);
    await _prefs.setString(_kRefreshTokenKey, refreshToken);
    await _prefs.setString(_kAccessTokenExpiryKey, accessTokenExpiry);
  }

  String? get accessToken => _prefs.getString(_kAccessTokenKey);
  String? get refreshToken => _prefs.getString(_kRefreshTokenKey);
  String? get accessTokenExpiry => _prefs.getString(_kAccessTokenExpiryKey);

  bool isAccessTokenExpired() {
    final expiryStr = accessTokenExpiry;
    if (expiryStr == null || expiryStr.isEmpty) return true;
    try {
      final expiryTime = DateTime.parse(expiryStr).toUtc();
      final currentTime = DateTime.now().toUtc();
      return currentTime.isAfter(expiryTime);
    } catch (e) {
      return true;
    }
  }

  Future<void> clearToken() async {
    await _prefs.remove(_kAccessTokenKey);
    await _prefs.remove(_kRefreshTokenKey);
    await _prefs.remove(_kAccessTokenExpiryKey);
  }

  /// Dio 专用：刷新 token（使用独立 Dio 实例避免拦截器循环调用）
  Future<bool> refreshAccessToken() async {
    final refreshTokenVal = refreshToken;
    if (refreshTokenVal == null || refreshTokenVal.isEmpty) return false;

    // 创建独立的 Dio 实例，不使用拦截器避免循环调用
    final refreshDio = Dio(
      BaseOptions(
        baseUrl: dotenv.env['API_BASE_URL'] ?? '',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Debug 模式忽略证书错误，Release 模式严格验证
    refreshDio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        if (kDebugMode) {
          client.badCertificateCallback = (cert, host, port) => true;
        }
        return client;
      },
    );

    try {
      final response = await refreshDio.post(
        '/Auth/refresh-token',
        data: {'refreshToken': refreshTokenVal},
      );

      if (response.statusCode == 200) {
        final jsonMap = response.data;
        if (jsonMap['success'] == true) {
          final data = jsonMap['data'];
          await saveToken(
            accessToken: data['newAccessToken'],
            refreshToken: refreshTokenVal,
            accessTokenExpiry: data['newAccessTokenExpiry'],
          );
          return true;
        }
      }
      await clearToken();
      return false;
    } catch (e) {
      await clearToken();
      return false;
    } finally {
      refreshDio.close();
    }
  }
}

/// Token 拦截器：自动注入 Authorization header，处理 401 自动刷新
class TokenInterceptor extends Interceptor {
  final Dio dio;

  TokenInterceptor(this.dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 登录接口不需要 token
    if (options.path.contains('/Auth/login')) {
      return handler.next(options); // 拦截器放行请求
    }

    // 自动注入 token
    final accessToken = tokenManager.accessToken;
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 仅处理 401 错误
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // 防止刷新死循环：记录是否正在刷新
    if (_isRefreshing) {
      // 等待刷新完成
      await _refreshCompleter?.future;
      if (_refreshSuccess) {
        // 重试原请求
        final retryResponse = await dio.fetch(err.requestOptions);
        return handler.resolve(retryResponse);
      }
      return handler.next(err);
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<bool>(); // 这是一个可以等待的bool，承诺完成器

    try {
      final refreshed = await tokenManager.refreshAccessToken();
      _refreshSuccess = refreshed;
      if (refreshed) {
        // 重试原请求
        final retryResponse = await dio.fetch(err.requestOptions);
        _refreshCompleter?.complete(true);
        _refreshCompleter = null; // 显式置null，避免其他逻辑复用了旧的Completer
        _isRefreshing = false;
        return handler.resolve(retryResponse);
      }
    } catch (e) {
      _refreshSuccess = false;
    } finally {
      if (!_refreshCompleter!.isCompleted) {
        _refreshCompleter?.complete(_refreshSuccess);
      }
      _refreshCompleter = null;
      _isRefreshing = false;
    }

    // 刷新失败，清除用户信息，要求重新登录
    if (!_refreshSuccess) {
      userManager.clearUserInfo();
    }

    handler.next(err);
  }

  bool _isRefreshing = false;
  bool _refreshSuccess = false;
  Completer<bool>? _refreshCompleter;
}

// --------------- 全局实例 ---------------
final TokenManager tokenManager = TokenManager();
final ApiClient apiClient = ApiClient();

/// 初始化 Token 拦截器，应在 main() 中调用
void setupTokenInterceptor() {
  dioClient.dio.interceptors.add(TokenInterceptor(dioClient.dio));
}

// --------------- ApiClient ---------------

class ApiClient {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? '';

  Future<QuQResponse<LoginResponseModel>> login({
    required String account,
    required String password,
  }) async {
    try {
      final response = await dioClient.dio.post(
        '/Auth/login',
        data: {'phone': account, 'password': password},
      );
      return QuQResponse.fromJson(
        response.data,
        (json) => LoginResponseModel.fromJson(json),
      );
    } catch (e) {
      return QuQResponse<LoginResponseModel>(
        success: false,
        data: null,
        message: '登录请求失败：${e.toString()}',
      );
    }
  }

  Future<bool> logout() async {
    try {
      final response = await dioClient.dio.post(
        '/Auth/logout',
        data: {'refreshToken': tokenManager.refreshToken ?? "no-refreshToken"},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 获取服务器当前毫秒时间戳
  Future<QuQResponse<Map<String, dynamic>>> getServerTime() async {
    try {
      final response = await dioClient.dio.get('/Common/current-time');
      return QuQResponse.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      return QuQResponse<Map<String, dynamic>>(
        success: false,
        data: null,
        message: '获取服务器时间失败：${e.toString()}',
      );
    }
  }

  Future<QuQResponse<LocationModel>> getLocation() async {
    try {
      final response = await dioClient.dio.get('/Checkin/locations');
      return QuQResponse.fromJson(
        response.data,
        (json) => LocationModel.fromJson(json),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return QuQResponse<LocationModel>(
          success: false,
          data: null,
          message: '登录已过期，请重新登录',
        );
      }
      return QuQResponse<LocationModel>(
        success: false,
        data: null,
        message: '请求失败:${e.toString()}',
      );
    } catch (e) {
      return QuQResponse<LocationModel>(
        success: false,
        data: null,
        message: '请求失败:${e.toString()}',
      );
    }
  }

  Future<QuQResponse<List<CheckinRecordDto>>> getCheckinStatus() async {
    try {
      final response = await dioClient.dio.get('/Checkin/today-status');
      return QuQResponse.fromJson(
        response.data,
        (json) => (json as List<dynamic>)
            .map(
              (item) => CheckinRecordDto.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return QuQResponse<List<CheckinRecordDto>>(
          success: false,
          data: null,
          message: '登录已过期，请重新登录',
        );
      }
      return QuQResponse<List<CheckinRecordDto>>(
        success: false,
        data: null,
        message: '获取今日打卡记录失败:${e.toString()}',
      );
    } catch (e) {
      return QuQResponse<List<CheckinRecordDto>>(
        success: false,
        data: null,
        message: '获取今日打卡记录失败:${e.toString()}',
      );
    }
  }

  Future<QuQResponse<MonthlyAttendance>> getMonthlyCheckin(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await dioClient.dio.post(
        '/Checkin/checkin-info',
        data: {
          "startDate": startDate.toIso8601String(),
          "endDate": endDate.toIso8601String(),
        },
      );
      return QuQResponse.fromJson(
        response.data,
        (json) => MonthlyAttendance.fromJson(json),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return QuQResponse<MonthlyAttendance>(
          success: false,
          data: null,
          message: '登录已过期，请重新登录',
        );
      }
      return QuQResponse<MonthlyAttendance>(
        success: false,
        data: null,
        message: '获取打卡记录失败:${e.toString()}',
      );
    } catch (e) {
      return QuQResponse<MonthlyAttendance>(
        success: false,
        data: null,
        message: '获取打卡记录失败:${e.toString()}',
      );
    }
  }

  Future<QuQResponse<CheckinRecordDto>> performCheckin(
    CheckinType checkinType,
    Position position,
  ) async {
    try {
      final devInfo = await CheckinUtils.getDevInfoJson();
      final response = await dioClient.dio.post(
        '/Checkin/perform-checkin',
        data: {
          "checkinType": checkinType.value,
          "longitude": position.longitude,
          "latitude": position.latitude,
          "accuracy": position.accuracy,
          "altitude": position.altitude,
          "heading": position.heading,
          "speed": position.speed,
          "source": 1,
          "deviceInfo": devInfo,
          "networkType": "not defined",
        },
      );
      return QuQResponse.fromJson(
        response.data,
        (json) => CheckinRecordDto.fromJson(json),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return QuQResponse<CheckinRecordDto>(
          success: false,
          data: null,
          message: '登录已过期，请重新登录',
        );
      }
      return QuQResponse<CheckinRecordDto>(
        success: false,
        data: null,
        message: '请求失败:${e.toString()}',
      );
    } catch (e) {
      return QuQResponse<CheckinRecordDto>(
        success: false,
        data: null,
        message: '请求失败:${e.toString()}',
      );
    }
  }

  Future<QuQResponse<String>> submitApproval(
    SubmitApprovalRequest submitRequest,
  ) async {
    try {
      final response = await dioClient.dio.post(
        '/Approval/submit',
        data: submitRequest,
      );
      final jsonMap = response.data;
      return QuQResponse<String>(
        success: jsonMap['success'] ?? false,
        message: jsonMap['message'] ?? '',
        data: jsonMap['data'] ?? '',
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return QuQResponse<String>(
          success: false,
          data: null,
          message: '登录已过期，请重新登录',
        );
      }
      return QuQResponse<String>(
        success: false,
        data: null,
        message: '请求失败:${e.toString()}',
      );
    } catch (e) {
      return QuQResponse<String>(
        success: false,
        data: null,
        message: '请求失败:${e.toString()}',
      );
    }
  }

  Future<QuQResponse<String>> processApproval(
    ApprovalActionRequest request,
  ) async {
    try {
      final response = await dioClient.dio.post(
        '/Approval/action',
        data: request.toJson(),
      );
      final jsonMap = response.data;
      return QuQResponse<String>(
        success: jsonMap['success'] ?? false,
        message: jsonMap['message'] ?? '',
        data: jsonMap['data'] ?? '',
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return QuQResponse<String>(
          success: false,
          data: null,
          message: '登录已过期，请重新登录',
        );
      }
      return QuQResponse<String>(
        success: false,
        data: null,
        message: '请求失败:${e.toString()}',
      );
    } catch (e) {
      return QuQResponse<String>(
        success: false,
        data: null,
        message: '请求失败:${e.toString()}',
      );
    }
  }

  Future<QuQResponse<List<ApprovalProcessDetailResponse>>>
  getMyPendingApprovals() async {
    try {
      final response = await dioClient.dio.get('/Approval/pending');
      return QuQResponse.fromJson(
        response.data,
        (json) => (json as List<dynamic>)
            .map(
              (item) => ApprovalProcessDetailResponse.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList(),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return QuQResponse<List<ApprovalProcessDetailResponse>>(
          success: false,
          data: null,
          message: '登录已过期，请重新登录',
        );
      }
      return QuQResponse<List<ApprovalProcessDetailResponse>>(
        success: false,
        data: null,
        message: '获取待审批列表失败:${e.toString()}',
      );
    } catch (e) {
      return QuQResponse<List<ApprovalProcessDetailResponse>>(
        success: false,
        data: null,
        message: '获取待审批列表失败:${e.toString()}',
      );
    }
  }

  /// 获取用户提交的申请列表
  Future<QuQResponse<List<ApprovalProcessDetailResponse>>>
  getMyApplications() async {
    try {
      final response = await dioClient.dio.get('/Approval/my-applications');
      return QuQResponse.fromJson(
        response.data,
        (json) => (json as List<dynamic>)
            .map(
              (item) => ApprovalProcessDetailResponse.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList(),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return QuQResponse<List<ApprovalProcessDetailResponse>>(
          success: false,
          data: null,
          message: '登录已过期，请重新登录',
        );
      }
      return QuQResponse<List<ApprovalProcessDetailResponse>>(
        success: false,
        data: null,
        message: '获取我的申请列表失败:${e.toString()}',
      );
    } catch (e) {
      return QuQResponse<List<ApprovalProcessDetailResponse>>(
        success: false,
        data: null,
        message: '获取我的申请列表失败:${e.toString()}',
      );
    }
  }
}
