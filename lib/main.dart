import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// 注意：這裡必須與 pubspec.yaml 的 name: soratalk_v2 一致
import 'package:soratalk_v2/screens/chat_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoraTalk V2',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // 使用天空藍色調，符合 Sora (天空) 的意象
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
        // 關鍵優化：強制使用 Noto Sans JP 字體，確保日文漢字與括號讀音在 Web 端絕對不位移
        textTheme: GoogleFonts.notoSansJpTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: const ChatScreen(),
    );
  }
}