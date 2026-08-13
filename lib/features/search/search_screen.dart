import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:manage_bills/app/theme.dart';
import 'package:manage_bills/features/auth/auth_provider.dart';
import 'package:manage_bills/features/search/barcode_scanner_screen.dart';
import 'package:manage_bills/features/search/search_provider.dart';
import 'package:manage_bills/models/user_role.dart';

// ============================================================
// Search Screen — modern redesign with dynamic search
// ============================================================

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _barcodeCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _specCtrl = TextEditingController();
  late final AnimationController _headerCtrl;
  late final Animation<double> _headerFade;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _headerFade =
        CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _barcodeCtrl.dispose();
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _specCtrl.dispose();
    _headerCtrl.dispose();
    super.dispose();
  }

  /// Triggers a debounced search with current field values.
  void _triggerDynamicSearch() {
    ref.read(searchProvider.notifier).searchDebounced(SearchQuery(
          barcode: _barcodeCtrl.text.trim(),
          itemCode: _codeCtrl.text.trim(),
          itemName: _nameCtrl.text.trim(),
          specification: _specCtrl.text.trim(),
        ));
  }

  void _search() {
    ref.read(searchProvider.notifier).search(SearchQuery(
          barcode: _barcodeCtrl.text.trim(),
          itemCode: _codeCtrl.text.trim(),
          itemName: _nameCtrl.text.trim(),
          specification: _specCtrl.text.trim(),
        ));
  }

  void _clear() {
    _barcodeCtrl.clear();
    _codeCtrl.clear();
    _nameCtrl.clear();
    _specCtrl.clear();
    ref.read(searchProvider.notifier).clear();
  }

  Future<void> _openScanner() async {
    final result = await Navigator.of(context).push<String?>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (result != null && result.isNotEmpty) {
      _barcodeCtrl.text = result;
      _search();
    }
  }

  Future<void> _onRefresh() async {
    _search();
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final searchState = ref.watch(searchProvider);
    final role = ref.watch(userRoleProvider).valueOrNull ?? UserRole.guest;
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
          // ── Gradient App Bar ─────────────────────────────────
          SliverAppBar(
            expandedHeight: 130,
            floating: true,
            snap: true,
            pinned: false,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
                child: SafeArea(
                  child: FadeTransition(
                    opacity: _headerFade,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Manage Bills',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  role.isGuest
                                      ? 'Guest Mode'
                                      : role.isSuperAdmin
                                          ? 'Super Admin'
                                          : 'Admin',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Action icons
                          _buildAppBarActions(role, user, context),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Card(
                elevation: isDark ? 0 : 2,
                shadowColor: Colors.black12,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Barcode + camera
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              key: const Key('search_barcode_field'),
                              controller: _barcodeCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Barcode',
                                prefixIcon:
                                    Icon(Icons.barcode_reader, size: 18),
                                isDense: true,
                              ),
                              onChanged: (_) => _triggerDynamicSearch(),
                              onSubmitted: (_) => _search(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _ScanButton(onPressed: _openScanner),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              key: const Key('search_code_field'),
                              controller: _codeCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Item Code',
                                isDense: true,
                              ),
                              onChanged: (_) => _triggerDynamicSearch(),
                              onSubmitted: (_) => _search(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              key: const Key('search_name_field'),
                              controller: _nameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Item Name',
                                isDense: true,
                              ),
                              onChanged: (_) => _triggerDynamicSearch(),
                              onSubmitted: (_) => _search(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        key: const Key('search_spec_field'),
                        controller: _specCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Specification',
                          isDense: true,
                        ),
                        onChanged: (_) => _triggerDynamicSearch(),
                        onSubmitted: (_) => _search(),
                      ),
                      const SizedBox(height: 14),
                      // Search + Clear buttons
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _SearchButton(onPressed: _search),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              key: const Key('search_clear_button'),
                              onPressed: _clear,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12)),
                              ),
                              child: const Text('Clear'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Results ──────────────────────────────────────────
          searchState.when(
            data: (results) {
              if (results.isEmpty) {
                return SliverFillRemaining(
                  child: _EmptyState(cs: cs, theme: theme),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                sliver: SliverList.separated(
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) =>
                      _ProductCard(result: results[i], role: role),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Text('Error: $e',
                    style: TextStyle(color: cs.error)),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildAppBarActions(UserRole role, user, BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (role.canManage) ...[
          _AppBarIconBtn(
            icon: Icons.receipt_long_outlined,
            tooltip: 'Bills',
            onTap: () => context.push('/admin/bills'),
          ),
          _AppBarIconBtn(
            icon: Icons.inventory_2_outlined,
            tooltip: 'Products',
            onTap: () => context.push('/admin/products'),
          ),
          _AppBarIconBtn(
            icon: Icons.business_outlined,
            tooltip: 'Companies',
            onTap: () => context.push('/admin/companies'),
          ),
        ],
        if (role.isSuperAdmin) ...[
          _AppBarIconBtn(
            icon: Icons.delete_sweep_outlined,
            tooltip: 'Recycle Bin',
            onTap: () => context.push('/super-admin/recycle-bin'),
          ),
          _AppBarIconBtn(
            icon: Icons.admin_panel_settings_outlined,
            tooltip: 'Admin Dashboard',
            onTap: () => context.push('/super-admin'),
          ),
        ],
        if (role.isGuest)
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Login',
                style: TextStyle(color: Colors.white, fontSize: 13)),
          )
        else
          _UserAvatar(user: user, onSignOut: () async {
            await AuthService.signOut();
            if (context.mounted) context.go('/search');
          }),
      ],
    );
  }
}

// ── Gradient search button ────────────────────────────────────

class _SearchButton extends StatelessWidget {
  const _SearchButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('search_submit_button'),
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: const Padding(
            padding:
                EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.manage_search_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                SizedBox(width: 8),
                Text(
                  'Search',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  const _ScanButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: const Key('search_scan_button'),
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            Icons.camera_alt_outlined,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: 22,
          ),
        ),
      ),
    );
  }
}

// ── Product result card ───────────────────────────────────────

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.result, required this.role});
  final SearchResult result;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final currFmt = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);

    return Card(
      elevation: isDark ? 0 : 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Color accent dot
                Container(
                  width: 4,
                  height: 44,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.itemName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (result.barcode.isNotEmpty)
                            _Tag(
                              icon: Icons.barcode_reader,
                              label: result.barcode,
                              cs: cs,
                            ),
                          if (result.itemCode.isNotEmpty)
                            _Tag(
                              icon: Icons.tag,
                              label: result.itemCode,
                              cs: cs,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Sale price badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    currFmt.format(result.salePrice),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            if (result.specification.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                result.specification,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.6)),
              ),
            ],
            if (result.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                result.description,
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            // Admin-only pricing + company name
            if (role.canManage && result.product != null) ...[
              const SizedBox(height: 10),
              Divider(height: 1, color: cs.outlineVariant),
              const SizedBox(height: 10),
              Row(
                children: [
                  _PriceTag(
                    label: 'Purchase',
                    value: currFmt.format(result.product!.purchasePrice),
                    color: cs.secondary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.business, size: 14, color: cs.outline),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            result.companyName.isNotEmpty
                                ? result.companyName
                                : 'Unknown Company',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label, required this.cs});
  final IconData icon;
  final String label;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: cs.outline),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 11, color: cs.outline)),
      ],
    );
  }
}

class _PriceTag extends StatelessWidget {
  const _PriceTag(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ',
            style: TextStyle(
                fontSize: 11,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5))),
        Text(value,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

// ── Empty state ───────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.cs, required this.theme});
  final ColorScheme cs;
  final ThemeData theme;

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
            child: Icon(
              Icons.manage_search_rounded,
              size: 40,
              color: cs.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Search for products',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Use the fields above to find items\nby name, code, barcode or spec',
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.outline, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── AppBar helpers ────────────────────────────────────────────

class _AppBarIconBtn extends StatelessWidget {
  const _AppBarIconBtn(
      {required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: Colors.white, size: 22),
      tooltip: tooltip,
      onPressed: onTap,
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user, required this.onSignOut});
  final dynamic user;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final photoUrl = user?.photoURL as String?;
    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: CircleAvatar(
          radius: 16,
          backgroundImage:
              photoUrl != null && photoUrl.isNotEmpty
                  ? NetworkImage(photoUrl)
                  : null,
          backgroundColor: Colors.white24,
          child: photoUrl == null || photoUrl.isEmpty
              ? const Icon(Icons.person, color: Colors.white, size: 18)
              : null,
        ),
      ),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'email',
          enabled: false,
          child: Text(
            user?.email as String? ?? '',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'signout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 16),
              SizedBox(width: 8),
              Text('Sign Out'),
            ],
          ),
        ),
      ],
      onSelected: (v) {
        if (v == 'signout') onSignOut();
      },
    );
  }
}
