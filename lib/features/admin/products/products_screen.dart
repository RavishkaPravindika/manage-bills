import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:manage_bills/app/theme.dart';
import 'package:manage_bills/core/constants.dart';
import 'package:manage_bills/models/product.dart';
import 'package:uuid/uuid.dart';

// ============================================================
// Products Screen — modern redesign
// ============================================================

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return SliverFillRemaining(
                  child: _EmptyState(cs: cs),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                sliver: SliverList.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final product = Product.fromDoc(docs[i]);
                    return _ProductCard(
                      product: product,
                      isDark: isDark,
                      cs: cs,
                      context: context,
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_product_fab'),
        onPressed: () => _showForm(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
        backgroundColor: const Color(0xFF06B6D4),
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showForm(BuildContext context, Product? product) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductFormSheet(product: product),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.isDark,
    required this.cs,
    required this.context,
  });
  final Product product;
  final bool isDark;
  final ColorScheme cs;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);
    final margin = product.salePrice - product.purchasePrice;
    final marginPct = product.purchasePrice > 0
        ? (margin / product.purchasePrice * 100)
        : 0.0;
    final marginColor = margin >= 0 ? const Color(0xFF10B981) : cs.error;

    return Card(
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
                    _IconBtn(
                      key: Key('edit_product_${product.id}'),
                      icon: Icons.edit_outlined,
                      color: cs.primary,
                      onTap: () => _showForm(context, product),
                    ),
                    const SizedBox(height: 4),
                    _IconBtn(
                      key: Key('delete_product_${product.id}'),
                      icon: Icons.delete_outline,
                      color: cs.error,
                      onTap: () => _confirmDelete(context),
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
                    color: marginColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: marginColor.withValues(alpha: 0.3)),
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
          ],
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Product'),
        content: Text('Delete "${product.itemName}"? This cannot be undone.'),
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
              final batch = FirebaseFirestore.instance.batch();
              batch.delete(FirebaseFirestore.instance
                  .collection(FirestoreCollections.products)
                  .doc(product.id));
              batch.delete(FirebaseFirestore.instance
                  .collection(FirestoreCollections.publicProducts)
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

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.label, required this.icon, required this.cs});
  final String label;
  final IconData icon;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
              style: TextStyle(fontSize: 11, color: cs.onSurface)),
        ],
      ),
    );
  }
}

class _PriceBadge extends StatelessWidget {
  const _PriceBadge(
      {required this.label, required this.value, required this.gradient});
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
  const _EmptyState({required this.cs});
  final ColorScheme cs;

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
          const Text('No products yet',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Tap + to add your first product',
              style: TextStyle(color: cs.outline, fontSize: 13)),
        ],
      ),
    );
  }
}

// ── Product Form Bottom Sheet ─────────────────────────────────

class ProductFormSheet extends StatefulWidget {
  const ProductFormSheet({super.key, this.product});
  final Product? product;

  @override
  State<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();
  bool _saving = false;
  String? _selectedCompanyId;
  String? _selectedCompanyName;

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
    _salePriceCtrl =
        TextEditingController(text: p != null ? p.salePrice.toString() : '');
    _purchasePriceCtrl = TextEditingController(
        text: p != null ? p.purchasePrice.toString() : '');
    _specCtrl = TextEditingController(text: p?.specification ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _selectedCompanyId = p?.companyId;
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _codeCtrl, _barcodeCtrl, _salePriceCtrl,
      _purchasePriceCtrl, _specCtrl, _descCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCompanyId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a company')));
      return;
    }
    setState(() => _saving = true);

    final id = widget.product?.id ?? _uuid.v4();
    final data = Product(
      id: id,
      itemName: _nameCtrl.text.trim(),
      itemCode: _codeCtrl.text.trim(),
      barcode: _barcodeCtrl.text.trim(),
      salePrice: double.tryParse(_salePriceCtrl.text) ?? 0,
      purchasePrice: double.tryParse(_purchasePriceCtrl.text) ?? 0,
      specification: _specCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      categoryId: '', // Add missing categoryId
      companyId: _selectedCompanyId!,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.product != null;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
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
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Company selector
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection(FirestoreCollections.companies)
                          .orderBy('name')
                          .snapshots(),
                      builder: (context, snap) {
                        final docs = snap.data?.docs ?? [];
                        return DropdownButtonFormField<String>(
                          value: _selectedCompanyId,
                          decoration: const InputDecoration(
                            labelText: 'Company',
                            prefixIcon: Icon(Icons.business_outlined),
                          ),
                          items: docs.map((d) {
                            return DropdownMenuItem(
                              value: d.id,
                              child: Text(d.data()['name'] ?? d.id),
                            );
                          }).toList(),
                          onChanged: (v) =>
                              setState(() => _selectedCompanyId = v),
                          validator: (v) =>
                              v == null ? 'Select a company' : null,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Item Name *',
                          prefixIcon: Icon(Icons.inventory_outlined)),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _codeCtrl,
                            decoration: const InputDecoration(
                                labelText: 'Item Code',
                                prefixIcon: Icon(Icons.tag)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _barcodeCtrl,
                            decoration: const InputDecoration(
                                labelText: 'Barcode',
                                prefixIcon: Icon(Icons.barcode_reader)),
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
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[\d.]'))
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Sale Price *',
                              prefixIcon: Icon(Icons.sell_outlined),
                              prefixText: 'Rs. ',
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (double.tryParse(v) == null) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _purchasePriceCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[\d.]'))
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Purchase Price *',
                              prefixIcon: Icon(Icons.shopping_bag_outlined),
                              prefixText: 'Rs. ',
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (double.tryParse(v) == null) return 'Invalid';
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
                          prefixIcon: Icon(Icons.description_outlined)),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                          labelText: 'Description',
                          prefixIcon: Icon(Icons.notes_outlined)),
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
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(isEdit ? 'Update Product' : 'Create Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
