# CLAUDE.md

本文件为 Claude Code (claude.ai/code) 提供在此代码仓库中工作的指导。

## 项目概述

朝夕 OA 是一个基于 Flutter 的移动办公自动化应用，提供员工考勤打卡、请假申请、行政事务等功能。

**应用名称**: 朝夕
**框架**: Flutter 3.35.5 / Dart 3.9.2
**状态管理**: Flutter 内置 setState（无外部状态管理库）
**HTTP 客户端**: Dart HttpClient + 自定义 ApiClient 封装

## 常用命令

```bash
# 安装依赖
flutter pub get

# 运行应用
flutter run

# 运行到指定设备
flutter run -d <device-id>

# 静态分析
flutter analyze

# 运行测试
flutter test

# 重新生成应用图标（替换 assets/icons/oa_icon.png 后）
flutter pub run flutter_launcher_icons
```

## 配置

在项目根目录创建 `.env` 文件：
```
API_BASE_URL=https://your-api-domain.com/api
```

## 项目架构

### 目录结构

```
lib/
├── main.dart                      # 应用入口，初始化 dotenv、TokenManager、UserManager
├── models/                        # 数据模型
│   ├── response.dart              # QuQResponse<T> 泛型 API 响应封装
│   ├── auth.dart                  # 登录/认证相关模型
│   ├── checkin.dart               # 考勤打卡相关模型
│   ├── location.dart              # 定位服务模型
│   ├── affairs.dart               # 事务中心菜单模型
│   ├── tool_function.dart         # 工作台功能项模型
│   └── constants/                 # 全局常量
│       ├── app_colors.dart        # 颜色常量（主题色 #14B8A6）
│       ├── text_style.dart        # 文本样式常量
│       └── checkin_enums.dart     # 考勤相关枚举
├── pages/                         # UI 页面
│   ├── home_page.dart            # 底部导航主页（工作台 + 我的）
│   ├── tool_page.dart            # 工作台页面（第一 Tab）
│   ├── mine_page.dart            # 我的页面（第二 Tab，含登录/用户信息）
│   ├── checkin_page.dart          # 考勤打卡页面（上下班打卡 + 月度统计）
│   ├── affairs_page.dart          # 事务中心页面（手风琴菜单 + 搜索）
│   └── affairs_feature/          # 事务功能页面实现
│       ├── feature_page.dart      # FeaturePage 抽象基类 + 工厂路由
│       └── leave_page.dart        # 请假申请表单页面
└── utils/                         # 工具类和服务
    ├── api_client.dart            # 核心 HTTP 客户端（单例，含 Token 管理）
    ├── user_manager.dart          # 用户信息单例存储
    ├── location_service.dart      # GPS 定位服务
    └── checkin_utils.dart         # 考勤相关工具函数
```

### 核心模式

**ApiClient** (`lib/utils/api_client.dart`) 是核心 HTTP 处理器：
- 单例模式，全局实例：`apiClient`、`tokenManager`
- 收到 401 响应时自动刷新 Token
- 所有 API 方法返回 `QuQResponse<T>` 封装

**Token 管理**：
- `TokenManager` 通过 SharedPreferences 存储 accessToken / refreshToken
- `isAccessTokenExpired()` 检查 Token 有效性
- `_refreshToken()` 自动在 API 调用前刷新 Token

**功能路由** (`lib/pages/affairs_feature/feature_page.dart`)：
- `FeaturePage` 是功能页面的抽象基类
- `FeaturePage.createPage(SubMenuModel)` 工厂方法通过 `functionKey` 路由到具体页面
- 目前仅 `leave_request` 已实现，其他功能显示"功能开发中"占位页

**UserManager** (`lib/utils/user_manager.dart`)：
- 单例模式，存储/获取用户信息（用户名、部门、职位、角色）
- 通过 SharedPreferences 持久化

### API 响应格式

所有 API 响应使用 `QuQResponse<T>` 封装：
```dart
QuQResponse<T> {
  bool success;
  T? data;
  String? message;
}
```

### 颜色系统

主题色为 **Teal** (`#14B8A6`)，在 `AppColors` 类中定义：
- `primary`: 主色调 (#14B8A6)
- `secondary`: 次要色 (#475569)
- `mainBackground`: 主背景色 (#F8FAFC)
- 新拟物化配色：`neuBackground`、`neuTextPrimary`、`neuTextSecondary` 等

### 国际化

应用支持中英文本地化：
- `Locale('en', 'US')` - 英语
- `Locale('zh', 'CN')` - 简体中文

## 添加新功能

### 添加工作台新功能项

1. 在 `pages/tool_page.dart` 的 `ToolPage.children` 中添加 `ToolItem`

### 添加事务中心新一级功能

1. 在 `pages/affairs_page.dart` 的 `_originalMenuList` 中添加新的 `MenuModel`，并为 `SubMenuModel` 指定唯一的 `functionKey`
2. 子功能的新建和跳转参考**添加事务中心新子功能**

### 添加事务中心新子功能

1. 在 `pages/affairs_page.dart` 的 `_originalMenuList` 中添加新的 `SubMenuModel`，指定唯一的 `functionKey`
2. 在 `lib/pages/affairs_feature/` 下创建新的页面类，继承 `FeaturePage`
3. 在 `FeaturePage.createPage()` 工厂方法中添加新的 case 分支

## 代码风格

- 注释使用中文
- 代码中的函数名、变量名等保持英文风格
- 遵循 Flutter/Dart 官方命名规范
