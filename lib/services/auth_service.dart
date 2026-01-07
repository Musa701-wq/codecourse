// import 'dart:io' show Platform;
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/foundation.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:sign_in_with_apple/sign_in_with_apple.dart';
//
// class AuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//
//   Stream<User?> get userChanges => _auth.userChanges();
//
//   /// 🔹 Sign in with Google
//   Future<User?> signInWithGoogle() async {
//     try {
//       final googleUser = await GoogleSignIn(scopes: ['email']).signIn();
//       if (googleUser == null) return null;
//
//       final googleAuth = await googleUser.authentication;
//       final credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.accessToken,
//         idToken: googleAuth.idToken,
//       );
//
//       final userCredential = await _auth.signInWithCredential(credential);
//       return userCredential.user;
//     } catch (e) {
//       debugPrint("❌ Google Sign-In failed: $e");
//       rethrow;
//     }
//   }
//
//   /// 🔹 Sign in with Apple - Enhanced version
//   Future<User?> signInWithApple() async {
//     if (!Platform.isIOS && !Platform.isMacOS) {
//       throw UnsupportedError('Apple Sign-In works only on iOS/macOS.');
//     }
//
//     try {
//
//       final appleCredential = await SignInWithApple.getAppleIDCredential(
//         scopes: [
//           AppleIDAuthorizationScopes.email,
//           AppleIDAuthorizationScopes.fullName,
//         ],
//       );
//
//
//
//       // Check if we have the necessary tokens
//       if (appleCredential.identityToken == null) {
//         throw FirebaseAuthException(
//           code: 'missing-identity-token',
//           message: 'Apple Sign-In failed: No identity token received',
//         );
//       }
//
//       final oauthCredential = OAuthProvider('apple.com').credential(
//         idToken: appleCredential.identityToken,
//         accessToken: appleCredential.authorizationCode,
//       );
//
//       final userCredential = await _auth.signInWithCredential(oauthCredential);
//
//       return userCredential.user;
//     } on FirebaseAuthException catch (e) {
//       debugPrint("❌ Firebase Auth Error during Apple Sign-In:");
//       debugPrint("   Code: ${e.code}");
//       debugPrint("   Message: ${e.message}");
//       debugPrint("   Details: ${e.stackTrace}");
//       rethrow;
//     } on SignInWithAppleAuthorizationException catch (e) {
//       debugPrint("❌ Apple Authorization Error:");
//       debugPrint("   Code: ${e.code}");
//       debugPrint("   Message: ${e.message}");
//       rethrow;
//     } catch (e, stackTrace) {
//       debugPrint("❌ Unexpected error during Apple Sign-In:");
//       debugPrint("   Error: $e");
//       debugPrint("   Stack: $stackTrace");
//       rethrow;
//     }
//   }
//   /// 🔹 Sign out from Firebase and Google
//   Future<void> signOut() async {
//     try {
//       await _auth.signOut();
//
//       final googleSignIn = GoogleSignIn();
//       if (await googleSignIn.isSignedIn()) {
//         await googleSignIn.signOut();
//       }
//
//       debugPrint("✅ User signed out successfully");
//     } catch (e) {
//       debugPrint("❌ Error signing out: $e");
//       rethrow;
//     }
//   }
// }

import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔧 Keep a single GoogleSignIn instance to better manage state
  GoogleSignIn? _googleSignIn;

  Stream<User?> get userChanges => _auth.userChanges();

  /// 🔹 Sign in with Google - ULTIMATE FIX with Silent Sign-In Bypass
  Future<User?> signInWithGoogle() async {
    try {
      // 🔧 CRITICAL FIX: Dispose old instance and create completely fresh one
      _googleSignIn = null;

      await Future.delayed(const Duration(milliseconds: 300));

      // 🔧 KEY FIX: Add clientId to force fresh authentication flow
      // This bypasses the silent sign-in that uses cached tokens
      _googleSignIn = GoogleSignIn(
        scopes: ['email'],
        forceCodeForRefreshToken: true,
        // This forces the account picker to show every time
        signInOption: SignInOption.standard,
      );

      debugPrint("🔄 Created fresh GoogleSignIn instance");

      // Clear Firebase session
      await _auth.signOut().catchError((_) {});
      debugPrint("✅ Cleared Firebase session");

      // Full Google cleanup
      try {
        if (await _googleSignIn!.isSignedIn()) {
          await _googleSignIn!.signOut();
          debugPrint("✅ Signed out from Google");
        }
      } catch (e) {
        debugPrint("⚠️ Sign out: $e");
      }

      try {
        await _googleSignIn!.disconnect();
        debugPrint("✅ Disconnected from Google");
      } catch (e) {
        debugPrint("⚠️ Disconnect: $e");
      }

      // Wait for cache clear
      await Future.delayed(const Duration(seconds: 1));
      debugPrint("🔄 Starting Google Sign-In with account picker...");

      // 🔧 KEY FIX: Use signIn() which shows account picker
      // This forces user interaction and bypasses silent authentication
      final googleUser = await _googleSignIn!.signIn();

      if (googleUser == null) {
        debugPrint("⚠️ User cancelled Google Sign-In");
        return null;
      }

      debugPrint("✅ User selected: ${googleUser.email}");

      // Clear any cached auth before getting tokens
      await googleUser.clearAuthCache();
      await Future.delayed(const Duration(milliseconds: 300));

      // 🔧 CRITICAL: Get fresh authentication
      // The key here is that after showing the account picker,
      // Google should provide fresh tokens
      GoogleSignInAuthentication? googleAuth;

      try {
        googleAuth = await googleUser.authentication;

        if (googleAuth.idToken == null || googleAuth.idToken!.isEmpty) {
          throw Exception("Empty token received");
        }

        debugPrint("✅ Got fresh token (length: ${googleAuth.idToken!.length})");

      } catch (e) {
        debugPrint("⚠️ Token fetch failed: $e");

        // One retry with longer delay
        debugPrint("🔄 Retrying token fetch...");
        await googleUser.clearAuthCache();
        await Future.delayed(const Duration(seconds: 1));

        googleAuth = await googleUser.authentication;

        if (googleAuth.idToken == null) {
          throw FirebaseAuthException(
            code: 'missing-id-token',
            message: 'Failed to get valid token after retry',
          );
        }

        debugPrint("✅ Got token on retry (length: ${googleAuth.idToken!.length})");
      }

      // Sign in to Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      debugPrint("✅ Firebase sign-in successful: ${userCredential.user?.email}");

      return userCredential.user;

    } on FirebaseAuthException catch (e) {
      debugPrint("❌ Firebase Auth Error: ${e.code} - ${e.message}");

      // If account exists with different credential, provide helpful message
      if (e.code == 'account-exists-with-different-credential') {
        throw FirebaseAuthException(
          code: e.code,
          message: 'An account already exists with this email using a different sign-in method.',
        );
      }

      rethrow;
    } on PlatformException catch (e) {
      debugPrint("❌ Platform Exception:");
      debugPrint("   Code: ${e.code}");
      debugPrint("   Message: ${e.message}");
      debugPrint("   Details: ${e.details}");

      // Handle the persistent expired token issue
      if (e.code == 'sign_in_failed' &&
          (e.message?.contains('expired') == true ||
              e.details?.toString().contains('expired') == true)) {

        debugPrint("❌ PERSISTENT EXPIRED TOKEN DETECTED");
        debugPrint("💡 This requires manual intervention");

        // Throw a user-friendly error
        throw PlatformException(
          code: 'persistent_expired_token',
          message: 'Google sign-in cache is corrupted. Please:\n\n'
              '1. Open iPad Settings\n'
              '2. Find and tap "Google"\n'
              '3. Tap "Sign out"\n'
              '4. Return here and try again\n\n'
              'This will clear the expired cached credentials.',
          details: 'Requires manual Settings intervention',
        );
      }

      rethrow;
    } catch (e) {
      debugPrint("❌ Google Sign-In failed: $e");
      rethrow;
    }
  }

  /// 🔹 Alternative: Silent Sign-In (for returning users)
  /// This method attempts silent sign-in first, falls back to interactive
  Future<User?> signInWithGoogleSilent() async {
    try {
      _googleSignIn ??= GoogleSignIn(
        scopes: ['email'],
        forceCodeForRefreshToken: true,
      );

      // Try silent sign-in first
      debugPrint("🔄 Attempting silent sign-in...");
      GoogleSignInAccount? googleUser = await _googleSignIn!.signInSilently();

      if (googleUser == null) {
        debugPrint("⚠️ Silent sign-in failed, showing account picker...");
        // Fall back to interactive sign-in
        return await signInWithGoogle();
      }

      debugPrint("✅ Silent sign-in successful: ${googleUser.email}");

      final googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null) {
        debugPrint("⚠️ No token from silent sign-in, trying interactive...");
        return await signInWithGoogle();
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;

    } catch (e) {
      debugPrint("⚠️ Silent sign-in failed: $e");
      // Fall back to interactive sign-in
      return await signInWithGoogle();
    }
  }

  /// 🔹 Sign in with Apple
  Future<User?> signInWithApple() async {
    if (!Platform.isIOS && !Platform.isMacOS) {
      throw UnsupportedError('Apple Sign-In works only on iOS/macOS.');
    }

    try {
      await _auth.signOut().catchError((_) {});

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

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
      debugPrint("✅ Apple sign-in successful: ${userCredential.user?.email}");

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ Firebase Auth Error during Apple Sign-In:");
      debugPrint("   Code: ${e.code}");
      debugPrint("   Message: ${e.message}");
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

  /// 🔹 Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();

      if (_googleSignIn != null) {
        try {
          if (await _googleSignIn!.isSignedIn()) {
            await _googleSignIn!.signOut();
          }
          await _googleSignIn!.disconnect();
        } catch (e) {
          debugPrint("⚠️ Error during Google sign out: $e");
        }
        _googleSignIn = null;
      }

      debugPrint("✅ User signed out successfully");
    } catch (e) {
      debugPrint("❌ Error signing out: $e");
      rethrow;
    }
  }
}