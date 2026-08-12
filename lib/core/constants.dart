// ============================================================
// Manage Bills — Application Constants
// ============================================================

/// The hardcoded Super Admin email address.
const String kSuperAdminEmail = 'ravishkapravinsika99@gmail.com';

/// ── Google Sign-In ───────────────────────────────────────────
/// Your Web OAuth 2.0 Client ID from Google Cloud Console.
///
/// How to get it:
///   1. Go to https://console.cloud.google.com/apis/credentials
///   2. Select project: test-admin-database
///   3. Create Credentials → OAuth client ID → Web application
///   4. Paste the resulting ID below (ends in .apps.googleusercontent.com)
///
/// IMPORTANT: Also add the authorized JavaScript origin in that console:
///   Development: http://localhost:5000
///   Production:  https://your-domain.com
const String kGoogleWebClientId =
    'PASTE_YOUR_WEB_OAUTH_CLIENT_ID_HERE.apps.googleusercontent.com';

/// Firestore collection names — centralised to avoid typos.
class FirestoreCollections {
  const FirestoreCollections._();

  /// Full product documents — admin access only.
  static const String products = 'products';

  /// Public product mirror — safe fields only, guest-readable.
  static const String publicProducts = 'publicProducts';

  /// Company documents.
  static const String companies = 'companies';

  /// Bill documents.
  static const String bills = 'bills';

  /// Admin user documents keyed by UID.
  static const String admins = 'admins';
}

/// Fields that are safe to expose to unauthenticated guests.
const List<String> kGuestSafeProductFields = [
  'itemName',
  'itemCode',
  'barcode',
  'salePrice',
  'specification',
  'description',
];
