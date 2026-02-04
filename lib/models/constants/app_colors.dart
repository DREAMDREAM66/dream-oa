import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// 全局颜色常量
/// 命名规则：
/// 1. 基础色：primary（主题色）、secondary（次要色）、accent（强调色）
/// 2. 功能色：success（成功）、warning（警告）、error（错误）、info（信息）
/// 3. 中性色：white、black、grey100（浅灰）、grey200（中灰）...
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF14B8A6);
  static const Color secondary = Color(0xFF475569);
  static const Color mainBackground = Color(0xFFF8FAFC);
  // static const Color primaryLight = Color(0xFFB8E9B8);
  // static const Color primaryDark = Color(0xFF77C477);

  static const Color success = Color(0xFF52C41A);
  static const Color warning = Color(0xFFFAAD14);
}
