import 'package:flutter/material.dart';
import '../models/constants/app_colors.dart';
import 'mine_page.dart';
import 'tool_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    ToolPage(),
    MinePage(), // 我的页面
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.mainBackground,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.keyboard), label: '工作台'),
          BottomNavigationBarItem(icon: Icon(Icons.face), label: '我'),
        ],
        selectedItemColor: AppColors.primary,
      ),
    );
  }
}
