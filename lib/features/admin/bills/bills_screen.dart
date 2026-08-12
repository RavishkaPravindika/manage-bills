import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:manage_bills/app/theme.dart';
import 'package:manage_bills/core/constants.dart';
import 'package:manage_bills/models/bill.dart';
import 'package:manage_bills/models/company.dart';
import 'package:manage_bills/models/product.dart';

// ============================================================
// Bills Screen — modern redesign
// ============================================================

class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.go('/search'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
                child: const SafeArea(
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Text(
                        'Bills',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
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
                .collection(FirestoreCollections.bills)
                .orderBy('date', descending: true)
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
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.receipt_long_outlined,
                              size: 36, color: cs.onPrimaryContainer),
                        ),
                        const SizedBox(height: 16),
                        const Text('No bills yet',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('Tap + to create your first bill',
                            style: TextStyle(
                                color: cs.outline, fontSize: 13)),
                      ],
                    ),
                  ),
                );
              }

              // Summary
              final totalVal = docs.fold<double>(
                  0, (sum, d) => sum + (d.data()['totalAmount'] ?? 0));

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                sliver: SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _SummaryCard(
                        count: docs.length,
                        total: totalVal,
                        isDark: isDark,
                        cs: cs,
                      ),
                    ),
                    const SliverToBoxAdapter(
                        child: SizedBox(height: 16)),
                    SliverList.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (_, i) => _BillCard(
                          bill: Bill.fromDoc(docs[i]),
                          isDark: isDark,
                          cs: cs),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_bill_fab'),
        onPressed: () => Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) => const BillFormScreen()),
        ),
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('New Bill'),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.count,
    required this.total,
    required this.isDark,
    required this.cs,
  });
  final int count;
  final double total;
  final bool isDark;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Generated',
                    style: TextStyle(color: cs.outline, fontSize: 13)),
                const SizedBox(height: 4),
                ShaderMask(
                  shaderCallback: (b) =>
                      AppTheme.primaryGradient.createShader(b),
                  child: Text(
                    fmt.format(total),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(count.toString(),
                    style: TextStyle(
                      color: cs.onPrimaryContainer,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    )),
                Text('Bills',
                    style: TextStyle(
                      color: cs.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  const _BillCard(
      {required this.bill, required this.isDark, required this.cs});
  final Bill bill;
  final bool isDark;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy, HH:mm');
    final currFmt =
        NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);

    return Card(
      elevation: isDark ? 0 : 2,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute(
              builder: (_) => BillDetailScreen(bill: bill)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.receipt,
                        color: cs.onSecondaryContainer, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bill.companyName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateFmt.format(bill.date),
                          style: TextStyle(
                              color: cs.outline, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    currFmt.format(bill.totalAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: cs.outlineVariant),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 14, color: cs.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${bill.items.length} items included',
                    style: TextStyle(
                        color: cs.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── New Bill Form (2-step) ────────────────────────────────────

class BillFormScreen extends StatefulWidget {
  const BillFormScreen({super.key});

  @override
  State<BillFormScreen> createState() => _BillFormScreenState();
}

class _BillFormScreenState extends State<BillFormScreen> {
  final int _step = 0;
  Company? _selectedCompany;
  List<Company> _companies = [];
  List<Product> _products = [];
  final List<BillItem> _items = [];
  bool _saving = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCompanies();
    _loadProducts();
  }

  Future<void> _loadCompanies() async {
    final snap = await FirebaseFirestore.instance
        .collection(FirestoreCollections.companies)
        .orderBy('name')
        .get();
    if (mounted) {
      setState(() => _companies = snap.docs.map(Company.fromDoc).toList());
    }
  }

  Future<void> _loadProducts() async {
    final snap = await FirebaseFirestore.instance
        .collection(FirestoreCollections.products)
        .orderBy('itemName')
        .get();
    if (mounted) {
      setState(() => _products = snap.docs.map(Product.fromDoc).toList());
    }
  }

  double get _total =>
      _items.fold(0.0, (acc, item) => acc + item.subtotal);

  void _addItem(Product product) {
    final existing = _items.indexWhere((i) => i.productId == product.id);
    setState(() {
      if (existing >= 0) {
        _items[existing] = _items[existing].copyWith(
          quantity: _items[existing].quantity + 1,
        );
      } else {
        _items.add(BillItem(
          productId: product.id,
          itemName: product.itemName,
          quantity: 1,
          unitPrice: product.salePrice,
        ));
      }
    });
  }

  void _updateQty(int index, int qty) {
    if (qty <= 0) {
      setState(() => _items.removeAt(index));
    } else {
      setState(() {
        _items[index] = _items[index].copyWith(quantity: qty);
      });
    }
  }

  Future<void> _saveBill() async {
    if (_selectedCompany == null || _items.isEmpty) return;
    setState(() => _saving = true);

    final bill = Bill(
      id: '',
      date: DateTime.now(),
      companyId: _selectedCompany!.id,
      companyName: _selectedCompany!.name,
      totalAmount: _total,
      items: _items,
    );

    await FirebaseFirestore.instance
        .collection(FirestoreCollections.bills)
        .add(bill.toMap());

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currFmt =
        NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: Text(_step == 0 ? 'Select Company' : 'Add Items'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Step indicator
          Container(
            color: cs.surfaceContainerHigh,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StepBubble(
                    number: 1, active: true, title: 'Company'),
                Container(width: 40, height: 2, color: cs.primary),
                _StepBubble(
                    number: 2,
                    active: _step == 1,
                    title: 'Items'),
              ],
            ),
          ),
          Expanded(
            child: _step == 0
                ? _buildStep1(isDark, cs)
                : _buildStep2(isDark, cs, currFmt),
          ),
        ],
      ),
      bottomNavigationBar: _step == 1
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2))
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total',
                              style: TextStyle(
                                  color: cs.outline, fontSize: 12)),
                          Text(currFmt.format(_total),
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _items.isEmpty || _saving
                          ? null
                          : _saveBill,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check),
                      label: const Text('Save Bill'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildStep1(bool isDark, ColorScheme cs) {
    if (_companies.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _companies.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final c = _companies[i];
        final selected = _selectedCompany?.id == c.id;
        return ListTile(
          onTap: () => setState(() => _selectedCompany = c),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: selected ? cs.primary : Colors.transparent,
              width: 2,
            ),
          ),
          tileColor:
              selected ? cs.primaryContainer : cs.surfaceContainerHigh,
          leading: Icon(Icons.business,
              color: selected ? cs.primary : cs.outline),
          title: Text(c.name,
              style: TextStyle(
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
          trailing: selected
              ? Icon(Icons.check_circle, color: cs.primary)
              : null,
        );
      },
    );
  }

  Widget _buildStep2(bool isDark, ColorScheme cs, NumberFormat currFmt) {
    // Filter products belonging to selected company + search query
    final available = _products.where((p) {
      if (p.companyId != _selectedCompany!.id) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return p.itemName.toLowerCase().contains(q) ||
          p.itemCode.toLowerCase().contains(q) ||
          p.barcode.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        // Product search
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Search items to add',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        // Added items list
        if (_items.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('Added Items (${_items.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final item = _items[i];
                return Container(
                  width: 200,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isDark ? Colors.white12 : Colors.black12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.itemName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(currFmt.format(item.unitPrice),
                          style: TextStyle(
                              color: cs.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Row(
                        children: [
                          _QtyBtn(
                              icon: Icons.remove,
                              onTap: () =>
                                  _updateQty(i, item.quantity - 1)),
                          Expanded(
                            child: Text(
                              item.quantity.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          _QtyBtn(
                              icon: Icons.add,
                              onTap: () =>
                                  _updateQty(i, item.quantity + 1)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(),
          ),
        ],
        // Available products
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: available.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final p = available[i];
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: cs.outlineVariant),
                ),
                title: Text(p.itemName,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  '${p.itemCode.isNotEmpty ? '${p.itemCode} • ' : ''}${currFmt.format(p.salePrice)}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle),
                  color: cs.primary,
                  onPressed: () => _addItem(p),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 16),
        ),
      ),
    );
  }
}

class _StepBubble extends StatelessWidget {
  const _StepBubble(
      {required this.number, required this.active, required this.title});
  final int number;
  final bool active;
  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: active ? cs.primary : cs.surface,
            shape: BoxShape.circle,
            border: Border.all(color: active ? cs.primary : cs.outline),
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: TextStyle(
                color: active ? cs.onPrimary : cs.outline,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: active ? cs.onSurface : cs.outline,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

// ── Bill Detail Screen ────────────────────────────────────────

class BillDetailScreen extends StatelessWidget {
  const BillDetailScreen({super.key, required this.bill});
  final Bill bill;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy, HH:mm');
    final currFmt =
        NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Bill Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.receipt_long, size: 48),
                  const SizedBox(height: 16),
                  Text(bill.companyName,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(dateFmt.format(bill.date),
                      style: TextStyle(color: cs.outline)),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        for (final item in bill.items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text('${item.quantity}x',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item.itemName),
                                      Text(
                                          currFmt.format(item.unitPrice),
                                          style: TextStyle(
                                              color: cs.outline,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Text(
                                  currFmt.format(item.subtotal),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        const Divider(),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            Text(currFmt.format(bill.totalAmount),
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: cs.primary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
