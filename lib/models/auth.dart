class LoginResponseModel {
  final String accessToken;
  final String refreshToken;
  final String accessTokenExpiry;
  final String refreshTokenExpiry;
  final String username;
  final String phone;
  final String department;
  final String title;
  final String role;

  LoginResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiry,
    required this.refreshTokenExpiry,
    required this.username,
    required this.phone,
    required this.department,
    required this.title,
    required this.role,
  });

  // 从 JSON 解析
  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      accessTokenExpiry: json['accessTokenExpiry'] ?? '',
      refreshTokenExpiry: json['refreshTokenExpiry'] ?? '',
      username: json['username'] ?? '',
      phone: json['phone'] ?? '',
      department: json['department'] ?? '',
      title: json['title'] ?? '',
      role: json['role'] ?? '',
    );
  }
}

// 刷新 Token 响应数据模型（对应 data 字段）
class RefreshTokenResponseModel {
  final String newAccessToken;
  final String newAccessTokenExpiry;

  RefreshTokenResponseModel({
    required this.newAccessToken,
    required this.newAccessTokenExpiry,
  });

  // 从 JSON 解析
  factory RefreshTokenResponseModel.fromJson(Map<String, dynamic> json) {
    return RefreshTokenResponseModel(
      newAccessToken: json['newAccessToken'] ?? '',
      newAccessTokenExpiry: json['newAccessTokenExpiry'] ?? '',
    );
  }
}
