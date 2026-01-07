/*
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:in_app_purchase/in_app_purchase.dart';
import '../ads/ads_provider.dart'; // ✅ Tumhara actual ads provider
import '../core/App_theme.dart';
import 'credit_manager.dart';
import 'i_app_manager.dart';

class CreditsPurchaseScreen extends StatefulWidget {
  const CreditsPurchaseScreen({Key? key}) : super(key: key);

  @override
  State<CreditsPurchaseScreen> createState() => _CreditsPurchaseScreenState();
}

class _CreditsPurchaseScreenState extends State<CreditsPurchaseScreen> {
  final IAPManager _iapManager = IAPManager();
  bool _isLoading = true;
  bool _isPurchasing = false;
  String? _errorMessage;
  String? _currentPurchasingProductId;

  @override
  void initState() {
    super.initState();
    _initIAP();

    // ✅ FIXED: Tumhara actual AdType.lensAd use kiya
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        final adProvider = context.read<AdProvider>();
        // Lens ad preload karo for watch ad feature
        adProvider.preloadAd(AdType.lensAd);
        debugPrint('[PurchaseScreen] ✅ Lens Ad preload requested');
      } catch (e) {
        debugPrint('[PurchaseScreen] ⚠️ Ad preload error: $e');
      }
    });
  }

  Future<void> _initIAP() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final creditManager = context.read<CreditManager>();
      await _iapManager.init(creditManager);

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("❌ [Purchase Screen] Init error: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Failed to load purchases. Please try again.";
        });
      }
    }
  }

  // ✅ NEW: Watch ad function added
  Future<void> _watchAdForCredits() async {
    final colorScheme = Theme.of(context).colorScheme;
    final onPrimary = colorScheme.onPrimary;
    final primaryColor = colorScheme.primary;
    final errorColor = colorScheme.error;

    try {
      debugPrint('🎬 [PurchaseScreen] Starting watch ad for credits');

      final adProvider = context.read<AdProvider>();
      final creditManager = context.read<CreditManager>();

      // Check if ad is ready
      if (!adProvider.isLensAd) {
        debugPrint('⚠️ [PurchaseScreen] Lens ad not ready');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.info_outline, color: onPrimary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ad is loading. Please wait a moment...',
                      style: TextStyle(
                        fontSize: AppTheme.responsiveFont(
                          context,
                          phone: 14,
                          tablet: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: primaryColor,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }

        // Try to load ad again
        adProvider.preloadAd(AdType.lensAd);
        return;
      }

      // Check timing restrictions
      if (!adProvider.canShowRewarded()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.timer_outlined, color: onPrimary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Please wait 2 minutes between ads',
                      style: TextStyle(
                        fontSize: AppTheme.responsiveFont(
                          context,
                          phone: 14,
                          tablet: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: primaryColor,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        return;
      }

      final creditsBefore = creditManager.credits;

      // Show rewarded ad
      adProvider.showRewardedAd(
        AdType.lensAd,
        onRewarded: () async {
          debugPrint('🎁 [PurchaseScreen] Ad reward earned');

          // Add credits
          final success = await creditManager.rewardForAd();

          if (success && mounted) {
            final creditsAfter = creditManager.credits;
            final creditsEarned = creditsAfter - creditsBefore;

            debugPrint('✅ [PurchaseScreen] Credits added: $creditsEarned');

            // Show success dialog
            _showAdRewardDialog();
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Failed to add credits. Please try again.'),
                backgroundColor: errorColor,
              ),
            );
          }
        },
      );

    } catch (e) {
      debugPrint('❌ [PurchaseScreen] Watch ad error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: errorColor,
          ),
        );
      }
    }
  }

  Future<void> _handlePurchase(ProductDetails product) async {
    if (_isPurchasing) {
      debugPrint("⚠️ [Purchase Screen] Purchase already in progress");
      return;
    }

    setState(() {
      _isPurchasing = true;
      _currentPurchasingProductId = product.id;
      _errorMessage = null;
    });

    try {
      debugPrint("🛒 [Purchase Screen] Initiating purchase: ${product.id}");

      final creditsBefore = context.read<CreditManager>().credits;
      final success = await _iapManager.purchaseProduct(product);

      if (!success && mounted) {
        setState(() {
          _isPurchasing = false;
          _currentPurchasingProductId = null;
        });
      } else {
        debugPrint("✅ [Purchase Screen] Purchase initiated successfully");

        // Wait for purchase to complete and credits to update
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          final creditsAfter = context.read<CreditManager>().credits;
          final creditsAdded = creditsAfter - creditsBefore;

          setState(() {
            _isPurchasing = false;
            _currentPurchasingProductId = null;
          });

          if (creditsAdded > 0) {
            _showPurchaseSuccessDialog(creditsAdded);
          }
        }
      }
    } catch (e) {
      debugPrint("❌ [Purchase Screen] Purchase error: ${e.toString()}");

      if (mounted) {
        setState(() {
          _isPurchasing = false;
          _currentPurchasingProductId = null;
        });
      }
    }
  }

  void _showPurchaseSuccessDialog(int creditsAdded) {
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;
    final primaryColor = colorScheme.primary;
    final surface = colorScheme.surface;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(
              AppTheme.responsiveSize(context, phone: 24, tablet: 32),
            ),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Icon with Animation
                Container(
                  width: AppTheme.responsiveSize(
                    context,
                    phone: 80,
                    tablet: 110,
                  ),
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 80,
                    tablet: 110,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: primaryColor,
                    size: AppTheme.responsiveSize(
                      context,
                      phone: 50,
                      tablet: 64,
                    ),
                  ),
                ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 24,
                    tablet: 32,
                  ),
                ),

                // Success Title
                  Text(
                    'Purchase Successful!',
                    style: TextStyle(
                      fontSize: AppTheme.responsiveFont(
                        context,
                        phone: 24,
                        tablet: 28,
                      ),
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 12,
                    tablet: 16,
                  ),
                ),

                // Credits Added Info
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.responsiveSize(
                      context,
                      phone: 20,
                      tablet: 28,
                    ),
                    vertical: AppTheme.responsiveSize(
                      context,
                      phone: 12,
                      tablet: 16,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(
                      AppTheme.responsiveSize(context, phone: 12, tablet: 16),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_circle,
                        color: AppTheme.primaryColor,
                        size: AppTheme.responsiveSize(
                          context,
                          phone: 24,
                          tablet: 30,
                        ),
                      ),
                      SizedBox(
                        width: AppTheme.responsiveSize(
                          context,
                          phone: 8,
                          tablet: 12,
                        ),
                      ),
                      Text(
                        '$creditsAdded Credits',
                        style: TextStyle(
                          fontSize: AppTheme.responsiveFont(
                            context,
                            phone: 20,
                            tablet: 26,
                          ),
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 16,
                    tablet: 22,
                  ),
                ),

                // Current Balance
                  Text(
                    'New Balance: ${context.read<CreditManager>().credits} Credits',
                    style: TextStyle(
                      fontSize: AppTheme.responsiveFont(
                        context,
                        phone: 16,
                        tablet: 18,
                      ),
                      color: onSurface.withOpacity(0.75),
                    ),
                  ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 24,
                    tablet: 32,
                  ),
                ),

                // Confirmation Message
                  Text(
                    'Your credits have been added to your account successfully. You can now use them for AI coding features.',
                    style: TextStyle(
                      fontSize: AppTheme.responsiveFont(
                        context,
                        phone: 14,
                        tablet: 16,
                      ),
                      color: onSurface.withOpacity(0.75),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 24,
                    tablet: 32,
                  ),
                ),

                // OK Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: EdgeInsets.symmetric(
                        vertical: AppTheme.responsiveSize(
                          context,
                          phone: 16,
                          tablet: 20,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.responsiveSize(
                            context,
                            phone: 12,
                            tablet: 16,
                          ),
                        ),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Got it!',
                      style: TextStyle(
                        fontSize: AppTheme.responsiveFont(
                          context,
                          phone: 16,
                          tablet: 18,
                        ),
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleRestore() async {
    if (_isLoading || _isPurchasing) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final onPrimary = colorScheme.onPrimary;
    final errorColor = colorScheme.error;

    try {
      debugPrint("🔄 [Purchase Screen] Restoring purchases...");

      final creditManager = context.read<CreditManager>();

      // Call restore with proper result handling
      final result = await _iapManager.restorePurchases(creditManager);

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (result.success) {
        if (result.creditsRestored > 0) {
          // Show success dialog with credits restored
          _showRestoreSuccessDialog(result.creditsRestored);
        } else {
          // No purchases to restore
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.info_outline, color: onPrimary),
                  SizedBox(
                    width: AppTheme.responsiveSize(
                      context,
                      phone: 12,
                      tablet: 16,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'No previous purchases found to restore.',
                      style: TextStyle(
                        fontSize: AppTheme.responsiveFont(
                          context,
                          phone: 14,
                          tablet: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: primaryColor,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppTheme.responsiveSize(context, phone: 10, tablet: 12),
                ),
              ),
            ),
          );
        }
      } else {
        // Restore had some issues
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.warning_outlined, color: onPrimary),
                  SizedBox(
                    width: AppTheme.responsiveSize(
                      context,
                      phone: 12,
                      tablet: 16,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Some purchases could not be restored. Please try again.',
                      style: TextStyle(
                        fontSize: AppTheme.responsiveFont(
                          context,
                          phone: 14,
                          tablet: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: primaryColor,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppTheme.responsiveSize(context, phone: 10, tablet: 12),
                ),
              ),
            ),
          );
      }
    } catch (e) {
      debugPrint("❌ [Purchase Screen] Restore error: $e");

      if (mounted) {
        setState(() => _isLoading = false);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.error_outline, color: onPrimary),
                    SizedBox(
                      width: AppTheme.responsiveSize(
                        context,
                        phone: 12,
                        tablet: 16,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Failed to restore purchases: ${e.toString()}',
                        style: TextStyle(
                          fontSize: AppTheme.responsiveFont(
                            context,
                            phone: 14,
                            tablet: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: errorColor,
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppTheme.responsiveSize(context, phone: 10, tablet: 12),
                  ),
                ),
              ),
            );
      }
    }
  }

  void _showRestoreSuccessDialog(int creditsRestored) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final onSurface = colorScheme.onSurface;
    final surface = colorScheme.surface;
    final mutedText = onSurface.withOpacity(0.75);
    final onPrimary = colorScheme.onPrimary;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(
              AppTheme.responsiveSize(context, phone: 24, tablet: 32),
            ),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Icon
                Container(
                  width: AppTheme.responsiveSize(
                    context,
                    phone: 80,
                    tablet: 110,
                  ),
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 80,
                    tablet: 110,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.restore,
                    color: primaryColor,
                    size: AppTheme.responsiveSize(
                      context,
                      phone: 50,
                      tablet: 64,
                    ),
                  ),
                ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 24,
                    tablet: 32,
                  ),
                ),

                // Title
                Text(
                  'Purchases Restored!',
                  style: TextStyle(
                    fontSize: AppTheme.responsiveFont(
                      context,
                      phone: 24,
                      tablet: 28,
                    ),
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 12,
                    tablet: 16,
                  ),
                ),

                // Credits Restored
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.responsiveSize(
                      context,
                      phone: 20,
                      tablet: 28,
                    ),
                    vertical: AppTheme.responsiveSize(
                      context,
                      phone: 12,
                      tablet: 16,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(
                      AppTheme.responsiveSize(context, phone: 12, tablet: 16),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_circle,
                        color: AppTheme.primaryColor,
                        size: AppTheme.responsiveSize(
                          context,
                          phone: 24,
                          tablet: 30,
                        ),
                      ),
                      SizedBox(
                        width: AppTheme.responsiveSize(
                          context,
                          phone: 8,
                          tablet: 12,
                        ),
                      ),
                      Text(
                        '$creditsRestored Credits',
                        style: TextStyle(
                          fontSize: AppTheme.responsiveFont(
                            context,
                            phone: 20,
                            tablet: 26,
                          ),
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 16,
                    tablet: 22,
                  ),
                ),

                // Current Balance
                Text(
                  'Current Balance: ${context.read<CreditManager>().credits} Credits',
                  style: TextStyle(
                    fontSize: AppTheme.responsiveFont(
                      context,
                      phone: 16,
                      tablet: 18,
                    ),
                    color: mutedText,
                  ),
                ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 24,
                    tablet: 32,
                  ),
                ),

                // Message
                Text(
                  'Your previous purchases have been successfully restored to your account.',
                  style: TextStyle(
                    fontSize: AppTheme.responsiveFont(
                      context,
                      phone: 14,
                      tablet: 16,
                    ),
                    color: mutedText,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 24,
                    tablet: 32,
                  ),
                ),

                // Done Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: EdgeInsets.symmetric(
                        vertical: AppTheme.responsiveSize(
                          context,
                          phone: 16,
                          tablet: 20,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.responsiveSize(
                            context,
                            phone: 12,
                            tablet: 16,
                          ),
                        ),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Done',
                      style: TextStyle(
                        fontSize: AppTheme.responsiveFont(
                          context,
                          phone: 16,
                          tablet: 18,
                        ),
                        fontWeight: FontWeight.w600,
                        color: onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAdRewardDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final onSurface = colorScheme.onSurface;
    final mutedText = onSurface.withOpacity(0.75);
    final onPrimary = colorScheme.onPrimary;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: AppTheme.responsiveSize(
                    context,
                    phone: 80,
                    tablet: 100,
                  ),
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 80,
                    tablet: 100,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_circle_filled,
                    color: primaryColor,
                    size: AppTheme.responsiveSize(
                      context,
                      phone: 50,
                      tablet: 60,
                    ),
                  ),
                ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 24,
                    tablet: 30,
                  ),
                ),
                Text(
                  'Credits Earned!',
                  style: TextStyle(
                    fontSize: AppTheme.responsiveFont(
                      context,
                      phone: 24,
                      tablet: 28,
                    ),
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                  ),
                ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 12,
                    tablet: 16,
                  ),
                ),
                Text(
                  '+${CreditManager.rewardedAdCredits} Credits',
                  style: TextStyle(
                    fontSize: AppTheme.responsiveFont(
                      context,
                      phone: 20,
                      tablet: 24,
                    ),
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 16,
                    tablet: 20,
                  ),
                ),
                Text(
                  'Thanks for watching! Your credits have been added.',
                  style: TextStyle(
                    fontSize: AppTheme.responsiveFont(
                      context,
                      phone: 14,
                      tablet: 16,
                    ),
                    color: mutedText,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 24,
                    tablet: 28,
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: EdgeInsets.symmetric(
                        vertical: AppTheme.responsiveSize(
                          context,
                          phone: 16,
                          tablet: 20,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.responsiveSize(
                            context,
                            phone: 12,
                            tablet: 16,
                          ),
                        ),
                      ),
                    ),
                    child: Text(
                      'Awesome!',
                      style: TextStyle(
                        fontSize: AppTheme.responsiveFont(
                          context,
                          phone: 16,
                          tablet: 18,
                        ),
                        fontWeight: FontWeight.w600,
                        color: onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _launchExternalLink(String url) async {
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open link. Please try again later.')),
        );
      }
      return;
    }

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final creditManager = context.watch<CreditManager>();
    final adProvider = context.watch<AdProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mutedTextColor = colorScheme.onSurface.withOpacity(0.7);
    final cardBackgroundColor = colorScheme.surfaceVariant;
    final gradientStart = colorScheme.primaryContainer;
    final gradientEnd = colorScheme.secondaryContainer != colorScheme.primaryContainer
        ? colorScheme.secondaryContainer
        : colorScheme.secondary;
    final onPrimaryColor = colorScheme.onPrimary;
    final onPrimarySubtle = colorScheme.onPrimary.withOpacity(0.85);
    final shadowColor = theme.shadowColor.withOpacity(0.18);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: AppTheme.appBarHeight(context),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: colorScheme.onBackground,
            size: AppTheme.responsiveSize(context, phone: 24, tablet: 28),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Get Credits',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onBackground,
            fontWeight: FontWeight.bold,
            fontSize: AppTheme.responsiveFont(context, phone: 20, tablet: 24),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: colorScheme.onBackground,
              size: AppTheme.responsiveSize(context, phone: 22, tablet: 26),
            ),
            onPressed: _isLoading ? null : _handleRestore,
            tooltip: 'Restore Purchases',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Loading products...',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Credits Display
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: AppTheme.responsiveSize(
                  context,
                  phone: 40,
                  tablet: 56,
                ),
                horizontal: AppTheme.responsiveSize(
                  context,
                  phone: 24,
                  tablet: 32,
                ),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    gradientStart,
                    gradientEnd,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Your Credits',
                    style: TextStyle(
                      color: onPrimarySubtle,
                      fontSize: AppTheme.responsiveFont(
                        context,
                        phone: 16,
                        tablet: 20,
                      ),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(
                    height: AppTheme.responsiveSize(
                      context,
                      phone: 12,
                      tablet: 18,
                    ),
                  ),
                  Text(
                    '${creditManager.credits}',
                    style: TextStyle(
                      color: onPrimaryColor,
                      fontSize: AppTheme.responsiveFont(
                        context,
                        phone: 64,
                        tablet: 80,
                      ),
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                  SizedBox(
                    height: AppTheme.responsiveSize(
                      context,
                      phone: 8,
                      tablet: 12,
                    ),
                  ),
                  Text(
                    'Use credits for AI coding features',
                    style: TextStyle(
                      color: onPrimarySubtle,
                      fontSize: AppTheme.responsiveFont(
                        context,
                        phone: 14,
                        tablet: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Error Message (if any)
            if (_errorMessage != null)
              Container(
                margin: EdgeInsets.all(
                  AppTheme.responsiveSize(context, phone: 16, tablet: 22),
                ),
                padding: EdgeInsets.all(
                  AppTheme.responsiveSize(context, phone: 16, tablet: 20),
                ),
                decoration: BoxDecoration(
                  color: cardBackgroundColor,
                  borderRadius: BorderRadius.circular(
                    AppTheme.responsiveSize(
                      context,
                      phone: 12,
                      tablet: 16,
                    ),
                  ),
                  border: Border.all(color: colorScheme.primary),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: colorScheme.error,
                      size: AppTheme.responsiveSize(
                        context,
                        phone: 22,
                        tablet: 26,
                      ),
                    ),
                    SizedBox(
                      width: AppTheme.responsiveSize(
                        context,
                        phone: 12,
                        tablet: 16,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                          fontSize: AppTheme.responsiveFont(
                            context,
                            phone: 14,
                            tablet: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ✅ FIXED: Watch Ad Section with proper state checks
            Container(
              margin: EdgeInsets.symmetric(
                horizontal: AppTheme.responsiveSize(
                  context,
                  phone: 16,
                  tablet: 22,
                ),
                vertical: AppTheme.responsiveSize(
                  context,
                  phone: 8,
                  tablet: 12,
                ),
              ),
              decoration: BoxDecoration(
                color: cardBackgroundColor,
                borderRadius: BorderRadius.circular(
                  AppTheme.responsiveSize(context, phone: 16, tablet: 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: AppTheme.responsiveSize(
                      context,
                      phone: 10,
                      tablet: 14,
                    ),
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: adProvider.isLensAd ? _watchAdForCredits : null,
                  borderRadius: BorderRadius.circular(
                    AppTheme.responsiveSize(
                      context,
                      phone: 16,
                      tablet: 20,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(
                      AppTheme.responsiveSize(
                        context,
                        phone: 16,
                        tablet: 20,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(
                            AppTheme.responsiveSize(
                              context,
                              phone: 12,
                              tablet: 16,
                            ),
                          ),
                          decoration: BoxDecoration(
                            color: gradientEnd,
                            borderRadius: BorderRadius.circular(
                              AppTheme.responsiveSize(
                                context,
                                phone: 12,
                                tablet: 16,
                              ),
                            ),
                          ),
                          child: Icon(
                            Icons.play_circle_filled,
                            color: colorScheme.primary,
                            size: AppTheme.responsiveSize(
                              context,
                              phone: 32,
                              tablet: 40,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: AppTheme.responsiveSize(
                            context,
                            phone: 16,
                            tablet: 20,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Rewarded ad',
                                    style: TextStyle(
                                      fontSize: AppTheme.responsiveFont(
                                        context,
                                        phone: 15,
                                        tablet: 18,
                                      ),
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: AppTheme.responsiveSize(
                                        context,
                                        phone: 8,
                                        tablet: 10,
                                      ),
                                      vertical: AppTheme.responsiveSize(
                                        context,
                                        phone: 2,
                                        tablet: 4,
                                      ),
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.responsiveSize(
                                          context,
                                          phone: 8,
                                          tablet: 10,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      '+${CreditManager.rewardedAdCredits}',
                                      style: TextStyle(
                                        color: colorScheme.onPrimary,
                                        fontSize: AppTheme.responsiveFont(
                                          context,
                                          phone: 13,
                                          tablet: 16,
                                        ),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: AppTheme.responsiveSize(
                                  context,
                                  phone: 4,
                                  tablet: 6,
                                ),
                              ),
                              Text(
                                adProvider.isLensAd
                                    ? 'Tap to watch the Lens rewarded ad'
                                    : 'Loading Lens rewarded ad...',
                                style: TextStyle(
                                  fontSize: AppTheme.responsiveFont(
                                    context,
                                    phone: 13,
                                    tablet: 16,
                                  ),
                                  color: mutedTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          adProvider.isLensAd
                              ? Icons.chevron_right
                              : Icons.hourglass_empty,
                          color: mutedTextColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Rest of the UI (Products, FAQs, etc.)
            _buildProductsSection(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsSection() {
    final colorScheme = Theme.of(context).colorScheme;
    final mutedTextColor = colorScheme.onSurface.withOpacity(0.7);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Buy Credits Section Header
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppTheme.responsiveSize(context, phone: 16, tablet: 22),
            AppTheme.responsiveSize(context, phone: 24, tablet: 32),
            AppTheme.responsiveSize(context, phone: 16, tablet: 22),
            AppTheme.responsiveSize(context, phone: 8, tablet: 12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buy Credits',
                style: TextStyle(
                  fontSize: AppTheme.responsiveFont(
                    context,
                    phone: 22,
                    tablet: 26,
                  ),
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              SizedBox(
                height: AppTheme.responsiveSize(
                  context,
                  phone: 4,
                  tablet: 6,
                ),
              ),
              Text(
                'Credits power AI coding features and advanced tools.',
                style: TextStyle(
                  fontSize: AppTheme.responsiveFont(
                    context,
                    phone: 14,
                    tablet: 18,
                  ),
                  color: mutedTextColor,
                ),
              ),
            ],
          ),
        ),

        // Credit Packages Grid
        if (!_iapManager.isAvailable)
          Container(
            margin: EdgeInsets.all(
              AppTheme.responsiveSize(context, phone: 16, tablet: 22),
            ),
            padding: EdgeInsets.all(
              AppTheme.responsiveSize(context, phone: 16, tablet: 20),
            ),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer.withOpacity(0.9),
              borderRadius: BorderRadius.circular(
                AppTheme.responsiveSize(
                  context,
                  phone: 12,
                  tablet: 16,
                ),
              ),
              border: Border.all(color: colorScheme.primary),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: colorScheme.primary,
                ),
                SizedBox(
                  width: AppTheme.responsiveSize(
                    context,
                    phone: 12,
                    tablet: 16,
                  ),
                ),
                Expanded(
                  child: Text(
                    'In-App Purchases are not available. Please check your settings.',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                      fontSize: AppTheme.responsiveFont(
                        context,
                        phone: 14,
                        tablet: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (_iapManager.products.isEmpty)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading credit packages...',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.responsiveSize(
                context,
                phone: 16,
                tablet: 22,
              ),
            ),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppTheme.responsiveSize(
                  context,
                  phone: 12,
                  tablet: 16,
                ),
                mainAxisSpacing: AppTheme.responsiveSize(
                  context,
                  phone: 12,
                  tablet: 16,
                ),
                childAspectRatio: 0.85,
              ),
              itemCount: _iapManager.products.length,
              itemBuilder: (context, index) {
                final product = _iapManager.products[index];
                final credits =
                    IAPManager.productCredits[product.id] ?? 0;
                final isThisProductPurchasing =
                    _isPurchasing &&
                        _currentPurchasingProductId == product.id;

                return NatureCreditCard(
                  price: product.price,
                  credits: credits,
                  isPurchasing: isThisProductPurchasing,
                  onTap: () => _handlePurchase(product),
                );
              },
            ),
          ),

        const SizedBox(height: 16),

        // Restore Purchases Button
        Center(
          child: TextButton.icon(
            onPressed: _isLoading ? null : _handleRestore,
            icon: Icon(
              Icons.restore,
              color: colorScheme.primary,
            ),
            label: Text(
              'Restore Purchases',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),
        ),

        // Links
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => _launchExternalLink(
                  'https://vectorlabzlimited.com/privacy-policy/',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                ),
                child: Text(
                  'Privacy Policy',
                style: TextStyle(
                  fontSize: AppTheme.responsiveFont(
                    context,
                    phone: 14,
                    tablet: 16,
                  ),
                ),
                ),
              ),
              Text(
                ' | ',
                style: TextStyle(
                  color: mutedTextColor,
                  fontSize: AppTheme.responsiveFont(
                    context,
                    phone: 14,
                    tablet: 16,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _launchExternalLink(
                  'https://vectorlabzlimited.com/terms-of-use/',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                ),
                child: Text(
                  'Terms of Use',
                  style: TextStyle(
                    fontSize: AppTheme.responsiveFont(
                      context,
                      phone: 14,
                      tablet: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Purchase Info
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.responsiveSize(context, phone: 24, tablet: 32),
          ).copyWith(bottom: AppTheme.responsiveSize(context, phone: 8, tablet: 10)),
          child: Container(
            padding: EdgeInsets.all(
              AppTheme.responsiveSize(context, phone: 12, tablet: 16),
            ),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(
                AppTheme.responsiveSize(context, phone: 12, tablet: 16),
              ),
              border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Purchase Information',
                  style: TextStyle(
                    fontSize: AppTheme.responsiveFont(context, phone: 12, tablet: 14),
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                SizedBox(
                  height: AppTheme.responsiveSize(context, phone: 4, tablet: 6),
                ),
                Text(
                  'Credits are granted for lifetime until consumed and cannot be transferred.',
                  style: TextStyle(
                    fontSize: AppTheme.responsiveFont(context, phone: 12, tablet: 14),
                    color: mutedTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),

        // FAQs
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(
            AppTheme.responsiveSize(context, phone: 24, tablet: 32),
          ),
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(
              AppTheme.responsiveSize(context, phone: 18, tablet: 22),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FAQs',
                style: TextStyle(
                  fontSize: AppTheme.responsiveFont(
                    context,
                    phone: 20,
                    tablet: 24,
                  ),
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimary,
                ),
              ),
              SizedBox(
                height: AppTheme.responsiveSize(
                  context,
                  phone: 16,
                  tablet: 20,
                ),
              ),
              _buildFAQItem(
                'How can I spend credits?',
                'Use them for AI coding features and advanced tools.',
              ),
              _buildFAQItem(
                'Do credits expire?',
                'Credits never expire — they stay in your account until you use them.',
              ),
              _buildFAQItem(
                'How many credits do I start with?',
                'Fresh installs get 30 complimentary credits to explore features.',
              ),
              _buildFAQItem(
                'How do I add more credits?',
                'You can watch rewarded ads to earn bonus credits or buy a credit pack.',
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer, {bool isLast = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final onPrimary = colorScheme.onPrimary;
    final onPrimaryMuted = onPrimary.withOpacity(0.85);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: AppTheme.responsiveFont(context, phone: 15, tablet: 18),
              color: onPrimary,
            ),
          ),
          SizedBox(
            height: AppTheme.responsiveSize(context, phone: 4, tablet: 6),
          ),
          Text(
            answer,
            style: TextStyle(
              color: onPrimaryMuted,
              fontSize: AppTheme.responsiveFont(context, phone: 14, tablet: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// NatureCreditCard widget remains the same
class NatureCreditCard extends StatelessWidget {
  final String price;
  final int credits;
  final bool isPurchasing;
  final VoidCallback onTap;

  const NatureCreditCard({
    Key? key,
    required this.price,
    required this.credits,
    required this.isPurchasing,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cardBackground = colorScheme.surfaceVariant;
    final borderColor = colorScheme.outline;
    final mutedText = colorScheme.onSurface.withOpacity(0.65);
    final accentColor = colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isPurchasing ? null : onTap,
        borderRadius: BorderRadius.circular(
          AppTheme.responsiveSize(context, phone: 16, tablet: 20),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(
              AppTheme.responsiveSize(context, phone: 16, tablet: 20),
            ),
            border: Border.all(
              color: borderColor,
              width: AppTheme.responsiveSize(context, phone: 2, tablet: 3),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(
              AppTheme.responsiveSize(context, phone: 12, tablet: 16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(
                    AppTheme.responsiveSize(context, phone: 12, tablet: 16),
                  ),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(
                      AppTheme.responsiveSize(context, phone: 12, tablet: 16),
                    ),
                  ),
                  child: Icon(
                    Icons.credit_card_rounded,
                    color: accentColor,
                    size: AppTheme.responsiveSize(
                      context,
                      phone: 28,
                      tablet: 34,
                    ),
                  ),
                ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 8,
                    tablet: 12,
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '$credits Credits',
                      style: TextStyle(
                        fontSize: AppTheme.responsiveFont(
                          context,
                          phone: 16,
                          tablet: 20,
                        ),
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(
                      height: AppTheme.responsiveSize(
                        context,
                        phone: 4,
                        tablet: 6,
                      ),
                    ),
                    Text(
                      'For AI features',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppTheme.responsiveFont(
                          context,
                          phone: 11,
                          tablet: 14,
                        ),
                        color: mutedText,
                      ),
                    ),
                  ],
                ),
                if (isPurchasing)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: accentColor,
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      vertical: AppTheme.responsiveSize(
                        context,
                        phone: 8,
                        tablet: 12,
                      ),
                    ),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(
                        AppTheme.responsiveSize(context, phone: 12, tablet: 16),
                      ),
                    ),
                    child: Text(
                      price,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: AppTheme.responsiveFont(
                          context,
                          phone: 14,
                          tablet: 18,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
*/


//////////////////////////

/*
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:in_app_purchase/in_app_purchase.dart';
import '../ads/ads_provider.dart';
import '../core/App_theme.dart';
import 'credit_manager.dart';
import 'i_app_manager.dart';

class CreditsPurchaseScreen extends StatefulWidget {
  const CreditsPurchaseScreen({Key? key}) : super(key: key);

  @override
  State<CreditsPurchaseScreen> createState() => _CreditsPurchaseScreenState();
}

class _CreditsPurchaseScreenState extends State<CreditsPurchaseScreen> {
  final IAPManager _iapManager = IAPManager();
  bool _isLoading = true;
  bool _isPurchasing = false;
  String? _errorMessage;
  String? _currentPurchasingProductId;

  @override
  void initState() {
    super.initState();
    _initIAP();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        final adProvider = context.read<AdProvider>();
        adProvider.preloadAd(AdType.lensAd);
        debugPrint('[PurchaseScreen] ✅ Lens Ad preload requested');
      } catch (e) {
        debugPrint('[PurchaseScreen] ⚠️ Ad preload error: $e');
      }
    });
  }

  Future<void> _initIAP() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final creditManager = context.read<CreditManager>();
      await _iapManager.init(creditManager);

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("❌ [Purchase Screen] Init error: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Failed to load purchases. Please try again.";
        });
      }
    }
  }

  Future<void> _watchAdForCredits() async {
    final colorScheme = Theme.of(context).colorScheme;
    final onPrimary = colorScheme.onPrimary;
    final primaryColor = colorScheme.primary;
    final errorColor = colorScheme.error;

    try {
      debugPrint('🎬 [PurchaseScreen] Starting watch ad for credits');

      final adProvider = context.read<AdProvider>();
      final creditManager = context.read<CreditManager>();

      if (!adProvider.isLensAd) {
        debugPrint('⚠️ [PurchaseScreen] Lens ad not ready');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.info_outline, color: onPrimary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ad is loading. Please wait a moment...',
                      style: TextStyle(
                        fontSize: AppTheme.responsiveFont(
                          context,
                          phone: 14,
                          tablet: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: primaryColor,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }

        adProvider.preloadAd(AdType.lensAd);
        return;
      }

      if (!adProvider.canShowRewarded()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.timer_outlined, color: onPrimary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Please wait 2 minutes between ads',
                      style: TextStyle(
                        fontSize: AppTheme.responsiveFont(
                          context,
                          phone: 14,
                          tablet: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: primaryColor,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        return;
      }

      final creditsBefore = creditManager.credits;

      adProvider.showRewardedAd(
        AdType.lensAd,
        onRewarded: () async {
          debugPrint('🎁 [PurchaseScreen] Ad reward earned');

          final success = await creditManager.rewardForAd();

          if (success && mounted) {
            final creditsAfter = creditManager.credits;
            final creditsEarned = creditsAfter - creditsBefore;

            debugPrint('✅ [PurchaseScreen] Credits added: $creditsEarned');

            _showAdRewardDialog();
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Failed to add credits. Please try again.'),
                backgroundColor: errorColor,
              ),
            );
          }
        },
      );
    } catch (e) {
      debugPrint('❌ [PurchaseScreen] Watch ad error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: errorColor,
          ),
        );
      }
    }
  }

  Future<void> _handlePurchase(ProductDetails product) async {
    if (_isPurchasing) {
      debugPrint("⚠️ [Purchase Screen] Purchase already in progress");
      return;
    }

    setState(() {
      _isPurchasing = true;
      _currentPurchasingProductId = product.id;
      _errorMessage = null;
    });

    try {
      debugPrint("🛒 [Purchase Screen] Initiating purchase: ${product.id}");

      final creditsBefore = context.read<CreditManager>().credits;
      final success = await _iapManager.purchaseProduct(product);

      if (!success && mounted) {
        setState(() {
          _isPurchasing = false;
          _currentPurchasingProductId = null;
        });
      } else {
        debugPrint("✅ [Purchase Screen] Purchase initiated successfully");

        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          final creditsAfter = context.read<CreditManager>().credits;
          final creditsAdded = creditsAfter - creditsBefore;

          setState(() {
            _isPurchasing = false;
            _currentPurchasingProductId = null;
          });

          if (creditsAdded > 0) {
            _showPurchaseSuccessDialog(creditsAdded);
          }
        }
      }
    } catch (e) {
      debugPrint("❌ [Purchase Screen] Purchase error: ${e.toString()}");

      if (mounted) {
        setState(() {
          _isPurchasing = false;
          _currentPurchasingProductId = null;
        });
      }
    }
  }

  void _showPurchaseSuccessDialog(int creditsAdded) {
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;
    final primaryColor = colorScheme.primary;
    final surface = colorScheme.surface;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(
              AppTheme.responsiveSize(context, phone: 24, tablet: 32),
            ),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: AppTheme.responsiveSize(
                    context,
                    phone: 80,
                    tablet: 110,
                  ),
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 80,
                    tablet: 110,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: primaryColor,
                    size: AppTheme.responsiveSize(
                      context,
                      phone: 50,
                      tablet: 64,
                    ),
                  ),
                ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 24,
                    tablet: 32,
                  ),
                ),
                Text(
                  'Purchase Successful!',
                  style: TextStyle(
                    fontSize: AppTheme.responsiveFont(
                      context,
                      phone: 24,
                      tablet: 28,
                    ),
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 12,
                    tablet: 16,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.responsiveSize(
                      context,
                      phone: 20,
                      tablet: 28,
                    ),
                    vertical: AppTheme.responsiveSize(
                      context,
                      phone: 12,
                      tablet: 16,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(
                      AppTheme.responsiveSize(context, phone: 12, tablet: 16),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_circle,
                        color: primaryColor,
                        size: AppTheme.responsiveSize(
                          context,
                          phone: 24,
                          tablet: 30,
                        ),
                      ),
                      SizedBox(
                        width: AppTheme.responsiveSize(
                          context,
                          phone: 8,
                          tablet: 12,
                        ),
                      ),
                      Text(
                        '$creditsAdded Credits',
                        style: TextStyle(
                          fontSize: AppTheme.responsiveFont(
                            context,
                            phone: 20,
                            tablet: 26,
                          ),
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 16,
                    tablet: 22,
                  ),
                ),
                Text(
                  'New Balance: ${context.read<CreditManager>().credits} Credits',
                  style: TextStyle(
                    fontSize: AppTheme.responsiveFont(
                      context,
                      phone: 16,
                      tablet: 18,
                    ),
                    color: onSurface.withOpacity(0.75),
                  ),
                ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 24,
                    tablet: 32,
                  ),
                ),
                Text(
                  'Your credits have been added to your account successfully. You can now use them for AI coding features.',
                  style: TextStyle(
                    fontSize: AppTheme.responsiveFont(
                      context,
                      phone: 14,
                      tablet: 16,
                    ),
                    color: onSurface.withOpacity(0.75),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 24,
                    tablet: 32,
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: EdgeInsets.symmetric(
                        vertical: AppTheme.responsiveSize(
                          context,
                          phone: 16,
                          tablet: 20,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.responsiveSize(
                            context,
                            phone: 12,
                            tablet: 16,
                          ),
                        ),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Got it!',
                      style: TextStyle(
                        fontSize: AppTheme.responsiveFont(
                          context,
                          phone: 16,
                          tablet: 18,
                        ),
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleRestore() async {
    if (_isLoading || _isPurchasing) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final onPrimary = colorScheme.onPrimary;
    final errorColor = colorScheme.error;

    try {
      debugPrint("🔄 [Purchase Screen] Restoring purchases...");

      final creditManager = context.read<CreditManager>();
      final result = await _iapManager.restorePurchases(creditManager);

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (result.success) {
        if (result.creditsRestored > 0) {
          _showRestoreSuccessDialog(result.creditsRestored);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.info_outline, color: onPrimary),
                  SizedBox(
                    width: AppTheme.responsiveSize(
                      context,
                      phone: 12,
                      tablet: 16,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'No previous purchases found to restore.',
                      style: TextStyle(
                        fontSize: AppTheme.responsiveFont(
                          context,
                          phone: 14,
                          tablet: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: primaryColor,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppTheme.responsiveSize(context, phone: 10, tablet: 12),
                ),
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning_outlined, color: onPrimary),
                SizedBox(
                  width: AppTheme.responsiveSize(
                    context,
                    phone: 12,
                    tablet: 16,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Some purchases could not be restored. Please try again.',
                    style: TextStyle(
                      fontSize: AppTheme.responsiveFont(
                        context,
                        phone: 14,
                        tablet: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: primaryColor,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppTheme.responsiveSize(context, phone: 10, tablet: 12),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ [Purchase Screen] Restore error: $e");

      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: onPrimary),
                SizedBox(
                  width: AppTheme.responsiveSize(
                    context,
                    phone: 12,
                    tablet: 16,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Failed to restore purchases: ${e.toString()}',
                    style: TextStyle(
                      fontSize: AppTheme.responsiveFont(
                        context,
                        phone: 14,
                        tablet: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: errorColor,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppTheme.responsiveSize(context, phone: 10, tablet: 12),
              ),
            ),
          ),
        );
      }
    }
  }

  void _showRestoreSuccessDialog(int creditsRestored) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final onSurface = colorScheme.onSurface;
    final surface = colorScheme.surface;
    final mutedText = onSurface.withOpacity(0.75);
    final onPrimary = colorScheme.onPrimary;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(
              AppTheme.responsiveSize(context, phone: 24, tablet: 32),
            ),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: AppTheme.responsiveSize(
                    context,
                    phone: 80,
                    tablet: 110,
                  ),
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 80,
                    tablet: 110,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.restore,
                    color: primaryColor,
                    size: AppTheme.responsiveSize(
                      context,
                      phone: 50,
                      tablet: 64,
                    ),
                  ),
                ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 24,
                    tablet: 32,
                  ),
                ),
                Text(
                  'Purchases Restored!',
                  style: TextStyle(
                    fontSize: AppTheme.responsiveFont(
                      context,
                      phone: 24,
                      tablet: 28,
                    ),
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 12,
                    tablet: 16,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.responsiveSize(
                      context,
                      phone: 20,
                      tablet: 28,
                    ),
                    vertical: AppTheme.responsiveSize(
                      context,
                      phone: 12,
                      tablet: 16,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(
                      AppTheme.responsiveSize(context, phone: 12, tablet: 16),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_circle,
                        color: primaryColor,
                        size: AppTheme.responsiveSize(
                          context,
                          phone: 24,
                          tablet: 30,
                        ),
                      ),
                      SizedBox(
                        width: AppTheme.responsiveSize(
                          context,
                          phone: 8,
                          tablet: 12,
                        ),
                      ),
                      Text(
                        '$creditsRestored Credits',
                        style: TextStyle(
                          fontSize: AppTheme.responsiveFont(
                            context,
                            phone: 20,
                            tablet: 26,
                          ),
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 16,
                    tablet: 22,
                  ),
                ),
                Text(
                  'Current Balance: ${context.read<CreditManager>().credits} Credits',
                  style: TextStyle(
                    fontSize: AppTheme.responsiveFont(
                      context,
                      phone: 16,
                      tablet: 18,
                    ),
                    color: mutedText,
                  ),
                ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 24,
                    tablet: 32,
                  ),
                ),
                Text(
                  'Your previous purchases have been successfully restored to your account.',
                  style: TextStyle(
                    fontSize: AppTheme.responsiveFont(
                      context,
                      phone: 14,
                      tablet: 16,
                    ),
                    color: mutedText,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 24,
                    tablet: 32,
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: EdgeInsets.symmetric(
                        vertical: AppTheme.responsiveSize(
                          context,
                          phone: 16,
                          tablet: 20,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.responsiveSize(
                            context,
                            phone: 12,
                            tablet: 16,
                          ),
                        ),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Done',
                      style: TextStyle(
                        fontSize: AppTheme.responsiveFont(
                          context,
                          phone: 16,
                          tablet: 18,
                        ),
                        fontWeight: FontWeight.w600,
                        color: onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAdRewardDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final onSurface = colorScheme.onSurface;
    final mutedText = onSurface.withOpacity(0.75);
    final onPrimary = colorScheme.onPrimary;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: AppTheme.responsiveSize(
                    context,
                    phone: 80,
                    tablet: 100,
                  ),
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 80,
                    tablet: 100,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_circle_filled,
                    color: primaryColor,
                    size: AppTheme.responsiveSize(
                      context,
                      phone: 50,
                      tablet: 60,
                    ),
                  ),
                ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 24,
                    tablet: 30,
                  ),
                ),
                Text(
                  'Credits Earned!',
                  style: TextStyle(
                    fontSize: AppTheme.responsiveFont(
                      context,
                      phone: 24,
                      tablet: 28,
                    ),
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                  ),
                ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 12,
                    tablet: 16,
                  ),
                ),
                Text(
                  '+${CreditManager.rewardedAdCredits} Credits',
                  style: TextStyle(
                    fontSize: AppTheme.responsiveFont(
                      context,
                      phone: 20,
                      tablet: 24,
                    ),
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 16,
                    tablet: 20,
                  ),
                ),
                Text(
                  'Thanks for watching! Your credits have been added.',
                  style: TextStyle(
                    fontSize: AppTheme.responsiveFont(
                      context,
                      phone: 14,
                      tablet: 16,
                    ),
                    color: mutedText,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 24,
                    tablet: 28,
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: EdgeInsets.symmetric(
                        vertical: AppTheme.responsiveSize(
                          context,
                          phone: 16,
                          tablet: 20,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.responsiveSize(
                            context,
                            phone: 12,
                            tablet: 16,
                          ),
                        ),
                      ),
                    ),
                    child: Text(
                      'Awesome!',
                      style: TextStyle(
                        fontSize: AppTheme.responsiveFont(
                          context,
                          phone: 16,
                          tablet: 18,
                        ),
                        fontWeight: FontWeight.w600,
                        color: onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _launchExternalLink(String url) async {
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Unable to open link. Please try again later.')),
        );
      }
      return;
    }

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final creditManager = context.watch<CreditManager>();
    final adProvider = context.watch<AdProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 400).clamp(0.75, 1.4);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: colorScheme.onSurface,
            size: 24 * scale,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Store',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: (theme.textTheme.headlineSmall?.fontSize ?? 20) * scale,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.restore,
              color: colorScheme.onSurface,
              size: 24 * scale,
            ),
            onPressed: _isLoading ? null : _handleRestore,
            tooltip: 'Restore Purchases',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: colorScheme.primary,
            ),
            SizedBox(height: 16 * scale),
            Text(
              'Loading products...',
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14 * scale,
              ),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: EdgeInsets.all(16 * scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Balance Card
            Container(
              padding: EdgeInsets.all(24 * scale),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary.withOpacity(0.15),
                    colorScheme.secondary.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(20 * scale),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'CURRENT BALANCE',
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 12 * scale,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 16 * scale),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        creditManager.isLoading
                            ? '...'
                            : '${creditManager.credits}',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 56 * scale,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 8 * scale),
                        child: Text(
                          ' CRD',
                          style: TextStyle(
                            fontSize: 20 * scale,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16 * scale),
                  Wrap(
                    spacing: 8 * scale,
                    runSpacing: 8 * scale,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildBadge('AI Generation', scale, colorScheme),
                      _buildBadge('Code Assist', scale, colorScheme),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 20 * scale),

            // Watch & Earn Section
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: adProvider.isLensAd ? _watchAdForCredits : null,
                borderRadius: BorderRadius.circular(16 * scale),
                child: Container(
                  padding: EdgeInsets.all(16 * scale),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16 * scale),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56 * scale,
                        height: 56 * scale,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12 * scale),
                        ),
                        child: Icon(
                          Icons.play_circle_filled_rounded,
                          color: colorScheme.primary,
                          size: 32 * scale,
                        ),
                      ),
                      SizedBox(width: 16 * scale),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Watch & Earn',
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 16 * scale,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4 * scale),
                            Text(
                              adProvider.isLensAd
                                  ? 'Get +${CreditManager.rewardedAdCredits} Credits instantly'
                                  : 'Loading ad...',
                              style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.6),
                                fontSize: 14 * scale,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: colorScheme.onSurface.withOpacity(0.4),
                        size: 16 * scale,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 24 * scale),

            // Credit Packs Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Credit Packs',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 20 * scale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12 * scale,
                    vertical: 6 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20 * scale),
                  ),
                  child: Text(
                    'INSTANT DELIVERY',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 10 * scale,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16 * scale),

            // Credit Packages Grid
            if (!_iapManager.isAvailable)
              Container(
                padding: EdgeInsets.all(16 * scale),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12 * scale),
                  border: Border.all(color: colorScheme.primary),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: colorScheme.primary,
                      size: 24 * scale,
                    ),
                    SizedBox(width: 12 * scale),
                    Expanded(
                      child: Text(
                        'In-App Purchases are not available. Please check your settings.',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                          fontSize: 14 * scale,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (_iapManager.products.isEmpty)
              Container(
                padding: EdgeInsets.all(32 * scale),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        color: colorScheme.primary,
                      ),
                      SizedBox(height: 16 * scale),
                      Text(
                        'Loading credit packages...',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 14 * scale,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              _buildCreditPacksGrid(scale, colorScheme),

            SizedBox(height: 32 * scale),

            // Restore Purchases Button
            Center(
              child: TextButton.icon(
                onPressed: _isLoading ? null : _handleRestore,
                icon: Icon(
                  Icons.restore,
                  color: colorScheme.primary,
                  size: 20 * scale,
                ),
                label: Text(
                  'Restore Purchases',
                  style: TextStyle(
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),

            SizedBox(height: 16 * scale),

            // Links
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => _launchExternalLink(
                      'https://vectorlabzlimited.com/privacy-policy/',
                    ),
                    child: Text(
                      'Privacy Policy',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 14 * scale,
                      ),
                    ),
                  ),
                  Text(
                    ' • ',
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 14 * scale,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _launchExternalLink(
                      'https://vectorlabzlimited.com/terms-of-use/',
                    ),
                    child: Text(
                      'Terms of Use',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 14 * scale,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16 * scale),

            // FAQ Section
            _buildFAQSection(scale, colorScheme),

            SizedBox(height: 24 * scale),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, double scale, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12 * scale,
        vertical: 6 * scale,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20 * scale),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 12 * scale,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCreditPacksGrid(double scale, ColorScheme colorScheme) {
    final products = _iapManager.products;

    if (products.isEmpty) return SizedBox.shrink();

    // First 2 products horizontal
    final firstTwo = products.length >= 2 ? products.take(2).toList() : products;
    // Remaining products vertical
    final remaining = products.length > 2 ? products.skip(2).toList() : <ProductDetails>[];

    return Column(
      children: [
        // First Row - 2 Horizontal Cards (or less if not enough products)
        if (firstTwo.isNotEmpty)
          Row(
            children: [
              for (int i = 0; i < firstTwo.length; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: i == 0 && firstTwo.length > 1 ? 8 * scale : 0,
                      left: i == 1 ? 8 * scale : 0,
                    ),
                    child: _buildHorizontalCreditCard(
                      firstTwo[i],
                      scale,
                      colorScheme,
                    ),
                  ),
                ),
            ],
          ),

        if (remaining.isNotEmpty) SizedBox(height: 16 * scale),

        // Remaining products - Vertical Cards
        ...remaining.map((product) => Padding(
          padding: EdgeInsets.only(bottom: 16 * scale),
          child: _buildVerticalCreditCard(product, scale, colorScheme),
        )),
      ],
    );
  }

  Widget _buildHorizontalCreditCard(
      ProductDetails product,
      double scale,
      ColorScheme colorScheme,
      ) {
    final credits = IAPManager.productCredits[product.id] ?? 0;
    final isThisProductPurchasing =
        _isPurchasing && _currentPurchasingProductId == product.id;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isThisProductPurchasing ? null : () => _handlePurchase(product),
        borderRadius: BorderRadius.circular(16 * scale),
        child: Container(
          padding: EdgeInsets.all(16 * scale),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16 * scale),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(12 * scale),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12 * scale),
                ),
                child: Icon(
                  Icons.apps_rounded,
                  color: colorScheme.primary,
                  size: 28 * scale,
                ),
              ),
              SizedBox(height: 12 * scale),
              Text(
                '$credits',
                style: TextStyle(
                  fontSize: 32 * scale,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                'CREDITS',
                style: TextStyle(
                  fontSize: 10 * scale,
                  color: colorScheme.onSurface.withOpacity(0.6),
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4 * scale),
              Text(
                'For AI Features',
                style: TextStyle(
                  fontSize: 11 * scale,
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              SizedBox(height: 12 * scale),
              if (isThisProductPurchasing)
                SizedBox(
                  width: 24 * scale,
                  height: 24 * scale,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 10 * scale),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(10 * scale),
                  ),
                  child: Text(
                    product.price,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14 * scale,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalCreditCard(
      ProductDetails product,
      double scale,
      ColorScheme colorScheme,
      ) {
    final credits = IAPManager.productCredits[product.id] ?? 0;
    final isThisProductPurchasing =
        _isPurchasing && _currentPurchasingProductId == product.id;
    final isBestValue = credits == 2500;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isThisProductPurchasing ? null : () => _handlePurchase(product),
        borderRadius: BorderRadius.circular(16 * scale),
        child: Container(
          padding: EdgeInsets.all(16 * scale),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16 * scale),
            border: Border.all(
              color: isBestValue
                  ? colorScheme.primary.withOpacity(0.5)
                  : colorScheme.outline.withOpacity(0.2),
              width: isBestValue ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12 * scale),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12 * scale),
                ),
                child: Icon(
                  isBestValue ? Icons.diamond_rounded : Icons.trending_up_rounded,
                  color: colorScheme.primary,
                  size: 32 * scale,
                ),
              ),
              SizedBox(width: 16 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$credits',
                          style: TextStyle(
                            fontSize: 24 * scale,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(width: 8 * scale),
                        Text(
                          'Credits',
                          style: TextStyle(
                            fontSize: 14 * scale,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        if (isBestValue) ...[
                          SizedBox(width: 8 * scale),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8 * scale,
                              vertical: 4 * scale,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(6 * scale),
                            ),
                            child: Text(
                              'BEST VALUE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9 * scale,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 4 * scale),
                    Text(
                      isBestValue ? 'Most Popular Choice' : 'Pro Developer Pack',
                      style: TextStyle(
                        fontSize: 12 * scale,
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (isThisProductPurchasing)
                SizedBox(
                  width: 24 * scale,
                  height: 24 * scale,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                )
              else
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20 * scale,
                    vertical: 12 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(10 * scale),
                    border: Border.all(
                      color: colorScheme.onSurface,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    product.price,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 16 * scale,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQSection(double scale, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(20 * scale),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline_rounded,
                color: colorScheme.primary,
                size: 24 * scale,
              ),
              SizedBox(width: 12 * scale),
              Text(
                'FAQ',
                style: TextStyle(
                  fontSize: 20 * scale,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 16 * scale),
          _buildFAQItem(
            'How can I spend credits?',
            'Use them for AI coding features and advanced tools.',
            scale,
            colorScheme,
          ),
          SizedBox(height: 12 * scale),
          _buildFAQItem(
            'Do credits expire?',
            'Credits never expire — they stay in your account until you use them.',
            scale,
            colorScheme,
          ),
          SizedBox(height: 12 * scale),
          _buildFAQItem(
            'How do I add more credits?',
            'You can watch rewarded ads to earn bonus credits or buy a credit pack.',
            scale,
            colorScheme,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(
      String question,
      String answer,
      double scale,
      ColorScheme colorScheme, {
        bool isLast = false,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14 * scale,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 4 * scale),
        Text(
          answer,
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.7),
            fontSize: 13 * scale,
            height: 1.4,
          ),
        ),
        if (!isLast)
          Container(
            margin: EdgeInsets.only(top: 12 * scale),
            height: 1,
            color: colorScheme.outline.withOpacity(0.1),
          ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}*/
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:in_app_purchase/in_app_purchase.dart';
import '../ads/ads_provider.dart';
import '../core/App_theme.dart';
import 'credit_manager.dart';
import 'i_app_manager.dart';

class CreditsPurchaseScreen extends StatefulWidget {
  const CreditsPurchaseScreen({Key? key}) : super(key: key);

  @override
  State<CreditsPurchaseScreen> createState() => _CreditsPurchaseScreenState();
}

class _CreditsPurchaseScreenState extends State<CreditsPurchaseScreen> {
  final IAPManager _iapManager = IAPManager();
  bool _isLoading = true;
  bool _isPurchasing = false;
  String? _errorMessage;
  String? _currentPurchasingProductId;

  @override
  void initState() {
    super.initState();
    _initIAP();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        final adProvider = context.read<AdProvider>();
        adProvider.preloadAd(AdType.lensAd);
        debugPrint('[PurchaseScreen] ✅ Lens Ad preload requested');
      } catch (e) {
        debugPrint('[PurchaseScreen] ⚠️ Ad preload error: $e');
      }
    });
  }

  Future<void> _initIAP() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final creditManager = context.read<CreditManager>();
      await _iapManager.init(creditManager);

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("❌ [Purchase Screen] Init error: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Failed to load purchases. Please try again.";
        });
      }
    }
  }

  Future<void> _watchAdForCredits() async {
    final colorScheme = Theme.of(context).colorScheme;
    final onPrimary = colorScheme.onPrimary;
    final primaryColor = colorScheme.primary;
    final errorColor = colorScheme.error;

    try {
      debugPrint('🎬 [PurchaseScreen] Starting watch ad for credits');

      final adProvider = context.read<AdProvider>();
      final creditManager = context.read<CreditManager>();

      if (!adProvider.isLensAd) {
        debugPrint('⚠️ [PurchaseScreen] Lens ad not ready');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.info_outline, color: onPrimary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ad is loading. Please wait a moment...',
                      style: TextStyle(
                        fontSize: AppTheme.responsiveFont(
                          context,
                          phone: 14,
                          tablet: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: primaryColor,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }

        adProvider.preloadAd(AdType.lensAd);
        return;
      }

      if (!adProvider.canShowRewarded()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.timer_outlined, color: onPrimary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Please wait 2 minutes between ads',
                      style: TextStyle(
                        fontSize: AppTheme.responsiveFont(
                          context,
                          phone: 14,
                          tablet: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: primaryColor,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        return;
      }

      final creditsBefore = creditManager.credits;

      adProvider.showRewardedAd(
        AdType.lensAd,
        onRewarded: () async {
          debugPrint('🎁 [PurchaseScreen] Ad reward earned');

          final success = await creditManager.rewardForAd();

          if (success && mounted) {
            final creditsAfter = creditManager.credits;
            final creditsEarned = creditsAfter - creditsBefore;

            debugPrint('✅ [PurchaseScreen] Credits added: $creditsEarned');

            _showAdRewardDialog();
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Failed to add credits. Please try again.'),
                backgroundColor: errorColor,
              ),
            );
          }
        },
      );
    } catch (e) {
      debugPrint('❌ [PurchaseScreen] Watch ad error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: errorColor,
          ),
        );
      }
    }
  }

  Future<void> _handlePurchase(ProductDetails product) async {
    if (_isPurchasing) {
      debugPrint("⚠️ [Purchase Screen] Purchase already in progress");
      return;
    }

    setState(() {
      _isPurchasing = true;
      _currentPurchasingProductId = product.id;
      _errorMessage = null;
    });

    try {
      debugPrint("🛒 [Purchase Screen] Initiating purchase: ${product.id}");

      final creditsBefore = context.read<CreditManager>().credits;
      final success = await _iapManager.purchaseProduct(product);

      if (!success && mounted) {
        setState(() {
          _isPurchasing = false;
          _currentPurchasingProductId = null;
        });
      } else {
        debugPrint("✅ [Purchase Screen] Purchase initiated successfully");

        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          final creditsAfter = context.read<CreditManager>().credits;
          final creditsAdded = creditsAfter - creditsBefore;

          setState(() {
            _isPurchasing = false;
            _currentPurchasingProductId = null;
          });

          if (creditsAdded > 0) {
            _showPurchaseSuccessDialog(creditsAdded);
          }
        }
      }
    } catch (e) {
      debugPrint("❌ [Purchase Screen] Purchase error: ${e.toString()}");

      if (mounted) {
        setState(() {
          _isPurchasing = false;
          _currentPurchasingProductId = null;
        });
      }
    }
  }

  void _showPurchaseSuccessDialog(int creditsAdded) {
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;
    final primaryColor = colorScheme.primary;
    final surface = colorScheme.surface;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(
              AppTheme.responsiveSize(context, phone: 24, tablet: 32),
            ),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: AppTheme.responsiveSize(
                    context,
                    phone: 80,
                    tablet: 110,
                  ),
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 80,
                    tablet: 110,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: primaryColor,
                    size: AppTheme.responsiveSize(
                      context,
                      phone: 50,
                      tablet: 64,
                    ),
                  ),
                ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 24,
                    tablet: 32,
                  ),
                ),
                Text(
                  'Purchase Successful!',
                  style: TextStyle(
                    fontSize: AppTheme.responsiveFont(
                      context,
                      phone: 24,
                      tablet: 28,
                    ),
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 12,
                    tablet: 16,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.responsiveSize(
                      context,
                      phone: 20,
                      tablet: 28,
                    ),
                    vertical: AppTheme.responsiveSize(
                      context,
                      phone: 12,
                      tablet: 16,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(
                      AppTheme.responsiveSize(context, phone: 12, tablet: 16),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_circle,
                        color: primaryColor,
                        size: AppTheme.responsiveSize(
                          context,
                          phone: 24,
                          tablet: 30,
                        ),
                      ),
                      SizedBox(
                        width: AppTheme.responsiveSize(
                          context,
                          phone: 8,
                          tablet: 12,
                        ),
                      ),
                      Text(
                        '$creditsAdded Credits',
                        style: TextStyle(
                          fontSize: AppTheme.responsiveFont(
                            context,
                            phone: 20,
                            tablet: 26,
                          ),
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 16,
                    tablet: 22,
                  ),
                ),
                Text(
                  'New Balance: ${context.read<CreditManager>().credits} Credits',
                  style: TextStyle(
                    fontSize: AppTheme.responsiveFont(
                      context,
                      phone: 16,
                      tablet: 18,
                    ),
                    color: onSurface.withOpacity(0.75),
                  ),
                ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 24,
                    tablet: 32,
                  ),
                ),
                Text(
                  'Your credits have been added to your account successfully. You can now use them for AI coding features.',
                  style: TextStyle(
                    fontSize: AppTheme.responsiveFont(
                      context,
                      phone: 14,
                      tablet: 16,
                    ),
                    color: onSurface.withOpacity(0.75),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 24,
                    tablet: 32,
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: EdgeInsets.symmetric(
                        vertical: AppTheme.responsiveSize(
                          context,
                          phone: 16,
                          tablet: 20,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.responsiveSize(
                            context,
                            phone: 12,
                            tablet: 16,
                          ),
                        ),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Got it!',
                      style: TextStyle(
                        fontSize: AppTheme.responsiveFont(
                          context,
                          phone: 16,
                          tablet: 18,
                        ),
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleRestore() async {
    if (_isLoading || _isPurchasing) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final onPrimary = colorScheme.onPrimary;
    final errorColor = colorScheme.error;

    try {
      debugPrint("🔄 [Purchase Screen] Restoring purchases...");

      final creditManager = context.read<CreditManager>();
      final result = await _iapManager.restorePurchases(creditManager);

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (result.success) {
        if (result.creditsRestored > 0) {
          _showRestoreSuccessDialog(result.creditsRestored);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.info_outline, color: onPrimary),
                  SizedBox(
                    width: AppTheme.responsiveSize(
                      context,
                      phone: 12,
                      tablet: 16,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'No previous purchases found to restore.',
                      style: TextStyle(
                        fontSize: AppTheme.responsiveFont(
                          context,
                          phone: 14,
                          tablet: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: primaryColor,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppTheme.responsiveSize(context, phone: 10, tablet: 12),
                ),
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning_outlined, color: onPrimary),
                SizedBox(
                  width: AppTheme.responsiveSize(
                    context,
                    phone: 12,
                    tablet: 16,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Some purchases could not be restored. Please try again.',
                    style: TextStyle(
                      fontSize: AppTheme.responsiveFont(
                        context,
                        phone: 14,
                        tablet: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: primaryColor,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppTheme.responsiveSize(context, phone: 10, tablet: 12),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ [Purchase Screen] Restore error: $e");

      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: onPrimary),
                SizedBox(
                  width: AppTheme.responsiveSize(
                    context,
                    phone: 12,
                    tablet: 16,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Failed to restore purchases: ${e.toString()}',
                    style: TextStyle(
                      fontSize: AppTheme.responsiveFont(
                        context,
                        phone: 14,
                        tablet: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: errorColor,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppTheme.responsiveSize(context, phone: 10, tablet: 12),
              ),
            ),
          ),
        );
      }
    }
  }

  void _showRestoreSuccessDialog(int creditsRestored) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final onSurface = colorScheme.onSurface;
    final surface = colorScheme.surface;
    final mutedText = onSurface.withOpacity(0.75);
    final onPrimary = colorScheme.onPrimary;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(
              AppTheme.responsiveSize(context, phone: 24, tablet: 32),
            ),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: AppTheme.responsiveSize(
                    context,
                    phone: 80,
                    tablet: 110,
                  ),
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 80,
                    tablet: 110,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.restore,
                    color: primaryColor,
                    size: AppTheme.responsiveSize(
                      context,
                      phone: 50,
                      tablet: 64,
                    ),
                  ),
                ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 24,
                    tablet: 32,
                  ),
                ),
                Text(
                  'Purchases Restored!',
                  style: TextStyle(
                    fontSize: AppTheme.responsiveFont(
                      context,
                      phone: 24,
                      tablet: 28,
                    ),
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 12,
                    tablet: 16,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.responsiveSize(
                      context,
                      phone: 20,
                      tablet: 28,
                    ),
                    vertical: AppTheme.responsiveSize(
                      context,
                      phone: 12,
                      tablet: 16,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(
                      AppTheme.responsiveSize(context, phone: 12, tablet: 16),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_circle,
                        color: primaryColor,
                        size: AppTheme.responsiveSize(
                          context,
                          phone: 24,
                          tablet: 30,
                        ),
                      ),
                      SizedBox(
                        width: AppTheme.responsiveSize(
                          context,
                          phone: 8,
                          tablet: 12,
                        ),
                      ),
                      Text(
                        '$creditsRestored Credits',
                        style: TextStyle(
                          fontSize: AppTheme.responsiveFont(
                            context,
                            phone: 20,
                            tablet: 26,
                          ),
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 16,
                    tablet: 22,
                  ),
                ),
                Text(
                  'Current Balance: ${context.read<CreditManager>().credits} Credits',
                  style: TextStyle(
                    fontSize: AppTheme.responsiveFont(
                      context,
                      phone: 16,
                      tablet: 18,
                    ),
                    color: mutedText,
                  ),
                ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 24,
                    tablet: 32,
                  ),
                ),
                Text(
                  'Your previous purchases have been successfully restored to your account.',
                  style: TextStyle(
                    fontSize: AppTheme.responsiveFont(
                      context,
                      phone: 14,
                      tablet: 16,
                    ),
                    color: mutedText,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 24,
                    tablet: 32,
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: EdgeInsets.symmetric(
                        vertical: AppTheme.responsiveSize(
                          context,
                          phone: 16,
                          tablet: 20,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.responsiveSize(
                            context,
                            phone: 12,
                            tablet: 16,
                          ),
                        ),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Done',
                      style: TextStyle(
                        fontSize: AppTheme.responsiveFont(
                          context,
                          phone: 16,
                          tablet: 18,
                        ),
                        fontWeight: FontWeight.w600,
                        color: onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAdRewardDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final onSurface = colorScheme.onSurface;
    final mutedText = onSurface.withOpacity(0.75);
    final onPrimary = colorScheme.onPrimary;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: AppTheme.responsiveSize(
                    context,
                    phone: 80,
                    tablet: 100,
                  ),
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 80,
                    tablet: 100,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_circle_filled,
                    color: primaryColor,
                    size: AppTheme.responsiveSize(
                      context,
                      phone: 50,
                      tablet: 60,
                    ),
                  ),
                ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 24,
                    tablet: 30,
                  ),
                ),
                Text(
                  'Credits Earned!',
                  style: TextStyle(
                    fontSize: AppTheme.responsiveFont(
                      context,
                      phone: 24,
                      tablet: 28,
                    ),
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                  ),
                ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 12,
                    tablet: 16,
                  ),
                ),
                Text(
                  '+${CreditManager.rewardedAdCredits} Credits',
                  style: TextStyle(
                    fontSize: AppTheme.responsiveFont(
                      context,
                      phone: 20,
                      tablet: 24,
                    ),
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 16,
                    tablet: 20,
                  ),
                ),
                Text(
                  'Thanks for watching! Your credits have been added.',
                  style: TextStyle(
                    fontSize: AppTheme.responsiveFont(
                      context,
                      phone: 14,
                      tablet: 16,
                    ),
                    color: mutedText,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: AppTheme.responsiveSize(
                    context,
                    phone: 24,
                    tablet: 28,
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: EdgeInsets.symmetric(
                        vertical: AppTheme.responsiveSize(
                          context,
                          phone: 16,
                          tablet: 20,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.responsiveSize(
                            context,
                            phone: 12,
                            tablet: 16,
                          ),
                        ),
                      ),
                    ),
                    child: Text(
                      'Awesome!',
                      style: TextStyle(
                        fontSize: AppTheme.responsiveFont(
                          context,
                          phone: 16,
                          tablet: 18,
                        ),
                        fontWeight: FontWeight.w600,
                        color: onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _launchExternalLink(String url) async {
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Unable to open link. Please try again later.')),
        );
      }
      return;
    }

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final creditManager = context.watch<CreditManager>();
    final adProvider = context.watch<AdProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 400).clamp(0.75, 1.4);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: colorScheme.onSurface,
            size: 24 * scale,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Store',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: (theme.textTheme.headlineSmall?.fontSize ?? 20) * scale,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.restore,
              color: colorScheme.onSurface,
              size: 24 * scale,
            ),
            onPressed: _isLoading ? null : _handleRestore,
            tooltip: 'Restore Purchases',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: colorScheme.primary,
            ),
            SizedBox(height: 16 * scale),
            Text(
              'Loading products...',
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14 * scale,
              ),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: EdgeInsets.all(16 * scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Balance Card
            Container(
              padding: EdgeInsets.all(24 * scale),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary.withOpacity(0.15),
                    colorScheme.secondary.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(20 * scale),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'CURRENT BALANCE',
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 12 * scale,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 16 * scale),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        creditManager.isLoading
                            ? '...'
                            : '${creditManager.credits}',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 56 * scale,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 8 * scale),
                        child: Text(
                          ' CRD',
                          style: TextStyle(
                            fontSize: 20 * scale,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16 * scale),
                  Wrap(
                    spacing: 8 * scale,
                    runSpacing: 8 * scale,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildBadge('Smart Learning', scale, colorScheme),
                      _buildBadge('Code Assist', scale, colorScheme),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 20 * scale),

            // Watch & Earn Section
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: adProvider.isLensAd ? _watchAdForCredits : null,
                borderRadius: BorderRadius.circular(16 * scale),
                child: Container(
                  padding: EdgeInsets.all(16 * scale),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16 * scale),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56 * scale,
                        height: 56 * scale,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(12 * scale),
                        ),
                        child: Icon(
                          Icons.play_circle_filled_rounded,
                          color: Colors.white,
                          size: 32 * scale,
                        ),
                      ),
                      SizedBox(width: 16 * scale),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Watch & Earn',
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 16 * scale,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4 * scale),
                            Text(
                              adProvider.isLensAd
                                  ? 'Get +${CreditManager.rewardedAdCredits} Credits instantly'
                                  : 'Loading ad...',
                              style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.6),
                                fontSize: 14 * scale,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: colorScheme.onSurface.withOpacity(0.4),
                        size: 16 * scale,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 24 * scale),

            // Credit Packs Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Credit Packs',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 20 * scale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12 * scale,
                    vertical: 6 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20 * scale),
                  ),
                  child: Text(
                    'INSTANT DELIVERY',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 10 * scale,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16 * scale),

            // Credit Packages Grid
            if (!_iapManager.isAvailable)
              Container(
                padding: EdgeInsets.all(16 * scale),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12 * scale),
                  border: Border.all(color: colorScheme.primary),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: colorScheme.primary,
                      size: 24 * scale,
                    ),
                    SizedBox(width: 12 * scale),
                    Expanded(
                      child: Text(
                        'In-App Purchases are not available. Please check your settings.',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                          fontSize: 14 * scale,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (_iapManager.products.isEmpty)
              Container(
                padding: EdgeInsets.all(32 * scale),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        color: colorScheme.primary,
                      ),
                      SizedBox(height: 16 * scale),
                      Text(
                        'Loading credit packages...',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 14 * scale,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              _buildCreditPacksGrid(scale, colorScheme),

            SizedBox(height: 32 * scale),

            // Restore Purchases Button
            Center(
              child: TextButton.icon(
                onPressed: _isLoading ? null : _handleRestore,
                icon: Icon(
                  Icons.restore,
                  color: colorScheme.primary,
                  size: 20 * scale,
                ),
                label: Text(
                  'Restore Purchases',
                  style: TextStyle(
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),

            SizedBox(height: 16 * scale),

            // Links
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => _launchExternalLink(
                      'https://vectorlabzlimited.com/privacy-policy/',
                    ),
                    child: Text(
                      'Privacy Policy',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 14 * scale,
                      ),
                    ),
                  ),
                  Text(
                    ' • ',
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 14 * scale,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _launchExternalLink(
                      'https://vectorlabzlimited.com/terms-of-use/',
                    ),
                    child: Text(
                      'Terms of Use',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 14 * scale,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16 * scale),

            // FAQ Section
            _buildFAQSection(scale, colorScheme),

            SizedBox(height: 24 * scale),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, double scale, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12 * scale,
        vertical: 6 * scale,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20 * scale),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 12 * scale,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCreditPacksGrid(double scale, ColorScheme colorScheme) {
    final products = _iapManager.products;

    if (products.isEmpty) return SizedBox.shrink();

    // First 2 products horizontal
    final firstTwo = products.length >= 2 ? products.take(2).toList() : products;
    // Remaining products vertical
    final remaining = products.length > 2 ? products.skip(2).toList() : <ProductDetails>[];

    return Column(
      children: [
        // First Row - 2 Horizontal Cards (or less if not enough products)
        if (firstTwo.isNotEmpty)
          Row(
            children: [
              for (int i = 0; i < firstTwo.length; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: i == 0 && firstTwo.length > 1 ? 8 * scale : 0,
                      left: i == 1 ? 8 * scale : 0,
                    ),
                    child: _buildHorizontalCreditCard(
                      firstTwo[i],
                      scale,
                      colorScheme,
                    ),
                  ),
                ),
            ],
          ),

        if (remaining.isNotEmpty) SizedBox(height: 16 * scale),

        // Remaining products - Vertical Cards
        ...remaining.map((product) => Padding(
          padding: EdgeInsets.only(bottom: 16 * scale),
          child: _buildVerticalCreditCard(product, scale, colorScheme),
        )),
      ],
    );
  }

  Widget _buildHorizontalCreditCard(
      ProductDetails product,
      double scale,
      ColorScheme colorScheme,
      ) {
    final credits = IAPManager.productCredits[product.id] ?? 0;
    final isThisProductPurchasing =
        _isPurchasing && _currentPurchasingProductId == product.id;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isThisProductPurchasing ? null : () => _handlePurchase(product),
        borderRadius: BorderRadius.circular(16 * scale),
        child: Container(
          padding: EdgeInsets.all(16 * scale),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16 * scale),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(12 * scale),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12 * scale),
                ),
                child: Icon(
                  Icons.apps_rounded,
                  color: colorScheme.primary,
                  size: 28 * scale,
                ),
              ),
              SizedBox(height: 12 * scale),
              Text(
                '$credits',
                style: TextStyle(
                  fontSize: 32 * scale,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                'CREDITS',
                style: TextStyle(
                  fontSize: 10 * scale,
                  color: colorScheme.onSurface.withOpacity(0.6),
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4 * scale),
              Text(
                'For AI Features',
                style: TextStyle(
                  fontSize: 11 * scale,
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              SizedBox(height: 12 * scale),
              if (isThisProductPurchasing)
                SizedBox(
                  width: 24 * scale,
                  height: 24 * scale,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 10 * scale),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(10 * scale),
                  ),
                  child: Text(
                    product.price,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14 * scale,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalCreditCard(
      ProductDetails product,
      double scale,
      ColorScheme colorScheme,
      ) {
    final credits = IAPManager.productCredits[product.id] ?? 0;
    final isThisProductPurchasing =
        _isPurchasing && _currentPurchasingProductId == product.id;
    final isBestValue = credits == 2500;
    final isProPack = credits == 5000;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isThisProductPurchasing ? null : () => _handlePurchase(product),
        borderRadius: BorderRadius.circular(16 * scale),
        child: Container(
          padding: EdgeInsets.all(16 * scale),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16 * scale),
            border: Border.all(
              color: isBestValue
                  ? colorScheme.primary.withOpacity(0.5)
                  : colorScheme.outline.withOpacity(0.2),
              width: isBestValue ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(14 * scale),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isBestValue || isProPack
                        ? [Colors.amber.shade600, Colors.amber.shade700]
                        : [colorScheme.primary.withOpacity(0.2), colorScheme.primary.withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(14 * scale),
                ),
                child: Icon(
                  isBestValue
                      ? Icons.diamond_rounded
                      : isProPack
                      ? Icons.trending_up_rounded
                      : Icons.apps_rounded,
                  color: isBestValue || isProPack ? Colors.white : colorScheme.primary,
                  size: 36 * scale,
                ),
              ),
              SizedBox(width: 16 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isBestValue) ...[
                      Row(
                        children: [
                          Text(
                            '$credits',
                            style: TextStyle(
                              fontSize: 28 * scale,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(width: 12 * scale),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10 * scale,
                              vertical: 6 * scale,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade600,
                              borderRadius: BorderRadius.circular(8 * scale),
                            ),
                            child: Text(
                              'BEST\nVALUE',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 9 * scale,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4 * scale),
                      Text(
                        'Most Popular Choice',
                        style: TextStyle(
                          fontSize: 13 * scale,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Text(
                            '$credits',
                            style: TextStyle(
                              fontSize: 28 * scale,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(width: 8 * scale),
                          Text(
                            'Credits',
                            style: TextStyle(
                              fontSize: 15 * scale,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4 * scale),
                      Text(
                        'Pro Developer Pack',
                        style: TextStyle(
                          fontSize: 13 * scale,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isThisProductPurchasing)
                SizedBox(
                  width: 24 * scale,
                  height: 24 * scale,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                )
              else
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20 * scale,
                    vertical: 12 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(10 * scale),
                    border: Border.all(
                      color: colorScheme.onSurface,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    product.price,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 16 * scale,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQSection(double scale, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(20 * scale),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline_rounded,
                color: colorScheme.primary,
                size: 24 * scale,
              ),
              SizedBox(width: 12 * scale),
              Text(
                'FAQ',
                style: TextStyle(
                  fontSize: 20 * scale,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 16 * scale),
          _FAQItem(
            question: 'How can I spend credits?',
            answer: 'Use them for AI coding features and advanced tools.',
            scale: scale,
            colorScheme: colorScheme,
          ),
          SizedBox(height: 8 * scale),
          _FAQItem(
            question: 'Do credits expire?',
            answer: 'Credits never expire — they stay in your account until you use them.',
            scale: scale,
            colorScheme: colorScheme,
          ),
          SizedBox(height: 8 * scale),
          _FAQItem(
            question: 'How do I add more credits?',
            answer: 'You can watch rewarded ads to earn bonus credits or buy a credit pack.',
            scale: scale,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class _FAQItem extends StatefulWidget {
  final String question;
  final String answer;
  final double scale;
  final ColorScheme colorScheme;

  const _FAQItem({
    required this.question,
    required this.answer,
    required this.scale,
    required this.colorScheme,
  });

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: widget.colorScheme.outline.withOpacity(0.1),
        ),
        borderRadius: BorderRadius.circular(12 * widget.scale),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(12 * widget.scale),
          child: Padding(
            padding: EdgeInsets.all(12 * widget.scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.question,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14 * widget.scale,
                          color: widget.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: widget.colorScheme.onSurface.withOpacity(0.6),
                      size: 24 * widget.scale,
                    ),
                  ],
                ),
                if (_isExpanded) ...[
                  SizedBox(height: 8 * widget.scale),
                  Text(
                    widget.answer,
                    style: TextStyle(
                      color: widget.colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 13 * widget.scale,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}