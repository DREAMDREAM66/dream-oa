# DreamOA - Open Source Office System based on Flutter

> A lightweight(really?), cross-platform mobile OA (Office Automation) frontend solution. Platform support depends on Flutter capabilities.

🇨🇳 [简体中文](README.md) | 🇺🇸 English

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter Version](https://img.shields.io/badge/Flutter-3.35.5-blue)](https://flutter.dev)


## Project Preview

<div align="center">
  <img src="screenshots/login.jpg" width="28%" alt="Login" />
  <img src="screenshots/tools.jpg" width="28%" alt="Workbench" />
  <img src="screenshots/checkin.jpg" width="28%" alt="Check-in" />
</div>

<div align="center">
  <img src="screenshots/checkin-detail.jpg" width="28%" alt="Attendance Records" />
  <img src="screenshots/affairs.jpg" width="28%" alt="Affairs" />
  <img src="screenshots/leave.jpg" width="28%" alt="Leave" />
</div>

<small>⚠️ The UI shown in the screenshots may not reflect the latest version. Actual interface is based on the project code.</small>


## Core Features

The project is currently in its early stages. Implemented features include:

- **Authentication**: Username/Password login with automatic Token refresh.
- **Attendance**: Clock-in/out functionality with history display.
- **Approval Workflow**: Initiate leave applications.
- **Localization**: Multi-language support (Chinese/English).

*Planned Features: Approval chains, Global State Management, Custom Form Engine.*

## Tech Stack

- **Framework**: Flutter 3.35.5 (Dart 3.9.2)
- **State Management**: Built-in setState
- **Network**: Dio 5.9.2
- **Local Storage**: SharedPreferences
- **UI Components**: [Calendar: flutter_calendar_carousel](https://github.com/hyochan/flutter_calendar_carousel)

## Quick Start

### Prerequisites
**Developer Environment**
- Flutter SDK >= 3.35.5
- Dart SDK >= 3.9.2

### Installation & Running

1. **Clone the repository**
   ```bash
   git clone https://github.com/DREAMDREAM66/dream-oa.git
   cd dream-oa
   ```
2. **Install Dependencies**
   ```bash
   # Get packages
   flutter pub get
   # Check environment health
   flutter doctor
   ```
3. **Configuration**  
   Create a .env file in the root directory.  
   *This file contains sensitive info and is included in .gitignore, so it won't be committed.*
   ```
   # Enter your backend API address
   API_BASE_URL=https://your-api-domain.com/api
   ```
4. **Build & Run**
   ```
   flutter run
   # Or run on a specific device
   flutter run -d <device_id>
   ```

### Additional Configuration

1. **App Icon**  
   This project uses flutter_launcher_icons to generate icons. To customize:  
   - Place your source icon (oa_icon.png, recommended 1024x1024) in the assets/icons/ directory.
   - Run the following command in the project root:
   ```
   flutter pub run flutter_launcher_icons
   ```
2. **API Endpoints**  
   All API request definitions are located in utils/api_client.dart. You can modify them to match your backend:
   ``` dart
   final uri = Uri.parse('$baseUrl/Checkin/checkin-info');
   ```

## Contributing

**The author is a beginner in the open-source world. Contributions and suggestions from all angles are highly welcome!**

**We welcome Issues and Pull Requests!**
1. *Fork this repository*
2. *Create a Feat_xxx branch*
3. *Commit your changes*
4. *Open a Pull Request*

## License  

This project is licensed under the MIT License.  
In short: You are free to use, modify, and distribute this software for commercial or non-commercial purposes, provided you retain the original copyright notice.  

See the [LICENSE](LICENSE) file for details.