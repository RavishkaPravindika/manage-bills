import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:manage_bills/app/theme.dart';
import 'package:manage_bills/core/constants.dart';
import 'package:manage_bills/models/recycled_item.dart';

// ============================================================
// Recycle Bin Screen — Super Admin tool to view, restore,
// or permanently delete recycled items.
// ============================================================

class RecycleBinScreen extends StatelessWidget {
  const RecycleBinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFmt = DateFormat('dd MMM yyyy, HH:mm');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.go('/super-admin'),
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
                        'Recycle Bin',
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
                .collection(FirestoreCollections.recycleBin)
                .orderBy('deletedAt', descending: true)
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
                          child: Icon(Icons.delete_outline,
                              size: 40, color: cs.onPrimaryContainer),
                        ),
                        const SizedBox(height: 16),
                        const Text('Recycle Bin is Empty',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('Deleted items will appear here',
                            style: TextStyle(
                                color: cs.outline, fontSize: 13)),
                      ],
                    ),
                  ),
                );
              }

              final items = docs.map(RecycledItem.fromDoc).toList();

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                sliver: SliverList.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final item = items[i];
                    return Card(
                      elevation: isDark ? 0 : 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _TypeBadge(
                                  label: item.typeLabel,
                                  cs: cs,
                                ),
                                const Spacer(),
                                Text(
                                  dateFmt.format(item.deletedAt),
                                  style: TextStyle(
                                      color: cs.outline, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item.itemName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.restore, size: 18),
                                  label: const Text('Restore'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: cs.primary,
                                  ),
                                  onPressed: () =>
                                      _restoreItem(context, item),
                                ),
                                const SizedBox(width: 8),
                                FilledButton.icon(
                                  icon: const Icon(Icons.delete_forever,
                                      size: 18),
                                  label: const Text('Delete Forever'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: cs.error,
                                  ),
                                  onPressed: () =>
                                      _permanentlyDeleteItem(context, item),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _restoreItem(BuildContext context, RecycledItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Restore Item'),
        content: Text('Restore "${item.itemName}" to active storage?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final fs = FirebaseFirestore.instance;
    final batch = fs.batch();

    // Re-create in original collection
    final origRef = fs.collection(item.originalCollection).doc(item.originalId);
    batch.set(origRef, item.data);

    // If it's a product, also restore to publicProducts mirror
    if (item.originalCollection == FirestoreCollections.products) {
      final publicRef =
          fs.collection(FirestoreCollections.publicProducts).doc(item.originalId);
      final safeMap = {
        'itemName': item.data['itemName'] ?? '',
        'itemCode': item.data['itemCode'] ?? '',
        'barcode': item.data['barcode'] ?? '',
        'salePrice': item.data['salePrice'] ?? 0.0,
        'specification': item.data['specification'] ?? '',
        'description': item.data['description'] ?? '',
      };
      batch.set(publicRef, safeMap);
    }

    // Delete from recycleBin
    final binRef = fs.collection(FirestoreCollections.recycleBin).doc(item.id);
    batch.delete(binRef);

    await batch.commit();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restored "${item.itemName}"')),
      );
    }
  }

  Future<void> _permanentlyDeleteItem(
      BuildContext context, RecycledItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Permanently Delete'),
        content: Text(
            'Permanently delete "${item.itemName}"? This CANNOT be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseFirestore.instance
        .collection(FirestoreCollections.recycleBin)
        .doc(item.id)
        .delete();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permanently deleted "${item.itemName}"')),
      );
    }
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label, required this.cs});
  final String label;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: cs.onPrimaryContainer,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
