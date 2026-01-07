import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/App_theme.dart';
import '../services/course_service.dart';
import '../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  bool _loading = true;
  
  // Analytics data
  int _totalCourses = 0;
  int _totalLessonsCompleted = 0;
  int _totalPoints = 0;
  int _activeCourses = 0;
  List<Map<String, dynamic>> _courseStats = [];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
    _logAnalyticsScreenView();
  }

  Future<void> _logAnalyticsScreenView() async {
    await _analytics.logScreenView(
      screenName: 'AnalyticsScreen',
      screenClass: 'AnalyticsScreen',
    );
  }

  Future<void> _loadAnalytics() async {
    setState(() => _loading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _loading = false);
        return;
      }

      // Get all courses
      final allCourses = await CourseService.loadCourses();
      
      // Get all progress
      final allProgress = await _firestoreService.getAllCourseProgress(user.uid);
      
      // Calculate statistics
      int totalLessons = 0;
      int activeCoursesCount = 0;
      final List<Map<String, dynamic>> courseStatsList = [];

      for (final course in allCourses) {
        final progress = allProgress[course.title] ?? {'completedDays': <int>[], 'currentDay': 0};
        final completedDays = List<int>.from(progress['completedDays'] ?? []);
        final totalDays = course.days.length;
        final completedCount = completedDays.length;
        final progressPercentage = totalDays > 0 ? (completedCount / totalDays) : 0.0;
        
        if (completedCount > 0 || progress['currentDay'] > 0) {
          activeCoursesCount++;
        }
        
        totalLessons += completedCount;
        
        courseStatsList.add({
          'title': course.title,
          'completed': completedCount,
          'total': totalDays,
          'progress': progressPercentage,
          'currentDay': progress['currentDay'] ?? 0,
        });
      }

      // Sort by progress (descending)
      courseStatsList.sort((a, b) => (b['progress'] as double).compareTo(a['progress'] as double));

      setState(() {
        _totalCourses = allCourses.length;
        _totalLessonsCompleted = totalLessons;
        _totalPoints = totalLessons * 5; // 5 points per lesson
        _activeCourses = activeCoursesCount;
        _courseStats = courseStatsList;
        _loading = false;
      });

      // Log analytics event to Firebase
      await _analytics.logEvent(
        name: 'analytics_viewed',
        parameters: {
          'total_courses': _totalCourses,
          'total_lessons_completed': _totalLessonsCompleted,
          'total_points': _totalPoints,
          'active_courses': _activeCourses,
        },
      );
    } catch (e) {
      debugPrint('Error loading analytics: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text(
          'Learning Analytics',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'custom',
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Cards
                    _buildOverviewSection(theme, colorScheme),
                    const SizedBox(height: 24),
                    
                    // Total Statistics
                    _buildTotalStatsSection(theme, colorScheme),
                    const SizedBox(height: 24),
                    
                    // Progress Pie Chart
                    _buildProgressPieChart(theme, colorScheme),
                    const SizedBox(height: 24),
                    
                    // Course Progress Bar Chart
                    _buildCourseProgressBarChart(theme, colorScheme),
                    const SizedBox(height: 24),
                    
                    // Course Progress Breakdown
                    _buildCourseProgressSection(theme, colorScheme),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewSection(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Total Courses',
            value: '$_totalCourses',
            icon: Icons.school_rounded,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Active Courses',
            value: '$_activeCourses',
            icon: Icons.trending_up_rounded,
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalStatsSection(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withOpacity(0.1),
            colorScheme.secondary.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overall Statistics',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'custom',
            ),
          ),
          const SizedBox(height: 20),
          _AnalyticsRow(
            label: 'Lessons Completed',
            value: '$_totalLessonsCompleted',
            icon: Icons.check_circle_rounded,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          _AnalyticsRow(
            label: 'Total Points Earned',
            value: '$_totalPoints',
            icon: Icons.stars_rounded,
            color: AppColors.secondary,
          ),
          const SizedBox(height: 16),
          _AnalyticsRow(
            label: 'Average Progress',
            value: _courseStats.isNotEmpty
                ? '${(_courseStats.map((e) => e['progress'] as double).reduce((a, b) => a + b) / _courseStats.length * 100).toStringAsFixed(1)}%'
                : '0%',
            icon: Icons.analytics_rounded,
            color: colorScheme.tertiaryContainer,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressPieChart(ThemeData theme, ColorScheme colorScheme) {
    if (_courseStats.isEmpty) return const SizedBox.shrink();
    
    final completed = _totalLessonsCompleted;
    final totalLessons = _courseStats.fold<int>(0, (sum, stat) => sum + (stat['total'] as int));
    final remaining = totalLessons - completed;
    
    if (totalLessons == 0) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: colorScheme.surface.withOpacity(0.5),
        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overall Progress',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'custom',
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: [
                      PieChartSectionData(
                        value: completed.toDouble(),
                        title: '${((completed / totalLessons) * 100).toStringAsFixed(0)}%',
                        color: colorScheme.primary,
                        radius: 60,
                        titleStyle: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'custom',
                        ),
                      ),
                      PieChartSectionData(
                        value: remaining.toDouble(),
                        title: '${((remaining / totalLessons) * 100).toStringAsFixed(0)}%',
                        color: colorScheme.surface.withOpacity(0.5),
                        radius: 60,
                        titleStyle: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontFamily: 'custom',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LegendItem(
                      color: colorScheme.primary,
                      label: 'Completed',
                      value: '$completed lessons',
                      theme: theme,
                    ),
                    const SizedBox(height: 12),
                    _LegendItem(
                      color: colorScheme.surface.withOpacity(0.5),
                      label: 'Remaining',
                      value: '$remaining lessons',
                      theme: theme,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCourseProgressBarChart(ThemeData theme, ColorScheme colorScheme) {
    if (_courseStats.isEmpty) return const SizedBox.shrink();
    
    // Take top 5 courses for better visualization
    final topCourses = _courseStats.take(5).toList();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: colorScheme.surface.withOpacity(0.5),
        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Course Progress Comparison',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'custom',
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => colorScheme.primary,
                    tooltipRoundedRadius: 8,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= topCourses.length) return const Text('');
                        final title = topCourses[value.toInt()]['title'] as String;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            title.length > 12 ? '${title.substring(0, 12)}...' : title,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontFamily: 'custom',
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontFamily: 'custom',
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: colorScheme.surface.withOpacity(0.3),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(
                      color: colorScheme.onSurface.withOpacity(0.2),
                      width: 1,
                    ),
                    left: BorderSide(
                      color: colorScheme.onSurface.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                barGroups: topCourses.asMap().entries.map((entry) {
                  final index = entry.key;
                  final stat = entry.value;
                  final progress = (stat['progress'] as double) * 100;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: progress,
                        color: index % 2 == 0 
                            ? colorScheme.primary 
                            : AppColors.secondary,
                        width: 30,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseProgressSection(ThemeData theme, ColorScheme colorScheme) {
    if (_courseStats.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: colorScheme.surface.withOpacity(0.5),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 64,
                color: colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No course progress yet',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                  fontFamily: 'custom',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Course Progress Breakdown',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'custom',
          ),
        ),
        const SizedBox(height: 16),
        ..._courseStats.map((stat) => _CourseProgressCard(
          title: stat['title'] as String,
          completed: stat['completed'] as int,
          total: stat['total'] as int,
          progress: stat['progress'] as double,
          currentDay: stat['currentDay'] as int,
          theme: theme,
          colorScheme: colorScheme,
        )),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'custom',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
              fontFamily: 'custom',
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _AnalyticsRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontFamily: 'custom',
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'custom',
          ),
        ),
      ],
    );
  }
}

class _CourseProgressCard extends StatelessWidget {
  final String title;
  final int completed;
  final int total;
  final double progress;
  final int currentDay;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _CourseProgressCard({
    required this.title,
    required this.completed,
    required this.total,
    required this.progress,
    required this.currentDay,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surface.withOpacity(0.5),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'custom',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'custom',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: colorScheme.surface.withOpacity(0.5),
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completed/$total lessons completed',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                  fontFamily: 'custom',
                ),
              ),
              if (currentDay > 0)
                Text(
                  'Current: Day $currentDay',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'custom',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final ThemeData theme;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'custom',
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'custom',
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
