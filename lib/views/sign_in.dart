// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/auth_provider.dart';
//
// class SignInScreen extends StatelessWidget {
//   const SignInScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//
//     return Scaffold(
//       backgroundColor: theme.scaffoldBackgroundColor,
//       body: SafeArea(
//         child: Center(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 24),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 SizedBox(
//                   height: 180,
//                   child: Image.asset(
//                     'assets/images/coding_logo.png',
//                     fit: BoxFit.contain,
//                   ),
//                 ),
//
//                 const SizedBox(height: 40),
//
//                 Text(
//                   "Welcome to Coding Tutor",
//                   style: theme.textTheme.headlineSmall?.copyWith(
//                     color: theme.colorScheme.onSurface,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 26,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   "Start your coding journey — one lesson at a time.",
//                   style: theme.textTheme.bodyMedium?.copyWith(
//                     color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
//                     fontSize: 15,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//
//                 const SizedBox(height: 24),
//
//                 _LoginButton(
//                   icon: 'assets/images/google.png',
//                   text: 'Continue with Google',
//                   backgroundColor: theme.colorScheme.primary,
//                   textColor: theme.colorScheme.onPrimary,
//                   onTap: () async {
//                     final messenger = ScaffoldMessenger.of(context);
//                     try {
//                       await context.read<AuthProvider>().signInWithGoogle();
//                     } catch (e) {
//                       messenger.showSnackBar(
//                         SnackBar(
//                           content: Text('Google sign-in failed: ${e.toString()}'),
//                           behavior: SnackBarBehavior.floating,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           backgroundColor: Colors.red,
//                         ),
//                       );
//                     }
//                   },
//                 ),
//
//                 const SizedBox(height: 12),
//
//                 _LoginButton(
//                   icon: 'assets/images/img.png',
//                   text: 'Continue with Apple',
//                   backgroundColor: theme.colorScheme.surface,
//                   textColor: theme.colorScheme.onSurface,
//                   onTap: () async {
//                     final messenger = ScaffoldMessenger.of(context);
//
//                     await context.read<AuthProvider>().signInWithApple();
//
//                     }
//
//
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class _LoginButton extends StatelessWidget {
//   final String icon;
//   final String text;
//   final Color backgroundColor;
//   final Color textColor;
//   final VoidCallback onTap;
//
//   const _LoginButton({
//     required this.icon,
//     required this.text,
//     required this.backgroundColor,
//     required this.textColor,
//     required this.onTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return ElevatedButton(
//       onPressed: onTap,
//       style: ElevatedButton.styleFrom(
//         backgroundColor: backgroundColor,
//         foregroundColor: textColor,
//         minimumSize: const Size(double.infinity, 56),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(14),
//         ),
//         elevation: 0,
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Image.asset(icon, height: 22),
//           const SizedBox(width: 12),
//           Text(
//             text,
//             style: TextStyle(
//               color: textColor,
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  // 🔧 FIX: Prevent double-tap on iPad
  bool _isGoogleSignInProgress = false;
  bool _isAppleSignInProgress = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 180,
                  child: Image.asset(
                    'assets/images/coding_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 40),

                Text(
                  "Welcome to Coding Tutor",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Start your coding journey — one lesson at a time.",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                _LoginButton(
                  icon: 'assets/images/google.png',
                  text: 'Continue with Google',
                  backgroundColor: theme.colorScheme.primary,
                  textColor: theme.colorScheme.onPrimary,
                  isLoading: _isGoogleSignInProgress,
                  onTap: _isGoogleSignInProgress ? null : _handleGoogleSignIn,
                ),

                const SizedBox(height: 12),

                _LoginButton(
                  icon: 'assets/images/img.png',
                  text: 'Continue with Apple',
                  backgroundColor: theme.colorScheme.surface,
                  textColor: theme.colorScheme.onSurface,
                  isLoading: _isAppleSignInProgress,
                  onTap: _isAppleSignInProgress ? null : _handleAppleSignIn,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔧 FIX: Prevent double-tap for Google Sign-In
  Future<void> _handleGoogleSignIn() async {
    if (_isGoogleSignInProgress) {
      debugPrint('⚠️ Google sign-in already in progress, ignoring tap');
      return;
    }

    setState(() => _isGoogleSignInProgress = true);

    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<AuthProvider>().signInWithGoogle();
    } on PlatformException catch (e) {
      String message = 'Sign-in failed';
      Duration duration = const Duration(seconds: 4);

      if (e.message?.contains('expired') == true ||
          e.details?.toString().contains('expired') == true) {
        message = 'Cached token expired. Please go to iPad Settings → Google and sign out, then try again.';
        duration = const Duration(seconds: 8);
      } else if (e.code == 'network_error') {
        message = 'Network error. Check your connection.';
      } else if (e.code == 'sign_in_canceled') {
        message = 'Sign-in was cancelled';
      } else if (e.code == 'sign_in_failed') {
        message = 'Sign-in failed. Try signing out of Google in iPad Settings first.';
        duration = const Duration(seconds: 6);
      }

      // messenger.showSnackBar(
      //   SnackBar(
      //     content: Text(message),
      //     duration: duration,
      //     behavior: SnackBarBehavior.floating,
      //     shape: RoundedRectangleBorder(
      //       borderRadius: BorderRadius.circular(12),
      //     ),
      //     backgroundColor: Colors.red,
      //     action: e.message?.contains('expired') == true
      //         ? SnackBarAction(
      //       label: 'How to fix',
      //       textColor: Colors.white,
      //       onPressed: () {
      //         _showFixInstructions();
      //       },
      //     )
      //         : null,
      //   ),
      // );
    } catch (e) {
      // messenger.showSnackBar(
      //   SnackBar(
      //     content: Text('Google sign-in failed: ${e.toString()}'),
      //     behavior: SnackBarBehavior.floating,
      //     shape: RoundedRectangleBorder(
      //       borderRadius: BorderRadius.circular(12),
      //     ),
      //     backgroundColor: Colors.red,
      //   ),
      // );
    } finally {
      // ✅ Reset state after a delay to prevent rapid re-taps
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() => _isGoogleSignInProgress = false);
      }
    }
  }

  void _showFixInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fix Expired Token'),
        content: const Text(
          'To fix this issue:\n\n'
              '1. Open iPad Settings\n'
              '2. Scroll down to find "Google"\n'
              '3. Tap "Sign out"\n'
              '4. Return to this app and try again\n\n'
              'This will clear the expired cached token.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  // 🔧 FIX: Prevent double-tap for Apple Sign-In
  Future<void> _handleAppleSignIn() async {
    if (_isAppleSignInProgress) {
      debugPrint('⚠️ Apple sign-in already in progress, ignoring tap');
      return;
    }

    setState(() => _isAppleSignInProgress = true);

    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<AuthProvider>().signInWithApple();
    } catch (e) {
      // messenger.showSnackBar(
      //   SnackBar(
      //     content: Text('Apple sign-in failed: ${e.toString()}'),
      //     behavior: SnackBarBehavior.floating,
      //     shape: RoundedRectangleBorder(
      //       borderRadius: BorderRadius.circular(12),
      //     ),
      //     backgroundColor: Colors.red,
      //   ),
      // );
    } finally {
      // ✅ Reset state after a delay
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() => _isAppleSignInProgress = false);
      }
    }
  }
}

class _LoginButton extends StatelessWidget {
  final String icon;
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onTap;
  final bool isLoading;

  const _LoginButton({
    required this.icon,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 0,
        disabledBackgroundColor: backgroundColor.withValues(alpha: 0.6),
        disabledForegroundColor: textColor.withValues(alpha: 0.6),
      ),
      child: isLoading
          ? SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      )
          : Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(icon, height: 22),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}