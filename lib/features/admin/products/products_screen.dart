import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:manage_bills/app/theme.dart';
import 'package:manage_bills/core/constants.dart';
import 'package:manage_bills/features/auth/auth_provider.dart';
import 'package:manage_bills/models/bill.dart';
import 'package:manage_bills/models/product.dart';
import 'package:manage_bills/models/user_role.dart';
import 'package:manage_bills/features/search/barcode_scanner_screen.dart';
import 'package:uuid/uuid.dart';

// ============================================================
// Products Screen — with search, swipe-refresh, ownership,
// soft-delete, product tap → related bills
// ============================================================

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final role = ref.watch(userRoleProvider).valueOrNull ?? UserRole.guest;
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.go('/search'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.cyanGradient,
                ),
                child: const SafeArea(
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Text(
                        'Products',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Search bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search products by name, code or barcode...',
                  prefixIcon: const Icon(Icons.manage_search_rounded),
                  isDense: true,
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () =>
                              setState(() => _searchQuery = ''),
                        )
                      : null,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection(FirestoreCollections.products)
                .orderBy('itemName')
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final allDocs = snap.data?.docs ?? [];
              final docs = _searchQuery.isEmpty
                  ? allDocs
                  : allDocs.where((d) {
                      final q = _searchQuery.toLowerCase();
                      final data = d.data();
                      final name = (data['itemName'] as String? ?? '')
                          .toLowerCase();
                      final code = (data['itemCode'] as String? ?? '')
                          .toLowerCase();
                      final barcode =
                          (data['barcode'] as String? ?? '')
                              .toLowerCase();
                      return name.contains(q) ||
                          code.contains(q) ||
                          barcode.contains(q);
                    }).toList();

              if (docs.isEmpty) {
                return SliverFillRemaining(
                  child: _EmptyState(
                      cs: cs,
                      hasSearch: _searchQuery.isNotEmpty),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                sliver: SliverList.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final product = Product.fromDoc(docs[i]);
                    return _ProductCard(
                      product: product,
                      isDark: isDark,
                      cs: cs,
                      role: role,
                      currentUid: currentUid,
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
      // FAB removed — products are added via bill creation
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.isDark,
    required this.cs,
    required this.role,
    required this.currentUid,
  });
  final Product product;
  final bool isDark;
  final ColorScheme cs;
  final UserRole role;
  final String currentUid;

  bool get _canEdit =>
      role.isSuperAdmin ||
      (role.isAdmin && product.createdBy == currentUid);

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);
    final margin = product.salePrice - product.purchasePrice;
    final marginPct = product.purchasePrice > 0
        ? (margin / product.purchasePrice * 100)
        : 0.0;
    final marginColor =
        margin >= 0 ? const Color(0xFF10B981) : cs.error;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) =>
                ProductRelatedBillsScreen(product: product),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left accent bar
                  Container(
                    width: 4,
                    height: 50,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      gradient: AppTheme.cyanGradient,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.itemName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            if (product.itemCode.isNotEmpty)
                              _Chip(
                                label: product.itemCode,
                                icon: Icons.tag,
                                cs: cs,
                              ),
                            if (product.barcode.isNotEmpty)
                              _Chip(
                                label: product.barcode,
                                icon: Icons.barcode_reader,
                                cs: cs,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Action buttons
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_canEdit)
                        _IconBtn(
                          key: Key('edit_product_${product.id}'),
                          icon: Icons.edit_outlined,
                          color: cs.primary,
                          onTap: () => _showForm(context, product),
                        ),
                      if (_canEdit) const SizedBox(height: 4),
                      if (role.isSuperAdmin)
                        _IconBtn(
                          key: Key('delete_product_${product.id}'),
                          icon: Icons.delete_outline,
                          color: cs.error,
                          onTap: () =>
                              _confirmDelete(context),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Price row
              Row(
                children: [
                  _PriceBadge(
                    label: 'Sale',
                    value: fmt.format(product.salePrice),
                    gradient: AppTheme.primaryGradient,
                  ),
                  const SizedBox(width: 8),
                  _PriceBadge(
                    label: 'Purchase',
                    value: fmt.format(product.purchasePrice),
                    gradient: AppTheme.cyanGradient,
                  ),
                  const Spacer(),
                  // Margin indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          marginColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color:
                              marginColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${marginPct.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: marginColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              // Tap hint
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 12, color: cs.outline),
                  const SizedBox(width: 4),
                  Text('Tap to see related bills',
                      style: TextStyle(
                          fontSize: 11, color: cs.outline)),
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right,
                      size: 14, color: cs.outline),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showForm(BuildContext ctx, Product? p) {
    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductFormSheet(product: p),
    );
  }

  void _confirmDelete(BuildContext ctx) {
    showDialog<void>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Product'),
        content: Text(
            'Move "${product.itemName}" to recycle bin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor:
                    Theme.of(dialogCtx).colorScheme.error),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              final fs = FirebaseFirestore.instance;
              final uid =
                  FirebaseAuth.instance.currentUser?.uid ?? '';
              // Move to recycle bin
              await fs
                  .collection(FirestoreCollections.recycleBin)
                  .add({
                'originalCollection':
                    FirestoreCollections.products,
                'originalId': product.id,
                'data': product.toMap(),
                'deletedBy': uid,
                'deletedAt': Timestamp.now(),
                'itemName': 'Product: ${product.itemName}',
              });
              final batch = fs.batch();
              batch.delete(fs
                  .collection(FirestoreCollections.products)
                  .doc(product.id));
              batch.delete(fs
                  .collection(
                      FirestoreCollections.publicProducts)
                  .doc(product.id));
              await batch.commit();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Product Related Bills Screen ──────────────────────────────

class ProductRelatedBillsScreen extends StatelessWidget {
  const ProductRelatedBillsScreen({super.key, required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currFmt =
        NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);
    final dateFmt = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(product.itemName),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.cyanGradient,
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection(FirestoreCollections.bills)
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator());
          }
          final allBills = snap.data?.docs
                  .map(Bill.fromDoc)
                  .toList() ??
              [];
          // Filter bills that contain this product
          final relatedBills = allBills
              .where((b) => b.items
                  .any((item) => item.productId == product.id))
              .toList();

          if (relatedBills.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 48, color: cs.outline),
                  const SizedBox(height: 16),
                  const Text('No related bills found',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    'This product hasn\'t been added to any bill yet',
                    style: TextStyle(
                        color: cs.outline, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: relatedBills.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final bill = relatedBills[i];
              final matchingItem = bill.items.firstWhere(
                  (item) => item.productId == product.id);
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: cs.secondaryContainer,
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.receipt,
                                color:
                                    cs.onSecondaryContainer,
                                size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(bill.companyName,
                                    style: const TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                        fontSize: 15)),
                                Text(
                                    dateFmt
                                        .format(bill.date),
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: cs.outline)),
                              ],
                            ),
                          ),
                          Text(
                            currFmt
                                .format(bill.totalAmount),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(
                          height: 1,
                          color: cs.outlineVariant),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'Qty: ${matchingItem.quantity}',
                            style: TextStyle(
                                color: cs.primary,
                                fontWeight:
                                    FontWeight.w600),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Unit Price: ${currFmt.format(matchingItem.unitPrice)}',
                            style: TextStyle(
                                color: cs.outline,
                                fontSize: 13),
                          ),
                          const Spacer(),
                          Text(
                            currFmt.format(
                                matchingItem.subtotal),
                            style: const TextStyle(
                                fontWeight:
                                    FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.label, required this.icon, required this.cs});
  final String label;
  final IconData icon;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: cs.outline),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: cs.onSurface)),
        ],
      ),
    );
  }
}

class _PriceBadge extends StatelessWidget {
  const _PriceBadge(
      {required this.label,
      required this.value,
      required this.gradient});
  final String label;
  final String value;
  final LinearGradient gradient;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5))),
        ShaderMask(
          shaderCallback: (b) => gradient.createShader(b),
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.cs, this.hasSearch = false});
  final ColorScheme cs;
  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.inventory_2_outlined,
                size: 36, color: cs.onSecondaryContainer),
          ),
          const SizedBox(height: 16),
          Text(hasSearch ? 'No matching products' : 'No products yet',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
              hasSearch
                  ? 'Try a different search term'
                  : 'Products are added when creating bills',
              style:
                  TextStyle(color: cs.outline, fontSize: 13)),
        ],
      ),
    );
  }
}

// ── Product Form Bottom Sheet ─────────────────────────────────

class ProductFormSheet extends StatefulWidget {
  const ProductFormSheet(
      {super.key, this.product, this.initialCompanyId});
  final Product? product;
  final String? initialCompanyId;

  @override
  State<ProductFormSheet> createState() =>
      _ProductFormSheetState();
}

class _ProductFormSheetState extends State<ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();
  bool _saving = false;
  String? _selectedCompanyId;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _salePriceCtrl;
  late final TextEditingController _purchasePriceCtrl;
  late final TextEditingController _specCtrl;
  late final TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.itemName ?? '');
    _codeCtrl = TextEditingController(text: p?.itemCode ?? '');
    _barcodeCtrl = TextEditingController(text: p?.barcode ?? '');
    _salePriceCtrl = TextEditingController(
        text: p != null ? p.salePrice.toString() : '');
    _purchasePriceCtrl = TextEditingController(
        text: p != null ? p.purchasePrice.toString() : '');
    _specCtrl = TextEditingController(text: p?.specification ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _selectedCompanyId =
        p?.companyId ?? widget.initialCompanyId;
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _codeCtrl,
      _barcodeCtrl,
      _salePriceCtrl,
      _purchasePriceCtrl,
      _specCtrl,
      _descCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final result = await Navigator.of(context).push<String?>(
      MaterialPageRoute(
          builder: (_) => const BarcodeScannerScreen()),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _barcodeCtrl.text = result);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCompanyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select a company')));
      return;
    }
    setState(() => _saving = true);

    final uid =
        FirebaseAuth.instance.currentUser?.uid ?? '';
    final id = widget.product?.id ?? _uuid.v4();
    final data = Product(
      id: id,
      itemName: _nameCtrl.text.trim(),
      itemCode: _codeCtrl.text.trim(),
      barcode: _barcodeCtrl.text.trim(),
      salePrice:
          double.tryParse(_salePriceCtrl.text) ?? 0,
      purchasePrice:
          double.tryParse(_purchasePriceCtrl.text) ?? 0,
      specification: _specCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      categoryId: '',
      companyId: _selectedCompanyId!,
      createdBy: widget.product?.createdBy ?? uid,
    );

    final batch = FirebaseFirestore.instance.batch();
    batch.set(
      FirebaseFirestore.instance
          .collection(FirestoreCollections.products)
          .doc(id),
      data.toMap(),
    );
    batch.set(
      FirebaseFirestore.instance
          .collection(FirestoreCollections.publicProducts)
          .doc(id),
      data.toPublicMap(),
    );
    await batch.commit();

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark =
        Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.product != null;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color:
              isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                isEdit ? 'Edit Product' : 'New Product',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Company selector
                    StreamBuilder<
                        QuerySnapshot<
                            Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection(
                              FirestoreCollections.companies)
                          .orderBy('name')
                          .snapshots(),
                      builder: (context, snap) {
                        final docs =
                            snap.data?.docs ?? [];
                        return DropdownButtonFormField<
                            String>(
                          value: _selectedCompanyId,
                          decoration:
                              const InputDecoration(
                            labelText: 'Company',
                            prefixIcon: Icon(
                                Icons.business_outlined),
                          ),
                          items: docs.map((d) {
                            return DropdownMenuItem(
                              value: d.id,
                              child: Text(
                                  d.data()['name'] ??
                                      d.id),
                            );
                          }).toList(),
                          onChanged: (v) => setState(
                              () =>
                                  _selectedCompanyId = v),
                          validator: (v) => v == null
                              ? 'Select a company'
                              : null,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Item Name *',
                          prefixIcon: Icon(
                              Icons.inventory_outlined)),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _codeCtrl,
                            decoration:
                                const InputDecoration(
                                    labelText:
                                        'Item Code',
                                    prefixIcon:
                                        Icon(Icons.tag)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller:
                                      _barcodeCtrl,
                                  decoration:
                                      const InputDecoration(
                                    labelText:
                                        'Barcode',
                                    prefixIcon: Icon(Icons
                                        .barcode_reader),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(
                                    Icons
                                        .qr_code_scanner,
                                    size: 22),
                                tooltip:
                                    'Scan Barcode',
                                onPressed:
                                    _scanBarcode,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _salePriceCtrl,
                            keyboardType:
                                const TextInputType
                                    .numberWithOptions(
                                    decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter
                                  .allow(
                                      RegExp(r'[\d.]'))
                            ],
                            decoration:
                                const InputDecoration(
                              labelText:
                                  'Sale Price *',
                              prefixIcon: Icon(
                                  Icons.sell_outlined),
                              prefixText: 'Rs. ',
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Required';
                              }
                              if (double.tryParse(v) == null) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller:
                                _purchasePriceCtrl,
                            keyboardType:
                                const TextInputType
                                    .numberWithOptions(
                                    decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter
                                  .allow(
                                      RegExp(r'[\d.]'))
                            ],
                            decoration:
                                const InputDecoration(
                              labelText:
                                  'Purchase Price *',
                              prefixIcon: Icon(Icons
                                  .shopping_bag_outlined),
                              prefixText: 'Rs. ',
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Required';
                              }
                              if (double.tryParse(v) == null) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _specCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Specification',
                          prefixIcon: Icon(
                              Icons.description_outlined)),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                          labelText: 'Description',
                          prefixIcon:
                              Icon(Icons.notes_outlined)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                key: const Key('product_save_button'),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white),
                      )
                    : Text(isEdit
                        ? 'Update Product'
                        : 'Create Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
