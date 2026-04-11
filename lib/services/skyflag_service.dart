import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';

/// SKYFLAG OW（オファーウォール）遷移用URL生成（仕様書 p.6-7）
class SkyflagService {
  SkyflagService._();
  static final SkyflagService instance = SkyflagService._();

  /// 連携シートの「テスト / 本番」に合わせて切り替え。
  /// - `prod` … 本番
  /// - `stg` … テスト（STG）
  ///
  /// ビルド例: `--dart-define=SKYFLAG_ENV=stg`
  static const String skyflagEnv = String.fromEnvironment(
    'SKYFLAG_ENV',
    defaultValue: 'prod',
  );

  static bool get _isStg {
    final e = skyflagEnv.toLowerCase().trim();
    return e == 'stg' || e == 'staging' || e == 'test';
  }

  // ---------------------------------------------------------------------------
  // メディアID（_owp）: SKYFLAG 担当発行後に置き換えてください。
  // dart-define で上書き可能: SKYFLAG_MEDIA_ID_STG / SKYFLAG_MEDIA_ID_PROD
  // または従来どおり SKYFLAG_MEDIA_ID のみ（stg/prod 共通で使う場合）
  // ---------------------------------------------------------------------------
  /// テスト（stg）用 _owp（プレースホルダ）
  static const String mediaIdStg = 'REPLACE_WITH_MEDIA_ID_STG';
  /// 本番（prod）用 _owp（プレースホルダ）
  static const String mediaIdProd = 'REPLACE_WITH_MEDIA_ID_PROD';

  static const String mediaIdStgOverride = String.fromEnvironment(
    'SKYFLAG_MEDIA_ID_STG',
    defaultValue: '',
  );
  static const String mediaIdProdOverride = String.fromEnvironment(
    'SKYFLAG_MEDIA_ID_PROD',
    defaultValue: '',
  );

  /// 本番のみ: 連携シートで iOS / Android で _owp が分かれる場合に指定（空なら下記にフォールバック）
  static const String mediaIdProdIosOverride = String.fromEnvironment(
    'SKYFLAG_MEDIA_ID_PROD_IOS',
    defaultValue: '',
  );
  static const String mediaIdProdAndroidOverride = String.fromEnvironment(
    'SKYFLAG_MEDIA_ID_PROD_ANDROID',
    defaultValue: '',
  );

  /// 後方互換: 環境に関係なく単一メディアIDで動かす場合
  static const String mediaIdSingle = String.fromEnvironment(
    'SKYFLAG_MEDIA_ID',
    defaultValue: '',
  );

  static String _resolvedMediaId() {
    if (mediaIdSingle.isNotEmpty) {
      return mediaIdSingle;
    }
    if (_isStg) {
      return mediaIdStgOverride.isNotEmpty ? mediaIdStgOverride : mediaIdStg;
    }
    if (!kIsWeb) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
          if (mediaIdProdIosOverride.isNotEmpty) {
            return mediaIdProdIosOverride;
          }
          break;
        case TargetPlatform.android:
          if (mediaIdProdAndroidOverride.isNotEmpty) {
            return mediaIdProdAndroidOverride;
          }
          break;
        default:
          break;
      }
    }
    return mediaIdProdOverride.isNotEmpty ? mediaIdProdOverride : mediaIdProd;
  }

  /// suid 暗号化のための秘密鍵（AES）。
  /// 本番では必須（未設定時は例外を投げる）。
  static const String defaultAesSecret = String.fromEnvironment(
    'SKYFLAG_AES_SECRET',
    defaultValue: '',
  );

  /// URLスキームのアプリ名（仕様書の `{app_name}` に相当）
  static const String defaultAppScheme = 'poigo';

  /// WebView の User-Agent（空なら OS 既定）。OW が「OS 非対応」と誤判定する場合の検証用。
  /// 例: `--dart-define=SKYFLAG_WEBVIEW_USER_AGENT=Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36`
  /// ※ 本番で使う前に SKYFLAG 担当へ可否を確認すること。
  static const String webviewUserAgent = String.fromEnvironment(
    'SKYFLAG_WEBVIEW_USER_AGENT',
    defaultValue: '',
  );

  // ---------------------------------------------------------------------------
  // OW ベースURL: STG/本番で別URLが届いたらここを書き分けてください。
  // 現状は同一ホストのプレースホルダ。
  // ---------------------------------------------------------------------------
  /// テスト（STG）… 連携シート「オファーウォール テスト環境URL」のホスト（ow.stg.skyflag.jp）
  static const String owBaseUrlIosStg = 'https://ow.stg.skyflag.jp/ad/p/ow/index';
  static const String owBaseUrlAndroidStg =
      'https://ow.stg.skyflag.jp/ad/p/ow/index';
  static const String owBaseUrlPcStg = 'https://ow.stg.skyflag.jp/ad/p/ow/index';
  /// 本番 … ow.skyflag.jp
  static const String owBaseUrlIosProd = 'https://ow.skyflag.jp/ad/p/ow/index';
  static const String owBaseUrlAndroidProd =
      'https://ow.skyflag.jp/ad/p/ow/index';
  static const String owBaseUrlPcProd = 'https://ow.skyflag.jp/ad/p/ow/index';

  static String _owBaseUrlForPlatform() {
    if (kIsWeb) {
      return _isStg ? owBaseUrlPcStg : owBaseUrlPcProd;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return _isStg ? owBaseUrlIosStg : owBaseUrlIosProd;
      case TargetPlatform.android:
        return _isStg ? owBaseUrlAndroidStg : owBaseUrlAndroidProd;
      default:
        return _isStg ? owBaseUrlPcStg : owBaseUrlPcProd;
    }
  }

  /// AES-256-CBC (PKCS7) で suid を生成する
  static String _encryptSuid({
    required String uid,
    required String aesSecret,
  }) {
    final keyDigest = sha256.convert(utf8.encode(aesSecret)).bytes;
    final key = encrypt.Key(Uint8List.fromList(keyDigest));

    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(
        key,
        mode: encrypt.AESMode.cbc,
        padding: 'PKCS7',
      ),
    );

    final encrypted = encrypter.encrypt(uid, iv: iv);
    final out = Uint8List.fromList([...iv.bytes, ...encrypted.bytes]);
    return base64UrlEncode(out).replaceAll('=', '');
  }

  /// オファーウォールへ遷移するURLを生成（仕様書 p.6-7）
  /// `?_owp=...&suid=...` に `spram1` / `spram2` で導線識別子を付与可能。
  String buildOfferWallUrl({
    required String uid,
    String? mediaId,
    String? aesSecret,
    String? spram1,
    String? spram2,
  }) {
    final owp = mediaId ?? _resolvedMediaId();
    if (owp.isEmpty) {
      throw StateError(
        'SkyflagService: メディアID（_owp）が空です。'
        'SKYFLAG_MEDIA_ID_STG / SKYFLAG_MEDIA_ID_PROD（または PROD_IOS・PROD_ANDROID）を dart-define で設定してください。',
      );
    }

    final secret = aesSecret ?? defaultAesSecret;
    if (secret.trim().isEmpty) {
      throw StateError(
        'SkyflagService: SKYFLAG_AES_SECRET が空です。'
        'suid の暗号化が必須のため dart-define で設定してください。',
      );
    }
    final suid = _encryptSuid(uid: uid, aesSecret: secret);

    final baseUrl = _owBaseUrlForPlatform();
    final buffer = StringBuffer('$baseUrl?');
    buffer.write('_owp=${Uri.encodeComponent(owp)}&');
    buffer.write('suid=${Uri.encodeComponent(suid)}');

    if (spram1 != null && spram1.isNotEmpty) {
      buffer.write('&spram1=${Uri.encodeComponent(spram1)}');
    }
    if (spram2 != null && spram2.isNotEmpty) {
      buffer.write('&spram2=${Uri.encodeComponent(spram2)}');
    }
    final finalUrl = buffer.toString();
    if (kDebugMode) {
      // AccessDenied 切り分け用: 最終的に生成された OW URL を確認する。
      // ignore: avoid_print
      print('[SKYFLAG] offerwall url: $finalUrl');
    }
    return finalUrl;
  }
}
