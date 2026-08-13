import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================
// Product — Firestore products/{id} document model
// Full model used by admins.
// ============================================================

class Product {
  const Product({
    required this.id,
    required this.barcode,
    required this.itemCode,
    required this.itemName,
    required this.purchasePrice,
    required this.salePrice,
    required this.specification,
    required this.description,
    required this.categoryId,
    required this.companyId,
    this.createdBy = '',
  });

  final String id;
  final String barcode;
  final String itemCode;
  final String itemName;
  final double purchasePrice; // hidden from guests
  final double salePrice;
  final String specification;
  final String description;
  final String categoryId;
  final String companyId; // hidden from guests
  final String createdBy; // Firebase UID of admin who created this product

  factory Product.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Product(
      id: doc.id,
      barcode: data['barcode'] as String? ?? '',
      itemCode: data['itemCode'] as String? ?? '',
      itemName: data['itemName'] as String? ?? '',
      purchasePrice: (data['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      salePrice: (data['salePrice'] as num?)?.toDouble() ?? 0.0,
      specification: data['specification'] as String? ?? '',
      description: data['description'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? '',
      companyId: data['companyId'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
    );
  }

  /// Full map written to /products (admin-only collection).
  Map<String, dynamic> toMap() => {
        'barcode': barcode,
        'itemCode': itemCode,
        'itemName': itemName,
        'purchasePrice': purchasePrice,
        'salePrice': salePrice,
        'specification': specification,
        'description': description,
        'categoryId': categoryId,
        'companyId': companyId,
        'createdBy': createdBy,
      };

  /// Safe map written to /publicProducts (guest-readable).
  /// Excludes purchasePrice, companyId, and createdBy.
  Map<String, dynamic> toPublicMap() => {
        'barcode': barcode,
        'itemCode': itemCode,
        'itemName': itemName,
        'salePrice': salePrice,
        'specification': specification,
        'description': description,
      };

  Product copyWith({
    String? id,
    String? barcode,
    String? itemCode,
    String? itemName,
    double? purchasePrice,
    double? salePrice,
    String? specification,
    String? description,
    String? categoryId,
    String? companyId,
    String? createdBy,
  }) =>
      Product(
        id: id ?? this.id,
        barcode: barcode ?? this.barcode,
        itemCode: itemCode ?? this.itemCode,
        itemName: itemName ?? this.itemName,
        purchasePrice: purchasePrice ?? this.purchasePrice,
        salePrice: salePrice ?? this.salePrice,
        specification: specification ?? this.specification,
        description: description ?? this.description,
        categoryId: categoryId ?? this.categoryId,
        companyId: companyId ?? this.companyId,
        createdBy: createdBy ?? this.createdBy,
      );
}

// ============================================================
// PublicProduct — Firestore publicProducts/{id} document model
// Guest-visible fields only.
// ============================================================

class PublicProduct {
  const PublicProduct({
    required this.id,
    required this.barcode,
    required this.itemCode,
    required this.itemName,
    required this.salePrice,
    required this.specification,
    required this.description,
  });

  final String id;
  final String barcode;
  final String itemCode;
  final String itemName;
  final double salePrice;
  final String specification;
  final String description;

  factory PublicProduct.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return PublicProduct(
      id: doc.id,
      barcode: data['barcode'] as String? ?? '',
      itemCode: data['itemCode'] as String? ?? '',
      itemName: data['itemName'] as String? ?? '',
      salePrice: (data['salePrice'] as num?)?.toDouble() ?? 0.0,
      specification: data['specification'] as String? ?? '',
      description: data['description'] as String? ?? '',
    );
  }
}
