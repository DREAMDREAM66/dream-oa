import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// 全局颜色常量
/// 命名规则：
/// 1. 基础色：primary（主题色）、secondary（次要色）、mainBackground（主背景色）
/// 2. 功能色：success（成功）、warning（警告）、error（错误）、info（信息）
/// 3. 中性色：white、black、grey100（浅灰）、grey200（中灰）...
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF14B8A6);
  static const Color lightPrimary = Color(0xFF10B981);
  static const Color secondary = Color(0xFF475569);
  static const Color mainBackground = Color(0xFFF8FAFC);
  // static const Color primaryLight = Color(0xFFB8E9B8);
  // static const Color primaryDark = Color(0xFF77C477);

  static const Color success = Color(0xFF52C41A);
  static const Color warning = Color(0xFFFAAD14);

  static const Color dividerDark = Color(0xFFE4E4E4);
  static const Color divider = Color(0xFFF0F0F0);

  // ─── 通用中性色 ───────────────────────────────────────────────────────
  /// 标准灰色 — 用于次要文字、图标、分割线等
  static const Color grey = Color(0xFF9E9E9E);

  /// 次深灰色 — 用于 placeholder、辅助文字
  static const Color grey600 = Color(0xFF757575);

  /// 通用深色文字色
  static const Color black87 = Color(0xDD000000);

  // ─── 新拟物化配色 ─────────────────────────────────────────────────────
  /// 新拟物化卡片背景色 — 略深于纯白，使双层柔和阴影可见
  static const Color neuBackground = Color(0xFFF0F4F8);

  /// 新拟物化卡片内部分割线/边框色
  static const Color neuDivider = Color(0xFFE2E8F0);

  /// 新拟物化卡片主文字色
  static const Color neuTextPrimary = Color(0xFF1E293B);

  /// 新拟物化卡片次要/占位文字色
  static const Color neuTextSecondary = Color(0xFF94A3B8);
}
