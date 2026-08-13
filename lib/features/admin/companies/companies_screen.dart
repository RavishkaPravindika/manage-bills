import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manage_bills/app/theme.dart';
import 'package:manage_bills/core/constants.dart';
import 'package:manage_bills/features/auth/auth_provider.dart';
import 'package:manage_bills/models/company.dart';
import 'package:manage_bills/models/user_role.dart';

// ============================================================
// Companies Screen — modern redesign with search, ownership & recycle bin
// ============================================================

class CompaniesScreen extends ConsumerStatefulWidget {
  const CompaniesScreen({super.key});

  @override
  ConsumerState<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends ConsumerState<CompaniesScreen> {
  String _searchQuery = '';

  Future<void> _onRefresh() async {
    setState(() {});
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final role = ref.watch(userRoleProvider).valueOrNull ?? UserRole.guest;
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
          // Gradient app bar
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/search');
                }
              },
            ),
            actions: [
              if (role.isSuperAdmin)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
                  tooltip: 'Recycle Bin',
                  onPressed: () => context.push('/super-admin/recycle-bin'),
                ),
              const SizedBox(width: 8),
            ],
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
                        'Companies',
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

          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search companies by name...',
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

          // List
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection(FirestoreCollections.companies)
                .orderBy('name')
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
                      final name =
                          (d.data()['name'] as String? ?? '').toLowerCase();
                      return name.contains(_searchQuery.toLowerCase());
                    }).toList();

              if (docs.isEmpty) {
                return SliverFillRemaining(
                  child: _EmptyPlaceholder(
                    icon: Icons.business_outlined,
                    title: _searchQuery.isNotEmpty
                        ? 'No matching companies'
                        : 'No companies yet',
                    subtitle: _searchQuery.isNotEmpty
                        ? 'Try a different search term'
                        : 'Tap + to add your first company',
                    cs: cs,
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                sliver: SliverList.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final company = Company.fromDoc(docs[i]);
                    return _CompanyCard(
                      company: company,
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
    ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_company_fab'),
        onPressed: () => _showForm(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Add Company'),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  void _showForm(BuildContext context, Company? company) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CompanyFormSheet(company: company),
    );
  }
}

class _CompanyCard extends StatelessWidget {
  const _CompanyCard({
    required this.company,
    required this.isDark,
    required this.cs,
    required this.role,
    required this.currentUid,
  });
  final Company company;
  final bool isDark;
  final ColorScheme cs;
  final UserRole role;
  final String currentUid;

  bool get _canEdit =>
      role.isSuperAdmin ||
      (role.isAdmin && company.createdBy == currentUid);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.business_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              // Name + ID
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${company.id}',
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.outline,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_canEdit)
                    _IconAction(
                      key: Key('edit_company_${company.id}'),
                      icon: Icons.edit_outlined,
                      color: cs.primary,
                      onTap: () => _showEditForm(context),
                    ),
                  if (role.isSuperAdmin) ...[
                    if (_canEdit) const SizedBox(width: 4),
                    _IconAction(
                      key: Key('delete_company_${company.id}'),
                      icon: Icons.delete_outline,
                      color: cs.error,
                      onTap: () => _confirmDelete(context),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditForm(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CompanyFormSheet(company: company),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Company'),
        content: Text('Move "${company.name}" to recycle bin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final fs = FirebaseFirestore.instance;
                final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                await fs.collection(FirestoreCollections.recycleBin).add({
                  'originalCollection': FirestoreCollections.companies,
                  'originalId': company.id,
                  'data': company.toMap(),
                  'deletedBy': uid,
                  'deletedAt': Timestamp.now(),
                  'itemName': 'Company: ${company.name}',
                });
                await fs
                    .collection(FirestoreCollections.companies)
                    .doc(company.id)
                    .delete();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error moving to recycle bin: $e')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Company Form Bottom Sheet ─────────────────────────────────

class CompanyFormSheet extends StatefulWidget {
  const CompanyFormSheet({super.key, this.company});
  final Company? company;

  @override
  State<CompanyFormSheet> createState() => _CompanyFormSheetState();
}

class _CompanyFormSheetState extends State<CompanyFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.company?.name ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final col = FirebaseFirestore.instance
        .collection(FirestoreCollections.companies);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (widget.company == null) {
      await col.add({
        'name': _nameCtrl.text.trim(),
        'createdBy': uid,
      });
    } else {
      await col.doc(widget.company!.id).update({
        'name': _nameCtrl.text.trim(),
      });
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.company != null;

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
              isEdit ? 'Edit Company' : 'New Company',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: TextFormField(
                key: const Key('company_name_field'),
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Company Name',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
                autofocus: true,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
                onFieldSubmitted: (_) => _save(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              key: const Key('company_save_button'),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(isEdit ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────

class _IconAction extends StatelessWidget {
  const _IconAction({
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
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  const _EmptyPlaceholder({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cs,
  });
  final IconData icon;
  final String title;
  final String subtitle;
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
              color: cs.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: cs.onPrimaryContainer),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: TextStyle(color: cs.outline, fontSize: 13)),
        ],
      ),
    );
  }
}
