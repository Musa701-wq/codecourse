import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get userChanges => _auth.userChanges();

  /// 🔹 Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn(scopes: ['email']).signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      debugPrint("❌ Google Sign-In failed: $e");
      rethrow;
    }
  }

  /// 🔹 Sign in with Apple - Enhanced version
  Future<User?> signInWithApple() async {
    if (!Platform.isIOS && !Platform.isMacOS) {
      throw UnsupportedError('Apple Sign-In works only on iOS/macOS.');
    }

    try {

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );



      // Check if we have the necessary tokens
      if (appleCredential.identityToken == null) {
        throw FirebaseAuthException(
          code: 'missing-identity-token',
          message: 'Apple Sign-In failed: No identity token received',
        );
      }

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ Firebase Auth Error during Apple Sign-In:");
      debugPrint("   Code: ${e.code}");
      debugPrint("   Message: ${e.message}");
      debugPrint("   Details: ${e.stackTrace}");
      rethrow;
    } on SignInWithAppleAuthorizationException catch (e) {
      debugPrint("❌ Apple Authorization Error:");
      debugPrint("   Code: ${e.code}");
      debugPrint("   Message: ${e.message}");
      rethrow;
    } catch (e, stackTrace) {
      debugPrint("❌ Unexpected error during Apple Sign-In:");
      debugPrint("   Error: $e");
      debugPrint("   Stack: $stackTrace");
      rethrow;
    }
  }
  /// 🔹 Sign out from Firebase and Google
  Future<void> signOut() async {
    try {
      await _auth.signOut();

      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }

      debugPrint("✅ User signed out successfully");
    } catch (e) {
      debugPrint("❌ Error signing out: $e");
      rethrow;
    }
  }
}
