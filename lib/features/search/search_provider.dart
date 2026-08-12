import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manage_bills/core/constants.dart';
import 'package:manage_bills/features/auth/auth_provider.dart';
import 'package:manage_bills/models/product.dart';
import 'package:manage_bills/models/user_role.dart';

// ============================================================
// Search Provider — multi-field product search
// Routes guest queries to /publicProducts (safe fields only)
// Routes admin queries to /products (full fields)
// ============================================================

/// Search query parameters — empty strings mean "no filter".
class SearchQuery {
  const SearchQuery({
    this.barcode = '',
    this.itemCode = '',
    this.itemName = '',
    this.specification = '',
  });

  final String barcode;
  final String itemCode;
  final String itemName;
  final String specification;

  bool get isEmpty =>
      barcode.isEmpty &&
      itemCode.isEmpty &&
      itemName.isEmpty &&
      specification.isEmpty;

  SearchQuery copyWith({
    String? barcode,
    String? itemCode,
    String? itemName,
    String? specification,
  }) =>
      SearchQuery(
        barcode: barcode ?? this.barcode,
        itemCode: itemCode ?? this.itemCode,
        itemName: itemName ?? this.itemName,
        specification: specification ?? this.specification,
      );
}

// ── Search result wrapper ─────────────────────────────────────

/// A unified result type that carries either a [Product] (admin)
/// or a [PublicProduct] (guest). The UI inspects [isAdmin] to
/// decide which fields to display.
class SearchResult {
  const SearchResult.admin(this.product)
      : publicProduct = null,
        isAdmin = true;

  const SearchResult.guest(this.publicProduct)
      : product = null,
        isAdmin = false;

  final Product? product;
  final PublicProduct? publicProduct;
  final bool isAdmin;

  String get id => product?.id ?? publicProduct!.id;
  String get barcode => product?.barcode ?? publicProduct!.barcode;
  String get itemCode => product?.itemCode ?? publicProduct!.itemCode;
  String get itemName => product?.itemName ?? publicProduct!.itemName;
  double get salePrice => product?.salePrice ?? publicProduct!.salePrice;
  String get specification =>
      product?.specification ?? publicProduct!.specification;
  String get description => product?.description ?? publicProduct!.description;
}

// ── Search notifier ────────────────────────────────────────────

class SearchNotifier extends StateNotifier<AsyncValue<List<SearchResult>>> {
  SearchNotifier(this._ref) : super(const AsyncValue.data([]));

  final Ref _ref;
  SearchQuery _lastQuery = const SearchQuery();

  SearchQuery get lastQuery => _lastQuery;

  Future<void> search(SearchQuery query) async {
    if (query.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    _lastQuery = query;
    state = const AsyncValue.loading();

    try {
      final roleAsync = _ref.read(userRoleProvider);
      final role = await roleAsync.when(
        data: (r) async => r,
        loading: () async => UserRole.guest,
        error: (_, __) async => UserRole.guest,
      );

      final results = role.canManage
          ? await _searchAdmin(query)
          : await _searchGuest(query);

      state = AsyncValue.data(results);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Search /products (full admin access).
  Future<List<SearchResult>> _searchAdmin(SearchQuery q) async {
    final col = FirebaseFirestore.instance
        .collection(FirestoreCollections.products);

    // Firestore doesn't support multi-field OR queries natively;
    // we run the most specific filter and filter the rest client-side.
    QuerySnapshot<Map<String, dynamic>> snap;

    if (q.barcode.isNotEmpty) {
      snap = await col
          .where('barcode', isEqualTo: q.barcode.trim())
          .limit(50)
          .get();
    } else if (q.itemCode.isNotEmpty) {
      snap = await col
          .where('itemCode', isEqualTo: q.itemCode.trim())
          .limit(50)
          .get();
    } else if (q.itemName.isNotEmpty) {
      final name = q.itemName.trim().toLowerCase();
      // Prefix search using range query.
      snap = await col
          .where('itemName', isGreaterThanOrEqualTo: name)
          .where('itemName', isLessThan: '${name}z')
          .limit(50)
          .get();
    } else {
      final spec = q.specification.trim().toLowerCase();
      snap = await col
          .where('specification', isGreaterThanOrEqualTo: spec)
          .where('specification', isLessThan: '${spec}z')
          .limit(50)
          .get();
    }

    return snap.docs
        .map((d) => SearchResult.admin(Product.fromDoc(d)))
        .where((r) => _clientFilter(r, q))
        .toList();
  }

  /// Search /publicProducts (safe fields, guest access).
  Future<List<SearchResult>> _searchGuest(SearchQuery q) async {
    final col = FirebaseFirestore.instance
        .collection(FirestoreCollections.publicProducts);

    QuerySnapshot<Map<String, dynamic>> snap;

    if (q.barcode.isNotEmpty) {
      snap = await col
          .where('barcode', isEqualTo: q.barcode.trim())
          .limit(50)
          .get();
    } else if (q.itemCode.isNotEmpty) {
      snap = await col
          .where('itemCode', isEqualTo: q.itemCode.trim())
          .limit(50)
          .get();
    } else if (q.itemName.isNotEmpty) {
      final name = q.itemName.trim().toLowerCase();
      snap = await col
          .where('itemName', isGreaterThanOrEqualTo: name)
          .where('itemName', isLessThan: '${name}z')
          .limit(50)
          .get();
    } else {
      final spec = q.specification.trim().toLowerCase();
      snap = await col
          .where('specification', isGreaterThanOrEqualTo: spec)
          .where('specification', isLessThan: '${spec}z')
          .limit(50)
          .get();
    }

    return snap.docs
        .map((d) => SearchResult.guest(PublicProduct.fromDoc(d)))
        .where((r) => _clientFilter(r, q))
        .toList();
  }

  /// Client-side cross-field filter applied after the primary query.
  bool _clientFilter(SearchResult r, SearchQuery q) {
    if (q.barcode.isNotEmpty &&
        !r.barcode.contains(q.barcode.trim())) { return false; }
    if (q.itemCode.isNotEmpty &&
        !r.itemCode.contains(q.itemCode.trim())) { return false; }
    if (q.itemName.isNotEmpty &&
        !r.itemName.toLowerCase().contains(q.itemName.trim().toLowerCase())) {
      return false;
    }
    if (q.specification.isNotEmpty &&
        !r.specification
            .toLowerCase()
            .contains(q.specification.trim().toLowerCase())) { return false; }
    return true;
  }

  void clear() {
    _lastQuery = const SearchQuery();
    state = const AsyncValue.data([]);
  }
}

final searchProvider =
    StateNotifierProvider<SearchNotifier, AsyncValue<List<SearchResult>>>(
  (ref) => SearchNotifier(ref),
);
