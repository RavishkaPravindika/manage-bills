import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:manage_bills/core/constants.dart';
import 'package:manage_bills/models/user_role.dart';

// ============================================================
// Auth Provider — resolves Firebase user to a UserRole
// ============================================================

/// The raw Firebase [User] stream.
final firebaseAuthProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.authStateChanges(),
);

/// Resolved [UserRole] for the current session.
final userRoleProvider = FutureProvider<UserRole>((ref) async {
  final authAsync = ref.watch(firebaseAuthProvider);

  return authAsync.when(
    data: (user) async {
      if (user == null) return UserRole.guest;
      if (user.email == kSuperAdminEmail) return UserRole.superAdmin;

      try {
        final doc = await FirebaseFirestore.instance
            .collection(FirestoreCollections.admins)
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final status = doc.data()?['status'] as String?;
          if (status == 'approved') return UserRole.admin;
        }
      } catch (_) {}

      return UserRole.guest;
    },
    loading: () async => UserRole.guest,
    error: (_, __) async => UserRole.guest,
  );
});

/// Current Firebase [User] (may be null).
final currentUserProvider = Provider<User?>(
  (ref) => ref.watch(firebaseAuthProvider).valueOrNull,
);

// ============================================================
// AuthService — sign-in / sign-out helpers
// ============================================================

class AuthService {
  AuthService._();

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Web client ID — required for web and to get idToken on Android.
    clientId: kGoogleWebClientId,
    serverClientId: kGoogleWebClientId,
    scopes: ['email', 'profile'],
  );

  // ── Google Sign-In ─────────────────────────────────────────

  /// Signs in with Google and links to Firebase Auth.
  /// On first sign-in, creates a pending admins document.
  static Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in was cancelled.');
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCred =
        await FirebaseAuth.instance.signInWithCredential(credential);

    // Auto-create a pending admin document on first sign-in
    // (only for non-super-admin accounts).
    final user = userCred.user!;
    if (user.email != kSuperAdminEmail) {
      final adminRef = FirebaseFirestore.instance
          .collection(FirestoreCollections.admins)
          .doc(user.uid);
      final snap = await adminRef.get();
      if (!snap.exists) {
        await adminRef.set({
          'uid': user.uid,
          'email': user.email ?? '',
          'role': 'admin',
          'status': 'pending',
          'photoUrl': user.photoURL ?? '',
          'displayName': user.displayName ?? '',
        });
      }
    }

    return userCred;
  }

  // ── Email / Password ───────────────────────────────────────

  static Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> registerAdmin({
    required String email,
    required String password,
  }) async {
    final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await FirebaseFirestore.instance
        .collection(FirestoreCollections.admins)
        .doc(cred.user!.uid)
        .set({
      'uid': cred.user!.uid,
      'email': email,
      'role': 'admin',
      'status': 'pending',
      'photoUrl': '',
      'displayName': '',
    });
  }

  // ── Sign out ───────────────────────────────────────────────

  static Future<void> signOut() async {
    await Future.wait([
      FirebaseAuth.instance.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
}
