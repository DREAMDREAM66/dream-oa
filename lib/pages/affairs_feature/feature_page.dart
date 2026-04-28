import 'package:flutter/material.dart';
import 'package:oa_fontend/models/affairs.dart';
import 'package:oa_fontend/models/constants/app_colors.dart';
import 'package:oa_fontend/models/constants/text_style.dart';
import 'package:oa_fontend/pages/affairs_feature/leave_page.dart';
import 'package:oa_fontend/pages/affairs_feature/overtime_page.dart';

abstract class FeaturePage extends StatelessWidget {
  final String title;
  final String functionKey;

  const FeaturePage({
    super.key,
    required this.title,
    required this.functionKey,
  });

  static Widget createPage(SubMenuModel sm) {
    switch (sm.functionKey) {
      case 'leave_request':
        return LeavePage(title: sm.title, functionKey: sm.functionKey);
      case 'overtime_request':
        return OvertimePage(title: sm.title, functionKey: sm.functionKey);
      default:
        return _PlaceholderFeaturePage(
          title: sm.title,
          functionKey: sm.functionKey,
        );
    }
  }

  Widget buildContent(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: buildContent(context),
    );
  }
}

class _PlaceholderFeaturePage extends FeaturePage {
  const _PlaceholderFeaturePage({
    required super.title,
    required super.functionKey,
  });

  @override
  Widget buildContent(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.construction, size: 60, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '功能开发中',
              style: TextStyle(fontSize: 16, color: AppColors.grey),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('功能标识：$functionKey', style: AppTextStyle.tips),
          ),
        ],
      ),
    );
  }
}
