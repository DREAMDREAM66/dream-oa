import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'utils/api_client.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await tokenManager.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations
            .delegate, // 提供 Material 组件的翻译 (DatePicker, Button 等)
        GlobalWidgetsLocalizations.delegate, // 提供基础 Widget 的翻译
        GlobalCupertinoLocalizations.delegate, // 提供 iOS 风格组件的翻译
      ],
      supportedLocales: const [
        Locale('en', 'US'), // 英语 (默认必须有)
        Locale('zh', 'CN'), // 简体中文
      ],
      title: '朝夕',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
