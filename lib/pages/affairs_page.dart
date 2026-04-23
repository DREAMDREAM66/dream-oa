import 'package:flutter/material.dart';
import 'package:oa_fontend/models/affairs.dart';
import 'package:oa_fontend/models/constants/app_colors.dart';
import 'package:oa_fontend/models/constants/text_style.dart';
import 'affairs_feature/feature_page.dart';

class AffairsPage extends StatefulWidget {
  const AffairsPage({super.key});

  @override
  State<StatefulWidget> createState() => _AffairsPageState();
}

class _AffairsPageState extends State<AffairsPage> {
  final List<MenuModel> _originalMenuList = [
    MenuModel(
      title: '行政管理',
      subMenus: [
        SubMenuModel(title: '用印管理', functionKey: 'seal_management'),
        SubMenuModel(title: '用车管理', functionKey: 'car_management'),
      ],
    ),
    MenuModel(
      title: '考勤管理',
      subMenus: [
        SubMenuModel(title: '请假申请', functionKey: 'leave_request'),
        SubMenuModel(title: '加班申请', functionKey: 'overtime_request'),
        SubMenuModel(title: '补卡申请', functionKey: 'correct_checkin_request'),
      ],
    ),
  ];

  late List<MenuModel> _filteredMenuList;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredMenuList = List.from(_originalMenuList);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final String searchText = _searchController.text.trim().toLowerCase();
    if (searchText.isEmpty) {
      setState(() {
        _filteredMenuList = List.from(_originalMenuList);
      });
      return;
    }
    setState(() {
      _filteredMenuList = _originalMenuList
          .map((menu) {
            final List<SubMenuModel> matchSubMenus = menu.subMenus
                .where((sm) => sm.title.toLowerCase().contains(searchText))
                .toList();
            if (matchSubMenus.isNotEmpty) {
              return MenuModel(title: menu.title, subMenus: matchSubMenus);
            }
            return null;
          })
          .whereType<MenuModel>()
          .toList();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _filteredMenuList = List.from(_originalMenuList);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: const Text('事务中心'),
        centerTitle: true,
        backgroundColor: AppColors.mainBackground,
        foregroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              cursorColor: AppColors.primary,
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索一下吧',
                hintStyle: AppTextStyle.tips,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () => _clearSearch(),
                        icon: const Icon(
                          Icons.clear,
                          size: 16,
                          color: AppColors.grey,
                        ),
                      )
                    : IconButton(
                        onPressed: _performSearch,
                        icon: Icon(
                          Icons.search,
                          size: 16,
                          color: AppColors.grey,
                        ),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.grey, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.grey, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary, width: 1),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                isDense: true,
              ),
              style: AppTextStyle.subMenuTitle,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _performSearch(),
            ),
          ),
          Expanded(
            child: _filteredMenuList.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: AppColors.grey),
                        SizedBox(height: 12),
                        Text('未找到匹配的事务类型', style: AppTextStyle.tips),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: _filteredMenuList.asMap().entries.map((entry) {
                      final int index = entry.key;
                      final MenuModel menu = entry.value;
                      return Column(
                        children: [
                          _AccordionMenu(
                            title: menu.title,
                            titleStyle: AppTextStyle.menuTitle,
                            subMenus: menu.subMenus
                                .map(
                                  (sm) => _SubMenuTitle(
                                    title: sm.title,
                                    titleStyle: AppTextStyle.subMenuTitle,
                                    onTap: () => _handleSubMenuTap(context, sm),
                                  ),
                                )
                                .toList(),
                          ),
                          if (index != _filteredMenuList.length - 1)
                            const Divider(
                              height: 1,
                              color: AppColors.divider,
                              indent: 16,
                              endIndent: 16,
                            ),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  void _handleSubMenuTap(BuildContext context, SubMenuModel sm) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FeaturePage.createPage(sm)),
    );
  }
}

class _AccordionMenu extends StatefulWidget {
  final String title;
  final TextStyle titleStyle;
  final List<Widget> subMenus;

  const _AccordionMenu({
    required this.title,
    required this.titleStyle,
    required this.subMenus,
  });

  @override
  State<StatefulWidget> createState() => _AccordionMenuState();
}

class _AccordionMenuState extends State<_AccordionMenu> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.title, style: widget.titleStyle),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  size: 18,
                  color: AppColors.grey,
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Column(children: widget.subMenus),
          ),
      ],
    );
  }
}

class _SubMenuTitle extends StatelessWidget {
  final String title;
  final TextStyle titleStyle;
  final VoidCallback onTap;

  const _SubMenuTitle({
    required this.title,
    required this.titleStyle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(Icons.label_outline, size: 14, color: AppColors.grey),
            const SizedBox(width: 8),
            Text(title, style: titleStyle),
          ],
        ),
      ),
    );
  }
}
