/*
import 'package:coding_tutor/ads/ads_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../core/App_theme.dart';
import '../in_app_purchase/credit_purchase_screen.dart';
import '../in_app_purchase/i_app_manager.dart';
import '../models/course_model.dart';
import '../controllers/course_controller.dart';
import 'course_detail_screen.dart';
import 'premium_dialog.dart';

class CourseTopicsScreen extends StatefulWidget {
  final String courseTitle;
  final bool showPremiumDialog;
  final String? premiumLevelLabel;
  final Color? premiumColor;
  const CourseTopicsScreen({
    super.key,
    required this.courseTitle,
    this.showPremiumDialog = false,
    this.premiumLevelLabel,
    this.premiumColor,
  });

  @override
  State<CourseTopicsScreen> createState() => _CourseTopicsScreenState();
}

class _CourseTopicsScreenState extends State<CourseTopicsScreen> {
  final CourseController _controller = CourseController();
  Course? _course;
  Set<int> _completedDays = {};
  bool _loading = true;
  final ScrollController _scrollController = ScrollController();
  List<GlobalKey> _itemKeys = [];
  int? _resumeIndex;
  bool _hasPurchasedAnyPlan = false;
  bool _checkingPurchaseStatus = false;
  @override
  void initState() {
    super.initState();
    _load();
    _checkPurchaseStatus(); // Add this line

    // Preload ads after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        final adProvider = context.read<AdProvider>();
        adProvider.preloadAd(
          AdType.courseTopicsAd1,
          adSize: TemplateType.small,
        );
        adProvider.preloadAd(
          AdType.courseTopicsAd2,
          adSize: TemplateType.small,
        );
        adProvider.preloadAd(
          AdType.courseTopicsAd3,
          adSize: TemplateType.small,
        );

        debugPrint('[HomeScreen] ✅ Ads preload requested');
      } catch (e) {
        debugPrint('[HomeScreen] ⚠️ Ad preload error: $e');
      }
    });
  }
  Future<void> _checkPurchaseStatus() async {
    try {
      setState(() => _checkingPurchaseStatus = true);

      // Replace with your IAPManager instance
      final iapManager = IAPManager(); // Make sure you have IAPManager instance

      _hasPurchasedAnyPlan = await iapManager.hasPurchasedAnyPlanIOS();

      setState(() => _checkingPurchaseStatus = false);

      debugPrint('✅ Purchase status checked: $_hasPurchasedAnyPlan');
    } catch (e) {
      debugPrint('❌ Error checking purchase status: $e');
      setState(() => _checkingPurchaseStatus = false);
    }
  }
  void _openPurchaseScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CreditsPurchaseScreen(),
      ),
    );
  }
  void _handleTopicTap(CourseDay day) {
    // Show dialog if premium AND user hasn't purchased, but navigate anyway
    if (widget.showPremiumDialog && !_hasPurchasedAnyPlan) {
      showPremiumDialog(
        context,
        widget.premiumLevelLabel ?? 'Premium',
        widget.premiumColor ?? Theme.of(context).colorScheme.primary,
        onUnlock: _openPurchaseScreen,
      );
      // Navigate immediately even if dialog is shown
    }

    // Navigate to course detail screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourseDetailScreen(
          courseTitle: widget.courseTitle,
          initialDay: day.day,
        ),
      ),
    );
  }

  Future<void> _load() async {
    final course = await _controller.loadCourseByTitle(widget.courseTitle);
    final progress = await _controller.getProgress(widget.courseTitle);
    final completed = List<int>.from(progress['completedDays'] ?? []).toSet();
    // Compute resume index (next uncompleted day) using controller utility
    int resumeIndex = 0;
    if (course.days.isNotEmpty) {
      resumeIndex = _controller.computeStartingIndex(
        completedDays: completed,
        totalDays: course.days.length,
      );
    }
    setState(() {
      _course = course;
      _completedDays = completed;
      _loading = false;
      _resumeIndex = resumeIndex;
      _itemKeys = List<GlobalKey>.generate(
        course.days.length,
        (_) => GlobalKey(),
      );
    });

    // After first build, auto-scroll to the resume card
    WidgetsBinding.instance.addPostFrameCallback((_) => _attemptAutoScroll());
  }

  void _attemptAutoScroll() {
    if (!mounted) return;
    final idx = _resumeIndex;
    if (idx == null) return;
    if (idx < 0 || idx >= _itemKeys.length) return;

    // If target context exists, ensure it's visible
    final targetCtx = _itemKeys[idx].currentContext;
    if (targetCtx != null) {
      Scrollable.ensureVisible(
        targetCtx,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.05,
      );
      return;
    }

    // Fallback: estimate offset using first built item's height, then refine
    BuildContext? firstCtx;
    for (final key in _itemKeys) {
      if (key.currentContext != null) {
        firstCtx = key.currentContext;
        break;
      }
    }

    if (firstCtx == null) {
      // Items not built yet; try again next frame
      WidgetsBinding.instance.addPostFrameCallback((_) => _attemptAutoScroll());
      return;
    }

    final box = firstCtx.findRenderObject() as RenderBox?;
    if (box == null || !_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _attemptAutoScroll());
      return;
    }
    final h = box.size.height;
    double offset = idx * h;
    offset = offset.clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController
        .animateTo(
          offset,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        )
        .then((_) {
          final ctx2 = _itemKeys[idx].currentContext;
          if (ctx2 != null) {
            Scrollable.ensureVisible(
              ctx2,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: 0.05,
            );
          }
        });
  }

  // Function to remove "Day X - " prefix from title
  String _getCleanTitle(String title) {
    // Remove "Day X -", "Day X:", "Day X —", etc. at the start
    final regex = RegExp(r'^Day\s+\d+\s*[-–—:]*\s*');
    String cleaned = title.replaceAll(regex, '').trim();

    // Ensure no leading dash, colon, or whitespace remains
    cleaned = cleaned.replaceAll(RegExp(r'^[-–—:\s]+'), '').trim();

    return cleaned;
  }

*/
/*
  void _handleTopicTap(CourseDay day) {
    if (widget.showPremiumDialog) {
      showPremiumDialog(
        context,
        widget.premiumLevelLabel ?? 'Premium',
        widget.premiumColor ?? Theme.of(context).colorScheme.primary,
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourseDetailScreen(
          courseTitle: widget.courseTitle,
          initialDay: day.day,
        ),
      ),
    );
  }
*//*

*/
/*


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_loading || _course == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: colorScheme.primary,
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              Text(
                'Loading Topics...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                  fontFamily: 'custom',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final progressPercentage = _course!.days.isNotEmpty
        ? _completedDays.length / _course!.days.length
        : 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.courseTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'custom',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Course Topics',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
                fontFamily: 'custom',
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(progressPercentage * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'custom',
                  ),
                ),
                Text(
                  'Complete',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                    fontFamily: 'custom',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Header Card
          Container(
            margin: const EdgeInsets.all(20),
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
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Course Progress',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'custom',
                      ),
                    ),
                    Text(
                      '${_completedDays.length}/${_course!.days.length}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'custom',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progressPercentage.toDouble(),
                  backgroundColor: colorScheme.surface.withOpacity(0.5),
                  color: colorScheme.primary,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(10),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Keep going!',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontFamily: 'custom',
                      ),
                    ),
                    Text(
                      '${(progressPercentage * 100).toStringAsFixed(0)}% Complete',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'custom',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Topics List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _course!.days.length + _numberOfAdsToInsert(),
              itemBuilder: (context, index) {
                // Check if this index should show an ad
                if ((index + 1) % 4 == 0) {
                  return _buildAdSlot(index);
                }

                // Calculate real course/day index (ad slots shift indexes)
                final itemIndex = index - (index ~/ 4);

                final day = _course!.days[itemIndex];
                final isCompleted = _completedDays.contains(day.day);

                return _buildTopicCard(
                  itemIndex,
                  day,
                  isCompleted,
                  Theme.of(context),
                  Theme.of(context).colorScheme,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int _numberOfAdsToInsert() {
    return (_course!.days.length / 3).floor();
  }

  Widget _buildAdSlot(int index) {
    final adProvider = context.watch<AdProvider>();

    // Select which ad to show based on position
    if (index % 12 == 3 && adProvider.iscourseTopicsAd1) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        height: 120,
        child: AdWidget(ad: adProvider.courseTopicsAd1!),
      );
    }

    if (index % 12 == 7 && adProvider.iscourseTopicsAd2) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        height: 120,
        child: AdWidget(ad: adProvider.courseTopicsAd2!),
      );
    }

    if (index % 12 == 11 && adProvider.iscourseTopicsAd3) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        height: 120,
        child: AdWidget(ad: adProvider.courseTopicsAd3!),
      );
    }

    // fallback empty if ad not loaded
    return const SizedBox.shrink();
  }*//*

  Widget _buildTopicCard(
      int index,
      CourseDay day,
      bool isCompleted,
      ThemeData theme,
      ColorScheme colorScheme,
      ) {
    final progressPercentage = _completedDays.length / _course!.days.length;
    final cleanTitle = _getCleanTitle(day.title);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCompleted
              ? [
            AppColors.secondary.withOpacity(0.15),
            AppColors.secondary.withOpacity(0.05),
          ]
              : [
            colorScheme.primary.withOpacity(0.12),
            colorScheme.primary.withOpacity(0.04),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: (isCompleted ? AppColors.secondary : colorScheme.primary)
                .withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: (isCompleted ? AppColors.secondary : colorScheme.primary)
              .withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _handleTopicTap(day),

          borderRadius: BorderRadius.circular(20),
          splashColor: (isCompleted ? AppColors.secondary : colorScheme.primary)
              .withOpacity(0.1),

          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Day Number with Progress Ring
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                          (isCompleted
                              ? AppColors.secondary
                              : colorScheme.primary)
                              .withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                    ),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color:
                        (isCompleted
                            ? AppColors.secondary
                            : colorScheme.primary)
                            .withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          day.day.toString(),
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: isCompleted
                                ? AppColors.secondary
                                : colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            fontFamily: 'custom',
                          ),
                        ),
                      ),
                    ),
                    if (isCompleted)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.scaffoldBackgroundColor,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              cleanTitle, // Use cleaned title here
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize:
                                14, // Increased font size for better readability
                                fontFamily: 'custom',
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Day ${day.day} • ${_getTopicDescription(cleanTitle)}', // Use cleaned title for description
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 13,
                          fontFamily: 'custom',
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Progress indicator for the entire course
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: _completedDays.length,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      colorScheme.primary,
                                      AppColors.secondary,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            Expanded(
                              flex:
                              _course!.days.length - _completedDays.length,
                              child: const SizedBox(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 4),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_completedDays.length}/${_course!.days.length} topics',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.6),
                              fontFamily: 'custom',
                            ),
                          ),
                          Text(
                            '${(progressPercentage * 100).toStringAsFixed(0)}% complete',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'custom',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Navigation Arrow
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color:
                  (isCompleted ? AppColors.secondary : colorScheme.primary)
                      .withOpacity(0.7),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTopicDescription(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('variable') || lowerTitle.contains('data')) {
      return 'Learn data types and variables';
    } else if (lowerTitle.contains('control') || lowerTitle.contains('loop')) {
      return 'Master control flow and loops';
    } else if (lowerTitle.contains('function') ||
        lowerTitle.contains('method')) {
      return 'Understand functions and methods';
    } else if (lowerTitle.contains('class') || lowerTitle.contains('object')) {
      return 'Explore classes and objects';
    } else if (lowerTitle.contains('array') || lowerTitle.contains('list')) {
      return 'Work with arrays and collections';
    } else if (lowerTitle.contains('exception') ||
        lowerTitle.contains('error')) {
      return 'Handle exceptions and errors';
    } else if (lowerTitle.contains('inheritance') ||
        lowerTitle.contains('polymorphism')) {
      return 'Learn OOP concepts';
    } else if (lowerTitle.contains('interface') ||
        lowerTitle.contains('abstract')) {
      return 'Understand advanced OOP';
    } else {
      return 'Continue your learning journey';
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_loading || _course == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: colorScheme.primary,
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              Text(
                'Loading Topics...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                  fontFamily: 'custom',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final progressPercentage = _course!.days.isNotEmpty
        ? _completedDays.length / _course!.days.length
        : 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.courseTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'custom',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Course Topics',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
                fontFamily: 'custom',
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          // Purchase status badge - Add this
          _buildPurchaseStatusBadge(),
          const SizedBox(width: 8),

          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(progressPercentage * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'custom',
                  ),
                ),
                Text(
                  'Complete',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                    fontFamily: 'custom',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Header Card
          Container(
            margin: const EdgeInsets.all(20),
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
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Course Progress',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'custom',
                      ),
                    ),
                    Text(
                      '${_completedDays.length}/${_course!.days.length}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'custom',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progressPercentage.toDouble(),
                  backgroundColor: colorScheme.surface.withOpacity(0.5),
                  color: colorScheme.primary,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(10),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Keep going!',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontFamily: 'custom',
                      ),
                    ),
                    Text(
                      '${(progressPercentage * 100).toStringAsFixed(0)}% Complete',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'custom',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Topics List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _course!.days.length + _numberOfAdsToInsert(),
              itemBuilder: (context, index) {
                // Check if this index should show an ad
                if ((index + 1) % 4 == 0) {
                  return _buildAdSlot(index);
                }

                // Calculate real course/day index (ad slots shift indexes)
                final itemIndex = index - (index ~/ 4);

                final day = _course!.days[itemIndex];
                final isCompleted = _completedDays.contains(day.day);

                return _buildTopicCard(
                  itemIndex,
                  day,
                  isCompleted,
                  Theme.of(context),
                  Theme.of(context).colorScheme,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Add this method for purchase status badge
  Widget _buildPurchaseStatusBadge() {
    if (_checkingPurchaseStatus) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Checking...',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasPurchasedAnyPlan) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.verified,
              color: Colors.green.shade700,
              size: 14,
            ),
            const SizedBox(width: 5),
            Text(
              'Premium User',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
      );
    }

    if (widget.showPremiumDialog) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lock,
              color: Colors.orange.shade700,
              size: 14,
            ),
            const SizedBox(width: 5),
            Text(
              'Premium Course',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade700,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int _numberOfAdsToInsert() {
    return (_course!.days.length / 3).floor();
  }

  Widget _buildAdSlot(int index) {
    final adProvider = context.watch<AdProvider>();

    // Select which ad to show based on position
    if (index % 12 == 3 && adProvider.iscourseTopicsAd1) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        height: 120,
        child: AdWidget(ad: adProvider.courseTopicsAd1!),
      );
    }

    if (index % 12 == 7 && adProvider.iscourseTopicsAd2) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        height: 120,
        child: AdWidget(ad: adProvider.courseTopicsAd2!),
      );
    }

    if (index % 12 == 11 && adProvider.iscourseTopicsAd3) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        height: 120,
        child: AdWidget(ad: adProvider.courseTopicsAd3!),
      );
    }

    // fallback empty if ad not loaded
    return const SizedBox.shrink();
  }
}
*/
import 'package:coding_tutor/ads/ads_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../core/App_theme.dart';
import '../in_app_purchase/credit_purchase_screen.dart';
import '../in_app_purchase/i_app_manager.dart';
import '../models/course_model.dart';
import '../controllers/course_controller.dart';
import 'course_detail_screen.dart';
import 'premium_dialog.dart';

class CourseTopicsScreen extends StatefulWidget {
  final String courseTitle;
  final bool showPremiumDialog;
  final String? premiumLevelLabel;
  final Color? premiumColor;
  const CourseTopicsScreen({
    super.key,
    required this.courseTitle,
    this.showPremiumDialog = false,
    this.premiumLevelLabel,
    this.premiumColor,
  });

  @override
  State<CourseTopicsScreen> createState() => _CourseTopicsScreenState();
}

class _CourseTopicsScreenState extends State<CourseTopicsScreen> {
  final CourseController _controller = CourseController();
  Course? _course;
  Set<int> _completedDays = {};
  bool _loading = true;
  final ScrollController _scrollController = ScrollController();
  List<GlobalKey> _itemKeys = [];
  int? _resumeIndex;
  bool _hasPurchasedAnyPlan = false;
  bool _checkingPurchaseStatus = false;

  @override
  void initState() {
    super.initState();
    _load();
    _checkPurchaseStatus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        final adProvider = context.read<AdProvider>();
        adProvider.preloadAd(
          AdType.courseTopicsAd1,
          adSize: TemplateType.small,
        );
        adProvider.preloadAd(
          AdType.courseTopicsAd2,
          adSize: TemplateType.small,
        );
        adProvider.preloadAd(
          AdType.courseTopicsAd3,
          adSize: TemplateType.small,
        );

        debugPrint('[HomeScreen] ✅ Ads preload requested');
      } catch (e) {
        debugPrint('[HomeScreen] ⚠️ Ad preload error: $e');
      }
    });
  }

  Future<void> _checkPurchaseStatus() async {
    try {
      setState(() => _checkingPurchaseStatus = true);

      final iapManager = IAPManager();

      _hasPurchasedAnyPlan = await iapManager.hasPurchasedAnyPlanIOS();

      setState(() => _checkingPurchaseStatus = false);

      debugPrint('✅ Purchase status checked: $_hasPurchasedAnyPlan');
    } catch (e) {
      debugPrint('❌ Error checking purchase status: $e');
      setState(() => _checkingPurchaseStatus = false);
    }
  }

  void _openPurchaseScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CreditsPurchaseScreen(),
      ),
    );
  }

  void _handleTopicTap(CourseDay day) {
    if (widget.showPremiumDialog && !_hasPurchasedAnyPlan) {
      showPremiumDialog(
        context,
        widget.premiumLevelLabel ?? 'Premium',
        widget.premiumColor ?? Theme.of(context).colorScheme.primary,
        onUnlock: _openPurchaseScreen,
      );
     // return;

    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourseDetailScreen(
          courseTitle: widget.courseTitle,
          initialDay: day.day,
        ),
      ),
    );
  }

  Future<void> _load() async {
    final course = await _controller.loadCourseByTitle(widget.courseTitle);
    final progress = await _controller.getProgress(widget.courseTitle);
    final completed = List<int>.from(progress['completedDays'] ?? []).toSet();
    int resumeIndex = 0;
    if (course.days.isNotEmpty) {
      resumeIndex = _controller.computeStartingIndex(
        completedDays: completed,
        totalDays: course.days.length,
      );
    }
    setState(() {
      _course = course;
      _completedDays = completed;
      _loading = false;
      _resumeIndex = resumeIndex;
      _itemKeys = List<GlobalKey>.generate(
        course.days.length,
            (_) => GlobalKey(),
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _attemptAutoScroll());
  }

  void _attemptAutoScroll() {
    if (!mounted) return;
    final idx = _resumeIndex;
    if (idx == null) return;
    if (idx < 0 || idx >= _itemKeys.length) return;

    final targetCtx = _itemKeys[idx].currentContext;
    if (targetCtx != null) {
      Scrollable.ensureVisible(
        targetCtx,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.05,
      );
      return;
    }

    BuildContext? firstCtx;
    for (final key in _itemKeys) {
      if (key.currentContext != null) {
        firstCtx = key.currentContext;
        break;
      }
    }

    if (firstCtx == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _attemptAutoScroll());
      return;
    }

    final box = firstCtx.findRenderObject() as RenderBox?;
    if (box == null || !_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _attemptAutoScroll());
      return;
    }
    final h = box.size.height;
    double offset = idx * h;
    offset = offset.clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController
        .animateTo(
      offset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    )
        .then((_) {
      final ctx2 = _itemKeys[idx].currentContext;
      if (ctx2 != null) {
        Scrollable.ensureVisible(
          ctx2,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.05,
        );
      }
    });
  }

  String _getCleanTitle(String title) {
    final regex = RegExp(r'^Day\s+\d+\s*[-–—:]*\s*');
    String cleaned = title.replaceAll(regex, '').trim();
    cleaned = cleaned.replaceAll(RegExp(r'^[-–—:\s]+'), '').trim();
    return cleaned;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_loading || _course == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: colorScheme.primary,
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              Text(
                'Loading Topics...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                  fontFamily: 'custom',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final progressPercentage = _course!.days.isNotEmpty
        ? _completedDays.length / _course!.days.length
        : 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.courseTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'custom',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Course Topics',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
                fontFamily: 'custom',
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          _buildPurchaseStatusBadge(),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // New Progress Card Design
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary.withOpacity(0.15),
                  colorScheme.secondary.withOpacity(0.08),
                ],
              ),
              border: Border.all(
                color: colorScheme.primary.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Course Progress',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'custom',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Keep Going!',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'custom',
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${_completedDays.length}/${_course!.days.length}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'custom',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progressPercentage.toDouble(),
                    backgroundColor: colorScheme.surface.withOpacity(0.3),
                    color: colorScheme.primary,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_completedDays.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: colorScheme.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_completedDays.length} Completed',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'custom',
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'Start your journey',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                          fontFamily: 'custom',
                        ),
                      ),
                    Text(
                      '${(progressPercentage * 100).toStringAsFixed(0)}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'custom',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Course Modules Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Course Modules',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'custom',
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '${_course!.days.length} Modules',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'custom',
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Topics List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _course!.days.length + _numberOfAdsToInsert(),
              itemBuilder: (context, index) {
                if ((index + 1) % 4 == 0) {
                  return _buildAdSlot(index);
                }

                final itemIndex = index - (index ~/ 4);
                final day = _course!.days[itemIndex];
                final isCompleted = _completedDays.contains(day.day);

                return _buildTopicCard(
                  itemIndex,
                  day,
                  isCompleted,
                  theme,
                  colorScheme,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicCard(
      int index,
      CourseDay day,
      bool isCompleted,
      ThemeData theme,
      ColorScheme colorScheme,
      ) {
    final cleanTitle = _getCleanTitle(day.title);

    return Container(
      key: _itemKeys[index],
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.cardColor,
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _handleTopicTap(day),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Day Number Circle
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.primary.withOpacity(0.2),
                            colorScheme.primary.withOpacity(0.1),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          day.day.toString(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'custom',
                          ),
                        ),
                      ),
                    ),
                    if (isCompleted)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.scaffoldBackgroundColor,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cleanTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'custom',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            'Day ${day.day}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.6),
                              fontFamily: 'custom',
                            ),
                          ),
                          Text(
                            '.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _getTopicDescription(cleanTitle),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.6),
                                fontFamily: 'custom',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Progress bar - removed, no longer needed
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Arrow Icon
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: colorScheme.onSurface.withOpacity(0.5),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTopicDescription(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('variable') || lowerTitle.contains('data')) {
      return 'Learn data types and variables';
    } else if (lowerTitle.contains('control') || lowerTitle.contains('loop')) {
      return 'Master control flow and loops';
    } else if (lowerTitle.contains('function') ||
        lowerTitle.contains('method')) {
      return 'Understand functions and methods';
    } else if (lowerTitle.contains('class') || lowerTitle.contains('object')) {
      return 'Explore classes and objects';
    } else if (lowerTitle.contains('array') || lowerTitle.contains('list')) {
      return 'Work with arrays and collections';
    } else if (lowerTitle.contains('exception') ||
        lowerTitle.contains('error')) {
      return 'Handle exceptions and errors';
    } else if (lowerTitle.contains('inheritance') ||
        lowerTitle.contains('polymorphism')) {
      return 'Learn OOP concepts';
    } else if (lowerTitle.contains('interface') ||
        lowerTitle.contains('abstract')) {
      return 'Understand advanced OOP';
    } else {
      return 'Continue your learning journey';
    }
  }

  Widget _buildPurchaseStatusBadge() {
    if (_checkingPurchaseStatus) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Checking...',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasPurchasedAnyPlan) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.verified,
              color: Colors.green.shade700,
              size: 14,
            ),
            const SizedBox(width: 5),
            Text(
              'Premium User',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
      );
    }

    if (widget.showPremiumDialog) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lock,
              color: Colors.orange.shade700,
              size: 14,
            ),
            const SizedBox(width: 5),
            Text(
              'Premium Course',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade700,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int _numberOfAdsToInsert() {
    return (_course!.days.length / 3).floor();
  }

  Widget _buildAdSlot(int index) {
    final adProvider = context.watch<AdProvider>();

    if (index % 12 == 3 && adProvider.iscourseTopicsAd1) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        height: 120,
        child: AdWidget(ad: adProvider.courseTopicsAd1!),
      );
    }

    if (index % 12 == 7 && adProvider.iscourseTopicsAd2) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        height: 120,
        child: AdWidget(ad: adProvider.courseTopicsAd2!),
      );
    }

    if (index % 12 == 11 && adProvider.iscourseTopicsAd3) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        height: 120,
        child: AdWidget(ad: adProvider.courseTopicsAd3!),
      );
    }

    return const SizedBox.shrink();
  }
}
