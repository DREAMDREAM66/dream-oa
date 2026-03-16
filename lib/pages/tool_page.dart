import 'package:flutter/material.dart';
import '../models/constants/app_colors.dart';
import 'checkin_page.dart';
import 'affairs_page.dart';

class ToolPage extends StatelessWidget {
  const ToolPage({super.key});

  // 后续需要动态加载功能，需要改为StatefulWidget
  // List<ToolFunctionModel> _functionList = [
  //   ToolFunctionModel(
  //     functionKey: 'check_in',
  //     title: '打卡',
  //     iconName: 'access_time',
  //     isEnabled: true,
  //   ),
  //   ToolFunctionModel(
  //     functionKey: 'affairs',
  //     title: '事务',
  //     iconName: 'description',
  //     isEnabled: true,
  //   ),
  // ];通过后端接受这样一个列表
  //
  // children: _functionList
  //                 .map((model) => ToolItem(
  //                       icon: _getIconFromName(model.iconName),
  //                       title: model.title,
  //                       functionKey: model.functionKey,
  //                     ))
  //                 .toList(),动态生成

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
        children: const [
          ToolItem(
            icon: Icons.access_time,
            title: '打卡',
            functionKey: 'check_in',
          ),
          ToolItem(
            icon: Icons.description,
            title: '事务',
            functionKey: 'affairs',
          ),
        ],
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
      default:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$functionKey 功能暂未实现')));
        break;
    }
  }
}
