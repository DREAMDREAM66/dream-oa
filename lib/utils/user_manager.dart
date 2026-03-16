import 'package:shared_preferences/shared_preferences.dart';

class UserManager {
  // 类加载时直接初始化静态变量
  static final UserManager _instance = UserManager._internal();
  // 工厂构造函数
  factory UserManager() => _instance;
  // 命名构造函数，类似UserManager.fromJson
  UserManager._internal();

  static const String _keyUsername = 'username';
  static const String _keyPhone = 'phone';
  static const String _keyDepartment = 'department';
  static const String _keyTitle = 'title';
  static const String _keyRole = 'role';

  String? _username;
  String? _phone;
  String? _department;
  String? _title;
  String? _role;

  Future<void> saveUserInfo({
    required String username,
    required String phone,
    required String department,
    required String title,
    required String role,
  }) async {
    _username = username;
    _phone = phone;
    _department = department;
    _title = title;
    _role = role;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, username);
    await prefs.setString(_keyPhone, phone);
    await prefs.setString(_keyDepartment, department);
    await prefs.setString(_keyTitle, title);
    await prefs.setString(_keyRole, role);
  }

  Future<void> loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString(_keyUsername);
    _phone = prefs.getString(_keyPhone);
    _department = prefs.getString(_keyDepartment);
    _title = prefs.getString(_keyTitle);
    _role = prefs.getString(_keyRole);
  }

  Future<void> clearUserInfo() async {
    _username = null;
    _phone = null;
    _department = null;
    _title = null;
    _role = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyPhone);
    await prefs.remove(_keyDepartment);
    await prefs.remove(_keyTitle);
    await prefs.remove(_keyRole);
  }

  String? get username => _username;
  String? get phone => _phone;
  String? get department => _department;
  String? get title => _title;
  String? get role => _role;

  String getLastTwoChars() {
    if (_username == null || _username!.isEmpty) return '';
    if (_username!.length <= 2) return _username!;
    return username!.substring(_username!.length - 2);
  }
}

final userManager = UserManager();
