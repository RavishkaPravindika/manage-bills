// ============================================================
// UserRole — role enum for the authenticated user
// ============================================================

enum UserRole {
  /// Unauthenticated or authenticated but not approved.
  guest,

  /// Authenticated with an approved admins/{uid} document.
  admin,

  /// The hardcoded super admin (ravishkapravinsika99@gmail.com).
  superAdmin,
}

extension UserRoleX on UserRole {
  bool get isGuest => this == UserRole.guest;
  bool get isAdmin => this == UserRole.admin;
  bool get isSuperAdmin => this == UserRole.superAdmin;

  /// Returns true for admin or superAdmin.
  bool get canManage => this == UserRole.admin || this == UserRole.superAdmin;
}
