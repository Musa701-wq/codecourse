/*
import 'package:coding_tutor/ads/ads_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../core/App_theme.dart';
import '../in_app_purchase/credit_purchase_screen.dart';
import 'premium_dialog.dart';
import 'course_topics_screen.dart';

class CourseLevelSelectionScreen extends StatefulWidget {
  final String courseTitle;
  const CourseLevelSelectionScreen({super.key, required this.courseTitle});

  @override
  State<CourseLevelSelectionScreen> createState() =>
      _CourseLevelSelectionScreenState();
}

class _CourseLevelSelectionScreenState
    extends State<CourseLevelSelectionScreen> {
  @override
  void initState() {
    super.initState();
    // Preload ads after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        final adProvider = context.read<AdProvider>();
        adProvider.preloadAd(
          AdType.discoverPlantAd,
          adSize: TemplateType.small,
        );
        debugPrint('[HomeScreen] ✅ Ads preload requested');
      } catch (e) {
        debugPrint('[HomeScreen] ⚠️ Ad preload error: $e');
      }
    });
  }

  String _beginnerTitleFor(String title) {
    if (title.toLowerCase().contains('html')) {
      return 'html for Beginners';
    }
    else if (title.toLowerCase().contains('css'))
    {
      return 'css for Beginners';
    }  else if (title.toLowerCase().contains('script'))
    {
      return 'JavaScript for Beginners';
    }
    else if (title.toLowerCase().contains('java'))
    {
      return 'java for Beginners';
    }
    else if (title.toLowerCase().contains('python'))
    {
      return 'Python for Beginners';
    }

    else if (title.toLowerCase().contains('c++') ||
        title.toLowerCase().contains('cpp')) {
      return 'C++ for Beginners'; // Add this line
    }
    return 'Java for Beginners';
  }

  String? _intermediateTitleFor(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('html')) {
      return 'HTML Intermediate Level';
    }
    if (lower.contains('css')) {
      return 'CSS Intermediate Level';
    }
    if (lower.contains('javascript') || lower.contains('js')) {
      return 'JavaScript Intermediate Level';
    }
    if (lower.contains('python')) {
      return 'Python Intermediate Level';
    }
    if (lower.contains('java')) {
      return 'Java Intermediate Level';
    }
    if (lower.contains('c++') || lower.contains('cpp')) {
      return 'C++ Intermediate Level';
    }
    return null;
  }

  String? _advancedTitleFor(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('javascript') || lower.contains('js')) {
      return 'JavaScript Advanced Level';
    }
    if (lower.contains('css')) {
      return 'CSS Advanced Level';
    }
    if (lower.contains('html')) {
      return 'HTML Advanced Level';
    }
    if (lower.contains('python')) {
      return 'Python Advanced Level';
    }
    if (lower.contains('java')) {
      return 'Java Advanced Level';
    }
    if (lower.contains('c++') || lower.contains('cpp')) {
      return 'C++ Advanced Level';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final courseLower = widget.courseTitle.toLowerCase();
    final intermediateTitle = _intermediateTitleFor(widget.courseTitle);
    final advancedTitle = _advancedTitleFor(widget.courseTitle);
    final advancedColor = courseLower.contains('python')
        ? AppColors.secondary
        : courseLower.contains('html')
            ? AppColors.primary
            : courseLower.contains('css')
                ? AppColors.secondary.withOpacity(0.9)
                : (courseLower.contains('java') ||
                        courseLower.contains('c++') ||
                        courseLower.contains('cpp'))
                    ? AppColors.primary.withOpacity(0.9)
                    : AppColors.primary.withOpacity(0.8);

    Widget levelTile({
      required String label,
      required String subtitle,
      required IconData icon,
      required Color color,
      required bool isLocked,
      required VoidCallback onTap,
    }) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [color.withOpacity(0.15), color.withOpacity(0.05)]
                : [color.withOpacity(0.1), color.withOpacity(0.03)],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(isDark ? 0.2 : 0.1),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            splashColor: color.withOpacity(0.1),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: color.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              label,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                fontFamily: 'custom',
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (!isLocked)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.secondary.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  'FREE',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    fontFamily: 'custom',
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                            height: 1.4,
                            fontFamily: 'custom',
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: color.withOpacity(0.7),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary.withOpacity(isDark ? 0.15 : 0.1),
                    colorScheme.secondary.withOpacity(isDark ? 0.08 : 0.05),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: colorScheme.onSurface,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Choose Your Level',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      fontFamily: 'custom',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.courseTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'custom',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Select your experience level. Beginner level is completely free to start your learning journey!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                      height: 1.5,
                      fontFamily: 'custom',
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Levels List
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Beginner Level
                      levelTile(
                        label: 'Beginner',
                        subtitle:
                            'Perfect for starters. Learn fundamentals, basic syntax, and build your first programs.',
                        icon: Icons.rocket_launch_outlined,
                        color: AppColors.primary,
                        isLocked: false,
                        onTap: () {
                          final beginnerTitle = _beginnerTitleFor(
                            widget.courseTitle,
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CourseTopicsScreen(
                                courseTitle: beginnerTitle,
                              ),
                            ),
                          );
                        },
                      ),

                      // ad to show
                      _buildNativeAd(context, AdType.discoverPlantAd),

                      // Intermediate Level
                      levelTile(
                        label: 'Intermediate',
                        subtitle:
                            'Dive deeper into concepts, design patterns, and build more complex applications.',
                        icon: Icons.trending_up_rounded,
                        color: AppColors.secondary,
                        isLocked: true,
                        onTap: () {
                          if (intermediateTitle != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CourseTopicsScreen(
                                  courseTitle: intermediateTitle,
                                  showPremiumDialog: true,
                                ),
                              ),
                          );
                          } else {
                            showPremiumDialog(
                              context,
                              'Intermediate',
                              AppColors.secondary,
                              onUnlock: _openPurchaseScreen,
                            );
                          }
                        },
                      ),

                      // Advanced Level
                      levelTile(
                        label: 'Advanced',
                        subtitle:
                            'Master advanced topics, work on real-world projects, and become an expert.',
                        icon: Icons.star_outline_rounded,
                        color: advancedColor,
                        isLocked: true,
                        onTap: () {
                          if (advancedTitle != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CourseTopicsScreen(
                                  courseTitle: advancedTitle,
                                  showPremiumDialog: true,
                                  premiumLevelLabel: 'Advanced',
                                  premiumColor: advancedColor,
                                ),
                              ),
                          );
                          } else {
                            showPremiumDialog(
                              context,
                              'Advanced',
                              AppColors.primary.withOpacity(0.8),
                              onUnlock: _openPurchaseScreen,
                            );
                          }
                        },
                      ),

                      // Info Card
              */
/*        Container(
                        margin: const EdgeInsets.only(top: 24),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'More levels coming soon! Stay tuned for updates.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.8),
                                  fontFamily: 'custom',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),*//*

                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNativeAd(BuildContext context, AdType adType) {
    final adProvider = context.watch<AdProvider>();
    final isAdLoaded = adType == AdType.discoverPlantAd
        ? adProvider.isYVideoPageAd1
        : adProvider.isHomeAd2;
    final nativeAd = adType == AdType.discoverPlantAd
        ? adProvider.discoverPlantAd
        : adProvider.homeAd2;

    if (!isAdLoaded || nativeAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 130,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: AdWidget(ad: nativeAd),
      ),
    );
  }

  void _openPurchaseScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CreditsPurchaseScreen(),
      ),
    );
  }
}
*/
import 'package:coding_tutor/ads/ads_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../core/App_theme.dart';
import '../in_app_purchase/credit_purchase_screen.dart';
import 'premium_dialog.dart';
import 'course_topics_screen.dart';

class CourseLevelSelectionScreen extends StatefulWidget {
  final String courseTitle;
  const CourseLevelSelectionScreen({super.key, required this.courseTitle});

  @override
  State<CourseLevelSelectionScreen> createState() =>
      _CourseLevelSelectionScreenState();
}

class _CourseLevelSelectionScreenState
    extends State<CourseLevelSelectionScreen> {
  @override
  void initState() {
    super.initState();
    // Preload ads after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        final adProvider = context.read<AdProvider>();
        adProvider.preloadAd(
          AdType.discoverPlantAd,
          adSize: TemplateType.small,
        );
        debugPrint('[HomeScreen] ✅ Ads preload requested');
      } catch (e) {
        debugPrint('[HomeScreen] ⚠️ Ad preload error: $e');
      }
    });
  }

  String _beginnerTitleFor(String title) {
    if (title.toLowerCase().contains('html')) {
      return 'html for Beginners';
    } else if (title.toLowerCase().contains('css')) {
      return 'css for Beginners';
    } else if (title.toLowerCase().contains('script')) {
      return 'JavaScript for Beginners';
    } else if (title.toLowerCase().contains('java')) {
      return 'java for Beginners';
    } else if (title.toLowerCase().contains('python')) {
      return 'Python for Beginners';
    } else if (title.toLowerCase().contains('c++') ||
        title.toLowerCase().contains('cpp')) {
      return 'C++ for Beginners'; // Add this line
    }
    return 'Java for Beginners';
  }

  String? _intermediateTitleFor(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('html')) {
      return 'HTML Intermediate Level';
    }
    if (lower.contains('css')) {
      return 'CSS Intermediate Level';
    }
    if (lower.contains('javascript') || lower.contains('js')) {
      return 'JavaScript Intermediate Level';
    }
    if (lower.contains('python')) {
      return 'Python Intermediate Level';
    }
    if (lower.contains('java')) {
      return 'Java Intermediate Level';
    }
    if (lower.contains('c++') || lower.contains('cpp')) {
      return 'C++ Intermediate Level';
    }
    return null;
  }

  String? _advancedTitleFor(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('javascript') || lower.contains('js')) {
      return 'JavaScript Advanced Level';
    }
    if (lower.contains('css')) {
      return 'CSS Advanced Level';
    }
    if (lower.contains('html')) {
      return 'HTML Advanced Level';
    }
    if (lower.contains('python')) {
      return 'Python Advanced Level';
    }
    if (lower.contains('java')) {
      return 'Java Advanced Level';
    }
    if (lower.contains('c++') || lower.contains('cpp')) {
      return 'C++ Advanced Level';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final courseLower = widget.courseTitle.toLowerCase();
    final intermediateTitle = _intermediateTitleFor(widget.courseTitle);
    final advancedTitle = _advancedTitleFor(widget.courseTitle);
    final advancedColor = courseLower.contains('python')
        ? AppColors.secondary
        : courseLower.contains('html')
        ? AppColors.primary
        : courseLower.contains('css')
        ? AppColors.secondary.withOpacity(0.9)
        : (courseLower.contains('java') ||
        courseLower.contains('c++') ||
        courseLower.contains('cpp'))
        ? AppColors.primary.withOpacity(0.9)
        : AppColors.primary.withOpacity(0.8);

    Widget levelTile({
      required String label,
      required String subtitle,
      required IconData icon,
      required Color color,
      required bool isLocked,
      required VoidCallback onTap,
    }) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2433) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? const Color(0xFF2A3447)
                : Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Icon Container
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                                fontFamily: 'custom',
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (!isLocked)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00D9A5),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'FREE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    fontFamily: 'custom',
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white.withOpacity(0.6)
                                : Colors.black.withOpacity(0.6),
                            fontSize: 14,
                            height: 1.3,
                            fontFamily: 'custom',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Arrow Icon
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: isDark
                        ? Colors.white.withOpacity(0.4)
                        : Colors.black.withOpacity(0.4),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1419) : const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E2433)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF2A3447)
                              : Colors.grey.withOpacity(0.2),
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: isDark ? Colors.white : Colors.black,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Course Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      widget.courseTitle.toUpperCase(),
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        letterSpacing: 0.5,
                        fontFamily: 'custom',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Choose\n',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w700,
                            fontSize: 32,
                            height: 1.2,
                            fontFamily: 'custom',
                          ),
                        ),
                        TextSpan(
                          text: 'Your Level',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 32,
                            height: 1.2,
                            fontFamily: 'custom',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Subtitle
                  Text(
                    'Select your experience level to customize your learning path. Start your journey into the world of code.',
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withOpacity(0.6)
                          : Colors.black.withOpacity(0.6),
                      fontSize: 15,
                      height: 1.5,
                      fontFamily: 'custom',
                    ),
                  ),
                ],
              ),
            ),

            // Levels List
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Beginner Level
                      levelTile(
                        label: 'Beginner',
                        subtitle:
                        'Learn fundamentals, basic syntax, and build your fir...',
                        icon: Icons.rocket_launch_rounded,
                        color: const Color(0xFF5B7FFF),
                        isLocked: false,
                        onTap: () {
                          final beginnerTitle = _beginnerTitleFor(
                            widget.courseTitle,
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CourseTopicsScreen(
                                courseTitle: beginnerTitle,
                              ),
                            ),
                          );
                        },
                      ),

                      // ad to show
                      _buildNativeAd(context, AdType.discoverPlantAd),

                      // Intermediate Level
                      levelTile(
                        label: 'Intermediate',
                        subtitle:
                        'Dive deeper into concepts, design patterns, and...',
                        icon: Icons.trending_up_rounded,
                        color: const Color(0xFF00D9A5),
                        isLocked: true,
                        onTap: () {
                          if (intermediateTitle != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CourseTopicsScreen(
                                  courseTitle: intermediateTitle,
                                  showPremiumDialog: true,
                                ),
                              ),
                            );
                          } else {
                            showPremiumDialog(
                              context,
                              'Intermediate',
                              AppColors.secondary,
                              onUnlock: _openPurchaseScreen,
                            );
                          }
                        },
                      ),

                      // Advanced Level
                      levelTile(
                        label: 'Advanced',
                        subtitle:
                        'Master advanced topics, system design, and...',
                        icon: Icons.auto_awesome_rounded,
                        color: const Color(0xFFB580FF),
                        isLocked: true,
                        onTap: () {
                          if (advancedTitle != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CourseTopicsScreen(
                                  courseTitle: advancedTitle,
                                  showPremiumDialog: true,
                                  premiumLevelLabel: 'Advanced',
                                  premiumColor: advancedColor,
                                ),
                              ),
                            );
                          } else {
                            showPremiumDialog(
                              context,
                              'Advanced',
                              AppColors.primary.withOpacity(0.8),
                              onUnlock: _openPurchaseScreen,
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNativeAd(BuildContext context, AdType adType) {
    final adProvider = context.watch<AdProvider>();
    final isAdLoaded = adType == AdType.discoverPlantAd
        ? adProvider.isYVideoPageAd1
        : adProvider.isHomeAd2;
    final nativeAd = adType == AdType.discoverPlantAd
        ? adProvider.discoverPlantAd
        : adProvider.homeAd2;

    if (!isAdLoaded || nativeAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 130,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: AdWidget(ad: nativeAd),
      ),
    );
  }

  void _openPurchaseScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CreditsPurchaseScreen(),
      ),
    );
  }
}