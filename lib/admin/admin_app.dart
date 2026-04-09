import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';

/// 管理画面用ルートウィジェット。Web で同一 Firebase プロジェクトを管理する。
class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ポイ活 管理画面',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}
