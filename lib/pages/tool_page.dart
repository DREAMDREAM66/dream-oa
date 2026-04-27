import 'package:flutter/material.dart';
import '../models/constants/app_colors.dart';
import 'checkin_page.dart';
import 'affairs_page.dart';
import 'my_approval_page.dart';
import 'my_application_page.dart';

class ToolPage extends StatelessWidget {
  const ToolPage({super.key});

  // 后续需要动态加载功能，需要改为StatefulWidget
  static const List<ToolFunctionModel> _functionList = [
    ToolFunctionModel(
      functionKey: 'check_in',
      title: '打卡',
      icon: Icons.access_time,
      isEnabled: true,
    ),
    ToolFunctionModel(
      functionKey: 'affairs',
      title: '事务',
      icon: Icons.description,
      isEnabled: true,
    ),
    ToolFunctionModel(
      functionKey: 'my-approval',
      title: '审批',
      icon: Icons.checklist,
      isEnabled: true,
    ),
    ToolFunctionModel(
      functionKey: 'my-application',
      title: '我的申请',
      icon: Icons.assignment,
      isEnabled: true,
    ),
  ];
  // 通过后端接受这样一个列表

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: const Text('工作台'),
        // centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 1,
        foregroundColor: Colors.white,
      ),
      body: GridView.count(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        padding: const EdgeInsets.all(24),
        childAspectRatio: 1.0,
        children: _functionList
            .map(
              (item) => ToolItem(
                icon: item.icon,
                title: item.title,
                functionKey: item.functionKey,
              ),
            )
            .toList(),
      ),
    );
  }
}

class ToolItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String functionKey;

  const ToolItem({
    super.key,
    required this.icon,
    required this.title,
    required this.functionKey,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _handleFunctionTap(context, functionKey);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.mainBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: Icon(icon, size: 32, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _handleFunctionTap(BuildContext context, String functionKey) {
    switch (functionKey) {
      case 'check_in':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CheckInPage()),
        );
        break;
      case 'affairs':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AffairsPage()),
        );
        break;
      case 'my-approval':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyApprovalPage()),
        );
        break;
      case 'my-application':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyApplicationPage()),
        );
        break;
      default:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$functionKey 功能暂未实现')));
        break;
    }
  }
}

class ToolFunctionModel {
  final String functionKey;
  final String title;
  final IconData icon;
  final bool isEnabled;

  const ToolFunctionModel({
    required this.functionKey,
    required this.title,
    required this.icon,
    required this.isEnabled,
  });
}
