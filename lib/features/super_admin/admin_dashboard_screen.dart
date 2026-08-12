import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manage_bills/app/theme.dart';
import 'package:manage_bills/core/constants.dart';
import 'package:manage_bills/models/admin_user.dart';

// ============================================================
// Super Admin Dashboard — manage admin users
// ============================================================

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                        'Admin Access',
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
                .collection(FirestoreCollections.admins)
                .orderBy('email')
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final docs = snap.data?.docs ?? [];
              final admins = docs.map(AdminUser.fromDoc).toList();
              final pending =
                  admins.where((a) => a.status == AdminStatus.pending).length;
              final approved =
                  admins.where((a) => a.status == AdminStatus.approved).length;

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                sliver: SliverMainAxisGroup(
                  slivers: [
                    // Stats Row
                    SliverToBoxAdapter(
                      child: Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'Pending',
                              count: pending,
                              color: const Color(0xFFF59E0B), // amber
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              title: 'Approved',
                              count: approved,
                              color: const Color(0xFF10B981), // emerald
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                    if (admins.isEmpty)
                      SliverFillRemaining(
                        child: Center(
                          child: Text('No admin accounts found.',
                              style: TextStyle(color: cs.outline)),
                        ),
                      )
                    else
                      SliverList.separated(
                        itemCount: admins.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) => _AdminCard(
                          admin: admins[i],
                          isDark: isDark,
                          cs: cs,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.title, required this.count, required this.color});
  final String title;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  const _AdminCard(
      {required this.admin, required this.isDark, required this.cs});
  final AdminUser admin;
  final bool isDark;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    switch (admin.status) {
      case AdminStatus.approved:
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.check_circle;
        break;
      case AdminStatus.pending:
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.schedule;
        break;
      case AdminStatus.revoked:
        statusColor = cs.error;
        statusIcon = Icons.cancel;
        break;
    }

    return Card(
      elevation: isDark ? 0 : 2,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar (Google Profile Photo)
                CircleAvatar(
                  radius: 24,
                  backgroundColor: cs.surfaceContainerHigh,
                  backgroundImage:
                      admin.photoUrl != null && admin.photoUrl!.isNotEmpty
                          ? NetworkImage(admin.photoUrl!)
                          : null,
                  child: admin.photoUrl == null || admin.photoUrl!.isEmpty
                      ? Icon(Icons.person, color: cs.outline)
                      : null,
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (admin.displayName != null &&
                          admin.displayName!.isNotEmpty) ...[
                        Text(
                          admin.displayName!,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        admin.email,
                        style: TextStyle(
                          fontSize: 13,
                          color: admin.displayName != null &&
                                  admin.displayName!.isNotEmpty
                              ? cs.outline
                              : cs.onSurface,
                          fontWeight: admin.displayName == null ||
                                  admin.displayName!.isEmpty
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon,
                                size: 12, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              admin.status.name.toUpperCase(),
                              style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: cs.outlineVariant),
            const SizedBox(height: 8),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (admin.status != AdminStatus.approved)
                  TextButton.icon(
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                    style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF10B981)),
                    onPressed: () => _updateStatus(
                        context, admin.uid, AdminStatus.approved),
                  ),
                if (admin.status != AdminStatus.revoked)
                  TextButton.icon(
                    icon: const Icon(Icons.block, size: 18),
                    label: const Text('Revoke'),
                    style: TextButton.styleFrom(foregroundColor: cs.error),
                    onPressed: () => _updateStatus(
                        context, admin.uid, AdminStatus.revoked),
                  ),
                if (admin.status == AdminStatus.revoked)
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(foregroundColor: cs.error),
                    onPressed: () => _deleteAdmin(context, admin),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(
      BuildContext context, String uid, AdminStatus status) async {
    await FirebaseFirestore.instance
        .collection(FirestoreCollections.admins)
        .doc(uid)
        .update({'status': status.name});
  }

  Future<void> _deleteAdmin(BuildContext context, AdminUser admin) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Admin Record?'),
        content: Text('Delete ${admin.email}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection(FirestoreCollections.admins)
          .doc(admin.uid)
          .delete();
    }
  }
}
