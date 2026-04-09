import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poigo/models/user_model.dart';

/// 管理画面用 Firestore 操作（users 一覧・ポイント操作）
class AdminFirestoreService {
  AdminFirestoreService._();
  static final AdminFirestoreService _instance = AdminFirestoreService._();
  static AdminFirestoreService get instance => _instance;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  static const String _usersCollection = 'users';

  /// users コレクションのスナップショットストリーム（一覧用）
  /// ストリームエラー時はログを出して続行し、変換エラーは _parseSnapshot 内で catch してスキップ
  Stream<List<UserModel>> streamUsers() {
    final stream = _firestore.collection(_usersCollection).snapshots();
    return stream.handleError((Object e, StackTrace st) {
      // ignore: avoid_print
      print('[AdminFirestoreService] ストリーム取得エラー: $e');
      // ignore: avoid_print
      print(st);
    }).map<List<UserModel>>((snap) {
      // ignore: avoid_print
      print('[AdminFirestoreService] 取得: ${snap.docs.length} 件 (metadata.hasPendingWrites=${snap.metadata.hasPendingWrites})');
      return _parseSnapshot(snap);
    });
  }

  List<UserModel> _parseSnapshot(QuerySnapshot snap) {
    final list = <UserModel>[];
    for (final d in snap.docs) {
      try {
        final user = _userFromDoc(d);
        list.add(user);
      } catch (e, st) {
        // ignore: avoid_print
        print('[AdminFirestoreService] ユーザー変換エラー docId=${d.id}: $e');
        // ignore: avoid_print
        print(st);
        list.add(UserModel(id: d.id));
      }
    }
    list.sort((a, b) {
      final da = a.updatedAt ?? DateTime(0);
      final db = b.updatedAt ?? DateTime(0);
      return db.compareTo(da);
    });
    return list;
  }

  /// ポイントを加算（テスト用）
  Future<void> addPoints(String userId, int points) async {
    if (points <= 0) return;
    final ref = _firestore.collection(_usersCollection).doc(userId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      int total = 0;
      int earned = 0;
      if (snap.exists && snap.data() != null) {
        total = (snap.data()!['totalPoints'] as num?)?.toInt() ?? 0;
        earned = (snap.data()!['totalEarnedChips'] as num?)?.toInt() ?? 0;
      }
      total += points;
      earned += points;
      tx.set(ref, {
        'id': userId,
        'totalPoints': total,
        'totalEarnedChips': earned,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  /// ポイントを減算（テスト用）。0未満にはならない
  Future<void> subtractPoints(String userId, int points) async {
    if (points <= 0) return;
    final ref = _firestore.collection(_usersCollection).doc(userId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      int total = 0;
      if (snap.exists && snap.data() != null) {
        total = (snap.data()!['totalPoints'] as num?)?.toInt() ?? 0;
      }
      total = (total - points).clamp(0, 0x7FFFFFFF);
      tx.set(ref, {
        'id': userId,
        'totalPoints': total,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  UserModel _userFromDoc(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null || data is! Map) {
      return UserModel(id: doc.id);
    }
    final map = Map<String, dynamic>.from(data);
    map['id'] ??= doc.id;
    final u = map['updatedAt'];
    if (u is Timestamp) {
      map['updatedAt'] = u.toDate().toIso8601String();
    }
    final c = map['createdAt'];
    if (c is Timestamp) {
      map['createdAt'] = c.toDate().toIso8601String();
    }
    final lpu = map['lastPetUpdate'];
    if (lpu is Timestamp) {
      map['lastPetUpdate'] = lpu.toDate().toIso8601String();
    }
    return UserModel.fromMap(map);
  }
}
