import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();
  static const MethodChannel _phoneAuthGuardChannel =
      MethodChannel('jp.keygo.poigo/phone_auth_guard');

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  String normalizeJpPhoneNumber(String input) {
    final raw = input.replaceAll(RegExp(r'[\s\-()]'), '');
    if (raw.isEmpty) {
      throw const FormatException('電話番号を入力してください');
    }
    if (raw.startsWith('+81')) return raw;
    if (raw.startsWith('81')) return '+$raw';
    if (raw.startsWith('0')) return '+81${raw.substring(1)}';
    if (raw.startsWith('+')) return raw;
    return '+81$raw';
  }

  Future<String> verifyPhoneNumber(String inputPhoneNumber) async {
    final normalized = normalizeJpPhoneNumber(inputPhoneNumber);
    final completer = Completer<String>();

    await _auth.verifyPhoneNumber(
      phoneNumber: normalized,
      verificationCompleted: (PhoneAuthCredential credential) async {
        if (!completer.isCompleted) {
          completer.completeError(
            FirebaseAuthException(
              code: 'auto-verification',
              message: '自動認証が検出されました。手動コード入力を続けます。',
            ),
          );
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
    );

    return completer.future;
  }

  Future<bool> isPhoneAuthSupportedOnCurrentDevice() async {
    if (!Platform.isIOS) return true;
    try {
      final isSimulator =
          await _phoneAuthGuardChannel.invokeMethod<bool>('isIosSimulator') ?? false;
      return !isSimulator;
    } catch (_) {
      // ネイティブ判定に失敗した場合は既存フローを維持
      return true;
    }
  }

  Future<User> signInWithCredential({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    final current = _auth.currentUser;
    User user;

    if (current != null) {
      try {
        final linked = await current.linkWithCredential(credential);
        user = linked.user ?? _auth.currentUser!;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'provider-already-linked') {
          final result = await current.reauthenticateWithCredential(credential);
          user = result.user ?? _auth.currentUser!;
        } else {
          rethrow;
        }
      }
    } else {
      final result = await _auth.signInWithCredential(credential);
      if (result.user == null) {
        throw FirebaseAuthException(code: 'no-user', message: '認証に失敗しました。');
      }
      user = result.user!;
    }

    await _savePhoneVerification(user);
    return user;
  }

  bool hasVerifiedPhone(User? user) {
    if (user == null) return false;
    if ((user.phoneNumber ?? '').isNotEmpty) return true;
    return user.providerData.any((p) => p.providerId == PhoneAuthProvider.PROVIDER_ID);
  }

  Future<void> _savePhoneVerification(User user) async {
    await _firestore.collection('users').doc(user.uid).set({
      'id': user.uid,
      'phoneNumber': user.phoneNumber,
      'phoneVerified': true,
      'phoneVerifiedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

