class MenuModel {
  final String title;
  final List<SubMenuModel> subMenus;
  MenuModel({required this.title, required this.subMenus});
}

class SubMenuModel {
  final String title;
  final String functionKey;
  SubMenuModel({required this.title, required this.functionKey});
}
