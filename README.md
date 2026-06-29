# DreamOA - 基于 Flutter 的开源办公系统

> 一个轻量级（真的吗？）、跨平台的移动端 OA 前端解决方案。支持平台取决于Flutter。

🇨🇳 简体中文 | 🇺🇸 [English](README_EN.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter Version](https://img.shields.io/badge/Flutter-3.35.5-blue)](https://flutter.dev)


## 项目预览

<div align="center">
  <img src="screenshots/login.jpg" width="28%" alt="登录页" />
  <img src="screenshots/tools.jpg" width="28%" alt="工作台" />
  <img src="screenshots/checkin.jpg" width="28%" alt="打卡页" />
</div>

<div align="center">
  <img src="screenshots/checkin-detail.jpg" width="28%" alt="考勤记录" />
  <img src="screenshots/affairs.jpg" width="28%" alt="事务页" />
  <img src="screenshots/leave.jpg" width="28%" alt="请假页" />
</div>

<div align="center">
  <img src="screenshots/my-approval.jpg" width="28%" alt="待审批" />
  <img src="screenshots/approve-detail.jpg" width="28%" alt="审批详情" />
  <img src="screenshots/my-application.jpg" width="28%" alt="我的申请" />
</div>

> ⚠️ 截图展示的 UI 样式可能不代表最新版本，实际界面以项目代码为准。


## 相关项目

| 项目 | 仓库 | 说明 |
|------|------|------|
| **前端** | [dream-oa](https://github.com/DREAMDREAM66/dream-oa) | 本项目 |
| **后端** | [dream-oa-api](https://github.com/DREAMDREAM66/dream-oa-api) | .NET 后端服务 |


## 核心功能

目前项目处于起步阶段，已实现以下功能：

- **用户认证**：支持账号密码登录、Token 自动刷新。
- **打卡**：上下班打卡、打卡信息展示。
- **审批流程**：发起请假/加班申请，操作审批，查看我的申请。
- **个性化**：多语言支持 (中文/英文)。

*计划中功能：全局状态控制、自定义表单。*

## 技术栈

- **Framework**: Flutter 3.35.5 (Dart 3.9.2)
- **State Management**: Built-in setState
- **Network**: Dio 5.9.2
- **Local Storage**: SharedPreferences
- **UI Components**: [日历组件：flutter_calendar_carousel](https://github.com/hyochan/flutter_calendar_carousel)

## 快速开始

### 环境要求
**作者开发环境**
- Flutter SDK >= 3.35.5
- Dart SDK >= 3.9.2

### 安装与运行

1. **克隆项目**
   ```bash
   git clone https://github.com/DREAMDREAM66/dream-oa.git
   cd dream-oa
   ```
2. **依赖与环境**
   ```bash
   # 下载依赖
   flutter pub get
   # 可以运行flutter doctor检测运行环境是否完备
   flutter doctor
   ```
3. **配置**  
   在项目根目录新建.env文件  
   *.env 文件包含敏感信息，已加入 .gitignore，不会上传到仓库。*
   ```
   # 写入后端接口地址
   API_BASE_URL=https://your-api-domain.com/api
   ```
4. **编译运行**
   ```
   flutter run
   # 或者在指定设备运行
   flutter run -d <设备ID>
   ```

### 其它信息

1. **应用图标**  
   本项目采用flutter_launcher_icons包来生成图标，你可以进行以下操作将图标更改为你喜欢的：
   - 将你的图标源文件(oa_icon.png, 推荐1024x1024)放入assets/icons/目录。
   - 在项目目录下运行
   ```
   flutter pub run flutter_launcher_icons
   ```
2. **请求接口**  
   本项目向后端请求的接口都在utils/api_client.dart下定义，你可以修改为你的API
   ``` dart
   final response = await dioClient.dio.get('/Common/current-time');
   ```

### iOS 开发配置

Fork 本项目后，编译 iOS 前需要修改以下配置：

1. **用 Xcode 打开项目**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **修改 Bundle Identifier**
   - 选择左侧 `Runner` 项目
   - 进入 `Signing & Capabilities` 标签页
   - 将 `com.xcql.dreamoa` 改为你的唯一标识符（如 `com.yourname.yourapp`）

3. **选择开发者 Team**
   - 在同一页面的 `Team` 下拉菜单中选择你的开发者账号

4. **编译运行**
   ```bash
   flutter run
   ```

> 💡 **提示**：Android 编译无需额外配置，直接 `flutter build apk` 即可。

## 参与贡献

**作者是刚接触开源世界的个人练习生，欢迎大家在各个角度提出宝贵的建议**

**欢迎提交 Issue 和 Pull Request！**
1. *Fork 本仓库*
2. *新建 Feat_xxx 分支*
3. *提交代码*
4. *新建 Pull Request*

## 许可证 (License)

本项目采用 [MIT 许可证](LICENSE) 开源。  
简单来说：你可以自由使用、修改和商用，但请保留原作者版权声明。

详见 [LICENSE](LICENSE) 文件。