import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/response.dart';
import '../models/auth.dart';
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

  // Future<ApiResponse<List<FolderModel>>> getFolderList({
  //   required String filter,
  //   required int type,
  // }) async {
  //   if (tokenManager.isAccessTokenExpired() &&
  //       tokenManager.refreshToken != null) {
  //     final refreshSuccess = await _refreshToken();
  //     if (!refreshSuccess) {
  //       return ApiResponse<List<FolderModel>>(
  //         success: false,
  //         data: null,
  //         message: '登录已过期，请重新登录',
  //       );
  //     }
  //   }
  //   try {
  //     final uri = Uri.parse(
  //       '$baseUrl/Favorite/list',
  //     ).replace(queryParameters: {'filter': filter, 'type': type.toString()});
  //     // 构建请求
  //     final request = await _client.getUrl(uri);
  //     // 添加token
  //     final accessToken = tokenManager.accessToken;
  //     if (accessToken != null && accessToken.isNotEmpty) {
  //       request.headers.add('Authorization', 'Bearer $accessToken');
  //     }
  //     request.headers.add('Content-Type', 'application/json');
  //     // 发送请求，获取响应
  //     final response = await request.close();
  //     // 处理401
  //     if (response.statusCode == HttpStatus.unauthorized) {
  //       final refreshSuccess = await _refreshToken();
  //       if (refreshSuccess) {
  //         return getFolderList(filter: filter, type: type);
  //       } else {
  //         return ApiResponse<List<FolderModel>>(
  //           success: false,
  //           data: null,
  //           message: '登录已过期，请重新登录',
  //         );
  //       }
  //     }
  //     final responseBody = await utf8.decodeStream(response);
  //     return parseFolderListResponse(responseBody);
  //   } catch (e) {
  //     return ApiResponse<List<FolderModel>>(
  //       success: false,
  //       data: null,
  //       message: '请求失败：${e.toString()}',
  //     );
  //   }
  // }

  Future<QuQResponse<LoginResponseModel>> login({
    required String account,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/User/login');
      final request = await _client.postUrl(uri);
      request.headers.add('Content-Type', 'application/json');
      final requestBody = json.encode({'phone': account, 'password': password});
      request.write(requestBody);
      final response = await request.close();
      final responseBody = await utf8.decodeStream(response);
      final jsonMap = json.decode(responseBody);
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
      final uri = Uri.parse('$baseUrl/User/logout');
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
      final uri = Uri.parse('$baseUrl/user/refresh-token');
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
}
