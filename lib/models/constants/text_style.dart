import 'package:flutter/material.dart';
import 'package:oa_fontend/models/constants/app_colors.dart';

class AppTextStyle {
  AppTextStyle._();

  static const TextStyle menuTitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: Colors.black54,
  );
  static const TextStyle subMenuTitle = TextStyle(
    fontSize: 12,
    color: Colors.black54,
  );
  static const TextStyle tips = TextStyle(fontSize: 12, color: Colors.grey);
  static const TextStyle middleTips = TextStyle(
    fontSize: 14,
    color: Colors.grey,
  );
  static const TextStyle primaryTips = TextStyle(
    fontSize: 12,
    color: AppColors.primary,
  );
}
