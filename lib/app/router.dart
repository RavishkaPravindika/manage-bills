import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manage_bills/features/auth/auth_provider.dart';
import 'package:manage_bills/features/auth/login_screen.dart';
import 'package:manage_bills/features/search/search_screen.dart';
import 'package:manage_bills/features/admin/companies/companies_screen.dart';
import 'package:manage_bills/features/admin/products/products_screen.dart';
import 'package:manage_bills/features/admin/bills/bills_screen.dart';
import 'package:manage_bills/features/super_admin/admin_dashboard_screen.dart';
import 'package:manage_bills/features/super_admin/recycle_bin_screen.dart';
import 'package:manage_bills/models/user_role.dart';

// ============================================================
// App Router — go_router with role-based redirect guards
// ============================================================

final routerProvider = Provider<GoRouter>((ref) {
  // Rebuild router when role changes.
  final roleAsync = ref.watch(userRoleProvider);

  return GoRouter(
    initialLocation: '/search',
    redirect: (context, state) {
      final role = roleAsync.valueOrNull ?? UserRole.guest;
      final path = state.uri.path;

      // Super-admin routes: only superAdmin
      if (path.startsWith('/super-admin')) {
        if (!role.isSuperAdmin) return '/search';
      }

      // Admin routes: admin or superAdmin
      if (path.startsWith('/admin')) {
        if (!role.canManage) return '/search';
      }

      // Already logged in → redirect away from login
      if (path == '/login' && role.canManage) {
        return role.isSuperAdmin ? '/super-admin' : '/admin/bills';
      }

      return null; // no redirect
    },
    routes: [
      // Public
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Admin routes
      GoRoute(
        path: '/admin/companies',
        builder: (context, state) => const CompaniesScreen(),
      ),
      GoRoute(
        path: '/admin/products',
        builder: (context, state) => const ProductsScreen(),
      ),
      GoRoute(
        path: '/admin/bills',
        builder: (context, state) => const BillsScreen(),
      ),

      // Super Admin routes
      GoRoute(
        path: '/super-admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/super-admin/recycle-bin',
        builder: (context, state) => const RecycleBinScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri}')),
    ),
  );
});
