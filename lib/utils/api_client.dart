import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'checkin_utils.dart';
import '../models/constants/checkin_enums.dart';
import '../models/response.dart';
import '../models/auth.dart';
import '../models/location.dart';
import '../models/checkin.dart';
import '../models/approval.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}

// --------------- 全局实例 ---------------
final TokenManager tokenManager = TokenManager();
final ApiClient apiClient = ApiClient();

class ApiClient {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? '';
  static final HttpClient _client = HttpClient()
    ..badCertificateCallback = (cert, host, port) => true;

  Future<QuQResponse<LoginResponseModel>> login({
    required String account,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/Auth/login');
      final request = await _client.postUrl(uri);
      request.headers.add('Content-Type', 'application/json');
      final requestBody = json.encode({'phone': account, 'password': password});
      request.write(requestBody);
      final response = await request.close();
      final responseBody = await utf8.decodeStream(response);
      final jsonMap = json.decode(responseBody);
      // if (response.statusCode != HttpStatus.ok) {
      //   return QuQResponse<LoginResponseModel>(
      //     success: jsonMap['success'],
      //     data: null,
      //     message: jsonMap['message'],
      //   );
      // }
      return QuQResponse.fromJson(
        jsonMap,
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
      final uri = Uri.parse('$baseUrl/Auth/logout');
      final request = await _client.postUrl(uri);
      request.headers.add('Content-Type', 'application/json');
      final refreshToken = tokenManager.refreshToken;
      final requestBody = json.encode({
        'refreshToken': refreshToken ?? "no-refreshToken",
      });
      request.write(requestBody);
      final response = await request.close();
      if (response.statusCode == 200) return true;
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _refreshToken() async {
    final refreshToken = tokenManager.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      final uri = Uri.parse('$baseUrl/Auth/refresh-token');
      final request = await _client.postUrl(uri);
      request.headers.add('Content-Type', 'application/json');
      final requestBody = json.encode({'refreshToken': refreshToken});
      request.write(requestBody);
      final response = await request.close();
      final responseBody = await utf8.decodeStream(response);
      final jsonMap = json.decode(responseBody);
      final apiResponse = QuQResponse.fromJson(
        jsonMap,
        (json) => RefreshTokenResponseModel.fromJson(json),
      );
      if (apiResponse.success) {
        final refreshData = apiResponse.data!;
        await tokenManager.saveToken(
          accessToken: refreshData.newAccessToken,
          refreshToken: tokenManager.refreshToken!,
          accessTokenExpiry: refreshData.newAccessTokenExpiry,
        );
        return true;
      } else {
        await tokenManager.clearToken();
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // 获取服务器当前毫秒时间戳，避免客户端改时间作弊。虽然改了也没用
  Future<QuQResponse<Map<String, dynamic>>> getServerTime() async {
    try {
      final uri = Uri.parse('$baseUrl/Common/current-time');
      final request = await _client.getUrl(uri);
      //request.headers.add('Content-Type', 'application/json');
      final response = await request.close();
      if (response.statusCode == 500) throw Exception('服务器内部错误');
      final responseBody = await utf8.decodeStream(response);
      final jsonMap = json.decode(responseBody);
      return QuQResponse.fromJson(
        jsonMap,
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
    if (tokenManager.isAccessTokenExpired() &&
        tokenManager.refreshToken != null) {
      final refreshSuccess = await _refreshToken();
      if (!refreshSuccess) {
        return QuQResponse<LocationModel>(
          success: false,
          data: null,
          message: '登录已过期，请重新登录',
        );
      }
    }
    try {
      final uri = Uri.parse('$baseUrl/Checkin/locations');
      final request = await _client.getUrl(uri);
      final accessToken = tokenManager.accessToken;
      if (accessToken != null && accessToken.isNotEmpty) {
        request.headers.add('Authorization', 'Bearer $accessToken');
      }
      request.headers.add('Content-Type', 'application/json');
      final response = await request.close();
      if (response.statusCode == HttpStatus.unauthorized) {
        final refreshSuccess = await _refreshToken();
        if (refreshSuccess) {
          return getLocation();
        } else {
          return QuQResponse<LocationModel>(
            success: false,
            data: null,
            message: '登录已过期，请重新登录',
          );
        }
      }
      final responseBody = await utf8.decodeStream(response);
      final jsonMap = json.decode(responseBody);
      return QuQResponse.fromJson(
        jsonMap,
        (json) => LocationModel.fromJson(json),
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
    if (tokenManager.isAccessTokenExpired() &&
        tokenManager.refreshToken != null) {
      final refreshSuccess = await _refreshToken();
      if (!refreshSuccess) {
        return QuQResponse<List<CheckinRecordDto>>(
          success: false,
          data: null,
          message: '登录已过期，请重新登录',
        );
      }
    }
    try {
      final uri = Uri.parse('$baseUrl/Checkin/today-status');
      final request = await _client.getUrl(uri);
      final accessToken = tokenManager.accessToken;
      if (accessToken != null && accessToken.isNotEmpty) {
        request.headers.add('Authorization', 'Bearer $accessToken');
      }
      request.headers.add('Content-Type', 'application/json');
      final response = await request.close();
      if (response.statusCode == HttpStatus.unauthorized) {
        final refreshSuccess = await _refreshToken();
        if (refreshSuccess) {
          return getCheckinStatus();
        } else {
          return QuQResponse<List<CheckinRecordDto>>(
            success: false,
            data: null,
            message: '登录已过期，请重新登录',
          );
        }
      }
      final responseBody = await utf8.decodeStream(response);
      final jsonMap = json.decode(responseBody);
      return QuQResponse.fromJson(
        jsonMap,
        (json) => (json as List<dynamic>)
            .map(
              (item) => CheckinRecordDto.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
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
    if (tokenManager.isAccessTokenExpired() &&
        tokenManager.refreshToken != null) {
      final refreshSuccess = await _refreshToken();
      if (!refreshSuccess) {
        return QuQResponse<MonthlyAttendance>(
          success: false,
          data: null,
          message: '登录已过期，请重新登录',
        );
      }
    }
    try {
      final uri = Uri.parse('$baseUrl/Checkin/checkin-info');
      final request = await _client.postUrl(uri);
      final accessToken = tokenManager.accessToken;
      if (accessToken != null && accessToken.isNotEmpty) {
        request.headers.add('Authorization', 'Bearer $accessToken');
      }
      request.headers.add('Content-Type', 'application/json');
      final requestBody = json.encode({
        "startDate": startDate.toIso8601String(),
        "endDate": endDate.toIso8601String(),
      });
      request.write(requestBody);
      final response = await request.close();
      if (response.statusCode == HttpStatus.unauthorized) {
        final refreshSuccess = await _refreshToken();
        if (refreshSuccess) {
          return getMonthlyCheckin(startDate, endDate);
        } else {
          return QuQResponse<MonthlyAttendance>(
            success: false,
            data: null,
            message: '登录已过期，请重新登录',
          );
        }
      }
      final responseBody = await utf8.decodeStream(response);
      final jsonMap = json.decode(responseBody);
      return QuQResponse.fromJson(
        jsonMap,
        (json) => MonthlyAttendance.fromJson(json),
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
    if (tokenManager.isAccessTokenExpired() &&
        tokenManager.refreshToken != null) {
      final refreshSuccess = await _refreshToken();
      if (!refreshSuccess) {
        return QuQResponse<CheckinRecordDto>(
          success: false,
          data: null,
          message: '登录已过期，请重新登录',
        );
      }
    }
    try {
      final uri = Uri.parse('$baseUrl/Checkin/perform-checkin');
      final request = await _client.postUrl(uri);
      final accessToken = tokenManager.accessToken;
      if (accessToken != null && accessToken.isNotEmpty) {
        request.headers.add('Authorization', 'Bearer $accessToken');
      }
      request.headers.add('Content-Type', 'application/json');
      final devInfo = await CheckinUtils.getDevInfoJson();
      final requestBody = json.encode({
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
      });
      // request.write(requestBody);
      final bodyBtyes = utf8.encode(requestBody);
      request.add(bodyBtyes);
      final response = await request.close();
      if (response.statusCode == HttpStatus.unauthorized) {
        final refreshSuccess = await _refreshToken();
        if (refreshSuccess) {
          return performCheckin(checkinType, position);
        } else {
          return QuQResponse<CheckinRecordDto>(
            success: false,
            data: null,
            message: '登录已过期，请重新登录',
          );
        }
      }
      final responseBody = await utf8.decodeStream(response);
      final jsonMap = json.decode(responseBody);
      return QuQResponse.fromJson(
        jsonMap,
        (json) => CheckinRecordDto.fromJson(json),
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
    if (tokenManager.isAccessTokenExpired() &&
        tokenManager.refreshToken != null) {
      final refreshSuccess = await _refreshToken();
      if (!refreshSuccess) {
        return QuQResponse<String>(
          success: false,
          data: null,
          message: '登录已过期，请重新登录',
        );
      }
    }
    try {
      final uri = Uri.parse('$baseUrl/Approval/submit');
      final request = await _client.postUrl(uri);
      final accessToken = tokenManager.accessToken;
      if (accessToken != null && accessToken.isNotEmpty) {
        request.headers.add('Authorization', 'Bearer $accessToken');
      }
      request.headers.add('Content-Type', 'application/json');
      final requestBody = json.encode(submitRequest);
      final bodyBtyes = utf8.encode(requestBody);
      request.add(bodyBtyes);
      final response = await request.close();
      if (response.statusCode == HttpStatus.unauthorized) {
        final refreshSuccess = await _refreshToken();
        if (refreshSuccess) {
          return submitApproval(submitRequest);
        } else {
          return QuQResponse<String>(
            success: false,
            data: null,
            message: '登录已过期，请重新登录',
          );
        }
      }
      final responseBody = await utf8.decodeStream(response);
      final jsonMap = json.decode(responseBody);
      return QuQResponse<String>(
        success: jsonMap['success'] ?? false,
        message: jsonMap['message'] ?? '',
        data: jsonMap['data'] ?? '',
      );
    } catch (e) {
      return QuQResponse<String>(
        success: false,
        data: null,
        message: '请求失败:${e.toString()}',
      );
    }
  }
}
