// import 'package:flutter/foundation.dart';
// import 'dart:io';
//
// class AdHelper {
//   // iOS ad unit IDs (production)
//   static const Map<String, String> _iosAds = {
//     'homeAd1': 'ca-app-pub-3774337907915828/1575027464', // native ad
//     'homeAd2': 'ca-app-pub-3774337907915828/6398326345', // native ad
//     'calendarAd': 'ca-app-pub-3774337907915828/3855923488', // native ad
//     'myGardenAd': 'ca-app-pub-3774337907915828/6911114625', // native ad
//     'discoverPlantAd': 'ca-app-pub-3774337907915828/1738678993', // native ad
//     'courseTopicsAd1': 'ca-app-pub-3774337907915828/5322700789', // native ad
//     'courseTopicsAd2': 'ca-app-pub-3774337907915828/8641346306', // native ad
//     'courseTopicsAd3': 'ca-app-pub-3774337907915828/4887586512', // native ad
//     'lensAd': 'ca-app-pub-3774337907915828/6448080193', // REWARDED ad
//   };
//
//   // Test ad unit IDs (iOS)
//   static const Map<String, String> _testAds = {
//     'nativeIOS': 'ca-app-pub-3940256099942544/3986624511',
//     'rewardedIOS': 'ca-app-pub-3940256099942544/1712485313',
//   };
//
//   /// Use test ads in debug mode
//   static bool get useTestAds => kDebugMode;
//
//   static String _getAd(String adName, {bool isRewarded = false}) {
//     if (!Platform.isIOS) {
//       throw UnsupportedError('This app only supports iOS ads');
//     }
//
//     // Test mode
//     if (useTestAds) {
//       return isRewarded ? _testAds['rewardedIOS']! : _testAds['nativeIOS']!;
//     }
//
//     // Production mode
//     final adId = _iosAds[adName];
//     if (adId == null || adId.contains('XXXXXXX')) {
//       print(
//         "⚠️ Warning: Real ad ID not configured for $adName, using test ad",
//       );
//       return isRewarded ? _testAds['rewardedIOS']! : _testAds['nativeIOS']!;
//     }
//     return adId;
//   }
//
//   // Ad getters
//   static String get homeAd1 => _getAd('homeAd1');
//   static String get homeAd2 => _getAd('homeAd2');
//   static String get lensAd => _getAd('lensAd', isRewarded: true);
//   static String get calendarAd => _getAd('calendarAd');
//   static String get myGardenAd => _getAd('myGardenAd');
//   static String get discoverPlantAd => _getAd('discoverPlantAd');
//   static String get courseTopicsAd1 => _getAd('courseTopicsAd1');
//   static String get courseTopicsAd2 => _getAd('courseTopicsAd2');
//   static String get courseTopicsAd3 => _getAd('courseTopicsAd3');
// }


import 'package:flutter/foundation.dart';
import 'dart:io';

class AdHelper {
  // iOS ad unit IDs (production)
  static const Map<String, String> _iosAds = {
    'homeAd1': 'ca-app-pub-3774337907915828/1575027464', // native ad
    'homeAd2': 'ca-app-pub-3774337907915828/6398326345', // native ad
    'calendarAd': 'ca-app-pub-3774337907915828/3855923488', // native ad
    'myGardenAd': 'ca-app-pub-3774337907915828/6911114625', // native ad
    'discoverPlantAd': 'ca-app-pub-3774337907915828/1738678993', // native ad
    'courseTopicsAd1': 'ca-app-pub-3774337907915828/5322700789', // native ad
    'courseTopicsAd2': 'ca-app-pub-3774337907915828/8641346306', // native ad
    'courseTopicsAd3': 'ca-app-pub-3774337907915828/4887586512', // native ad
    'lensAd': 'ca-app-pub-3774337907915828/6448080193', // REWARDED ad
  };

  static String _getAd(String adName) {
    if (!Platform.isIOS) {
      throw UnsupportedError('This app only supports iOS ads');
    }

    final adId = _iosAds[adName];
    if (adId == null || adId.contains('XXXXXXX')) {
      throw Exception("⚠️ Real ad ID not configured for $adName");
    }
    return adId;
  }

  // Ad getters
  static String get homeAd1 => _getAd('homeAd1');
  static String get homeAd2 => _getAd('homeAd2');
  static String get lensAd => _getAd('lensAd');
  static String get calendarAd => _getAd('calendarAd');
  static String get myGardenAd => _getAd('myGardenAd');
  static String get discoverPlantAd => _getAd('discoverPlantAd');
  static String get courseTopicsAd1 => _getAd('courseTopicsAd1');
  static String get courseTopicsAd2 => _getAd('courseTopicsAd2');
  static String get courseTopicsAd3 => _getAd('courseTopicsAd3');
}
