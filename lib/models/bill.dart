import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================
// Bill — Firestore bills/{id} document model
// Line items are stored as an array field inside the bill doc.
// ============================================================

class BillItem {
  const BillItem({
    required this.productId,
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
  });

  final String productId;
  final String itemName;
  final int quantity;
  final double unitPrice;

  double get subtotal => quantity * unitPrice;

  factory BillItem.fromMap(Map<String, dynamic> map) => BillItem(
        productId: map['productId'] as String? ?? '',
        itemName: map['itemName'] as String? ?? '',
        quantity: (map['quantity'] as num?)?.toInt() ?? 1,
        unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'itemName': itemName,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };

  BillItem copyWith({
    String? productId,
    String? itemName,
    int? quantity,
    double? unitPrice,
  }) =>
      BillItem(
        productId: productId ?? this.productId,
        itemName: itemName ?? this.itemName,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice ?? this.unitPrice,
      );
}

class Bill {
  const Bill({
    required this.id,
    required this.date,
    required this.companyId,
    required this.companyName,
    required this.totalAmount,
    required this.items,
    this.createdBy = '',
  });

  final String id;
  final DateTime date;
  final String companyId;
  final String companyName; // denormalised for display
  final double totalAmount;
  final List<BillItem> items;
  final String createdBy; // Firebase UID of the admin who created this bill

  factory Bill.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final rawItems = data['items'] as List<dynamic>? ?? [];
    return Bill(
      id: doc.id,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      companyId: data['companyId'] as String? ?? '',
      companyName: data['companyName'] as String? ?? '',
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      items: rawItems
          .map((e) => BillItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      createdBy: data['createdBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'date': Timestamp.fromDate(date),
        'companyId': companyId,
        'companyName': companyName,
        'totalAmount': totalAmount,
        'items': items.map((e) => e.toMap()).toList(),
        'createdBy': createdBy,
      };

  Bill copyWith({
    String? id,
    DateTime? date,
    String? companyId,
    String? companyName,
    double? totalAmount,
    List<BillItem>? items,
    String? createdBy,
  }) =>
      Bill(
        id: id ?? this.id,
        date: date ?? this.date,
        companyId: companyId ?? this.companyId,
        companyName: companyName ?? this.companyName,
        totalAmount: totalAmount ?? this.totalAmount,
        items: items ?? this.items,
        createdBy: createdBy ?? this.createdBy,
      );
}
