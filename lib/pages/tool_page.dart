import 'package:flutter/material.dart';
import 'checkin_page.dart';

class ToolPage extends StatelessWidget {
  const ToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('工作台'),
        centerTitle: true,
        backgroundColor: const Color(0xFF99DE9F),
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
              color: const Color(0xFF99DE9F)..withAlpha(51),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 32, color: Colors.white),
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
      default:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$functionKey 功能暂未实现')));
        break;
    }
  }
}
