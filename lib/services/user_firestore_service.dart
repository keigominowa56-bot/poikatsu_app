import 'dart:math' show Random;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poigo/models/user_model.dart';
import 'package:poigo/services/device_id_service.dart';
import 'package:poigo/services/economy_settings_service.dart';
import 'package:poigo/services/level_service.dart';

/// Firestore の users/{userId} の読み書きとストリームを担当するサービス
class UserFirestoreService {
  UserFirestoreService._();
  static final UserFirestoreService _instance = UserFirestoreService._();
  static UserFirestoreService get instance => _instance;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  static const String _collection = 'users';
  static const String _pointHistoryCollection = 'point_history';
  static const String _rankSettingsCollection = 'rank_settings';

  /// チップ獲得履歴を point_history に1件追加
  Future<void> _logPointHistory(String uid, String reason, int amount) async {
    if (amount <= 0) return;
    await _firestore.collection(_pointHistoryCollection).add({
      'userId': uid,
      'reason': reason,
      'amount': amount,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── ランク/倍率（共通） ───

  /// 累計獲得チップに応じたボーナス倍率（1.0〜1.5）- ランク用
  static double bonusMultiplierFromEarned(int earned) {
    if (earned >= 500000) return 1.5;
    if (earned >= 200000) return 1.3;
    if (earned >= 50000) return 1.2;
    if (earned >= 10000) return 1.1;
    return 1.0;
  }

  /// レベルに応じた還元率（0〜0.5）を加味した倍率。1.0 + rate。
  static double _multiplierWithRedemption(int totalEarned, int levelPenalty) {
    final level = LevelService.displayLevel(totalEarned, levelPenalty);
    final rate = LevelService.redemptionRateForLevel(level);
    return 1.0 + rate;
  }

  static String rankNameFromEarned(int earned) {
    if (earned >= 500000) return 'ダイヤモンド';
    if (earned >= 200000) return 'プラチナ';
    if (earned >= 50000) return 'ゴールド';
    if (earned >= 10000) return 'シルバー';
    return 'ブロンズ';
  }

  /// ユーザードキュメントのスナップショットストリーム（クラウド同期用）
  Stream<UserModel?> streamUser(String uid) {
    return _firestore.collection(_collection).doc(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      final data = snap.data()!;
      return _userFromFirestoreData(snap.id, data);
    });
  }

  /// 初回ロード用：1回だけ取得。存在しなければ null
  Future<UserModel?> getUserOnce(String uid) async {
    final snap = await _firestore.collection(_collection).doc(uid).get();
    if (!snap.exists || snap.data() == null) return null;
    return _userFromFirestoreData(snap.id, snap.data()!);
  }

  /// ユーザードキュメントが無い場合のみ作成（デバイスチェック済みで deviceId を保存）
  Future<void> ensureUserExists(String uid) async {
    final snap = await _firestore.collection(_collection).doc(uid).get();
    if (snap.exists) return;
    final deviceId = await _getDeviceId();
    if (deviceId.isNotEmpty) {
      final existing = await _firestore
          .collection(_collection)
          .where('deviceId', isEqualTo: deviceId)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        throw StateError('このデバイスでは既にアカウントが作成されています');
      }
    }
    final code = _generateReferralCode(uid);
    final now = FieldValue.serverTimestamp();
    await _firestore.collection(_collection).doc(uid).set({
      'id': uid,
      'totalPoints': 0,
      'totalEarnedChips': 0,
      'todaySteps': 0,
      'totalSteps': 0,
      'updatedAt': now,
      'createdAt': now,
      if (deviceId.isNotEmpty) 'deviceId': deviceId,
      'referralCode': code,
      'fullness': 1.0,
      'cleanliness': 1.0,
      'petLevel': 1,
      'petExp': 0,
      'lastPetUpdate': now,
      'levelPenalty': 0,
    });
  }

  static Future<String> _getDeviceId() async {
    try {
      return await DeviceIdService.instance.getDeviceId();
    } catch (_) {
      return '';
    }
  }

  /// 同一デバイスで既にアカウントが作成されていないかチェック（1デバイス1アカウント）
  Future<bool> isDeviceAvailable(String deviceId) async {
    if (deviceId.isEmpty) return true;
    final q = await _firestore
        .collection(_collection)
        .where('deviceId', isEqualTo: deviceId)
        .limit(1)
        .get();
    return q.docs.isEmpty;
  }

  /// 歩数・タンク状態を保存（合計ポイントはそのまま）。初回作成時に deviceId を渡すと1デバイス1アカウントをチェック。
  Future<void> saveUserData(String uid, {int? totalPoints, int? todaySteps, DateTime? birthDate, String? prefecture, String? deviceId}) async {
    final ref = _firestore.collection(_collection).doc(uid);
    final snap = await ref.get();
    final now = FieldValue.serverTimestamp();

    if (!snap.exists) {
      if (deviceId != null && deviceId.isNotEmpty) {
        final existing = await _firestore
            .collection(_collection)
            .where('deviceId', isEqualTo: deviceId)
            .limit(1)
            .get();
        if (existing.docs.isNotEmpty) {
          throw StateError('このデバイスでは既にアカウントが作成されています');
        }
      }
      final referralCode = _generateReferralCode(uid);
      await ref.set({
        'id': uid,
        'totalPoints': totalPoints ?? 0,
        'totalEarnedChips': 0,
        'todaySteps': todaySteps ?? 0,
        'totalSteps': 0,
        'updatedAt': now,
        'createdAt': now,
        if (birthDate != null) 'birthDate': birthDate.toIso8601String(),
        if (prefecture != null) 'prefecture': prefecture,
        if (deviceId != null && deviceId.isNotEmpty) 'deviceId': deviceId,
        'referralCode': referralCode,
        'fullness': 1.0,
        'cleanliness': 1.0,
        'petLevel': 1,
        'petExp': 0,
        'lastPetUpdate': now,
      });
      return;
    }

    final data = snap.data()!;
    final updates = <String, dynamic>{'updatedAt': now};
    if (totalPoints != null) updates['totalPoints'] = totalPoints;
    if (todaySteps != null) {
      final prevToday = (data['todaySteps'] as num?)?.toInt() ?? 0;
      final prevTotal = (data['totalSteps'] as num?)?.toInt() ?? 0;
      updates['todaySteps'] = todaySteps;
      updates['totalSteps'] = prevTotal + (todaySteps! - prevToday).clamp(0, 0x7FFFFFFF);
    }
    if (birthDate != null) updates['birthDate'] = birthDate.toIso8601String();
    if (prefecture != null) updates['prefecture'] = prefecture;
    await ref.update(updates);
  }

  /// ペットお世話: 経過時間で減少した満腹度・清潔度を計算し、加算後に保存。レベルアップ時は true を返す。
  /// 1時間あたり10%減少。満腹/清潔度が0のまま「100→0の所要時間」(10時間)放置でレベルダウンペナルティ。
  static const double _petDecayPerHour = 0.10;
  static const int _petExpPerCare = 10;
  /// 100から0になるまでの時間（時間単位）。10%×10h = 100%
  static const double _petDecayDurationHours = 10.0;

  static int _expRequiredForLevel(int level) => 50 + level * 50;

  static DateTime? _parseTimestamp(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    return DateTime.tryParse(v.toString());
  }

  Future<bool> updatePetCare(String uid, {required double fullnessAdd, required double cleanlinessAdd, int? expAdd}) async {
    final ref = _firestore.collection(_collection).doc(uid);
    final expToAdd = expAdd ?? _petExpPerCare;
    final now = DateTime.now();

    final result = await _firestore.runTransaction<bool>((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists || snap.data() == null) return false;
      final data = snap.data()!;
      double fullness = (data['fullness'] as num?)?.toDouble() ?? 1.0;
      double cleanliness = (data['cleanliness'] as num?)?.toDouble() ?? 1.0;
      int petLevel = (data['petLevel'] as num?)?.toInt() ?? 1;
      int petExp = (data['petExp'] as num?)?.toInt() ?? 0;
      int levelPenalty = (data['levelPenalty'] as num?)?.toInt() ?? 0;
      DateTime? lastPet = _parseTimestamp(data['lastPetUpdate']);
      DateTime? lastFullnessZero = _parseTimestamp(data['lastFullnessZeroAt']);
      DateTime? lastCleanlinessZero = _parseTimestamp(data['lastCleanlinessZeroAt']);

      final last = lastPet ?? now;
      final hours = now.difference(last).inMinutes / 60.0;
      final decay = (hours * _petDecayPerHour).clamp(0.0, 1.0);
      final currentFullness = (fullness - decay).clamp(0.0, 1.0);
      final currentCleanliness = (cleanliness - decay).clamp(0.0, 1.0);

      int newPenalty = levelPenalty;
      DateTime? newLastFullnessZero = lastFullnessZero;
      DateTime? newLastCleanlinessZero = lastCleanlinessZero;

      if (currentFullness <= 0 && lastFullnessZero != null) {
        final elapsed = now.difference(lastFullnessZero).inMinutes / 60.0;
        if (elapsed >= _petDecayDurationHours) {
          newPenalty = levelPenalty + 1;
          newLastFullnessZero = null;
        }
      }
      if (currentCleanliness <= 0 && lastCleanlinessZero != null) {
        final elapsed = now.difference(lastCleanlinessZero).inMinutes / 60.0;
        if (elapsed >= _petDecayDurationHours) {
          newPenalty = levelPenalty + 1;
          newLastCleanlinessZero = null;
        }
      }

      final newFullness = (currentFullness + fullnessAdd).clamp(0.0, 1.0);
      final newCleanliness = (currentCleanliness + cleanlinessAdd).clamp(0.0, 1.0);
      if (newFullness <= 0) newLastFullnessZero = now;
      if (newCleanliness <= 0) newLastCleanlinessZero = now;

      int newExp = petExp + expToAdd;
      int newLevel = petLevel;
      final required = _expRequiredForLevel(petLevel);
      if (newExp >= required) {
        newLevel = petLevel + 1;
        newExp = newExp - required;
      }

      tx.update(ref, {
        'fullness': newFullness,
        'cleanliness': newCleanliness,
        'petLevel': newLevel,
        'petExp': newExp,
        'lastPetUpdate': Timestamp.fromDate(now),
        'levelPenalty': newPenalty,
        'lastFullnessZeroAt': newLastFullnessZero != null ? Timestamp.fromDate(newLastFullnessZero) : null,
        'lastCleanlinessZeroAt': newLastCleanlinessZero != null ? Timestamp.fromDate(newLastCleanlinessZero) : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return newLevel > petLevel;
    });
    return result;
  }

  /// Lv.4+用: 生成したキャラ画像URLとプロンプトをFirestoreに保存
  Future<void> saveCustomCharacter(String uid, String imageUrl, String prompt) async {
    final ref = _firestore.collection(_collection).doc(uid);
    await ref.set({
      'id': uid,
      'customCharacterImageUrl': imageUrl,
      'customCharacterPrompt': prompt,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// デバッグ用: ペットレベルを指定値に設定（テスト用。本番では呼ばないこと）
  Future<void> setPetLevelForDebug(String uid, int level) async {
    final ref = _firestore.collection(_collection).doc(uid);
    await ref.set({
      'petLevel': level.clamp(1, 99),
      'petExp': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// チップを付与（宝くじ当選など）。totalPoints と totalEarnedChips を加算し、履歴に記録する。
  Future<void> grantChips(String uid, int amount, String reason) async {
    if (amount <= 0) return;
    final ref = _firestore.collection(_collection).doc(uid);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      int total = (snap.data()?['totalPoints'] as num?)?.toInt() ?? 0;
      int totalEarned = (snap.data()?['totalEarnedChips'] as num?)?.toInt() ?? 0;
      total += amount;
      totalEarned += amount;
      tx.set(ref, {
        'id': uid,
        'totalPoints': total,
        'totalEarnedChips': totalEarned,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
    await _logPointHistory(uid, reason, amount);
  }

  /// お世話（広告 or チップ消費）など「履歴に残したいが grantPoints と紐づかない」行為用の獲得ログ。
  Future<void> logEarning(String uid, String reason, int amount) async {
    await _logPointHistory(uid, reason, amount);
  }

  /// チップを消費（ペットお世話用）。不足時は false、成功時は true。
  Future<bool> tryConsumePoints(String uid, int amount) async {
    if (amount <= 0) return true;
    final ref = _firestore.collection(_collection).doc(uid);
    return _firestore.runTransaction<bool>((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists || snap.data() == null) return false;
      int total = (snap.data()!['totalPoints'] as num?)?.toInt() ?? 0;
      if (total < amount) return false;
      tx.update(ref, {
        'totalPoints': total - amount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
  }

  /// ニックネーム（displayName）を保存
  Future<void> saveDisplayName(String uid, String? displayName) async {
    final ref = _firestore.collection(_collection).doc(uid);
    await ref.set({
      'id': uid,
      'displayName': displayName?.trim().isEmpty == true ? null : displayName?.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 天気予報のMy地域を保存（府県予報区コード、例: 130000）
  Future<void> saveWeatherAreaCode(String uid, String weatherAreaCode) async {
    final ref = _firestore.collection(_collection).doc(uid);
    await ref.set({
      'id': uid,
      'weatherAreaCode': weatherAreaCode,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 都道府県を保存（地域ニュース用）
  Future<void> savePrefecture(String uid, String prefecture) async {
    final ref = _firestore.collection(_collection).doc(uid);
    await ref.set({
      'id': uid,
      'prefecture': prefecture,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 生年月日のみ保存（占いフローで入力した場合）
  Future<void> saveBirthDate(String uid, DateTime birthDate) async {
    final ref = _firestore.collection(_collection).doc(uid);
    await ref.set({
      'id': uid,
      'birthDate': birthDate.toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 占いなどでポイントを付与（歩数・タンクは触らない）。不正防止: isBanned 時は付与せず、短時間の連打で isBanned に。
  Future<void> grantPoints(String uid, int points) async {
    if (points <= 0) return;
    const maxGrantsInWindow = 10;
    const windowSec = 60;

    final ref = _firestore.collection(_collection).doc(uid);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists && snap.data() != null) {
        final isBanned = (snap.data()!['isBanned'] as bool?) ?? false;
        if (isBanned) return;
      }
      int total = 0;
      int totalEarned = 0;
      String? lastGrantStr;
      int count = 0;
      if (snap.exists && snap.data() != null) {
        total = (snap.data()!['totalPoints'] as num?)?.toInt() ?? 0;
        totalEarned = (snap.data()!['totalEarnedChips'] as num?)?.toInt() ?? 0;
        lastGrantStr = snap.data()!['lastPointGrantAt']?.toString();
        count = (snap.data()!['pointGrantCount'] as num?)?.toInt() ?? 0;
      }
      final now = DateTime.now();
      if (lastGrantStr != null) {
        final lastGrant = DateTime.tryParse(lastGrantStr);
        if (lastGrant != null && now.difference(lastGrant).inSeconds < windowSec) {
          count += 1;
          if (count > maxGrantsInWindow) {
            tx.set(ref, {
              'id': uid,
              'isBanned': true,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
            return;
          }
        } else {
          count = 1;
        }
      } else {
        count = 1;
      }
      total += points;
      totalEarned += points;
      tx.set(ref, {
        'id': uid,
        'totalPoints': total,
        'totalEarnedChips': totalEarned,
        'lastPointGrantAt': now.toIso8601String(),
        'pointGrantCount': count,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  /// 読了ボーナス: 指定ポイント付与し、1日カウントを1増やす。最大回数は経済圏設定に従う。
  Future<void> grantReadBonusWithPoints(String uid, int points) async {
    final settings = await EconomySettingsService.instance.getEconomySettingsOnce();
    final maxPerDay = settings.newsReadBonusMaxPerDay;
    final ref = _firestore.collection(_collection).doc(uid);
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    int awarded = 0;
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      int total = 0;
      int totalEarned = 0;
      String? lastDate;
      int count = 0;
      int levelPenalty = 0;
      if (snap.exists && snap.data() != null) {
        final d = snap.data()!;
        total = (d['totalPoints'] as num?)?.toInt() ?? 0;
        totalEarned = (d['totalEarnedChips'] as num?)?.toInt() ?? 0;
        lastDate = d['lastReadBonusDate'] as String?;
        count = (d['dailyReadBonusCount'] as num?)?.toInt() ?? 0;
        levelPenalty = (d['levelPenalty'] as num?)?.toInt() ?? 0;
      }
      if (lastDate != todayStr) count = 0;
      if (count >= maxPerDay) return;
      count += 1;
      final mult = _multiplierWithRedemption(totalEarned, levelPenalty);
      awarded = (points * mult).round();
      if (awarded <= 0) awarded = points;
      total += awarded;
      totalEarned += awarded;
      tx.set(ref, {
        'id': uid,
        'totalPoints': total,
        'totalEarnedChips': totalEarned,
        'lastReadBonusDate': todayStr,
        'dailyReadBonusCount': count,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
    if (awarded > 0) {
      await _logPointHistory(uid, '読了', awarded);
    }
  }

  /// 読了ボーナス: そのまま受け取り（経済圏の base ポイント）
  Future<void> grantReadBonus(String uid) async {
    final settings = await EconomySettingsService.instance.getEconomySettingsOnce();
    await grantReadBonusWithPoints(uid, settings.readBonusBasePoints);
  }

  /// 読了ボーナスおかわり: 動画視聴後にカウントをリセットし、あとN回受け取れるようにする。
  Future<void> resetReadBonusForRefill(String uid) async {
    final settings = await EconomySettingsService.instance.getEconomySettingsOnce();
    final ref = _firestore.collection(_collection).doc(uid);
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    await ref.set({
      'id': uid,
      'dailyReadBonusCount': 0,
      'lastReadBonusRefillDate': todayStr,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 動画視聴後の倍増ポイント付与（読了ボーナス用）。カウントも1消費。
  Future<void> grantReadBonusVideoMultiplier(String uid) async {
    final settings = await EconomySettingsService.instance.getEconomySettingsOnce();
    await grantReadBonusWithPoints(uid, settings.readBonusVideoMultiplier);
  }

  /// 動画くじ: 経済圏設定の min〜max でランダムにポイント付与。24時間あたりの回数制限あり。
  Future<int> grantLotteryPoints(String uid) async {
    final settings = await EconomySettingsService.instance.getEconomySettingsOnce();
    final user = await getUserOnce(uid);
    if (user != null && user.todayVideoLotteryCount >= settings.videoLotteryMaxPerDay) {
      return 0;
    }
    final min = settings.lotteryMinPt;
    final max = settings.lotteryMaxPt;
    final range = (max - min + 1).clamp(1, 99);
    final points = min + Random().nextInt(range);
    final clamped = points.clamp(min, max);
    final ref = _firestore.collection(_collection).doc(uid);
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      int count = 0;
      String? lastDate = snap.data()?['lastVideoLotteryDate'] as String?;
      if (lastDate == todayStr) {
        count = (snap.data()!['videoLotteryCountToday'] as num?)?.toInt() ?? 0;
      }
      if (count >= settings.videoLotteryMaxPerDay) return;
      count += 1;
      int total = (snap.data()?['totalPoints'] as num?)?.toInt() ?? 0;
      int totalEarned = (snap.data()?['totalEarnedChips'] as num?)?.toInt() ?? 0;
      total += clamped;
      totalEarned += clamped;
      tx.set(ref, {
        'id': uid,
        'totalPoints': total,
        'totalEarnedChips': totalEarned,
        'lastVideoLotteryDate': todayStr,
        'videoLotteryCountToday': count,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
    await _logPointHistory(uid, 'くじ', clamped);
    return clamped;
  }

  /// ポイントGET（1タンク消費）：totalPoints 加算, todaySteps-500 して保存。
  ///
  /// [fixedAwardChips] を指定した場合はそのチップ数をそのまま付与（歩数タンクの固定報酬用）。
  /// 未指定時は従来どおりレベル倍率 × [pointsMultiplier] で算出。
  Future<void> addPointsAndConsumeTank(
    String uid, {
    int pointsMultiplier = 1,
    int? fixedAwardChips,
  }) async {
    final ref = _firestore.collection(_collection).doc(uid);
    int awarded = 0;
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      int totalPoints = 0;
      int totalEarned = 0;
      int todaySteps = 0;
      int levelPenalty = 0;
      if (snap.exists && snap.data() != null) {
        totalPoints = (snap.data()!['totalPoints'] as num?)?.toInt() ?? 0;
        totalEarned = (snap.data()!['totalEarnedChips'] as num?)?.toInt() ?? 0;
        todaySteps = (snap.data()!['todaySteps'] as num?)?.toInt() ?? 0;
        levelPenalty = (snap.data()!['levelPenalty'] as num?)?.toInt() ?? 0;
      }
      if (fixedAwardChips != null) {
        awarded = fixedAwardChips;
      } else {
        final mult = _multiplierWithRedemption(totalEarned, levelPenalty) * pointsMultiplier;
        awarded = (1 * mult).round();
        if (awarded <= 0) awarded = pointsMultiplier;
      }
      totalPoints += awarded;
      totalEarned += awarded;
      todaySteps = (todaySteps - 500).clamp(0, 0x7FFFFFFF);
      tx.set(ref, {
        'id': uid,
        'totalPoints': totalPoints,
        'totalEarnedChips': totalEarned,
        'todaySteps': todaySteps,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
    if (awarded > 0) {
      await _logPointHistory(uid, '歩数', awarded);
    }
  }

  static String _generateReferralCode(String uid) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random();
    final suffix = List.generate(6, (_) => chars[r.nextInt(chars.length)]).join();
    return '${uid.substring(uid.length > 4 ? uid.length - 4 : 0).padLeft(4, '0')}$suffix';
  }

  /// 招待コードが未設定なら生成して保存
  Future<String> ensureReferralCode(String uid) async {
    final user = await getUserOnce(uid);
    if (user?.referralCode != null && user!.referralCode!.isNotEmpty) {
      return user.referralCode!;
    }
    final code = _generateReferralCode(uid);
    final ref = _firestore.collection(_collection).doc(uid);
    await ref.set({'id': uid, 'referralCode': code, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    return code;
  }

  /// 招待コードを適用（紹介者・被紹介者にポイント付与）。成功時 true。自分自身のコード・既に紹介済み・無効コードは false。
  Future<bool> applyReferralCode(String inviteeUid, String code) async {
    if (code.trim().isEmpty) return false;
    final trimmed = code.trim().toUpperCase();
    final invitee = await getUserOnce(inviteeUid);
    if (invitee?.referredBy != null) return false;
    final ref = _firestore.collection(_collection);
    final referrerQuery = await ref.where('referralCode', isEqualTo: trimmed).limit(1).get();
    if (referrerQuery.docs.isEmpty) return false;
    final referrerId = referrerQuery.docs.first.id;
    if (referrerId == inviteeUid) return false;
    final invRef = ref.doc(inviteeUid);
    await invRef.set({
      'id': inviteeUid,
      'referredBy': referrerId,
      'referralPromptSeen': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    final settings = await EconomySettingsService.instance.getEconomySettingsOnce();
    await grantPoints(referrerId, settings.referralPointsInviter);
    await grantPoints(inviteeUid, settings.referralPointsInvitee);
    await _logPointHistory(referrerId, '友達紹介', settings.referralPointsInviter);
    await _logPointHistory(inviteeUid, '友達紹介', settings.referralPointsInvitee);
    return true;
  }

  /// 招待コード入力画面をスキップしたことを記録
  Future<void> setReferralPromptSeen(String uid) async {
    await _firestore.collection(_collection).doc(uid).set({
      'id': uid,
      'referralPromptSeen': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// BAN フラグの設定（管理画面用）
  Future<void> setBanned(String uid, bool banned) async {
    await _firestore.collection(_collection).doc(uid).set({
      'id': uid,
      'isBanned': banned,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  UserModel _userFromFirestoreData(String id, Map<String, dynamic> data) {
    DateTime? updatedAt;
    final u = data['updatedAt'];
    if (u != null) {
      if (u is Timestamp) {
        updatedAt = u.toDate();
      } else {
        updatedAt = DateTime.tryParse(u.toString());
      }
    }
    DateTime? birthDate;
    final b = data['birthDate'];
    if (b != null) {
      birthDate = DateTime.tryParse(b.toString());
    }
    DateTime? createdAt;
    final c = data['createdAt'];
    if (c != null) {
      if (c is Timestamp) {
        createdAt = c.toDate();
      } else {
        createdAt = DateTime.tryParse(c.toString());
      }
    }
    final count = (data['dailyReadBonusCount'] as num?)?.toInt();
    DateTime? lastPointGrantAt;
    final lpg = data['lastPointGrantAt'];
    if (lpg != null) lastPointGrantAt = DateTime.tryParse(lpg.toString());
    DateTime? lastPetUpdate;
    final lpu = data['lastPetUpdate'];
    if (lpu != null) {
      if (lpu is Timestamp) lastPetUpdate = lpu.toDate();
      else lastPetUpdate = DateTime.tryParse(lpu.toString());
    }
    return UserModel(
      id: id,
      displayName: data['displayName'] as String?,
      email: data['email'] as String?,
      totalPoints: (data['totalPoints'] as num?)?.toInt() ?? 0,
      totalEarnedChips: (data['totalEarnedChips'] as num?)?.toInt() ?? 0,
      todaySteps: (data['todaySteps'] as num?)?.toInt() ?? 0,
      totalSteps: (data['totalSteps'] as num?)?.toInt() ?? 0,
      tankLevels: const [0.0, 0.0, 0.0],
      updatedAt: updatedAt,
      createdAt: createdAt,
      birthDate: birthDate,
      prefecture: data['prefecture'] as String?,
      weatherAreaCode: data['weatherAreaCode'] as String?,
      dailyReadBonusCount: count,
      lastReadBonusDate: data['lastReadBonusDate'] as String?,
      lastReadBonusRefillDate: data['lastReadBonusRefillDate'] as String?,
      referralCode: data['referralCode'] as String?,
      referredBy: data['referredBy'] as String?,
      referralPromptSeen: data['referralPromptSeen'] as bool?,
      deviceId: data['deviceId'] as String?,
      isBanned: (data['isBanned'] as bool?) ?? false,
      lastPointGrantAt: lastPointGrantAt,
      pointGrantCount: (data['pointGrantCount'] as num?)?.toInt(),
      lastVideoLotteryDate: data['lastVideoLotteryDate'] as String?,
      videoLotteryCountToday: (data['videoLotteryCountToday'] as num?)?.toInt(),
      fullness: (data['fullness'] as num?)?.toDouble() ?? 1.0,
      cleanliness: (data['cleanliness'] as num?)?.toDouble() ?? 1.0,
      petLevel: (data['petLevel'] as num?)?.toInt() ?? 1,
      petExp: (data['petExp'] as num?)?.toInt() ?? 0,
      lastPetUpdate: lastPetUpdate,
      customCharacterImageUrl: data['customCharacterImageUrl'] as String?,
      customCharacterPrompt: data['customCharacterPrompt'] as String?,
      lastFullnessZeroAt: _parseTimestamp(data['lastFullnessZeroAt']),
      lastCleanlinessZeroAt: _parseTimestamp(data['lastCleanlinessZeroAt']),
      levelPenalty: (data['levelPenalty'] as num?)?.toInt() ?? 0,
    );
  }
}
