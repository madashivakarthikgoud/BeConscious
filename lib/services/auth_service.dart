import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Handles Google Sign-In via Firebase Auth (FREE, unlimited)
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Current signed-in user (null if not signed in)
  static User? get currentUser => _auth.currentUser;

  /// Whether user is signed in
  static bool get isSignedIn => _auth.currentUser != null;

  /// Stream of auth state changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with Google account
  static Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      return null;
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Get user display name
  static String? get displayName => _auth.currentUser?.displayName;

  /// Get user email
  static String? get email => _auth.currentUser?.email;

  /// Get user photo URL
  static String? get photoUrl => _auth.currentUser?.photoURL;
}

