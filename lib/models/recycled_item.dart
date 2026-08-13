import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================
// RecycledItem — Firestore recycleBin/{id} document model
// Stores deleted items with metadata for restore/permanent delete.
// ============================================================

class RecycledItem {
  const RecycledItem({
    required this.id,
    required this.originalCollection,
    required this.originalId,
    required this.data,
    required this.deletedBy,
    required this.deletedAt,
    required this.itemName,
  });

  final String id;
  final String originalCollection; // 'bills', 'products', 'companies', 'admins'
  final String originalId;
  final Map<String, dynamic> data; // original document data
  final String deletedBy; // Firebase UID of who deleted it
  final DateTime deletedAt;
  final String itemName; // human-readable label for the list

  factory RecycledItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return RecycledItem(
      id: doc.id,
      originalCollection: d['originalCollection'] as String? ?? '',
      originalId: d['originalId'] as String? ?? '',
      data: (d['data'] as Map<String, dynamic>?) ?? {},
      deletedBy: d['deletedBy'] as String? ?? '',
      deletedAt:
          (d['deletedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      itemName: d['itemName'] as String? ?? 'Unknown',
    );
  }

  Map<String, dynamic> toMap() => {
        'originalCollection': originalCollection,
        'originalId': originalId,
        'data': data,
        'deletedBy': deletedBy,
        'deletedAt': Timestamp.fromDate(deletedAt),
        'itemName': itemName,
      };

  /// Icon name helper for display.
  String get typeLabel => switch (originalCollection) {
        'bills' => 'Bill',
        'products' => 'Product',
        'companies' => 'Company',
        'admins' => 'Admin',
        _ => 'Item',
      };
}
