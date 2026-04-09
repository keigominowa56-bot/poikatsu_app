/// ユーザーのポイント情報を保持するモデル。
/// Firestore の users コレクションと対応させる想定。
class UserModel {
  const UserModel({
    required this.id,
    this.displayName,
    this.email,
    this.totalPoints = 0,
    this.totalEarnedChips = 0,
    this.todaySteps = 0,
    this.totalSteps = 0,
    this.tankLevels = const [0.0, 0.0, 0.0],
    this.updatedAt,
    this.createdAt,
    this.birthDate,
    this.prefecture,
    this.weatherAreaCode,
    this.dailyReadBonusCount,
    this.lastReadBonusDate,
    this.lastReadBonusRefillDate,
    this.referralCode,
    this.referredBy,
    this.referralPromptSeen,
    this.deviceId,
    this.isBanned = false,
    this.lastPointGrantAt,
    this.pointGrantCount,
    this.lastVideoLotteryDate,
    this.videoLotteryCountToday,
    this.fullness = 1.0,
    this.cleanliness = 1.0,
    this.petLevel = 1,
    this.petExp = 0,
    this.lastPetUpdate,
    this.customCharacterImageUrl,
    this.customCharacterPrompt,
    this.lastFullnessZeroAt,
    this.lastCleanlinessZeroAt,
    this.levelPenalty = 0,
  });

  /// Firebase Auth の UID または Firestore ドキュメント ID
  final String id;

  /// 表示名
  final String? displayName;

  /// メールアドレス（認証用）
  final String? email;

  /// 累計獲得ポイント
  final int totalPoints;

  /// 累計獲得チップ（ランキング・ランク計算用）
  final int totalEarnedChips;

  /// 今日の歩数（タンク計算の基準。500歩＝1タンク単位）
  final int todaySteps;

  /// 累計歩数（アプリ開始からの総歩数）
  final int totalSteps;

  /// 3つのポイントタンクの進捗（0.0〜1.0）。歩数から算出することも可能。
  final List<double> tankLevels;

  /// 最終更新日時
  final DateTime? updatedAt;

  /// アカウント作成日時（利用開始日表示用）
  final DateTime? createdAt;

  /// 生年月日（占いの精密診断で使用。未設定の場合はフロー内で入力）
  final DateTime? birthDate;

  /// 都道府県コード（1〜47の文字列）。地域ニュース用。未設定時は初回に選択させる
  final String? prefecture;

  /// 天気予報のMy地域（気象庁府県予報区コード、例: 130000）。未設定時は prefecture から推定
  final String? weatherAreaCode;

  /// 読了ボーナス: その日付で何回受け取ったか（lastReadBonusDate とセット）
  final int? dailyReadBonusCount;

  /// 読了ボーナス: 最後に受け取った日（YYYY-MM-DD）
  final String? lastReadBonusDate;

  /// 読了ボーナスおかわり: その日に動画リフィルを使ったか（lastReadBonusRefillDate とセット）
  final String? lastReadBonusRefillDate;

  /// 友達紹介: 自身の招待コード
  final String? referralCode;
  /// 友達紹介: 紹介者のUID（入力したコードのユーザー）
  final String? referredBy;
  /// 招待コード入力画面を一度表示済み（スキップ or 入力完了）
  final bool? referralPromptSeen;

  /// 不正防止: デバイスID（1デバイス1アカウント）
  final String? deviceId;
  /// 不正防止: BAN済み
  final bool isBanned;

  /// 異常検知: 直近のポイント付与時刻
  final DateTime? lastPointGrantAt;
  /// 異常検知: 短時間内の付与回数
  final int? pointGrantCount;

  /// 動画くじ: 最終視聴日（YYYY-MM-DD）
  final String? lastVideoLotteryDate;
  /// 動画くじ: その日の視聴回数
  final int? videoLotteryCountToday;

  /// 相棒育成: 満腹度 (0.0〜1.0)
  final double fullness;
  /// 相棒育成: 清潔度 (0.0〜1.0)
  final double cleanliness;
  /// 相棒育成: 現在のレベル
  final int petLevel;
  /// 相棒育成: 次のレベルまでの経験値
  final int petExp;
  /// 相棒育成: 最終更新日時（経過時間で満腹度・清潔度が減少）
  final DateTime? lastPetUpdate;

  /// Lv.4+用: OpenAIで生成した個別キャラ画像URL
  final String? customCharacterImageUrl;
  /// Lv.4+用: キャラ生成時のプロンプト（土台）
  final String? customCharacterPrompt;
  /// レベルダウンペナルティ用: 満腹度が最後に0になった時刻
  final DateTime? lastFullnessZeroAt;
  /// レベルダウンペナルティ用: 清潔度が最後に0になった時刻
  final DateTime? lastCleanlinessZeroAt;
  /// 放置ペナルティで下がったレベル数（表示レベル = levelFromChips - levelPenalty）
  final int levelPenalty;

  /// 累計獲得チップから算出した表示レベル（ペナルティ反映・最小1）
  int get displayLevel {
    if (totalEarnedChips < 500) return (1 - levelPenalty).clamp(1, 999);
    int lvl = 1;
    int threshold = 500;
    while (totalEarnedChips >= threshold) {
      lvl++;
      threshold *= 2;
    }
    return (lvl - levelPenalty).clamp(1, 999);
  }

  /// Firestore 用 Map に変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'totalPoints': totalPoints,
      'totalEarnedChips': totalEarnedChips,
      'todaySteps': todaySteps,
      'totalSteps': totalSteps,
      'tankLevels': List<double>.from(tankLevels),
      'updatedAt': updatedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'birthDate': birthDate?.toIso8601String(),
      'prefecture': prefecture,
      'weatherAreaCode': weatherAreaCode,
      'dailyReadBonusCount': dailyReadBonusCount,
      'lastReadBonusDate': lastReadBonusDate,
      'lastReadBonusRefillDate': lastReadBonusRefillDate,
      'referralCode': referralCode,
      'referredBy': referredBy,
      'referralPromptSeen': referralPromptSeen,
      'deviceId': deviceId,
      'isBanned': isBanned,
      'lastPointGrantAt': lastPointGrantAt?.toIso8601String(),
      'pointGrantCount': pointGrantCount,
      'lastVideoLotteryDate': lastVideoLotteryDate,
      'videoLotteryCountToday': videoLotteryCountToday,
      'fullness': fullness,
      'cleanliness': cleanliness,
      'petLevel': petLevel,
      'petExp': petExp,
      'lastPetUpdate': lastPetUpdate?.toIso8601String(),
      'customCharacterImageUrl': customCharacterImageUrl,
      'customCharacterPrompt': customCharacterPrompt,
      'lastFullnessZeroAt': lastFullnessZeroAt?.toIso8601String(),
      'lastCleanlinessZeroAt': lastCleanlinessZeroAt?.toIso8601String(),
      'levelPenalty': levelPenalty,
    };
  }

  /// Firestore の DocumentSnapshot や Map から生成
  factory UserModel.fromMap(Map<String, dynamic> map) {
    final tankLevelsRaw = map['tankLevels'];
    List<double> tanks = const [0.0, 0.0, 0.0];
    if (tankLevelsRaw is List) {
      tanks = tankLevelsRaw
          .map((e) => (e is num) ? e.toDouble() : 0.0)
          .take(3)
          .toList();
      while (tanks.length < 3) {
        tanks.add(0.0);
      }
    }
    DateTime? updated;
    if (map['updatedAt'] != null) {
      updated = DateTime.tryParse(map['updatedAt'].toString());
    }
    DateTime? created;
    if (map['createdAt'] != null) {
      created = DateTime.tryParse(map['createdAt'].toString());
    }
    DateTime? birth;
    if (map['birthDate'] != null) {
      birth = DateTime.tryParse(map['birthDate'].toString());
    }
    final count = (map['dailyReadBonusCount'] as num?)?.toInt();
    return UserModel(
      id: map['id'] as String? ?? '',
      displayName: map['displayName'] as String?,
      email: map['email'] as String?,
      totalPoints: (map['totalPoints'] as num?)?.toInt() ?? 0,
      totalEarnedChips: (map['totalEarnedChips'] as num?)?.toInt() ?? 0,
      todaySteps: (map['todaySteps'] as num?)?.toInt() ?? 0,
      totalSteps: (map['totalSteps'] as num?)?.toInt() ?? 0,
      tankLevels: tanks,
      updatedAt: updated,
      createdAt: created,
      birthDate: birth,
      prefecture: map['prefecture'] as String?,
      weatherAreaCode: map['weatherAreaCode'] as String?,
      dailyReadBonusCount: count,
      lastReadBonusDate: map['lastReadBonusDate'] as String?,
      lastReadBonusRefillDate: map['lastReadBonusRefillDate'] as String?,
      referralCode: map['referralCode'] as String?,
      referredBy: map['referredBy'] as String?,
      referralPromptSeen: (map['referralPromptSeen'] as bool?) ?? false,
      deviceId: map['deviceId'] as String?,
      isBanned: (map['isBanned'] as bool?) ?? false,
      lastPointGrantAt: map['lastPointGrantAt'] != null ? DateTime.tryParse(map['lastPointGrantAt'].toString()) : null,
      pointGrantCount: (map['pointGrantCount'] as num?)?.toInt(),
      lastVideoLotteryDate: map['lastVideoLotteryDate'] as String?,
      videoLotteryCountToday: (map['videoLotteryCountToday'] as num?)?.toInt(),
      fullness: (map['fullness'] as num?)?.toDouble() ?? 1.0,
      cleanliness: (map['cleanliness'] as num?)?.toDouble() ?? 1.0,
      petLevel: (map['petLevel'] as num?)?.toInt() ?? 1,
      petExp: (map['petExp'] as num?)?.toInt() ?? 0,
      lastPetUpdate: map['lastPetUpdate'] != null ? DateTime.tryParse(map['lastPetUpdate'].toString()) : null,
      customCharacterImageUrl: map['customCharacterImageUrl'] as String?,
      customCharacterPrompt: map['customCharacterPrompt'] as String?,
      lastFullnessZeroAt: map['lastFullnessZeroAt'] != null ? DateTime.tryParse(map['lastFullnessZeroAt'].toString()) : null,
      lastCleanlinessZeroAt: map['lastCleanlinessZeroAt'] != null ? DateTime.tryParse(map['lastCleanlinessZeroAt'].toString()) : null,
      levelPenalty: (map['levelPenalty'] as num?)?.toInt() ?? 0,
    );
  }

  /// 今日の読了ボーナス使用回数（lastReadBonusDate が今日の場合のみ count を返す）
  int get todayReadBonusCount {
    if (lastReadBonusDate == null || dailyReadBonusCount == null) return 0;
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return lastReadBonusDate == todayStr ? dailyReadBonusCount! : 0;
  }

  /// 今日すでに動画リフィルを使ったか
  bool get usedReadBonusRefillToday {
    if (lastReadBonusRefillDate == null) return false;
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return lastReadBonusRefillDate == todayStr;
  }

  /// 今日の動画くじ視聴回数（lastVideoLotteryDate が今日の場合のみ）
  int get todayVideoLotteryCount {
    if (lastVideoLotteryDate == null || videoLotteryCountToday == null) return 0;
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return lastVideoLotteryDate == todayStr ? videoLotteryCountToday! : 0;
  }

  UserModel copyWith({
    String? id,
    String? displayName,
    String? email,
    int? totalPoints,
    int? totalEarnedChips,
    int? todaySteps,
    int? totalSteps,
    List<double>? tankLevels,
    DateTime? updatedAt,
    DateTime? createdAt,
    DateTime? birthDate,
    String? prefecture,
    String? weatherAreaCode,
    int? dailyReadBonusCount,
    String? lastReadBonusDate,
    String? lastReadBonusRefillDate,
    String? referralCode,
    String? referredBy,
    bool? referralPromptSeen,
    String? deviceId,
    bool? isBanned,
    DateTime? lastPointGrantAt,
    int? pointGrantCount,
    String? lastVideoLotteryDate,
    int? videoLotteryCountToday,
    double? fullness,
    double? cleanliness,
    int? petLevel,
    int? petExp,
    DateTime? lastPetUpdate,
    String? customCharacterImageUrl,
    String? customCharacterPrompt,
    DateTime? lastFullnessZeroAt,
    DateTime? lastCleanlinessZeroAt,
    int? levelPenalty,
  }) {
    return UserModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      totalPoints: totalPoints ?? this.totalPoints,
      totalEarnedChips: totalEarnedChips ?? this.totalEarnedChips,
      todaySteps: todaySteps ?? this.todaySteps,
      totalSteps: totalSteps ?? this.totalSteps,
      tankLevels: tankLevels ?? List.from(this.tankLevels),
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      birthDate: birthDate ?? this.birthDate,
      prefecture: prefecture ?? this.prefecture,
      weatherAreaCode: weatherAreaCode ?? this.weatherAreaCode,
      dailyReadBonusCount: dailyReadBonusCount ?? this.dailyReadBonusCount,
      lastReadBonusDate: lastReadBonusDate ?? this.lastReadBonusDate,
      lastReadBonusRefillDate: lastReadBonusRefillDate ?? this.lastReadBonusRefillDate,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
      referralPromptSeen: referralPromptSeen ?? this.referralPromptSeen,
      deviceId: deviceId ?? this.deviceId,
      isBanned: isBanned ?? this.isBanned,
      lastPointGrantAt: lastPointGrantAt ?? this.lastPointGrantAt,
      pointGrantCount: pointGrantCount ?? this.pointGrantCount,
      lastVideoLotteryDate: lastVideoLotteryDate ?? this.lastVideoLotteryDate,
      videoLotteryCountToday: videoLotteryCountToday ?? this.videoLotteryCountToday,
      fullness: fullness ?? this.fullness,
      cleanliness: cleanliness ?? this.cleanliness,
      petLevel: petLevel ?? this.petLevel,
      petExp: petExp ?? this.petExp,
      lastPetUpdate: lastPetUpdate ?? this.lastPetUpdate,
      customCharacterImageUrl: customCharacterImageUrl ?? this.customCharacterImageUrl,
      customCharacterPrompt: customCharacterPrompt ?? this.customCharacterPrompt,
      lastFullnessZeroAt: lastFullnessZeroAt ?? this.lastFullnessZeroAt,
      lastCleanlinessZeroAt: lastCleanlinessZeroAt ?? this.lastCleanlinessZeroAt,
      levelPenalty: levelPenalty ?? this.levelPenalty,
    );
  }
}
