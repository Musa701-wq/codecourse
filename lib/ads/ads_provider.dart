// import 'package:coding_tutor/ads/ad_helper.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
//
// class AdProvider with ChangeNotifier {
//   // Ad State Management
//   final Map<AdType, AdState> _adStates = {
//     AdType.homeAd1: AdState(),
//     AdType.homeAd2: AdState(),
//     AdType.lensAd: AdState(),
//     AdType.calendarAd: AdState(),
//     AdType.myGardenAd: AdState(),
//     AdType.discoverPlantAd: AdState(),
//     AdType.courseTopicsAd1: AdState(),
//     AdType.courseTopicsAd2: AdState(),
//     AdType.courseTopicsAd3: AdState(),
//   };
//
//   // Ad instances
//   NativeAd? _homeAd1;
//   NativeAd? _homeAd2;
//   NativeAd? _calendarAd;
//   NativeAd? _myGardenAd;
//   NativeAd? _discoverPlantAd;
//   NativeAd? _courseTopicsAd1;
//   NativeAd? _courseTopicsAd2;
//   NativeAd? _courseTopicsAd3;
//   RewardedAd? _lensAd; // Changed to RewardedAd
//
//   // Retry and rate limiting
//   final Map<AdType, DateTime?> _lastLoadAttempt = {};
//   final Map<AdType, int> _retryCount = {};
//   static const Duration _reloadDelay = Duration(seconds: 30);
//   static const int _maxRetries = 3;
//
//   // Rewarded ad timing
//   DateTime? _lastRewardedShow;
//   static const Duration _minRewardedInterval = Duration(minutes: 2);
//
//   // Analytics
//   final Map<AdType, int> _loadAttempts = {};
//   final Map<AdType, int> _loadSuccess = {};
//   final Map<AdType, int> _loadFailures = {};
//
//   // Getters for ad loaded states
//   bool get isHomeAd1 => _adStates[AdType.homeAd1]!.isLoaded;
//   bool get isHomeAd2 => _adStates[AdType.homeAd2]!.isLoaded;
//   bool get isNotePageAd3 => _adStates[AdType.calendarAd]!.isLoaded;
//   bool get isExercisePageAd1 => _adStates[AdType.myGardenAd]!.isLoaded;
//   bool get isYVideoPageAd1 => _adStates[AdType.discoverPlantAd]!.isLoaded;
//   bool get iscourseTopicsAd1 => _adStates[AdType.courseTopicsAd1]!.isLoaded;
//   bool get iscourseTopicsAd2 => _adStates[AdType.courseTopicsAd2]!.isLoaded;
//   bool get iscourseTopicsAd3 => _adStates[AdType.courseTopicsAd3]!.isLoaded;
//
//   bool get isLensAd => _adStates[AdType.lensAd]!.isLoaded;
//
//   // Getter for ad instances
//   NativeAd? get homeAd1 => _homeAd1;
//   NativeAd? get homeAd2 => _homeAd2;
//   NativeAd? get calendarAd => _calendarAd;
//   NativeAd? get myGardenAd => _myGardenAd;
//   NativeAd? get discoverPlantAd => _discoverPlantAd;
//   NativeAd? get courseTopicsAd1 => _courseTopicsAd1;
//   NativeAd? get courseTopicsAd2 => _courseTopicsAd2;
//   NativeAd? get courseTopicsAd3 => _courseTopicsAd3;
//
//   RewardedAd? get lensAd => _lensAd;
//
//   /// Preload ad agar already loaded nahi hai
//   Future<void> preloadAd(AdType adType, {dynamic adSize}) async {
//     final state = _adStates[adType];
//
//     // Agar already loaded hai to skip karo
//     if (state?.isLoaded == true) {
//       print("ℹ️ ${adType.name} already loaded");
//       return;
//     }
//
//     // Rate limiting: 30 seconds ke andar dobara load na karo
//     final lastAttempt = _lastLoadAttempt[adType];
//     if (lastAttempt != null &&
//         DateTime.now().difference(lastAttempt) < _reloadDelay) {
//       print("⏳ ${adType.name} rate limited, waiting...");
//       return;
//     }
//
//     _lastLoadAttempt[adType] = DateTime.now();
//
//     // Load appropriate ad type
//     if (adType == AdType.lensAd) {
//       await initializeRewardedAdWithRetry(adType);
//     } else {
//       await initializeNativeAdWithRetry(adType, adSize);
//     }
//   }
//
//   /// Initialize rewarded ad with retry
//   Future<void> initializeRewardedAdWithRetry(
//     AdType adType, {
//     int retryAttempt = 0,
//   }) async {
//     final adHelperId = _getAdHelperId(adType);
//     if (adHelperId == null) return;
//
//     _trackLoadAttempt(adType);
//     print("🟡 Loading ${adType.name} Rewarded (Attempt ${retryAttempt + 1})");
//
//     await RewardedAd.load(
//       adUnitId: adHelperId,
//       request: const AdRequest(),
//       rewardedAdLoadCallback: RewardedAdLoadCallback(
//         onAdLoaded: (ad) {
//           print("✅ ${adType.name} Rewarded Ad Loaded");
//           _updateAdState(adType, true);
//           _storeRewardedAd(adType, ad);
//           _trackLoadSuccess(adType);
//           _retryCount[adType] = 0;
//         },
//         onAdFailedToLoad: (error) {
//           print("❌ ${adType.name} Rewarded Ad Failed: $error");
//           _trackLoadFailure(adType);
//           _updateAdState(adType, false);
//
//           // Retry with exponential backoff
//           if (retryAttempt < _maxRetries) {
//             final delay = Duration(seconds: (retryAttempt + 1) * 5);
//             print("🔄 Retrying ${adType.name} in ${delay.inSeconds}s");
//             Future.delayed(delay, () {
//               initializeRewardedAdWithRetry(
//                 adType,
//                 retryAttempt: retryAttempt + 1,
//               );
//             });
//           }
//         },
//       ),
//     );
//   }
//
//   /// Initialize native ad with retry
//   Future<void> initializeNativeAdWithRetry(
//     AdType adType,
//     dynamic adSize, {
//     int retryAttempt = 0,
//   }) async {
//     final adHelperId = _getAdHelperId(adType);
//     if (adHelperId == null) return;
//
//     _trackLoadAttempt(adType);
//     print("🟡 Loading ${adType.name} Native Ad (Attempt ${retryAttempt + 1})");
//
//     final nativeAd = NativeAd(
//       adUnitId: adHelperId,
//       listener: NativeAdListener(
//         onAdLoaded: (ad) {
//           print("✅ ${adType.name} Native Ad Loaded");
//           _updateAdState(adType, true);
//           _storeNativeAd(adType, ad as NativeAd);
//           _trackLoadSuccess(adType);
//           _retryCount[adType] = 0;
//         },
//         onAdFailedToLoad: (ad, error) {
//           print("❌ ${adType.name} Native Ad Failed: $error");
//           _trackLoadFailure(adType);
//           ad.dispose();
//
//           // Retry with exponential backoff
//           if (retryAttempt < _maxRetries) {
//             final delay = Duration(seconds: (retryAttempt + 1) * 5);
//             print("🔄 Retrying ${adType.name} in ${delay.inSeconds}s");
//             Future.delayed(delay, () {
//               initializeNativeAdWithRetry(
//                 adType,
//                 adSize,
//                 retryAttempt: retryAttempt + 1,
//               );
//             });
//           } else {
//             _updateAdState(adType, false);
//           }
//         },
//       ),
//       request: const AdRequest(),
//       nativeTemplateStyle: NativeTemplateStyle(templateType: adSize),
//     );
//
//     await nativeAd.load();
//   }
//
//   /// Legacy methods (keeping for backward compatibility)
//   Future<void> initializeRewardedAd(AdType adType) async {
//     await initializeRewardedAdWithRetry(adType);
//   }
//
//   Future<void> initializeNativeAd(AdType adType, adSize) async {
//     await initializeNativeAdWithRetry(adType, adSize);
//   }
//
//   /// Check if rewarded can be shown
//   bool canShowRewarded() {
//     if (_lastRewardedShow == null) return true;
//
//     return DateTime.now().difference(_lastRewardedShow!) > _minRewardedInterval;
//   }
//
//   /// Show rewarded ad with callback
//   void showRewardedAd(AdType adType, {required Function() onRewarded}) {
//     if (!canShowRewarded()) {
//       print(
//         "⏳ Too soon to show rewarded (wait ${_minRewardedInterval.inMinutes} min)",
//       );
//       return;
//     }
//
//     final adState = _adStates[adType];
//     final rewardedAd = _getRewardedAd(adType);
//
//     if (adState?.isLoaded != true || rewardedAd == null) {
//       print("⚠️ ${adType.name} Rewarded Ad not ready");
//       // Preload for next time
//       initializeRewardedAdWithRetry(adType);
//       return;
//     }
//
//     rewardedAd.fullScreenContentCallback = FullScreenContentCallback(
//       onAdShowedFullScreenContent: (ad) {
//         print("📺 ${adType.name} Rewarded Showing");
//       },
//       onAdDismissedFullScreenContent: (ad) {
//         print("ℹ️ ${adType.name} Rewarded Closed");
//         _lastRewardedShow = DateTime.now();
//         ad.dispose();
//         _updateAdState(adType, false);
//         // Immediately load next ad
//         Future.delayed(Duration(seconds: 1), () {
//           initializeRewardedAdWithRetry(adType);
//         });
//       },
//       onAdFailedToShowFullScreenContent: (ad, error) {
//         print("❌ ${adType.name} Rewarded Failed to Show: $error");
//         ad.dispose();
//         _updateAdState(adType, false);
//         // Try loading again
//         Future.delayed(Duration(seconds: 2), () {
//           initializeRewardedAdWithRetry(adType);
//         });
//       },
//     );
//
//     rewardedAd.show(
//       onUserEarnedReward: (ad, reward) {
//         print("🎁 User earned reward: ${reward.amount} ${reward.type}");
//         onRewarded(); // Call the callback when user earns reward
//       },
//     );
//   }
//
//   /// Refresh ad (dispose and reload)
//   Future<void> refreshAd(AdType adType, {dynamic adSize}) async {
//     print("🔄 Refreshing ${adType.name}");
//
//     // Dispose old ad
//     _disposeSpecificAd(adType);
//     _updateAdState(adType, false);
//
//     // Wait before reloading
//     await Future.delayed(Duration(seconds: 2));
//
//     // Reload
//     await preloadAd(adType, adSize: adSize);
//   }
//
//   /// Dispose specific ad
//   void _disposeSpecificAd(AdType adType) {
//     switch (adType) {
//       case AdType.homeAd1:
//         _homeAd1?.dispose();
//         _homeAd1 = null;
//         break;
//       case AdType.homeAd2:
//         _homeAd2?.dispose();
//         _homeAd2 = null;
//         break;
//       case AdType.calendarAd:
//         _calendarAd?.dispose();
//         _calendarAd = null;
//         break;
//       case AdType.myGardenAd:
//         _myGardenAd?.dispose();
//         _myGardenAd = null;
//         break;
//       case AdType.discoverPlantAd:
//         _discoverPlantAd?.dispose();
//         _discoverPlantAd = null;
//         break;
//       case AdType.lensAd:
//         _lensAd?.dispose();
//         _lensAd = null;
//         break;
//       case AdType.courseTopicsAd1:
//         _courseTopicsAd1?.dispose();
//         _courseTopicsAd1 = null;
//       case AdType.courseTopicsAd2:
//         _courseTopicsAd2?.dispose();
//         _courseTopicsAd2 = null;
//       case AdType.courseTopicsAd3:
//         _courseTopicsAd3?.dispose();
//         _courseTopicsAd3 = null;
//     }
//   }
//
//   /// Dispose all ads
//   void disposeAds() {
//     _homeAd1?.dispose();
//     _homeAd2?.dispose();
//     _calendarAd?.dispose();
//     _myGardenAd?.dispose();
//     _discoverPlantAd?.dispose();
//     _courseTopicsAd1?.dispose();
//     _courseTopicsAd2?.dispose();
//     _courseTopicsAd3?.dispose();
//     _lensAd?.dispose();
//
//     for (var state in _adStates.values) {
//       state.isLoaded = false;
//     }
//
//     notifyListeners();
//   }
//
//   /// Get fill rate for an ad type
//   double getFillRate(AdType adType) {
//     final attempts = _loadAttempts[adType] ?? 0;
//     final success = _loadSuccess[adType] ?? 0;
//
//     if (attempts == 0) return 0.0;
//     return success / attempts;
//   }
//
//   /// Print analytics
//   void printAnalytics() {
//     print("\n📊 ===== AD ANALYTICS =====");
//     for (var adType in AdType.values) {
//       final attempts = _loadAttempts[adType] ?? 0;
//       final success = _loadSuccess[adType] ?? 0;
//       final failures = _loadFailures[adType] ?? 0;
//       final fillRate = getFillRate(adType);
//
//       if (attempts > 0) {
//         print(
//           "${adType.name}: ${(fillRate * 100).toStringAsFixed(1)}% ($success/$attempts) | Failures: $failures",
//         );
//       }
//     }
//     print("========================\n");
//   }
//
//   // Helper methods
//   void _updateAdState(AdType adType, bool isLoaded) {
//     final state = _adStates[adType];
//     if (state != null) {
//       state.isLoaded = isLoaded;
//       notifyListeners();
//     }
//   }
//
//   void _trackLoadAttempt(AdType adType) {
//     _loadAttempts[adType] = (_loadAttempts[adType] ?? 0) + 1;
//   }
//
//   void _trackLoadSuccess(AdType adType) {
//     _loadSuccess[adType] = (_loadSuccess[adType] ?? 0) + 1;
//   }
//
//   void _trackLoadFailure(AdType adType) {
//     _loadFailures[adType] = (_loadFailures[adType] ?? 0) + 1;
//   }
//
//   void _storeRewardedAd(AdType adType, RewardedAd ad) {
//     switch (adType) {
//       case AdType.lensAd:
//         _lensAd = ad;
//         break;
//       default:
//         ad.dispose();
//         throw ArgumentError('Invalid ad type for rewarded ad');
//     }
//   }
//
//   void _storeNativeAd(AdType adType, NativeAd ad) {
//     switch (adType) {
//       case AdType.homeAd1:
//         _homeAd1 = ad;
//         break;
//       case AdType.homeAd2:
//         _homeAd2 = ad;
//         break;
//       case AdType.calendarAd:
//         _calendarAd = ad;
//         break;
//       case AdType.myGardenAd:
//         _myGardenAd = ad;
//         break;
//       case AdType.discoverPlantAd:
//         _discoverPlantAd = ad;
//         break;
//       case AdType.courseTopicsAd1:
//         _courseTopicsAd1 = ad;
//         break;
//       case AdType.courseTopicsAd2:
//         _courseTopicsAd2 = ad;
//         break;
//       case AdType.courseTopicsAd3:
//         _courseTopicsAd3 = ad;
//         break;
//
//       default:
//         ad.dispose();
//         throw ArgumentError('Invalid ad type for native ad');
//     }
//   }
//
//   RewardedAd? _getRewardedAd(AdType adType) {
//     switch (adType) {
//       case AdType.lensAd:
//         return _lensAd;
//       default:
//         return null;
//     }
//   }
//
//   String? _getAdHelperId(AdType adType) {
//     switch (adType) {
//       case AdType.homeAd1:
//         return AdHelper.homeAd1;
//       case AdType.homeAd2:
//         return AdHelper.homeAd2;
//       case AdType.calendarAd:
//         return AdHelper.calendarAd;
//       case AdType.myGardenAd:
//         return AdHelper.myGardenAd;
//       case AdType.discoverPlantAd:
//         return AdHelper.discoverPlantAd;
//       case AdType.courseTopicsAd1:
//         return AdHelper.courseTopicsAd1;
//       case AdType.courseTopicsAd2:
//         return AdHelper.courseTopicsAd2;
//       case AdType.courseTopicsAd3:
//         return AdHelper.courseTopicsAd3;
//       case AdType.lensAd:
//         return AdHelper.lensAd;
//     }
//   }
// }
//
// class AdState {
//   bool isLoaded = false;
// }
//
// enum AdType {
//   homeAd1,
//   homeAd2,
//   calendarAd,
//   myGardenAd,
//   discoverPlantAd,
//   courseTopicsAd1,
//   courseTopicsAd2,
//   courseTopicsAd3,
//   lensAd,
// }


import 'dart:math';

import 'package:coding_tutor/ads/ad_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AdProvider with ChangeNotifier {
  // Ad State Management
  final Map<AdType, AdState> _adStates = {
    AdType.homeAd1: AdState(),
    AdType.homeAd2: AdState(),
    AdType.lensAd: AdState(),
    AdType.calendarAd: AdState(),
    AdType.myGardenAd: AdState(),
    AdType.discoverPlantAd: AdState(),
    AdType.courseTopicsAd1: AdState(),
    AdType.courseTopicsAd2: AdState(),
    AdType.courseTopicsAd3: AdState(),
  };

  // Ad instances
  NativeAd? _homeAd1;
  NativeAd? _homeAd2;
  NativeAd? _calendarAd;
  NativeAd? _myGardenAd;
  NativeAd? _discoverPlantAd;
  NativeAd? _courseTopicsAd1;
  NativeAd? _courseTopicsAd2;
  NativeAd? _courseTopicsAd3;
  RewardedAd? _lensAd;

  // ✅ IMPROVED: Google recommended retry settings
  final Map<AdType, DateTime?> _lastLoadAttempt = {};
  final Map<AdType, int> _retryCount = {};
  final Map<AdType, bool> _isLoading = {};

  static const Duration _reloadDelay = Duration(seconds: 60);
  static const int _maxRetries = 3; // Max 3 attempts
  static const int _initialDelaySeconds = 5; // First retry: 5s
  static const double _backoffMultiplier = 3.0; // 1→2→4 seconds
  static const int _maxDelaySeconds = 15; // Cap at 8s

  // Rewarded ad timing
  DateTime? _lastRewardedShow;
  static const Duration _minRewardedInterval = Duration(minutes: 2);

  // Analytics
  final Map<AdType, int> _loadAttempts = {};
  final Map<AdType, int> _loadSuccess = {};
  final Map<AdType, int> _loadFailures = {};

  // Getters for ad loaded states
  bool get isHomeAd1 => _adStates[AdType.homeAd1]!.isLoaded;
  bool get isHomeAd2 => _adStates[AdType.homeAd2]!.isLoaded;
  bool get isNotePageAd3 => _adStates[AdType.calendarAd]!.isLoaded;
  bool get isExercisePageAd1 => _adStates[AdType.myGardenAd]!.isLoaded;
  bool get isYVideoPageAd1 => _adStates[AdType.discoverPlantAd]!.isLoaded;
  bool get iscourseTopicsAd1 => _adStates[AdType.courseTopicsAd1]!.isLoaded;
  bool get iscourseTopicsAd2 => _adStates[AdType.courseTopicsAd2]!.isLoaded;
  bool get iscourseTopicsAd3 => _adStates[AdType.courseTopicsAd3]!.isLoaded;
  bool get isLensAd => _adStates[AdType.lensAd]!.isLoaded;

  // ✅ NEW: Loading state getters
  bool isAdLoading(AdType adType) => _isLoading[adType] ?? false;

  // Getter for ad instances
  NativeAd? get homeAd1 => _homeAd1;
  NativeAd? get homeAd2 => _homeAd2;
  NativeAd? get calendarAd => _calendarAd;
  NativeAd? get myGardenAd => _myGardenAd;
  NativeAd? get discoverPlantAd => _discoverPlantAd;
  NativeAd? get courseTopicsAd1 => _courseTopicsAd1;
  NativeAd? get courseTopicsAd2 => _courseTopicsAd2;
  NativeAd? get courseTopicsAd3 => _courseTopicsAd3;
  RewardedAd? get lensAd => _lensAd;

  /// ✅ IMPROVED: Check internet connectivity
  Future<bool> _hasInternet() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      debugPrint("❌ Connectivity check failed: $e");
      return false;
    }
  }

  /// ✅ IMPROVED: Calculate exponential backoff with jitter
  Duration _calculateBackoff(int attempt) {
    // Exponential backoff: initialDelay * (backoffMultiplier ^ (attempt - 1))
    int delaySeconds = (_initialDelaySeconds * pow(_backoffMultiplier, attempt - 1)).toInt();

    // Cap at max delay
    delaySeconds = min(delaySeconds, _maxDelaySeconds);

    // Add jitter (±25%)
    final jitter = delaySeconds * 0.25 * (2 * (0.5 - DateTime.now().millisecond / 1000));
    final finalDelay = max(0, (delaySeconds + jitter).toInt());

    debugPrint("🔄 Retry delay: ${finalDelay}s (Attempt $attempt)");
    return Duration(seconds: finalDelay);
  }

  /// ✅ IMPROVED: Preload ad with connectivity and loading checks
  Future<void> preloadAd(AdType adType, {dynamic adSize}) async {
    final state = _adStates[adType];

    // Check if already loaded
    if (state?.isLoaded == true) {
      debugPrint("✅ ${adType.name} already loaded");
      return;
    }

    // Check if already loading
    if (_isLoading[adType] == true) {
      debugPrint("⏳ ${adType.name} already loading, skipping...");
      return;
    }

    // ✅ NEW: Check internet connectivity
    if (!await _hasInternet()) {
      debugPrint("❌ No internet connection for ${adType.name}");
      return;
    }

    // Rate limiting: 30 seconds ke andar dobara load na karo
    final lastAttempt = _lastLoadAttempt[adType];
    if (lastAttempt != null &&
        DateTime.now().difference(lastAttempt) < _reloadDelay) {
      final remainingTime = _reloadDelay.inSeconds -
          DateTime.now().difference(lastAttempt).inSeconds;
      debugPrint("⏳ ${adType.name} rate limited, wait ${remainingTime}s");
      return;
    }

    _lastLoadAttempt[adType] = DateTime.now();
    _isLoading[adType] = true;
    notifyListeners();

    // Load appropriate ad type
    if (adType == AdType.lensAd) {
      await initializeRewardedAdWithRetry(adType);
    } else {
      await initializeNativeAdWithRetry(adType, adSize);
    }

    _isLoading[adType] = false;
    notifyListeners();
  }

  /// ✅ IMPROVED: Initialize rewarded ad with exponential backoff
  Future<void> initializeRewardedAdWithRetry(
      AdType adType, {
        int retryAttempt = 0,
      }) async {
    final adHelperId = _getAdHelperId(adType);
    if (adHelperId == null) {
      debugPrint("❌ No ad ID for ${adType.name}");
      return;
    }

    _trackLoadAttempt(adType);
    debugPrint("🎁 Loading ${adType.name} Rewarded (Attempt ${retryAttempt + 1}/$_maxRetries)");

    await RewardedAd.load(
      adUnitId: adHelperId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint("✅ ${adType.name} Rewarded Ad Loaded Successfully");
          _updateAdState(adType, true);
          _storeRewardedAd(adType, ad);
          _trackLoadSuccess(adType);
          _retryCount[adType] = 0; // Reset retry count on success
        },
        onAdFailedToLoad: (error) {
          debugPrint("❌ ${adType.name} Rewarded Failed: Code ${error.code} - ${error.message}");
          _trackLoadFailure(adType);
          _updateAdState(adType, false);

          // ✅ IMPROVED: Retry with exponential backoff
          if (retryAttempt < _maxRetries) {
            final backoffDelay = _calculateBackoff(retryAttempt + 1);
            debugPrint("🔄 Retrying ${adType.name} after ${backoffDelay.inSeconds}s");

            Future.delayed(backoffDelay, () {
              // Only retry if not already loaded and not loading
              if (!(_adStates[adType]?.isLoaded ?? false) &&
                  !(_isLoading[adType] ?? false)) {
                initializeRewardedAdWithRetry(
                  adType,
                  retryAttempt: retryAttempt + 1,
                );
              }
            });
          } else {
            debugPrint("❌ ${adType.name} failed after $_maxRetries attempts");
          }
        },
      ),
    );
  }

  /// ✅ IMPROVED: Initialize native ad with exponential backoff
  Future<void> initializeNativeAdWithRetry(
      AdType adType,
      dynamic adSize, {
        int retryAttempt = 0,
      }) async {
    final adHelperId = _getAdHelperId(adType);
    if (adHelperId == null) {
      debugPrint("❌ No ad ID for ${adType.name}");
      return;
    }

    _trackLoadAttempt(adType);
    debugPrint("📱 Loading ${adType.name} Native (Attempt ${retryAttempt + 1}/$_maxRetries)");

    final nativeAd = NativeAd(
      adUnitId: adHelperId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint("✅ ${adType.name} Native Ad Loaded Successfully");
          _updateAdState(adType, true);
          _storeNativeAd(adType, ad as NativeAd);
          _trackLoadSuccess(adType);
          _retryCount[adType] = 0; // Reset retry count on success
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint("❌ ${adType.name} Native Failed: Code ${error.code} - ${error.message}");
          _trackLoadFailure(adType);
          ad.dispose();

          // ✅ IMPROVED: Retry with exponential backoff
          if (retryAttempt < _maxRetries) {
            final backoffDelay = _calculateBackoff(retryAttempt + 1);
            debugPrint("🔄 Retrying ${adType.name} after ${backoffDelay.inSeconds}s");

            Future.delayed(backoffDelay, () {
              // Only retry if not already loaded and not loading
              if (!(_adStates[adType]?.isLoaded ?? false) &&
                  !(_isLoading[adType] ?? false)) {
                initializeNativeAdWithRetry(
                  adType,
                  adSize,
                  retryAttempt: retryAttempt + 1,
                );
              }
            });
          } else {
            debugPrint("❌ ${adType.name} failed after $_maxRetries attempts");
            _updateAdState(adType, false);
          }
        },
        onAdClicked: (ad) {
          debugPrint("👆 ${adType.name} clicked");
        },
        onAdImpression: (ad) {
          debugPrint("👁️ ${adType.name} impression recorded");
        },
      ),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(templateType: adSize),
    );

    await nativeAd.load();
  }

  /// Legacy methods (keeping for backward compatibility)
  Future<void> initializeRewardedAd(AdType adType) async {
    await initializeRewardedAdWithRetry(adType);
  }

  Future<void> initializeNativeAd(AdType adType, adSize) async {
    await initializeNativeAdWithRetry(adType, adSize);
  }

  /// Check if rewarded can be shown
  bool canShowRewarded() {
    if (_lastRewardedShow == null) return true;

    final timeSinceLastShow = DateTime.now().difference(_lastRewardedShow!);
    return timeSinceLastShow > _minRewardedInterval;
  }

  /// ✅ IMPROVED: Show rewarded ad with better error handling
  void showRewardedAd(AdType adType, {required Function() onRewarded}) {
    // Check timing restrictions
    if (!canShowRewarded()) {
      final remaining = _minRewardedInterval.inMinutes -
          DateTime.now().difference(_lastRewardedShow!).inMinutes;
      debugPrint("⏳ Too soon! Wait $remaining more minute(s)");
      return;
    }

    final adState = _adStates[adType];
    final rewardedAd = _getRewardedAd(adType);

    // Check if ad is loaded
    if (adState?.isLoaded != true || rewardedAd == null) {
      debugPrint("⚠️ ${adType.name} not ready. Loading now...");
      // Preload for next time
      preloadAd(adType);
      return;
    }

    // Setup callbacks
    rewardedAd.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint("📺 ${adType.name} showing to user");
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint("👋 ${adType.name} dismissed");
        _lastRewardedShow = DateTime.now();
        ad.dispose();
        _updateAdState(adType, false);

        // Immediately load next ad with delay
        Future.delayed(const Duration(seconds: 2), () {
          preloadAd(adType);
        });
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint("❌ ${adType.name} failed to show: ${error.message}");
        ad.dispose();
        _updateAdState(adType, false);

        // Try loading again with delay
        Future.delayed(const Duration(seconds: 3), () {
          preloadAd(adType);
        });
      },
      onAdImpression: (ad) {
        debugPrint("👁️ ${adType.name} impression");
      },
    );

    // Show the ad
    rewardedAd.show(
      onUserEarnedReward: (ad, reward) {
        debugPrint("🎉 Reward earned: ${reward.amount} ${reward.type}");
        onRewarded(); // Call the callback
      },
    );
  }

  /// ✅ IMPROVED: Refresh ad with proper cleanup
  Future<void> refreshAd(AdType adType, {dynamic adSize}) async {
    debugPrint("🔄 Refreshing ${adType.name}");

    // Dispose old ad
    _disposeSpecificAd(adType);
    _updateAdState(adType, false);

    // Wait before reloading (prevent rate limiting)
    await Future.delayed(const Duration(seconds: 2));

    // Reload
    await preloadAd(adType, adSize: adSize);
  }

  /// ✅ NEW: Preload all ads with staggered timing
  Future<void> preloadAllAds(dynamic adSize) async {
    debugPrint("🚀 Preloading all ads with staggered timing...");

    // Priority 1: Rewarded ad (highest value)
    await preloadAd(AdType.lensAd);
    await Future.delayed(const Duration(milliseconds: 800));

    // Priority 2: Home screen ads (most visible)
    await preloadAd(AdType.homeAd1, adSize: adSize);
    await Future.delayed(const Duration(milliseconds: 500));

    await preloadAd(AdType.homeAd2, adSize: adSize);
    await Future.delayed(const Duration(milliseconds: 500));

    // Priority 3: Other screen ads
    await preloadAd(AdType.calendarAd, adSize: adSize);
    await Future.delayed(const Duration(milliseconds: 500));

    await preloadAd(AdType.myGardenAd, adSize: adSize);
    await Future.delayed(const Duration(milliseconds: 500));

    await preloadAd(AdType.discoverPlantAd, adSize: adSize);
    await Future.delayed(const Duration(milliseconds: 500));

    // Priority 4: Course topic ads
    await preloadAd(AdType.courseTopicsAd1, adSize: adSize);
    await Future.delayed(const Duration(milliseconds: 500));

    await preloadAd(AdType.courseTopicsAd2, adSize: adSize);
    await Future.delayed(const Duration(milliseconds: 500));

    await preloadAd(AdType.courseTopicsAd3, adSize: adSize);

    debugPrint("✅ All ads preload sequence initiated");
  }

  /// Dispose specific ad
  void _disposeSpecificAd(AdType adType) {
    switch (adType) {
      case AdType.homeAd1:
        _homeAd1?.dispose();
        _homeAd1 = null;
        break;
      case AdType.homeAd2:
        _homeAd2?.dispose();
        _homeAd2 = null;
        break;
      case AdType.calendarAd:
        _calendarAd?.dispose();
        _calendarAd = null;
        break;
      case AdType.myGardenAd:
        _myGardenAd?.dispose();
        _myGardenAd = null;
        break;
      case AdType.discoverPlantAd:
        _discoverPlantAd?.dispose();
        _discoverPlantAd = null;
        break;
      case AdType.lensAd:
        _lensAd?.dispose();
        _lensAd = null;
        break;
      case AdType.courseTopicsAd1:
        _courseTopicsAd1?.dispose();
        _courseTopicsAd1 = null;
        break;
      case AdType.courseTopicsAd2:
        _courseTopicsAd2?.dispose();
        _courseTopicsAd2 = null;
        break;
      case AdType.courseTopicsAd3:
        _courseTopicsAd3?.dispose();
        _courseTopicsAd3 = null;
        break;
    }
  }

  /// Dispose all ads
  void disposeAds() {
    debugPrint("🗑️ Disposing all ads");

    _homeAd1?.dispose();
    _homeAd2?.dispose();
    _calendarAd?.dispose();
    _myGardenAd?.dispose();
    _discoverPlantAd?.dispose();
    _courseTopicsAd1?.dispose();
    _courseTopicsAd2?.dispose();
    _courseTopicsAd3?.dispose();
    _lensAd?.dispose();

    for (var state in _adStates.values) {
      state.isLoaded = false;
    }

    notifyListeners();
  }

  /// Get fill rate for an ad type
  double getFillRate(AdType adType) {
    final attempts = _loadAttempts[adType] ?? 0;
    final success = _loadSuccess[adType] ?? 0;

    if (attempts == 0) return 0.0;
    return success / attempts;
  }

  /// ✅ IMPROVED: Print detailed analytics
  void printAnalytics() {
    debugPrint("\n📊 ========== AD ANALYTICS ==========");

    int totalLoaded = 0;
    int totalAttempts = 0;

    for (var adType in AdType.values) {
      final attempts = _loadAttempts[adType] ?? 0;
      final success = _loadSuccess[adType] ?? 0;
      final failures = _loadFailures[adType] ?? 0;
      final fillRate = getFillRate(adType);
      final isLoaded = _adStates[adType]?.isLoaded ?? false;

      if (attempts > 0) {
        totalAttempts += attempts;
        totalLoaded += success;

        final status = isLoaded ? "✅" : "❌";
        debugPrint(
          "$status ${adType.name.padRight(20)} | "
              "Fill: ${(fillRate * 100).toStringAsFixed(1)}% | "
              "Success: $success/$attempts | "
              "Fails: $failures",
        );
      }
    }

    if (totalAttempts > 0) {
      final overallFillRate = (totalLoaded / totalAttempts * 100).toStringAsFixed(1);
      debugPrint("\n📈 Overall Fill Rate: $overallFillRate% ($totalLoaded/$totalAttempts)");
    }

    debugPrint("====================================\n");
  }

  // Helper methods
  void _updateAdState(AdType adType, bool isLoaded) {
    final state = _adStates[adType];
    if (state != null) {
      state.isLoaded = isLoaded;
      notifyListeners();
    }
  }

  void _trackLoadAttempt(AdType adType) {
    _loadAttempts[adType] = (_loadAttempts[adType] ?? 0) + 1;
  }

  void _trackLoadSuccess(AdType adType) {
    _loadSuccess[adType] = (_loadSuccess[adType] ?? 0) + 1;
  }

  void _trackLoadFailure(AdType adType) {
    _loadFailures[adType] = (_loadFailures[adType] ?? 0) + 1;
  }

  void _storeRewardedAd(AdType adType, RewardedAd ad) {
    switch (adType) {
      case AdType.lensAd:
        _lensAd = ad;
        break;
      default:
        debugPrint("⚠️ Invalid ad type for rewarded ad: $adType. Disposing ad safely.");
        ad.dispose();
    }
  }

  void _storeNativeAd(AdType adType, NativeAd ad) {
    switch (adType) {
      case AdType.homeAd1:
        _homeAd1 = ad;
        break;
      case AdType.homeAd2:
        _homeAd2 = ad;
        break;
      case AdType.calendarAd:
        _calendarAd = ad;
        break;
      case AdType.myGardenAd:
        _myGardenAd = ad;
        break;
      case AdType.discoverPlantAd:
        _discoverPlantAd = ad;
        break;
      case AdType.courseTopicsAd1:
        _courseTopicsAd1 = ad;
        break;
      case AdType.courseTopicsAd2:
        _courseTopicsAd2 = ad;
        break;
      case AdType.courseTopicsAd3:
        _courseTopicsAd3 = ad;
        break;
      default:
        debugPrint("⚠️ Invalid ad type for native ad: $adType. Disposing ad safely.");
        ad.dispose();
    }
  }


  RewardedAd? _getRewardedAd(AdType adType) {
    switch (adType) {
      case AdType.lensAd:
        return _lensAd;
      default:
        return null;
    }
  }

  String? _getAdHelperId(AdType adType) {
    switch (adType) {
      case AdType.homeAd1:
        return AdHelper.homeAd1;
      case AdType.homeAd2:
        return AdHelper.homeAd2;
      case AdType.calendarAd:
        return AdHelper.calendarAd;
      case AdType.myGardenAd:
        return AdHelper.myGardenAd;
      case AdType.discoverPlantAd:
        return AdHelper.discoverPlantAd;
      case AdType.courseTopicsAd1:
        return AdHelper.courseTopicsAd1;
      case AdType.courseTopicsAd2:
        return AdHelper.courseTopicsAd2;
      case AdType.courseTopicsAd3:
        return AdHelper.courseTopicsAd3;
      case AdType.lensAd:
        return AdHelper.lensAd;
    }
  }

  @override
  void dispose() {
    disposeAds();
    super.dispose();
  }
}

class AdState {
  bool isLoaded = false;
}

enum AdType {
  homeAd1,
  homeAd2,
  calendarAd,
  myGardenAd,
  discoverPlantAd,
  courseTopicsAd1,
  courseTopicsAd2,
  courseTopicsAd3,
  lensAd,
}

