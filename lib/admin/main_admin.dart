import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:poigo/firebase_options.dart' show DefaultFirebaseOptions;
import 'admin_app.dart';

/// 管理画面（Web）のエントリポイント。
/// 実行例: flutter run -d chrome -t lib/admin/main_admin.dart
///
/// api-key-not-valid が出る場合: プロジェクトルートで
///   flutterfire configure
/// を実行し、Web を有効にして lib/firebase_options.dart を再生成してください。
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _ensureFirebaseInitialized();

  try {
    if (Firebase.apps.isNotEmpty) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  } catch (e) {
    // ignore: avoid_print
    print('Firebase Auth signInAnonymously error: $e');
  }

  runApp(const AdminApp());
}

Future<void> _ensureFirebaseInitialized() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') {
      // ignore: avoid_print
      print('Firebase initialization error: $e');
    }
  } catch (e) {
    // ignore: avoid_print
    print('Firebase initialization error: $e');
  }
}
