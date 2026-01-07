/*
import 'package:coding_tutor/ads/ads_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../core/App_theme.dart';
import '../controllers/course_controller.dart';
import '../models/course_model.dart';
import '../services/course_service.dart';
import 'course_topics_screen.dart';
import 'analytics_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final CourseController _controller = CourseController();
  bool _loading = true;
  List<Course> _courses = [];
  final Map<String, Map<String, dynamic>> _progressByCourse = {};

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        final adProvider = context.read<AdProvider>();
        adProvider.preloadAd(AdType.calendarAd, adSize: TemplateType.small);
        debugPrint('[HomeScreen] ✅ Ads preload requested');
      } catch (e) {
        debugPrint('[HomeScreen] ⚠️ Ad preload error: $e');
      }
    });
  }

  Future<void> _load() async {
    // Load all available courses (e.g., Java and Python)
    final courses = await CourseService.loadCourses();
    // Collect progress for each course
    for (final course in courses) {
      final progress = await _controller.getProgress(course.title);
      _progressByCourse[course.title] = progress;
    }
    setState(() {
      _courses = courses;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text(
          'Your Progress',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'custom',
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Analytics Section Card
                  _AnalyticsCard(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AnalyticsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  ...List.generate(_courses.length, (index) {
                    final course = _courses[index];
                    final progress =
                        _progressByCourse[course.title] ??
                        const {'completedDays': <int>[], 'currentDay': 0};
                    final completedDays = List<int>.from(
                      progress['completedDays'] ?? [],
                    );
                    final currentDay = (progress['currentDay'] ?? 0) as int;
                    final totalDays = course.days.length;
                    final percentage = totalDays > 0
                        ? (completedDays.length / totalDays).clamp(0.0, 1.0)
                        : 0.0;

                    final List<Widget> items = [];

                    // Add the progress card
                    items.add(
                      _ProgressCard(
                        title: course.title,
                        subtitle:
                            '$completedDays.length/$totalDays topics completed',
                        percentage: percentage,
                        accentColor: Theme.of(context).colorScheme.primary,
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Theme.of(
                              context,
                            ).scaffoldBackgroundColor,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                            ),
                            builder: (_) => _ProgressDetailSheet(
                              course: course,
                              completedDays: completedDays,
                              currentDay: currentDay,
                              percentage: percentage,
                              accentColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                            ),
                          );
                        },
                        currentDay: currentDay,
                      ),
                    );

                    // Insert ad after 3rd item
                    if (index == 2) {
                      items.add(const SizedBox(height: 16));
                      items.add(_buildNativeAd(context, AdType.calendarAd));
                      items.add(const SizedBox(height: 16));
                    } else {
                      items.add(const SizedBox(height: 16));
                    }

                    return Column(children: items);
                  }),
                ],
              ),
            ),
    );
  }

  Widget _buildNativeAd(BuildContext context, AdType adType) {
    final adProvider = context.watch<AdProvider>();
    final isAdLoaded = adType == AdType.homeAd1
        ? adProvider.isHomeAd1
        : adProvider.isHomeAd2;
    final nativeAd = adType == AdType.homeAd1
        ? adProvider.homeAd1
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
}

class _ProgressCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double percentage;
  final Color accentColor;
  final VoidCallback onTap;
  final int currentDay;

  const _ProgressCard({
    required this.title,
    required this.subtitle,
    required this.percentage,
    required this.accentColor,
    required this.onTap,
    required this.currentDay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  accentColor.withValues(alpha: 0.12),
                  accentColor.withValues(alpha: 0.05),
                ]
              : [
                  accentColor.withValues(alpha: 0.08),
                  accentColor.withValues(alpha: 0.03),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: isDark ? 0.2 : 0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: accentColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: accentColor.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.insights_rounded,
                    color: accentColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontFamily: 'custom',
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                          fontFamily: 'custom',
                        ),
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: percentage,
                          minHeight: 8,
                          backgroundColor: colorScheme.surface.withValues(
                            alpha: 0.6,
                          ),
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.flag_rounded,
                        size: 16,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Day $currentDay',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'custom',
                        ),
                      ),
                    ],
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

class _ProgressDetailSheet extends StatelessWidget {
  final Course course;
  final List<int> completedDays;
  final int currentDay;
  final double percentage;
  final Color accentColor;

  const _ProgressDetailSheet({
    required this.course,
    required this.completedDays,
    required this.currentDay,
    required this.percentage,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalDays = course.days.length;
    final completedCount = completedDays.length;
    final remaining = (totalDays - completedCount).clamp(0, totalDays);

    return SingleChildScrollView(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      course.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'custom',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Progress Overview',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  fontFamily: 'custom',
                ),
              ),

              const SizedBox(height: 20),

              // Donut Progress
              Row(
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(140, 140),
                          painter: _DonutProgressPainter(
                            percentage: percentage,
                            color: accentColor,
                            backgroundColor: colorScheme.surface.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(percentage * 100).toStringAsFixed(0)}%',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: accentColor,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'custom',
                              ),
                            ),
                            Text(
                              'Complete',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                                fontFamily: 'custom',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Stats
                  Expanded(
                    child: Column(
                      children: [
                        _StatTile(
                          label: 'Completed',
                          value: '$completedCount/$totalDays',
                          color: accentColor,
                        ),
                        const SizedBox(height: 10),
                        _StatTile(
                          label: 'Remaining',
                          value: '$remaining',
                          color: AppColors.secondary,
                        ),
                        const SizedBox(height: 10),
                        _StatTile(
                          label: 'Current Day',
                          value: '$currentDay',
                          color: colorScheme.tertiaryContainer,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Segmented progress by topic/day
              Text(
                'Topics Breakdown',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'custom',
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final day in course.days)
                    _DayChip(
                      dayNumber: day.day,
                      label: 'Day ${day.day}',
                      isCompleted: completedDays.contains(day.day),
                      accentColor: accentColor,
                      onTap: () {
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (_) => CourseTopicsScreen(courseTitle: course.title),
                        //   ),
                        // );
                      },
                    ),
                ],
              ),

              const SizedBox(height: 24),

              // Action: View Topics
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CourseTopicsScreen(courseTitle: course.title),
                      ),
                    );
                  },
                  icon: const Icon(Icons.list_alt_rounded),
                  label: const Text('View Topics'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [color.withValues(alpha: 0.18), color.withValues(alpha: 0.07)]
              : [color.withValues(alpha: 0.12), color.withValues(alpha: 0.05)],
        ),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontFamily: 'custom',
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontFamily: 'custom',
            ),
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final int dayNumber;
  final String label;
  final bool isCompleted;
  final Color accentColor;
  final VoidCallback onTap;

  const _DayChip({
    required this.dayNumber,
    required this.label,
    required this.isCompleted,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color base = isCompleted ? AppColors.secondary : accentColor;
    final Color fg = isCompleted ? Colors.white : base;
    final Color bg = isCompleted
        ? base.withOpacity(0.8)
        : base.withOpacity(0.12);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive width based on screen size
        final double chipWidth =
            constraints.maxWidth * 0.23; // 25% of parent width
        final double minWidth = 70;
        final double maxWidth = 110;

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: chipWidth.clamp(
              minWidth,
              maxWidth,
            ), // keeps it responsive yet bounded
            height: 40, // fixed height for consistent design
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: base.withOpacity(0.25)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isCompleted ? Icons.check_circle_rounded : Icons.circle,
                  size: 16,
                  color: fg,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isCompleted ? Colors.white : colorScheme.onSurface,
                      fontFamily: 'custom',
                      fontSize: 12,
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
}

class _DonutProgressPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final Color backgroundColor;

  _DonutProgressPainter({
    required this.percentage,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 10;
    const stroke = 12.0;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    // Background circle
    canvas.drawCircle(center, radius, bgPaint);

    // Foreground arc
    final sweep = 2 * 3.1415926535 * percentage;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -3.1415926535 / 2; // start at top
    canvas.drawArc(rect, startAngle, sweep, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _DonutProgressPainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

class _AnalyticsCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AnalyticsCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.secondary.withOpacity(0.15),
                  AppColors.secondary.withOpacity(0.05),
                ]
              : [
                  AppColors.secondary.withOpacity(0.12),
                  AppColors.secondary.withOpacity(0.04),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(isDark ? 0.3 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: AppColors.secondary.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.analytics_rounded,
                    color: AppColors.secondary,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'View Analytics',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'custom',
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Detailed insights into your learning progress',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                          fontFamily: 'custom',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.secondary,
                  size: 20,
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
import 'package:coding_tutor/ads/ads_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../core/App_theme.dart';
import '../controllers/course_controller.dart';
import '../models/course_model.dart';
import '../services/course_service.dart';
import 'course_topics_screen.dart';
import 'analytics_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final CourseController _controller = CourseController();
  bool _loading = true;
  List<Course> _courses = [];
  final Map<String, Map<String, dynamic>> _progressByCourse = {};

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        final adProvider = context.read<AdProvider>();
        adProvider.preloadAd(AdType.calendarAd, adSize: TemplateType.small);
        debugPrint('[HomeScreen] ✅ Ads preload requested');
      } catch (e) {
        debugPrint('[HomeScreen] ⚠️ Ad preload error: $e');
      }
    });
  }

  Future<void> _load() async {
    final courses = await CourseService.loadCourses();
    for (final course in courses) {
      final progress = await _controller.getProgress(course.title);
      _progressByCourse[course.title] = progress;
    }
    setState(() {
      _courses = courses;
      _loading = false;
    });
  }

  // Helper function to get course icon based on language
  String _getCourseIcon(String language) {
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

    // Default progress icon
    return 'assets/icons/coding-progress.png';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text(
          'Your Progress',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'custom',
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Analytics Section Card with custom icon
            _AnalyticsCard(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AnalyticsScreen(),
                  ),
                );
              },
              iconPath: 'assets/icons/bar-chart.png', // Custom icon
            ),
            const SizedBox(height: 15),
            ...List.generate(_courses.length, (index) {
              final course = _courses[index];
              final progress =
                  _progressByCourse[course.title] ??
                      const {'completedDays': <int>[], 'currentDay': 0};
              final completedDays = List<int>.from(
                progress['completedDays'] ?? [],
              );
              final currentDay = (progress['currentDay'] ?? 0) as int;
              final totalDays = course.days.length;
              final percentage = totalDays > 0
                  ? (completedDays.length / totalDays).clamp(0.0, 1.0)
                  : 0.0;

              final List<Widget> items = [];

              // Add the progress card with custom icon
              items.add(
                _ProgressCard(
                  title: course.title,
                  subtitle:
                  '$completedDays.length/$totalDays topics completed',
                  percentage: percentage,
                  accentColor: Theme.of(context).colorScheme.primary,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Theme.of(
                        context,
                      ).scaffoldBackgroundColor,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      builder: (_) => _ProgressDetailSheet(
                        course: course,
                        completedDays: completedDays,
                        currentDay: currentDay,
                        percentage: percentage,
                        accentColor: Theme.of(
                          context,
                        ).colorScheme.primary,
                        iconPath: _getCourseIcon(course.language),
                      ),
                    );
                  },
                  currentDay: currentDay,
                  iconPath: _getCourseIcon(course.language), // Custom icon
                ),
              );

              // Insert ad after 3rd item
              if (index == 2) {
                items.add(const SizedBox(height: 12));
                items.add(_buildNativeAd(context, AdType.calendarAd));
                items.add(const SizedBox(height: 12));
              } else {
                items.add(const SizedBox(height: 12));
              }

              return Column(children: items);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNativeAd(BuildContext context, AdType adType) {
    final adProvider = context.watch<AdProvider>();
    final isAdLoaded = adType == AdType.homeAd1
        ? adProvider.isHomeAd1
        : adProvider.isHomeAd2;
    final nativeAd = adType == AdType.homeAd1
        ? adProvider.homeAd1
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
}

class _ProgressCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double percentage;
  final Color accentColor;
  final VoidCallback onTap;
  final int currentDay;
  final String iconPath;

  const _ProgressCard({
    required this.title,
    required this.subtitle,
    required this.percentage,
    required this.accentColor,
    required this.onTap,
    required this.currentDay,
    required this.iconPath,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12), // Reduced from 16
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16), // Reduced from 20
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
            accentColor.withValues(alpha: 0.12),
            accentColor.withValues(alpha: 0.05),
          ]
              : [
            accentColor.withValues(alpha: 0.08),
            accentColor.withValues(alpha: 0.03),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: isDark ? 0.2 : 0.1),
            blurRadius: 12, // Reduced from 15
            offset: const Offset(0, 3), // Reduced from 4
          ),
        ],
        border: Border.all(color: accentColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: accentColor.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(16), // Reduced from 24
            child: Row(
              children: [
                // Icon container - smaller
                Container(
                  width: 48, // Reduced from 54
                  height: 48, // Reduced from 54
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12), // Reduced from 14
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8), // Reduced from 10
                    child: Image.asset(
                      iconPath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.insights_rounded,
                          color: accentColor,
                          size: 22, // Reduced from 26
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12), // Reduced from 16
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontFamily: 'custom',
                          color: colorScheme.onSurface,
                          fontSize: 15, // Smaller font
                        ),
                      ),
                      const SizedBox(height: 4), // Reduced from 6
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                          fontFamily: 'custom',
                          fontSize: 11, // Smaller font
                        ),
                      ),
                      const SizedBox(height: 8), // Reduced from 14
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6), // Reduced from 10
                        child: LinearProgressIndicator(
                          value: percentage,
                          minHeight: 6, // Reduced from 8
                          backgroundColor: colorScheme.surface.withValues(
                            alpha: 0.6,
                          ),
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8), // Reduced from 12
                // Day indicator - smaller
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10, // Reduced from 12
                    vertical: 6, // Reduced from 8
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10), // Reduced from 12
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.flag_rounded,
                        size: 14, // Reduced from 16
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 4), // Reduced from 6
                      Text(
                        'Day $currentDay',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'custom',
                          fontSize: 11, // Smaller font
                        ),
                      ),
                    ],
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
class _ProgressDetailSheet extends StatelessWidget {
  final Course course;
  final List<int> completedDays;
  final int currentDay;
  final double percentage;
  final Color accentColor;
  final String iconPath; // New parameter for custom icon

  const _ProgressDetailSheet({
    required this.course,
    required this.completedDays,
    required this.currentDay,
    required this.percentage,
    required this.accentColor,
    required this.iconPath,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalDays = course.days.length;
    final completedCount = completedDays.length;
    final remaining = (totalDays - completedCount).clamp(0, totalDays);

    return SingleChildScrollView(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Course icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(
                        iconPath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.code,
                            color: accentColor,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'custom',
                          ),
                        ),
                        Text(
                          'Progress Overview',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                            fontFamily: 'custom',
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Donut Progress
              Row(
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(140, 140),
                          painter: _DonutProgressPainter(
                            percentage: percentage,
                            color: accentColor,
                            backgroundColor: colorScheme.surface.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(percentage * 100).toStringAsFixed(0)}%',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: accentColor,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'custom',
                              ),
                            ),
                            Text(
                              'Complete',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                                fontFamily: 'custom',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Stats
                  Expanded(
                    child: Column(
                      children: [
                        _StatTile(
                          label: 'Completed',
                          value: '$completedCount/$totalDays',
                          color: accentColor,
                        ),
                        const SizedBox(height: 10),
                        _StatTile(
                          label: 'Remaining',
                          value: '$remaining',
                          color: AppColors.secondary,
                        ),
                        const SizedBox(height: 10),
                        _StatTile(
                          label: 'Current Day',
                          value: '$currentDay',
                          color: colorScheme.tertiaryContainer,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Segmented progress by topic/day
              Text(
                'Topics Breakdown',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'custom',
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final day in course.days)
                    _DayChip(
                      dayNumber: day.day,
                      label: 'Day ${day.day}',
                      isCompleted: completedDays.contains(day.day),
                      accentColor: accentColor,
                      onTap: () {
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (_) => CourseTopicsScreen(courseTitle: course.title),
                        //   ),
                        // );
                      },
                    ),
                ],
              ),

              const SizedBox(height: 24),

              // Action: View Topics
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CourseTopicsScreen(courseTitle: course.title),
                      ),
                    );
                  },
                  icon: const Icon(Icons.list_alt_rounded),
                  label: const Text('View Topics'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [color.withValues(alpha: 0.18), color.withValues(alpha: 0.07)]
              : [color.withValues(alpha: 0.12), color.withValues(alpha: 0.05)],
        ),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontFamily: 'custom',
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontFamily: 'custom',
            ),
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final int dayNumber;
  final String label;
  final bool isCompleted;
  final Color accentColor;
  final VoidCallback onTap;

  const _DayChip({
    required this.dayNumber,
    required this.label,
    required this.isCompleted,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color base = isCompleted ? AppColors.secondary : accentColor;
    final Color fg = isCompleted ? Colors.white : base;
    final Color bg = isCompleted
        ? base.withOpacity(0.8)
        : base.withOpacity(0.12);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double chipWidth = constraints.maxWidth * 0.23;
        final double minWidth = 70;
        final double maxWidth = 110;

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: chipWidth.clamp(minWidth, maxWidth),
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: base.withOpacity(0.25)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isCompleted ? Icons.check_circle_rounded : Icons.circle,
                  size: 16,
                  color: fg,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isCompleted ? Colors.white : colorScheme.onSurface,
                      fontFamily: 'custom',
                      fontSize: 12,
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
}

class _DonutProgressPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final Color backgroundColor;

  _DonutProgressPainter({
    required this.percentage,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 10;
    const stroke = 12.0;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    final sweep = 2 * 3.1415926535 * percentage;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -3.1415926535 / 2;
    canvas.drawArc(rect, startAngle, sweep, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _DonutProgressPainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

class _AnalyticsCard extends StatelessWidget {
  final VoidCallback onTap;
  final String iconPath; // New parameter for custom icon

  const _AnalyticsCard({
    required this.onTap,
    required this.iconPath,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
            AppColors.secondary.withOpacity(0.15),
            AppColors.secondary.withOpacity(0.05),
          ]
              : [
            AppColors.secondary.withOpacity(0.12),
            AppColors.secondary.withOpacity(0.04),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(isDark ? 0.3 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: AppColors.secondary.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                // Custom analytics icon from assets
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(
                      iconPath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback icon
                        return const Icon(
                          Icons.analytics_rounded,
                          color: AppColors.secondary,
                          size: 30,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'View Analytics',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'custom',
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Detailed insights into your learning progress',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                          fontFamily: 'custom',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}