/*
import 'package:coding_tutor/ads/ads_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../services/course_service.dart';
import '../models/course_model.dart';
import 'course_topics_screen.dart';

class AllCoursesScreen extends StatefulWidget {
  const AllCoursesScreen({super.key});

  @override
  State<AllCoursesScreen> createState() => _AllCoursesScreenState();
}

class _AllCoursesScreenState extends State<AllCoursesScreen> {
  @override
  void initState() {
    super.initState();
    // Preload ads after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        final adProvider = context.read<AdProvider>();
        adProvider.preloadAd(AdType.myGardenAd, adSize: TemplateType.medium);
        debugPrint(
          '[AllCoursesScreen] ✅ Medium ad preload requested',
        ); // ✅ Fixed screen name
      } catch (e) {
        debugPrint(
          '[AllCoursesScreen] ⚠️ Medium ad preload error: $e',
        ); // ✅ Fixed screen name
      }
    });
  }

  Future<List<Course>> _load() {
    return CourseService.loadCourses();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'All Courses',
          style: TextStyle(fontFamily: 'custom'),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        foregroundColor: colorScheme.onSurface,
      ),

      body: FutureBuilder<List<Course>>(
        future: _load(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load courses',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'custom',
                ),
              ),
            );
          }

          final courses = snapshot.data ?? [];
          if (courses.isEmpty) {
            return Center(
              child: Text(
                'No courses available',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'custom',
                ),
              ),
            );
          }

            final sortedCourses = List<Course>.from(courses)
              ..sort((a, b) => _courseLevelRank(a).compareTo(
                    _courseLevelRank(b),
                  ));

          // Build a scrollable column with courses and ad
          final List<Widget> courseWidgets = [];
            for (int i = 0; i < sortedCourses.length; i++) {
              final course = sortedCourses[i];
              final levelLabel = _courseLevelLabel(course);
            courseWidgets.add(
              Material(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CourseTopicsScreen(courseTitle: course.title),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.menu_book, color: colorScheme.primary),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course.title,
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontFamily: 'custom',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                course.language,
                                style: TextStyle(
                                    color:
                                        colorScheme.onSurface.withOpacity(0.7),
                                  fontFamily: 'custom',
                                  fontSize: 13,
                                ),
                              ),
                                if (levelLabel != 'Beginner') ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    levelLabel,
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontFamily: 'custom',
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
            );

            // Insert ad after the 3rd course
            if (i == 2) {
              courseWidgets.add(_buildNativeAd(context, AdType.myGardenAd));
            }

            // Add spacing between items
            courseWidgets.add(const SizedBox(height: 12));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: courseWidgets),
          );
        },
      ),
    );
  }

  Widget _buildNativeAd(BuildContext context, AdType adType) {
    final adProvider = context.watch<AdProvider>();

    // ✅ CORRECTED: Use the proper getters for myGardenAd
    final isAdLoaded = adType == AdType.myGardenAd
        ? adProvider
              .isExercisePageAd1 // This is the correct getter
        : adProvider.isHomeAd2;

    final nativeAd = adType == AdType.myGardenAd
        ? adProvider
              .myGardenAd // This is the correct getter
        : adProvider.homeAd2;

    if (!isAdLoaded || nativeAd == null) {
      return Container(
        height: 300,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        ),
        child: Center(
          child: Text(
            'Loading medium ad...',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 350, // Medium ad height
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AdWidget(ad: nativeAd),
      ),
    );
  }
}

int _courseLevelRank(Course course) {
  final title = course.title.toLowerCase();
  if (title.contains('advanced')) return 0;
  if (title.contains('intermediate')) return 1;
  return 2;
}

String _courseLevelLabel(Course course) {
  final title = course.title.toLowerCase();
  if (title.contains('advanced')) return 'Advanced Level';
  if (title.contains('intermediate')) return 'Intermediate Level';
  return 'Beginner Level';
}
*/
import 'package:coding_tutor/ads/ads_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../services/course_service.dart';
import '../models/course_model.dart';
import 'course_topics_screen.dart';

class AllCoursesScreen extends StatefulWidget {
  const AllCoursesScreen({super.key});

  @override
  State<AllCoursesScreen> createState() => _AllCoursesScreenState();
}

class _AllCoursesScreenState extends State<AllCoursesScreen> {
  @override
  void initState() {
    super.initState();
    // Preload ads after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        final adProvider = context.read<AdProvider>();
        adProvider.preloadAd(AdType.myGardenAd, adSize: TemplateType.medium);
        debugPrint(
          '[AllCoursesScreen] ✅ Medium ad preload requested',
        );
      } catch (e) {
        debugPrint(
          '[AllCoursesScreen] ⚠️ Medium ad preload error: $e',
        );
      }
    });
  }

  Future<List<Course>> _load() {
    return CourseService.loadCourses();
  }

  // Helper function to get icon based on language
  String _getLanguageIcon(String language) {
    final lang = language.toLowerCase();

    if (lang.contains('html')) {
      return 'assets/icons/code.png';
    } else if (lang.contains('css')) {
      return 'assets/icons/css.png';
    } else if (lang.contains('javascript') || lang.contains('js')) {
      return 'assets/icons/java-script.png';
    } else if (lang.contains('java')) {
      return 'assets/icons/java.png';
    } else if (lang.contains('python')) {
      return 'assets/icons/python.png';
    } else if (lang.contains('c++') || lang.contains('cpp')) {
      return 'assets/icons/c-.png';
    }

    // Default icon if not found
    return 'assets/icons/code.png';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'All Courses',
          style: TextStyle(fontFamily: 'custom'),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        foregroundColor: colorScheme.onSurface,
      ),

      body: FutureBuilder<List<Course>>(
        future: _load(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load courses',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'custom',
                ),
              ),
            );
          }

          final courses = snapshot.data ?? [];
          if (courses.isEmpty) {
            return Center(
              child: Text(
                'No courses available',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'custom',
                ),
              ),
            );
          }

          final sortedCourses = List<Course>.from(courses)
            ..sort((a, b) => _courseLevelRank(a).compareTo(
              _courseLevelRank(b),
            ));

          // Build a scrollable column with courses and ad
          final List<Widget> courseWidgets = [];
          for (int i = 0; i < sortedCourses.length; i++) {
            final course = sortedCourses[i];
            final levelLabel = _courseLevelLabel(course);
            final iconPath = _getLanguageIcon(course.language);

            courseWidgets.add(
              Material(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CourseTopicsScreen(courseTitle: course.title),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        // Custom icon from assets
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: colorScheme.surface.withOpacity(0.8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.asset(
                              iconPath,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback icon if image fails to load
                                return Icon(
                                  Icons.code,
                                  color: colorScheme.primary,
                                  size: 24,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course.title,
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontFamily: 'custom',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  // Language badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.secondary
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      course.language,
                                      style: TextStyle(
                                        color: colorScheme.secondary,
                                        fontFamily: 'custom',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Level indicator
                                  if (levelLabel != 'Beginner')
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getLevelColor(levelLabel, colorScheme)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _getShortLevelLabel(levelLabel),
                                        style: TextStyle(
                                          color: _getLevelColor(levelLabel, colorScheme),
                                          fontFamily: 'custom',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              // Show lessons count
                              const SizedBox(height: 4),
                              Text(
                                '${course.days.length} lessons',
                                style: TextStyle(
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                  fontFamily: 'custom',
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
            );

            // Insert ad after the 3rd course
            if (i == 2) {
              courseWidgets.add(_buildNativeAd(context, AdType.myGardenAd));
            }

            // Add spacing between items
            courseWidgets.add(const SizedBox(height: 12));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: courseWidgets),
          );
        },
      ),
    );
  }

  // Helper function to get level color
  Color _getLevelColor(String levelLabel, ColorScheme colorScheme) {
    if (levelLabel.contains('Advanced')) {
      return Colors.red; // Red for advanced
    } else if (levelLabel.contains('Intermediate')) {
      return Colors.orange; // Orange for intermediate
    } else {
      return Colors.green; // Green for beginner
    }
  }

  // Helper function to get short level label
  String _getShortLevelLabel(String levelLabel) {
    if (levelLabel.contains('Advanced')) {
      return 'ADV';
    } else if (levelLabel.contains('Intermediate')) {
      return 'INT';
    } else {
      return 'BEG';
    }
  }

  Widget _buildNativeAd(BuildContext context, AdType adType) {
    final adProvider = context.watch<AdProvider>();

    final isAdLoaded = adType == AdType.myGardenAd
        ? adProvider.isExercisePageAd1
        : adProvider.isHomeAd2;

    final nativeAd = adType == AdType.myGardenAd
        ? adProvider.myGardenAd
        : adProvider.homeAd2;

    if (!isAdLoaded || nativeAd == null) {
      return Container(
        height: 300,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        ),
        child: Center(
          child: Text(
            'Loading medium ad...',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 350,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AdWidget(ad: nativeAd),
      ),
    );
  }
}

int _courseLevelRank(Course course) {
  final title = course.title.toLowerCase();
  if (title.contains('advanced')) return 0;
  if (title.contains('intermediate')) return 1;
  return 2;
}

String _courseLevelLabel(Course course) {
  final title = course.title.toLowerCase();
  if (title.contains('advanced')) return 'Advanced Level';
  if (title.contains('intermediate')) return 'Intermediate Level';
  return 'Beginner Level';
}