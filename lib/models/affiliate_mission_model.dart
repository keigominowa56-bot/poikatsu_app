/// 成果報酬型広告（アフィリエイト案件）のモデル。
/// Firestore の affiliate_missions コレクションと対応。
class AffiliateMission {
  const AffiliateMission({
    required this.id,
    required this.title,
    this.description,
    required this.pointAmount,
    this.imageUrl,
    required this.affiliateUrl,
    this.category,
    this.isPublished = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  /// 条件・説明文
  final String? description;
  final int pointAmount;
  final String? imageUrl;
  /// 遷移先リンク
  final String affiliateUrl;
  /// 購入・面談など
  final String? category;
  final bool isPublished;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'pointAmount': pointAmount,
      'imageUrl': imageUrl,
      'affiliateUrl': affiliateUrl,
      'category': category,
      'isPublished': isPublished,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory AffiliateMission.fromMap(Map<String, dynamic> map) {
    DateTime? createdAt;
    if (map['createdAt'] != null) {
      createdAt = DateTime.tryParse(map['createdAt'].toString());
    }
    DateTime? updatedAt;
    if (map['updatedAt'] != null) {
      updatedAt = DateTime.tryParse(map['updatedAt'].toString());
    }
    return AffiliateMission(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String?,
      pointAmount: (map['pointAmount'] as num?)?.toInt() ?? 0,
      imageUrl: map['imageUrl'] as String?,
      affiliateUrl: map['affiliateUrl'] as String? ?? '',
      category: map['category'] as String?,
      isPublished: (map['isPublished'] as bool?) ?? true,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  AffiliateMission copyWith({
    String? id,
    String? title,
    String? description,
    int? pointAmount,
    String? imageUrl,
    String? affiliateUrl,
    String? category,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AffiliateMission(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      pointAmount: pointAmount ?? this.pointAmount,
      imageUrl: imageUrl ?? this.imageUrl,
      affiliateUrl: affiliateUrl ?? this.affiliateUrl,
      category: category ?? this.category,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
