/// チップ獲得履歴1件（point_history コレクション）
class PointHistoryEntry {
  const PointHistoryEntry({
    required this.id,
    required this.userId,
    required this.reason,
    required this.amount,
    required this.createdAt,
  });

  final String id;
  final String userId;
  /// 獲得理由（歩数、広告、お世話、読了、くじ、友達紹介 など）
  final String reason;
  final int amount;
  final DateTime createdAt;

  factory PointHistoryEntry.fromMap(String id, Map<String, dynamic> map) {
    DateTime? createdAt;
    final c = map['createdAt'];
    if (c != null) {
      if (c is DateTime) {
        createdAt = c;
      } else if (c is String) {
        createdAt = DateTime.tryParse(c);
      }
    }
    createdAt ??= DateTime.now();
    return PointHistoryEntry(
      id: id,
      userId: map['userId'] as String? ?? '',
      reason: map['reason'] as String? ?? '',
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      createdAt: createdAt ?? DateTime.now(),
    );
  }
}
