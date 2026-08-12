import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================
// AdminUser — Firestore admins/{uid} document model
// ============================================================

enum AdminStatus { pending, approved, revoked }

class AdminUser {
  const AdminUser({
    required this.uid,
    required this.email,
    required this.role,
    required this.status,
    this.photoUrl,
    this.displayName,
  });

  final String uid;
  final String email;
  final String role; // 'admin' | 'superAdmin'
  final AdminStatus status;
  final String? photoUrl;
  final String? displayName;

  factory AdminUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AdminUser(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? 'admin',
      status: _parseStatus(data['status'] as String?),
      photoUrl: data['photoUrl'] as String?,
      displayName: data['displayName'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'role': role,
        'status': status.name,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (displayName != null) 'displayName': displayName,
      };

  AdminUser copyWith({
    String? uid,
    String? email,
    String? role,
    AdminStatus? status,
    String? photoUrl,
    String? displayName,
  }) =>
      AdminUser(
        uid: uid ?? this.uid,
        email: email ?? this.email,
        role: role ?? this.role,
        status: status ?? this.status,
        photoUrl: photoUrl ?? this.photoUrl,
        displayName: displayName ?? this.displayName,
      );

  static AdminStatus _parseStatus(String? s) => switch (s) {
        'approved' => AdminStatus.approved,
        'revoked' => AdminStatus.revoked,
        _ => AdminStatus.pending,
      };
}
