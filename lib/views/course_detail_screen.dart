/*
import 'package:coding_tutor/ads/ads_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/course_controller.dart';
import '../models/course_model.dart';
import '../services/course_service.dart';
import 'compiler_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseTitle;
  final int? initialDay;
  const CourseDetailScreen({
    super.key,
    required this.courseTitle,
    this.initialDay,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  Course? _course;
  int _currentDay = 0;
  int _currentStep = 0;
  int _currentTaskIndex = 0;
  int _currentQuizIndex = 0;
  Set<int> _completedDays = {};
  bool _isLoading = true;
  int? _selectedOptionIndex;
  bool _showResult = false;
  bool _isCorrect = false;
  final CourseController _controller = CourseController();

  @override
  void initState() {
    super.initState();
    _loadCourse();
    // Preload ads after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        final adProvider = context.read<AdProvider>();
        adProvider.preloadAd(AdType.lensAd);
        debugPrint('[HomeScreen] ✅Rewarded Ads preload requested');
      } catch (e) {
        debugPrint('[HomeScreen] ⚠️ Ad preload error: $e');
      }
    });
  }

  void _goToPreviousStep() {
    final day = _course!.days[_currentDay];

    setState(() {
      if (_currentStep > 0) {
        if (_currentStep == 4) {
          if (_currentQuizIndex > 0) {
            _currentQuizIndex--;
            _selectedOptionIndex = null;
            _showResult = false;
            _isCorrect = false;
          } else {
            _currentStep = 3;
          }
        } else if (_currentStep >= 5 && day.interactiveTasks.isNotEmpty) {
          if (_currentTaskIndex > 0) {
            _currentTaskIndex--;
            _currentStep--;
          } else {
            _currentStep = 4;
          }
        } else {
          _currentStep--;
          // Initialize code editor when going back to code step
        }
      } else if (_currentDay > 0) {
        _currentDay--;
        final prevDay = _course!.days[_currentDay];
        _currentStep = prevDay.interactiveTasks.isNotEmpty
            ? 5 + prevDay.interactiveTasks.length - 1
            : prevDay.quiz.isNotEmpty
            ? 4
            : 3;
        _currentTaskIndex = prevDay.interactiveTasks.isNotEmpty
            ? prevDay.interactiveTasks.length - 1
            : 0;
        _currentQuizIndex =
        prevDay.quiz.isNotEmpty ? prevDay.quiz.length - 1 : 0;
      }
    });
  }

  Future<void> _loadCourse() async {
    final course = await CourseService.getCourseByTitle(widget.courseTitle);
    Set<int> completedDays = {};
    int startingIndex = 0;
    final progress = await _controller.getProgress(widget.courseTitle);
    final list = List<int>.from(progress['completedDays'] ?? []);
    completedDays = list.toSet();
    if (course.days.isNotEmpty) {
      startingIndex = _controller.computeStartingIndex(
        completedDays: completedDays,
        totalDays: course.days.length,
      );
    }
    if (widget.initialDay != null) {
      startingIndex = (widget.initialDay! - 1).clamp(0, course.days.length - 1);
    }

    setState(() {
      _course = course;
      _completedDays = completedDays;
      _currentDay = startingIndex;
      _currentStep = 0;
      _currentTaskIndex = 0;
      _currentQuizIndex = 0;
      _isLoading = false;
    });
  }

  Future<void> _markDayComplete(int day) async {
    await _controller.markDayComplete(widget.courseTitle, day);
    setState(() {
      _completedDays.add(day);
    });
  }

  void _advanceToNextDay() {
    final current = _course!.days[_currentDay];

    if (!_completedDays.contains(current.day)) {
      _markDayComplete(current.day);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Day ${current.day} completed successfully ✅'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    final adProvider = context.read<AdProvider>();
    if (adProvider.canShowRewarded()) {
      adProvider.showRewardedAd(AdType.lensAd, onRewarded: _proceedToNextDay);
    } else {
      _proceedToNextDay();
    }
  }

  void _proceedToNextDay() {
    if (_currentDay < _course!.days.length - 1) {
      setState(() {
        _currentDay++;
        _currentStep = 0;
        _currentTaskIndex = 0;
        _currentQuizIndex = 0;
        _selectedOptionIndex = null;
        _showResult = false;
        _isCorrect = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Course completed 🎉'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _goToNextStep() {
    final day = _course!.days[_currentDay];

    setState(() {
      if (_currentStep == 4) {
        if (_currentQuizIndex < day.quiz.length - 1) {
          _currentQuizIndex++;
          _selectedOptionIndex = null;
          _showResult = false;
          _isCorrect = false;
          return;
        } else {
          _currentStep++;
          return;
        }
      }

      if (_currentStep >= 5 && day.interactiveTasks.isNotEmpty) {
        if (_currentTaskIndex < day.interactiveTasks.length - 1) {
          _currentTaskIndex++;
          _currentStep++;
          return;
        } else {
          _finishDay();
          return;
        }
      }

      if (_currentStep < 3) {
        _currentStep++;
        // Initialize code editor when entering code step
        return;
      }

      if (day.quiz.isNotEmpty && _currentStep == 3) {
        _currentStep = 4;
        return;
      }

      if (day.interactiveTasks.isNotEmpty && _currentStep == 4) {
        _currentStep = 5;
        return;
      }

      _finishDay();
    });
  }

  Future<void> _finishDay() async {
    final current = _course!.days[_currentDay];

    if (!_completedDays.contains(current.day)) {
      await _markDayComplete(current.day);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Day ${current.day} completed 🎉'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    try {
      final adProvider = context.read<AdProvider>();

      if (adProvider.canShowRewarded()) {
        adProvider.showRewardedAd(
          AdType.lensAd,
          onRewarded: () {
            _proceedAfterFinish();
          },
        );
        return;
      }
    } catch (e) {
      debugPrint('[CourseDetail] Rewarded ad error: $e');
    }

    _proceedAfterFinish();
  }

  void _proceedAfterFinish() {
    if (!mounted) return;

    if (_currentDay < _course!.days.length - 1) {
      setState(() {
        _currentDay++;
        _currentStep = 0;
        _currentTaskIndex = 0;
        _currentQuizIndex = 0;
        _selectedOptionIndex = null;
        _showResult = false;
        _isCorrect = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Course completed 🎉'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _handleQuizNavigation() {
    final day = _course!.days[_currentDay];

    if (_currentQuizIndex < day.quiz.length - 1) {
      setState(() {
        _currentQuizIndex++;
        _selectedOptionIndex = null;
        _showResult = false;
        _isCorrect = false;
      });
    } else {
      setState(() {});
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Quiz completed ✅')));

      if (day.interactiveTasks.isNotEmpty) {
        setState(() {
          _currentStep = 5;
          _currentTaskIndex = 0;
          _selectedOptionIndex = null;
          _showResult = false;
          _isCorrect = false;
        });
      } else {
        _advanceToNextDay();
      }
    }
  }

  Widget _buildProgressIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                '${_completedDays.length}/${_course!.days.length}',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _course!.days.isNotEmpty
                ? _completedDays.length / _course!.days.length
                : 0,
            backgroundColor: Colors.grey[300],
            color: Theme.of(context).colorScheme.primary,
            minHeight: 8,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final List<String> steps = [
      'Concept',
      'Explanation',
      'Code',
      'Example',
      'Quiz',
      'Tasks',
    ];
    final int currentStepIndex = _currentStep > 4 ? 4 : _currentStep;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isActive = index == currentStepIndex;
              final isCompleted = index < currentStepIndex;

              return Column(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Theme.of(context).colorScheme.primary
                          : isCompleted
                          ? Colors.green
                          : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                          : Text(
                        '${index + 1}',
                        style: TextStyle(
                          color:
                          isActive ? Colors.white : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                      isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[600],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          Container(
            margin: const EdgeInsets.only(top: 15),
            height: 3,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(steps.length - 1, (index) {
                return Container(
                  width: (MediaQuery.of(context).size.width - 40) /
                      (steps.length - 1),
                  height: 2,
                  color: index < currentStepIndex
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[300],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text, {IconData? icon}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        if (icon != null)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
        Expanded(
          child: Text(
            text,
            textAlign: TextAlign.start,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionBody(String text) {
    final paragraphs = text
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    if (paragraphs.isEmpty && text.trim().isNotEmpty) {
      paragraphs.add(text.trim());
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: paragraphs
            .map(
              (paragraph) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildStructuredParagraph(paragraph),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildStructuredParagraph(String paragraph) {
    final lines = paragraph
        .split(RegExp(r'\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.length == 1) {
      return Text(
        lines.first,
        textAlign: TextAlign.start,
        style:
            Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) => _buildStructuredLine(line)).toList(),
    );
  }

  Widget _buildStructuredLine(String line) {
    final trimmed = line.trim();

    if (trimmed.isEmpty) {
      return const SizedBox(height: 4);
    }

    final bulletMatch = RegExp(r'^([\-•\*➤])\s+(.+)$').firstMatch(trimmed);
    final numberedMatch = RegExp(r'^(\d+[\.\)])\s+(.+)$').firstMatch(trimmed);

    if (bulletMatch != null || numberedMatch != null) {
      final match = bulletMatch ?? numberedMatch;
      if (match == null) {
        return const SizedBox(height: 4);
      }
      final prefix = bulletMatch != null
          ? '•'
          : (numberedMatch?.group(1) ?? '');
      final groupContent = match.group(2);
      if (groupContent == null) {
        return const SizedBox(height: 4);
      }
      final content = groupContent;

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$prefix ',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: Text(
                content,
                textAlign: TextAlign.start,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(height: 1.6),
              ),
            ),
          ],
        ),
      );
    }

    if (_isHeadingLine(trimmed)) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          trimmed,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        trimmed,
        textAlign: TextAlign.start,
        style:
            Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
      ),
    );
  }

  bool _isHeadingLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.endsWith(':')) return true;
    final words = trimmed.split(RegExp(r'\s+'));
    return trimmed == trimmed.toUpperCase() && words.length <= 5;
  }

  Widget _buildDefinitionView(CourseDay day) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              _sectionHeader(day.title, icon: Icons.lightbulb_outline),
              const SizedBox(height: 25),
              _sectionBody(day.definition),
            ],
          ),
          _buildNextButton('Next: Explanation', Icons.arrow_forward),
        ],
      ),
    );
  }

  Widget _buildExplanationView(CourseDay day) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              _sectionHeader('Explanation', icon: Icons.menu_book),
              const SizedBox(height: 25),
              _sectionBody(day.explanation),
              SizedBox(height: 12),
              _buildBottomNavButtons(
                onBack: _goToPreviousStep,
                onNext: _goToNextStep,
                nextLabel: 'Next: Explanation',
                nextIcon: Icons.arrow_forward,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCodeExampleView(CourseDay day) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              _sectionHeader('Code Example', icon: Icons.code),
              const SizedBox(height: 20),
              CompilerPane(
                key: ValueKey('${day.day}-${day.codeExample.hashCode}'),
                initialCode: day.codeExample,
                embedMode: true,
                forcedLanguage: _compilerLanguageOverride(),
              ),
            ],
          ),
          const SizedBox(height: 30),
          const SizedBox(height: 12),
          _buildBottomNavButtons(
            onBack: _goToPreviousStep,
            onNext: _goToNextStep,
            nextLabel: 'Next: Real-World Example',
            nextIcon: Icons.arrow_forward,
          ),
        ],
      ),
    );
  }

  String? _compilerLanguageOverride() {
    final lang = _course?.language;
    if (lang == null) return null;
    final normalized = lang.toLowerCase();
    if (normalized.contains('html')) return 'html';
    if (normalized.contains('css')) return 'css';
    if (normalized.contains('javascript') || normalized.contains('js')) {
      return 'javascript';
    }
    if (normalized.contains('python')) return 'python';
    if (normalized.contains('java') && !normalized.contains('javascript')) {
      return 'java';
    }
    if (normalized.contains('c++') || normalized.contains('cpp')) return 'cpp';
    return null;
  }

  // Rest of the widget methods remain the same...
  Widget _buildRealWorldView(CourseDay day) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              _sectionHeader('Real-World Example', icon: Icons.public),
              const SizedBox(height: 25),
              _sectionBody(day.realWorldExample),
              SizedBox(height: 12),
              _buildBottomNavButtons(
                onBack: _goToPreviousStep,
                onNext: _goToNextStep,
                nextLabel: 'Next: Quiz',
                nextIcon: Icons.arrow_forward,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskView(CourseDay day) {
    final String task = day.interactiveTasks[_currentTaskIndex];

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          children: [
            _sectionHeader(
              'Interactive Task ${_currentTaskIndex + 1}/${day.interactiveTasks.length}',
              icon: Icons.extension,
            ),
            const SizedBox(height: 25),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    task,
                    textAlign: TextAlign.start,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
        _currentTaskIndex < day.interactiveTasks.length - 1
            ? _buildBottomNavButtons(
          onBack: _goToPreviousStep,
          onNext: _goToNextStep,
          nextLabel: '',
          nextIcon: Icons.arrow_forward,
        )
            : _buildNextButton('Finish Day', Icons.celebration),
      ],
    );
  }

  Widget _buildQuizView(CourseDay day) {
    final q = day.quiz[_currentQuizIndex];

    void _goBack() {
      setState(() {
        if (_currentQuizIndex > 0) {
          _currentQuizIndex--;
        } else if (_currentStep > 3) {
          _currentStep--;
        }
        _selectedOptionIndex = null;
        _showResult = false;
        _isCorrect = false;
      });
    }

    void _goNext() {
      setState(() {
        if (_currentQuizIndex < day.quiz.length - 1) {
          _currentQuizIndex++;
        } else if (day.interactiveTasks.isNotEmpty) {
          _currentStep = 5;
          _currentTaskIndex = 0;
        } else {
          _finishDay();
        }
        _selectedOptionIndex = null;
        _showResult = false;
        _isCorrect = false;
      });
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _sectionHeader(
                  'Quiz ${_currentQuizIndex + 1}/${day.quiz.length}',
                  icon: Icons.quiz,
                ),
                const SizedBox(height: 25),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    q.question,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                ...q.options.asMap().entries.map((opt) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      borderRadius: BorderRadius.circular(12),
                      color: _selectedOptionIndex == opt.key
                          ? (_isCorrect
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2))
                          : Theme.of(context).colorScheme.surface,
                      elevation: 2,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _showResult
                            ? null
                            : () {
                          setState(() {
                            _selectedOptionIndex = opt.key;
                            _showResult = true;
                            _isCorrect = opt.value == q.answer;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          width: double.infinity,
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _selectedOptionIndex == opt.key
                                        ? (_isCorrect
                                        ? Colors.green
                                        : Colors.red)
                                        : Colors.grey,
                                    width: 2,
                                  ),
                                ),
                                child: _selectedOptionIndex == opt.key
                                    ? Icon(
                                  _isCorrect
                                      ? Icons.check
                                      : Icons.close,
                                  size: 16,
                                  color: _isCorrect
                                      ? Colors.green
                                      : Colors.red,
                                )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  opt.value,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 20),
                if (_showResult)
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _isCorrect
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isCorrect ? Colors.green : Colors.red,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isCorrect
                                      ? Icons.check_circle
                                      : Icons.error,
                                  color: _isCorrect ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isCorrect
                                      ? 'Correct!'
                                      : 'Incorrect. Try Again!',
                                  style: TextStyle(
                                    color:
                                    _isCorrect ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            if (_isCorrect &&
                                q.reasoning != null &&
                                q.reasoning!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: Text(
                                  q.reasoning!,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontStyle: FontStyle.italic),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: !_isCorrect
                            ? () {
                          setState(() {
                            _selectedOptionIndex = null;
                            _showResult = false;
                            _isCorrect = false;
                          });
                        }
                            : _handleQuizNavigation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              !_isCorrect
                                  ? 'Try Again'
                                  : _currentQuizIndex < day.quiz.length - 1
                                  ? 'Next Question'
                                  : (day.interactiveTasks.isNotEmpty
                                  ? 'Proceed to Tasks'
                                  : 'Finish Day'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              !_isCorrect ? Icons.refresh : Icons.arrow_forward,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        _buildBottomNavButtons(
          onBack: _goBack,
          onNext: _goNext,
          nextLabel: '',
          nextIcon: Icons.arrow_forward,
        ),
      ],
    );
  }

  Widget _buildBottomNavButtons({
    required VoidCallback onBack,
    required VoidCallback onNext,
    required String nextLabel,
    required IconData nextIcon,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: onBack,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[800],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back),
              SizedBox(width: 6),
              Text("Previous"),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: onNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_forward),
              SizedBox(width: 6),
              Text("Next"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNextButton(String text, IconData icon) {
    return ElevatedButton.icon(
      onPressed: _goToNextStep,
      icon: Icon(icon),
      label: Text(
        text,
        style: const TextStyle(fontSize: 16, fontFamily: 'custom'),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _course == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              Text(
                'Loading Course...',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    final day = _course!.days[_currentDay];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _course!.title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Day ${day.day}',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          _buildStepIndicator(),
          const SizedBox(height: 10),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Padding(
                key: ValueKey(
                  _currentStep * 1000 + _currentQuizIndex + _currentTaskIndex,
                ),
                padding: const EdgeInsets.all(20),
                child: _currentStep == 0
                    ? _buildDefinitionView(day)
                    : _currentStep == 1
                    ? _buildExplanationView(day)
                    : _currentStep == 2
                    ? _buildCodeExampleView(day)
                    : _currentStep == 3
                    ? _buildRealWorldView(day)
                    : _currentStep == 4
                    ? _buildQuizView(day)
                    : _currentStep >= 5 &&
                    _currentStep <
                        (5 +
                            day.interactiveTasks.length)
                    ? _buildTaskView(day)
                    : _buildQuizView(day),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
*/
/*

import 'package:coding_tutor/ads/ads_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/course_controller.dart';
import '../models/course_model.dart';
import '../services/course_service.dart';
import 'compiler_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseTitle;
  final int? initialDay;
  const CourseDetailScreen({
    super.key,
    required this.courseTitle,
    this.initialDay,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  Course? _course;
  int _currentDay = 0;
  int _currentStep = 0;
  int _currentTaskIndex = 0;
  int _currentQuizIndex = 0;
  Set<int> _completedDays = {};
  bool _isLoading = true;
  int? _selectedOptionIndex;
  bool _showResult = false;
  bool _isCorrect = false;
  final CourseController _controller = CourseController();

  @override
  void initState() {
    super.initState();
    _loadCourse();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final adProvider = context.read<AdProvider>();
        adProvider.preloadAd(AdType.lensAd);
        debugPrint('[HomeScreen] ✅Rewarded Ads preload requested');
      } catch (e) {
        debugPrint('[HomeScreen] ⚠️ Ad preload error: $e');
      }
    });
  }

  void _goToPreviousStep() {
    final day = _course!.days[_currentDay];
    setState(() {
      if (_currentStep > 0) {
        if (_currentStep == 4) {
          if (_currentQuizIndex > 0) {
            _currentQuizIndex--;
            _selectedOptionIndex = null;
            _showResult = false;
            _isCorrect = false;
          } else {
            _currentStep = 3;
          }
        } else if (_currentStep >= 5 && day.interactiveTasks.isNotEmpty) {
          if (_currentTaskIndex > 0) {
            _currentTaskIndex--;
            _currentStep--;
          } else {
            _currentStep = 4;
          }
        } else {
          _currentStep--;
        }
      } else if (_currentDay > 0) {
        _currentDay--;
        final prevDay = _course!.days[_currentDay];
        _currentStep = prevDay.interactiveTasks.isNotEmpty
            ? 5 + prevDay.interactiveTasks.length - 1
            : prevDay.quiz.isNotEmpty ? 4 : 3;
        _currentTaskIndex = prevDay.interactiveTasks.isNotEmpty
            ? prevDay.interactiveTasks.length - 1 : 0;
        _currentQuizIndex =
        prevDay.quiz.isNotEmpty ? prevDay.quiz.length - 1 : 0;
      }
    });
  }

  Future<void> _loadCourse() async {
    final course = await CourseService.getCourseByTitle(widget.courseTitle);
    Set<int> completedDays = {};
    int startingIndex = 0;
    final progress = await _controller.getProgress(widget.courseTitle);
    final list = List<int>.from(progress['completedDays'] ?? []);
    completedDays = list.toSet();
    if (course.days.isNotEmpty) {
      startingIndex = _controller.computeStartingIndex(
        completedDays: completedDays,
        totalDays: course.days.length,
      );
    }
    if (widget.initialDay != null) {
      startingIndex = (widget.initialDay! - 1).clamp(0, course.days.length - 1);
    }

    setState(() {
      _course = course;
      _completedDays = completedDays;
      _currentDay = startingIndex;
      _currentStep = 0;
      _currentTaskIndex = 0;
      _currentQuizIndex = 0;
      _isLoading = false;
    });
  }

  Future<void> _markDayComplete(int day) async {
    await _controller.markDayComplete(widget.courseTitle, day);
    setState(() {
      _completedDays.add(day);
    });
  }

  void _advanceToNextDay() {
    final current = _course!.days[_currentDay];
    if (!_completedDays.contains(current.day)) {
      _markDayComplete(current.day);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Day ${current.day} completed successfully ✅'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    final adProvider = context.read<AdProvider>();
    if (adProvider.canShowRewarded()) {
      adProvider.showRewardedAd(AdType.lensAd, onRewarded: _proceedToNextDay);
    } else {
      _proceedToNextDay();
    }
  }

  void _proceedToNextDay() {
    if (_currentDay < _course!.days.length - 1) {
      setState(() {
        _currentDay++;
        _currentStep = 0;
        _currentTaskIndex = 0;
        _currentQuizIndex = 0;
        _selectedOptionIndex = null;
        _showResult = false;
        _isCorrect = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Course completed 🎉'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _goToNextStep() {
    final day = _course!.days[_currentDay];
    setState(() {
      if (_currentStep == 4) {
        if (_currentQuizIndex < day.quiz.length - 1) {
          _currentQuizIndex++;
          _selectedOptionIndex = null;
          _showResult = false;
          _isCorrect = false;
          return;
        } else {
          _currentStep++;
          return;
        }
      }
      if (_currentStep >= 5 && day.interactiveTasks.isNotEmpty) {
        if (_currentTaskIndex < day.interactiveTasks.length - 1) {
          _currentTaskIndex++;
          _currentStep++;
          return;
        } else {
          _finishDay();
          return;
        }
      }
      if (_currentStep < 3) {
        _currentStep++;
        return;
      }
      if (day.quiz.isNotEmpty && _currentStep == 3) {
        _currentStep = 4;
        return;
      }
      if (day.interactiveTasks.isNotEmpty && _currentStep == 4) {
        _currentStep = 5;
        return;
      }
      _finishDay();
    });
  }

  Future<void> _finishDay() async {
    final current = _course!.days[_currentDay];
    if (!_completedDays.contains(current.day)) {
      await _markDayComplete(current.day);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Day ${current.day} completed 🎉'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    try {
      final adProvider = context.read<AdProvider>();
      if (adProvider.canShowRewarded()) {
        adProvider.showRewardedAd(AdType.lensAd, onRewarded: () {
          _proceedAfterFinish();
        });
        return;
      }
    } catch (e) {
      debugPrint('[CourseDetail] Rewarded ad error: $e');
    }
    _proceedAfterFinish();
  }

  void _proceedAfterFinish() {
    if (!mounted) return;
    if (_currentDay < _course!.days.length - 1) {
      setState(() {
        _currentDay++;
        _currentStep = 0;
        _currentTaskIndex = 0;
        _currentQuizIndex = 0;
        _selectedOptionIndex = null;
        _showResult = false;
        _isCorrect = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Course completed 🎉'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _handleQuizNavigation() {
    final day = _course!.days[_currentDay];
    if (_currentQuizIndex < day.quiz.length - 1) {
      setState(() {
        _currentQuizIndex++;
        _selectedOptionIndex = null;
        _showResult = false;
        _isCorrect = false;
      });
    } else {
      setState(() {});
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Quiz completed ✅')));
      if (day.interactiveTasks.isNotEmpty) {
        setState(() {
          _currentStep = 5;
          _currentTaskIndex = 0;
          _selectedOptionIndex = null;
          _showResult = false;
          _isCorrect = false;
        });
      } else {
        _advanceToNextDay();
      }
    }
  }

  Widget _buildProgressIndicator() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progressPercentage = _course!.days.isNotEmpty
        ? _completedDays.length / _course!.days.length : 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.cardColor,
        border: Border.all(color: colorScheme.primary.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progress', style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600, fontFamily: 'custom')),
              Text('${_completedDays.length}/${_course!.days.length}',
                  style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary, fontWeight: FontWeight.bold,
                      fontFamily: 'custom')),
            ],
          ),
          const SizedBox(height: 12),
      */
/*    ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: progressPercentage,
                backgroundColor: colorScheme.surface.withOpacity(0.5),
                color: colorScheme.primary, minHeight: 8),
          ),*//*

        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final List<Map<String, dynamic>> steps = [
      {'name': 'Concept', 'icon': Icons.lightbulb_outline},
      {'name': 'Explanation', 'icon': Icons.menu_book},
      {'name': 'Code', 'icon': Icons.code},
      {'name': 'Example', 'icon': Icons.public},
      {'name': 'Quiz', 'icon': Icons.quiz},
      {'name': 'Tasks', 'icon': Icons.check_circle_outline},
    ];
    final int currentStepIndex = _currentStep > 4 ? 5 : _currentStep;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.cardColor,
        border: Border.all(color: colorScheme.primary.withOpacity(0.2), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (index) {
          final step = steps[index];
          final isActive = index == currentStepIndex;
          final isCompleted = index < currentStepIndex;

          return Expanded(
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isActive ? colorScheme.primary :
                    isCompleted ? colorScheme.primary :
                    colorScheme.surface.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCompleted ? Icons.check : step['icon'],
                    color: isActive || isCompleted ? Colors.white :
                    colorScheme.onSurface.withOpacity(0.4),
                    size: 22,
                  ),
                ),
                const SizedBox(height: 6),
                Text(step['name'], textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        color: isActive ? colorScheme.primary :
                        colorScheme.onSurface.withOpacity(0.6),
                        fontFamily: 'custom'),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDayBadge() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final day = _course!.days[_currentDay];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
      ),
      child: Center(
        child: Text('Day ${day.day}',
            style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.primary, fontWeight: FontWeight.bold,
                fontFamily: 'custom')),
      ),
    );
  }

  Widget _sectionHeader(String text, {IconData? icon}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withOpacity(0.15),
            colorScheme.secondary.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          if (icon != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colorScheme.primary, size: 26),
            ),
          if (icon != null) const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold, color: colorScheme.primary,
                fontFamily: 'custom')),
          ),
        ],
      ),
    );
  }

  Widget _sectionBody(String text) {
    final theme = Theme.of(context);
    final paragraphs = text.split(RegExp(r'\n\s*\n')).map((p) => p.trim())
        .where((p) => p.isNotEmpty).toList();

    if (paragraphs.isEmpty && text.trim().isNotEmpty) {
      paragraphs.add(text.trim());
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: paragraphs.map((paragraph) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(paragraph, textAlign: TextAlign.start,
              style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.6, fontFamily: 'custom')),
        )).toList(),
      ),
    );
  }

  Widget _buildDefinitionView(CourseDay day) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _sectionHeader(day.title, icon: Icons.lightbulb_outline),
          const SizedBox(height: 16),
          _sectionBody(day.definition),
          const SizedBox(height: 20),
          _buildNextButton('Next: Explanation', Icons.arrow_forward),
        ],
      ),
    );
  }

  Widget _buildExplanationView(CourseDay day) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _sectionHeader('Explanation', icon: Icons.menu_book),
          const SizedBox(height: 16),
          _sectionBody(day.explanation),
          const SizedBox(height: 20),
          _buildBottomNavButtons(
              onBack: _goToPreviousStep, onNext: _goToNextStep,
              nextLabel: 'Next', nextIcon: Icons.arrow_forward),
        ],
      ),
    );
  }

  Widget _buildCodeExampleView(CourseDay day) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _sectionHeader('Code Example', icon: Icons.code),
          const SizedBox(height: 16),
          CompilerPane(
              key: ValueKey('${day.day}-${day.codeExample.hashCode}'),
              initialCode: day.codeExample, embedMode: true,
              forcedLanguage: _compilerLanguageOverride()),
          const SizedBox(height: 20),
          _buildBottomNavButtons(
              onBack: _goToPreviousStep, onNext: _goToNextStep,
              nextLabel: 'Next', nextIcon: Icons.arrow_forward),
        ],
      ),
    );
  }

  String? _compilerLanguageOverride() {
    final lang = _course?.language;
    if (lang == null) return null;
    final normalized = lang.toLowerCase();
    if (normalized.contains('html')) return 'html';
    if (normalized.contains('css')) return 'css';
    if (normalized.contains('javascript') || normalized.contains('js')) return 'javascript';
    if (normalized.contains('python')) return 'python';
    if (normalized.contains('java') && !normalized.contains('javascript')) return 'java';
    if (normalized.contains('c++') || normalized.contains('cpp')) return 'cpp';
    return null;
  }

  Widget _buildRealWorldView(CourseDay day) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _sectionHeader('Real-World Example', icon: Icons.public),
          const SizedBox(height: 16),
          _sectionBody(day.realWorldExample),
          const SizedBox(height: 20),
          _buildBottomNavButtons(
              onBack: _goToPreviousStep, onNext: _goToNextStep,
              nextLabel: 'Next', nextIcon: Icons.arrow_forward),
        ],
      ),
    );
  }

  Widget _buildTaskView(CourseDay day) {
    final String task = day.interactiveTasks[_currentTaskIndex];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _sectionHeader(
                    'Interactive Task ${_currentTaskIndex + 1}/${day.interactiveTasks.length}',
                    icon: Icons.extension),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.touch_app, size: 38,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 14),
                      Text(task, textAlign: TextAlign.start,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.5, fontFamily: 'custom')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _currentTaskIndex < day.interactiveTasks.length - 1
            ? _buildBottomNavButtons(onBack: _goToPreviousStep,
            onNext: _goToNextStep, nextLabel: 'Next',
            nextIcon: Icons.arrow_forward)
            : _buildBottomNavButtons(onBack: _goToPreviousStep,
            onNext: _finishDay, nextLabel: 'Finish',
            nextIcon: Icons.celebration),
      ],
    );
  }

  Widget _buildQuizView(CourseDay day) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final q = day.quiz[_currentQuizIndex];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                  ),
                  child: Text('Quiz ${_currentQuizIndex + 1}/${day.quiz.length}',
                      style: theme.textTheme.titleSmall?.copyWith(
                          color: colorScheme.primary, fontWeight: FontWeight.bold,
                          fontFamily: 'custom')),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.cardColor, borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
                  ),
                  child: Text(q.question, textAlign: TextAlign.start,
                      style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600, height: 1.5, fontFamily: 'custom')),
                ),
                const SizedBox(height: 20),
                ...q.options.asMap().entries.map((opt) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: _selectedOptionIndex == opt.key
                          ? (_isCorrect ? Colors.green.withOpacity(0.2) :
                      Colors.red.withOpacity(0.2)) : theme.cardColor,
                      border: Border.all(
                          color: _selectedOptionIndex == opt.key
                              ? (_isCorrect ? Colors.green : Colors.red)
                              : colorScheme.primary.withOpacity(0.2)),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _showResult ? null : () {
                        setState(() {
                          _selectedOptionIndex = opt.key;
                          _showResult = true;
                          _isCorrect = opt.value == q.answer;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 22, height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: _selectedOptionIndex == opt.key
                                        ? (_isCorrect ? Colors.green : Colors.red)
                                        : Colors.grey, width: 2),
                              ),
                              child: _selectedOptionIndex == opt.key
                                  ? Icon(_isCorrect ? Icons.check : Icons.close,
                                  size: 14,
                                  color: _isCorrect ? Colors.green : Colors.red)
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(opt.value,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 15, fontFamily: 'custom')),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 20),
                if (_showResult)
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _isCorrect ? Colors.green.withOpacity(0.1) :
                          Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _isCorrect ? Colors.green : Colors.red, width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_isCorrect ? Icons.check_circle : Icons.error,
                                color: _isCorrect ? Colors.green : Colors.red),
                            const SizedBox(width: 8),
                            Text(_isCorrect ? 'Correct!' : 'Incorrect. Try Again!',
                                style: TextStyle(
                                    color: _isCorrect ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold, fontSize: 15,
                                    fontFamily: 'custom')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: !_isCorrect ? () {
                          setState(() {
                            _selectedOptionIndex = null;
                            _showResult = false;
                            _isCorrect = false;
                          });
                        } : _handleQuizNavigation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(!_isCorrect ? 'Try Again' :
                        _currentQuizIndex < day.quiz.length - 1
                            ? 'Next Question'
                            : (day.interactiveTasks.isNotEmpty
                            ? 'Proceed to Tasks' : 'Finish Day'),
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildBottomNavButtons(
            onBack: _goToPreviousStep,
            onNext: () {
              setState(() {
                if (_currentQuizIndex < day.quiz.length - 1) {
                  _currentQuizIndex++;
                } else if (day.interactiveTasks.isNotEmpty) {
                  _currentStep = 5;
                  _currentTaskIndex = 0;
                } else {
                  _finishDay();
                }
                _selectedOptionIndex = null;
                _showResult = false;
                _isCorrect = false;
              });
            },
            nextLabel: 'Next', nextIcon: Icons.arrow_forward),
      ],
    );
  }

  Widget _buildBottomNavButtons({
    required VoidCallback onBack, required VoidCallback onNext,
    required String nextLabel, required IconData nextIcon}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: onBack,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [Icon(Icons.arrow_back, size: 18),
                  SizedBox(width: 6), Text("Previous",
                      style: TextStyle(fontFamily: 'custom'))],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [Text("Next", style: TextStyle(fontFamily: 'custom')),
                  SizedBox(width: 6), Icon(Icons.arrow_forward, size: 18)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton.icon(
        onPressed: _goToNextStep,
        icon: Icon(icon),
        label: Text(text, style: const TextStyle(fontSize: 15, fontFamily: 'custom')),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _course == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              Text('Loading Course...',
                  style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      );
    }

    final day = _course!.days[_currentDay];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_course!.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold, fontFamily: 'custom')),
            Text('Day ${day.day}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600], fontFamily: 'custom')),
          ],
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          _buildStepIndicator(),
          _buildDayBadge(),
          const SizedBox(height: 10),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Padding(
                key: ValueKey(
                    _currentStep * 1000 + _currentQuizIndex + _currentTaskIndex),
                padding: const EdgeInsets.all(20),
                child: _currentStep == 0
                    ? _buildDefinitionView(day)
                    : _currentStep == 1
                    ? _buildExplanationView(day)
                    : _currentStep == 2
                    ? _buildCodeExampleView(day)
                    : _currentStep == 3
                    ? _buildRealWorldView(day)
                    : _currentStep == 4
                    ? _buildQuizView(day)
                    : _currentStep >= 5 &&
                    _currentStep <
                        (5 + day.interactiveTasks.length)
                    ? _buildTaskView(day)
                    : _buildQuizView(day),
              ),
            ),
          ),
        ],
      ),
    );
  }
}*//*
import 'package:coding_tutor/ads/ads_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/course_controller.dart';
import '../models/course_model.dart';
import '../services/course_service.dart';
import 'compiler_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseTitle;
  final int? initialDay;
  const CourseDetailScreen({super.key, required this.courseTitle, this.initialDay});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  Course? _course;
  int _currentDay = 0;
  int _currentStep = 0;
  int _currentTaskIndex = 0;
  int _currentQuizIndex = 0;
  Set<int> _completedDays = {};
  bool _isLoading = true;
  int? _selectedOptionIndex;
  bool _showResult = false;
  bool _isCorrect = false;
  final CourseController _controller = CourseController();

  @override
  void initState() {
    super.initState();
    _loadCourse();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        context.read<AdProvider>().preloadAd(AdType.lensAd);
      } catch (e) {
        debugPrint('[CourseDetail] Ad preload error: $e');
      }
    });
  }

  Future<void> _loadCourse() async {
    final course = await CourseService.getCourseByTitle(widget.courseTitle);
    final progress = await _controller.getProgress(widget.courseTitle);
    Set<int> completedDays = List<int>.from(progress['completedDays'] ?? []).toSet();

    int startingIndex = 0;
    if (course.days.isNotEmpty) {
      startingIndex = _controller.computeStartingIndex(
          completedDays: completedDays, totalDays: course.days.length);
    }
    if (widget.initialDay != null) {
      startingIndex = (widget.initialDay! - 1).clamp(0, course.days.length - 1);
    }

    setState(() {
      _course = course;
      _completedDays = completedDays;
      _currentDay = startingIndex;
      _isLoading = false;
    });
  }

  Future<void> _markDayComplete(int day) async {
    await _controller.markDayComplete(widget.courseTitle, day);
    setState(() => _completedDays.add(day));
  }

  void _goToPreviousStep() {
    final day = _course!.days[_currentDay];
    setState(() {
      if (_currentStep > 0) {
        if (_currentStep == 4 && _currentQuizIndex > 0) {
          _currentQuizIndex--;
          _clearQuizState();
        } else if (_currentStep >= 5 && day.interactiveTasks.isNotEmpty && _currentTaskIndex > 0) {
          _currentTaskIndex--;
          _currentStep--;
        } else {
          _currentStep--;
        }
      } else if (_currentDay > 0) {
        _currentDay--;
        final prevDay = _course!.days[_currentDay];
        _currentStep = prevDay.interactiveTasks.isNotEmpty
            ? 5 + prevDay.interactiveTasks.length - 1
            : prevDay.quiz.isNotEmpty ? 4 : 3;
        _currentTaskIndex = prevDay.interactiveTasks.length - 1;
        _currentQuizIndex = prevDay.quiz.length - 1;
      }
    });
  }

  void _goToNextStep() {
    final day = _course!.days[_currentDay];
    setState(() {
      if (_currentStep == 4) {
        if (_currentQuizIndex < day.quiz.length - 1) {
          _currentQuizIndex++;
          _clearQuizState();
        } else {
          _currentStep++;
        }
      } else if (_currentStep >= 5 && day.interactiveTasks.isNotEmpty) {
        if (_currentTaskIndex < day.interactiveTasks.length - 1) {
          _currentTaskIndex++;
          _currentStep++;
        } else {
          _finishDay();
        }
      } else if (_currentStep < 3) {
        _currentStep++;
      } else if (day.quiz.isNotEmpty && _currentStep == 3) {
        _currentStep = 4;
      } else if (day.interactiveTasks.isNotEmpty && _currentStep == 4) {
        _currentStep = 5;
      } else {
        _finishDay();
      }
    });
  }

  void _clearQuizState() {
    _selectedOptionIndex = null;
    _showResult = false;
    _isCorrect = false;
  }

  Future<void> _finishDay() async {
    final current = _course!.days[_currentDay];
    if (!_completedDays.contains(current.day)) {
      await _markDayComplete(current.day);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Day ${current.day} completed 🎉'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    }

    try {
      final adProvider = context.read<AdProvider>();
      if (adProvider.canShowRewarded()) {
        adProvider.showRewardedAd(AdType.lensAd, onRewarded: _proceedAfterFinish);
        return;
      }
    } catch (e) {
      debugPrint('[CourseDetail] Ad error: $e');
    }
    _proceedAfterFinish();
  }

  void _proceedAfterFinish() {
    if (!mounted) return;
    if (_currentDay < _course!.days.length - 1) {
      setState(() {
        _currentDay++;
        _currentStep = 0;
        _currentTaskIndex = 0;
        _currentQuizIndex = 0;
        _clearQuizState();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Course completed 🎉'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    }
  }

  void _handleQuizNavigation() {
    final day = _course!.days[_currentDay];
    if (_currentQuizIndex < day.quiz.length - 1) {
      setState(() {
        _currentQuizIndex++;
        _clearQuizState();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz completed ✅')));
      if (day.interactiveTasks.isNotEmpty) {
        setState(() {
          _currentStep = 5;
          _currentTaskIndex = 0;
          _clearQuizState();
        });
      } else {
        _finishDay();
      }
    }
  }

  Widget _buildProgressIndicator() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = _completedDays.length / _course!.days.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.cardColor,
        border: Border.all(color: colorScheme.primary.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progress', style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600, fontFamily: 'custom')),
              Text('${_completedDays.length}/${_course!.days.length}',
                  style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary, fontWeight: FontWeight.bold,
                      fontFamily: 'custom')),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: colorScheme.surface.withOpacity(0.5),
              color: colorScheme.primary,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final steps = [
      {'name': 'Concept', 'icon': Icons.lightbulb_outline},
      {'name': 'Explanation', 'icon': Icons.menu_book},
      {'name': 'Code', 'icon': Icons.code},
      {'name': 'Example', 'icon': Icons.public},
      {'name': 'Quiz', 'icon': Icons.quiz},
      {'name': 'Tasks', 'icon': Icons.check_circle_outline},
    ];
    final currentIndex = _currentStep > 4 ? 5 : _currentStep;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.cardColor,
        border: Border.all(color: colorScheme.primary.withOpacity(0.2), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (i) {
          final step = steps[i];
          final isActive = i == currentIndex;
          final isCompleted = i < currentIndex;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: (isActive || isCompleted) ? colorScheme.primary :
                          colorScheme.surface.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCompleted ? Icons.check : step['icon'] as IconData,
                          color: (isActive || isCompleted) ? Colors.white :
                          colorScheme.onSurface.withOpacity(0.4),
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(step['name'] as String,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              color: isActive ? colorScheme.primary :
                              colorScheme.onSurface.withOpacity(0.6),
                              fontFamily: 'custom'),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (i < steps.length - 1)
                  Container(
                    width: 12, height: 2,
                    color: isCompleted ? colorScheme.primary : Colors.grey.withOpacity(0.3),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDayBadge() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final day = _course!.days[_currentDay];

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
        ),
        child: Text('Day ${day.day}',
            style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.primary, fontWeight: FontWeight.bold,
                fontFamily: 'custom')),
      ),
    );
  }

  Widget _buildContentContainer(String title, String content, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                        fontFamily: 'custom')),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(content,
              textAlign: TextAlign.start,
              style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.6, fontFamily: 'custom')),
        ],
      ),
    );
  }

  Widget _buildDefinitionView(CourseDay day) =>
      SingleChildScrollView(
        child: Column(
          children: [
            _buildContentContainer(day.title, day.definition, Icons.lightbulb_outline),
            const SizedBox(height: 20),
            _buildSingleButton('Next: Explanation', Icons.arrow_forward, _goToNextStep),
          ],
        ),
      );

  Widget _buildExplanationView(CourseDay day) =>
      SingleChildScrollView(
        child: Column(
          children: [
            _buildContentContainer('Explanation', day.explanation, Icons.menu_book),
            const SizedBox(height: 20),
            _buildNavButtons(),
          ],
        ),
      );

  Widget _buildCodeExampleView(CourseDay day) =>
      SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.code,
                            color: Theme.of(context).colorScheme.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('Code Example',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                                fontFamily: 'custom')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CompilerPane(
                      key: ValueKey('${day.day}-${day.codeExample.hashCode}'),
                      initialCode: day.codeExample,
                      embedMode: true,
                      forcedLanguage: _getLanguage()),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildNavButtons(),
          ],
        ),
      );

  String? _getLanguage() {
    final lang = _course?.language?.toLowerCase();
    if (lang == null) return null;
    if (lang.contains('html')) return 'html';
    if (lang.contains('css')) return 'css';
    if (lang.contains('javascript') || lang.contains('js')) return 'javascript';
    if (lang.contains('python')) return 'python';
    if (lang.contains('java') && !lang.contains('javascript')) return 'java';
    if (lang.contains('c++') || lang.contains('cpp')) return 'cpp';
    return null;
  }

  Widget _buildRealWorldView(CourseDay day) =>
      SingleChildScrollView(
        child: Column(
          children: [
            _buildContentContainer('Real-World Example', day.realWorldExample, Icons.public),
            const SizedBox(height: 20),
            _buildNavButtons(),
          ],
        ),
      );

  Widget _buildTaskView(CourseDay day) {
    final task = day.interactiveTasks[_currentTaskIndex];
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.extension, color: colorScheme.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                            'Interactive Task ${_currentTaskIndex + 1}/${day.interactiveTasks.length}',
                            style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                                fontFamily: 'custom')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Icon(Icons.touch_app, size: 38, color: colorScheme.primary),
                  const SizedBox(height: 14),
                  Text(task,
                      textAlign: TextAlign.start,
                      style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.5, fontFamily: 'custom')),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildNavButtons(),
      ],
    );
  }

  Widget _buildQuizView(CourseDay day) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final q = day.quiz[_currentQuizIndex];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                  ),
                  child: Text('Quiz ${_currentQuizIndex + 1}/${day.quiz.length}',
                      style: theme.textTheme.titleSmall?.copyWith(
                          color: colorScheme.primary, fontWeight: FontWeight.bold,
                          fontFamily: 'custom')),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primary.withOpacity(0.15),
                        colorScheme.secondary.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.primary.withOpacity(0.4), width: 1.5),
                  ),
                  child: Text(q.question,
                      textAlign: TextAlign.start,
                      style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.5,
                          fontSize: 16,
                          fontFamily: 'custom')),
                ),
                const SizedBox(height: 20),
                ...q.options.asMap().entries.map((opt) {
                  final isSelected = _selectedOptionIndex == opt.key;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected
                          ? (_isCorrect ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2))
                          : theme.cardColor,
                      border: Border.all(
                          color: isSelected
                              ? (_isCorrect ? Colors.green : Colors.red)
                              : colorScheme.primary.withOpacity(0.2)),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _showResult ? null : () {
                        setState(() {
                          _selectedOptionIndex = opt.key;
                          _showResult = true;
                          _isCorrect = opt.value == q.answer;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 22, height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: isSelected
                                        ? (_isCorrect ? Colors.green : Colors.red)
                                        : Colors.grey,
                                    width: 2),
                              ),
                              child: isSelected
                                  ? Icon(_isCorrect ? Icons.check : Icons.close,
                                  size: 14, color: _isCorrect ? Colors.green : Colors.red)
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(opt.value,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 15, fontFamily: 'custom')),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                if (_showResult) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _isCorrect ? Colors.green : Colors.red),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_isCorrect ? Icons.check_circle : Icons.error,
                            color: _isCorrect ? Colors.green : Colors.red),
                        const SizedBox(width: 8),
                        Text(_isCorrect ? 'Correct!' : 'Incorrect. Try Again!',
                            style: TextStyle(
                                color: _isCorrect ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                fontFamily: 'custom')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: !_isCorrect
                        ? () => setState(_clearQuizState)
                        : _handleQuizNavigation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                        !_isCorrect
                            ? 'Try Again'
                            : _currentQuizIndex < day.quiz.length - 1
                            ? 'Next Question'
                            : (day.interactiveTasks.isNotEmpty ? 'Proceed to Tasks' : 'Finish Day'),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildNavButtons(),
      ],
    );
  }

  Widget _buildNavButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _goToPreviousStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, size: 18),
                  SizedBox(width: 6),
                  Text("Previous", style: TextStyle(fontFamily: 'custom')),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _goToNextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Next", style: TextStyle(fontFamily: 'custom')),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleButton(String text, IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(text, style: const TextStyle(fontSize: 15, fontFamily: 'custom')),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _course == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 20),
              Text('Loading Course...', style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      );
    }

    final day = _course!.days[_currentDay];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_course!.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold, fontFamily: 'custom')),
            Text('Day ${day.day}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600], fontFamily: 'custom')),
          ],
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          _buildStepIndicator(),
          _buildDayBadge(),
          const SizedBox(height: 10),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Padding(
                key: ValueKey(_currentStep * 1000 + _currentQuizIndex + _currentTaskIndex),
                padding: const EdgeInsets.all(20),
                child: _currentStep == 0
                    ? _buildDefinitionView(day)
                    : _currentStep == 1
                    ? _buildExplanationView(day)
                    : _currentStep == 2
                    ? _buildCodeExampleView(day)
                    : _currentStep == 3
                    ? _buildRealWorldView(day)
                    : _currentStep == 4
                    ? _buildQuizView(day)
                    : _buildTaskView(day),
              ),
            ),
          ),
        ],
      ),
    );
  }
}*/
import 'package:coding_tutor/ads/ads_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/course_controller.dart';
import '../models/course_model.dart';
import '../services/course_service.dart';
import 'compiler_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseTitle;
  final int? initialDay;
  const CourseDetailScreen({super.key, required this.courseTitle, this.initialDay});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  Course? _course;
  int _currentDay = 0;
  int _currentStep = 0;
  int _currentTaskIndex = 0;
  int _currentQuizIndex = 0;
  Set<int> _completedDays = {};
  bool _isLoading = true;
  int? _selectedOptionIndex;
  bool _showResult = false;
  bool _isCorrect = false;
  final CourseController _controller = CourseController();

  @override
  void initState() {
    super.initState();
    _loadCourse();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        context.read<AdProvider>().preloadAd(AdType.lensAd);
      } catch (e) {
        debugPrint('[CourseDetail] Ad preload error: $e');
      }
    });
  }

  Future<void> _loadCourse() async {
    final course = await CourseService.getCourseByTitle(widget.courseTitle);
    final progress = await _controller.getProgress(widget.courseTitle);
    Set<int> completedDays = List<int>.from(progress['completedDays'] ?? []).toSet();

    int startingIndex = 0;
    if (course.days.isNotEmpty) {
      startingIndex = _controller.computeStartingIndex(
          completedDays: completedDays, totalDays: course.days.length);
    }
    if (widget.initialDay != null) {
      startingIndex = (widget.initialDay! - 1).clamp(0, course.days.length - 1);
    }

    setState(() {
      _course = course;
      _completedDays = completedDays;
      _currentDay = startingIndex;
      _isLoading = false;
    });
  }

  Future<void> _markDayComplete(int day) async {
    await _controller.markDayComplete(widget.courseTitle, day);
    setState(() => _completedDays.add(day));
  }

  void _goToPreviousStep() {
    final day = _course!.days[_currentDay];
    setState(() {
      if (_currentStep > 0) {
        if (_currentStep == 4 && _currentQuizIndex > 0) {
          _currentQuizIndex--;
          _clearQuizState();
        } else if (_currentStep >= 5 && day.interactiveTasks.isNotEmpty && _currentTaskIndex > 0) {
          _currentTaskIndex--;
          _currentStep--;
        } else {
          _currentStep--;
        }
      } else if (_currentDay > 0) {
        _currentDay--;
        final prevDay = _course!.days[_currentDay];
        _currentStep = prevDay.interactiveTasks.isNotEmpty
            ? 5 + prevDay.interactiveTasks.length - 1
            : prevDay.quiz.isNotEmpty ? 4 : 3;
        _currentTaskIndex = prevDay.interactiveTasks.length - 1;
        _currentQuizIndex = prevDay.quiz.length - 1;
      }
    });
  }

  void _goToNextStep() {
    final day = _course!.days[_currentDay];
    setState(() {
      if (_currentStep == 4) {
        if (_currentQuizIndex < day.quiz.length - 1) {
          _currentQuizIndex++;
          _clearQuizState();
        } else {
          _currentStep++;
        }
      } else if (_currentStep >= 5 && day.interactiveTasks.isNotEmpty) {
        if (_currentTaskIndex < day.interactiveTasks.length - 1) {
          _currentTaskIndex++;
          _currentStep++;
        } else {
          _finishDay();
        }
      } else if (_currentStep < 3) {
        _currentStep++;
      } else if (day.quiz.isNotEmpty && _currentStep == 3) {
        _currentStep = 4;
      } else if (day.interactiveTasks.isNotEmpty && _currentStep == 4) {
        _currentStep = 5;
      } else {
        _finishDay();
      }
    });
  }

  void _clearQuizState() {
    _selectedOptionIndex = null;
    _showResult = false;
    _isCorrect = false;
  }

  Future<void> _finishDay() async {
    final current = _course!.days[_currentDay];
    if (!_completedDays.contains(current.day)) {
      await _markDayComplete(current.day);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Day ${current.day} completed 🎉'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    }

    try {
      final adProvider = context.read<AdProvider>();
      if (adProvider.canShowRewarded()) {
        adProvider.showRewardedAd(AdType.lensAd, onRewarded: _proceedAfterFinish);
        return;
      }
    } catch (e) {
      debugPrint('[CourseDetail] Ad error: $e');
    }
    _proceedAfterFinish();
  }

  void _proceedAfterFinish() {
    if (!mounted) return;
    if (_currentDay < _course!.days.length - 1) {
      setState(() {
        _currentDay++;
        _currentStep = 0;
        _currentTaskIndex = 0;
        _currentQuizIndex = 0;
        _clearQuizState();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Course completed 🎉'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    }
  }

  void _handleQuizNavigation() {
    final day = _course!.days[_currentDay];
    if (_currentQuizIndex < day.quiz.length - 1) {
      setState(() {
        _currentQuizIndex++;
        _clearQuizState();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz completed ✅')));
      if (day.interactiveTasks.isNotEmpty) {
        setState(() {
          _currentStep = 5;
          _currentTaskIndex = 0;
          _clearQuizState();
        });
      } else {
        _finishDay();
      }
    }
  }

  Widget _buildProgressIndicator() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = _completedDays.length / _course!.days.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.cardColor,
        border: Border.all(color: colorScheme.primary.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progress', style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600, fontFamily: 'custom')),
              Text('${_completedDays.length}/${_course!.days.length}',
                  style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary, fontWeight: FontWeight.bold,
                      fontFamily: 'custom')),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: colorScheme.surface.withOpacity(0.5),
              color: colorScheme.primary,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final steps = [
      {'name': 'Concept', 'icon': Icons.lightbulb_outline},
      {'name': 'Explanation', 'icon': Icons.menu_book},
      {'name': 'Code', 'icon': Icons.code},
      {'name': 'Example', 'icon': Icons.public},
      {'name': 'Quiz', 'icon': Icons.quiz},
      {'name': 'Tasks', 'icon': Icons.check_circle_outline},
    ];
    final currentIndex = _currentStep > 4 ? 5 : _currentStep;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.cardColor,
        border: Border.all(color: colorScheme.primary.withOpacity(0.2), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (i) {
          final step = steps[i];
          final isActive = i == currentIndex;
          final isCompleted = i < currentIndex;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: (isActive || isCompleted) ? colorScheme.primary :
                          colorScheme.surface.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCompleted ? Icons.check : step['icon'] as IconData,
                          color: (isActive || isCompleted) ? Colors.white :
                          colorScheme.onSurface.withOpacity(0.4),
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(step['name'] as String,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              color: isActive ? colorScheme.primary :
                              colorScheme.onSurface.withOpacity(0.6),
                              fontFamily: 'custom'),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (i < steps.length - 1)
                  Container(
                    width: 12, height: 2,
                    color: isCompleted ? colorScheme.primary : Colors.grey.withOpacity(0.3),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDayBadge() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final day = _course!.days[_currentDay];

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
        ),
        child: Text('Day ${day.day}',
            style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.primary, fontWeight: FontWeight.bold,
                fontFamily: 'custom')),
      ),
    );
  }

  Widget _buildContentContainer(String title, String content, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: colorScheme.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title,
                      style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                          fontFamily: 'custom')),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(content,
                textAlign: TextAlign.start,
                style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.6, fontFamily: 'custom')),
          ],
        ),
      ),
    );
  }

  Widget _buildDefinitionView(CourseDay day) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildContentContainer(day.title, day.definition, Icons.lightbulb_outline),
          ),
          const SizedBox(height: 16),
          _buildSingleButton('Next: Explanation', Icons.arrow_forward, _goToNextStep),
        ],
      );

  Widget _buildExplanationView(CourseDay day) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildContentContainer('Explanation', day.explanation, Icons.menu_book),
          ),
          const SizedBox(height: 16),
          _buildNavButtons(),
        ],
      );

  Widget _buildCodeExampleView(CourseDay day) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.code,
                              color: Theme.of(context).colorScheme.primary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('Code Example',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontFamily: 'custom')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CompilerPane(
                        key: ValueKey('${day.day}-${day.codeExample.hashCode}'),
                        initialCode: day.codeExample,
                        embedMode: true,
                        forcedLanguage: _getLanguage()),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildNavButtons(),
        ],
      );

  String? _getLanguage() {
    final lang = _course?.language?.toLowerCase();
    if (lang == null) return null;
    if (lang.contains('html')) return 'html';
    if (lang.contains('css')) return 'css';
    if (lang.contains('javascript') || lang.contains('js')) return 'javascript';
    if (lang.contains('python')) return 'python';
    if (lang.contains('java') && !lang.contains('javascript')) return 'java';
    if (lang.contains('c++') || lang.contains('cpp')) return 'cpp';
    return null;
  }

  Widget _buildRealWorldView(CourseDay day) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildContentContainer('Real-World Example', day.realWorldExample, Icons.public),
          ),
          const SizedBox(height: 16),
          _buildNavButtons(),
        ],
      );

  Widget _buildTaskView(CourseDay day) {
    final task = day.interactiveTasks[_currentTaskIndex];
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.extension, color: colorScheme.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                            'Interactive Task ${_currentTaskIndex + 1}/${day.interactiveTasks.length}',
                            style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                                fontFamily: 'custom')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Icon(Icons.touch_app, size: 38, color: colorScheme.primary),
                  const SizedBox(height: 14),
                  Text(task,
                      textAlign: TextAlign.start,
                      style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.5, fontFamily: 'custom')),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildNavButtons(),
      ],
    );
  }

  Widget _buildQuizView(CourseDay day) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final q = day.quiz[_currentQuizIndex];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                  ),
                  child: Text('Quiz ${_currentQuizIndex + 1}/${day.quiz.length}',
                      style: theme.textTheme.titleSmall?.copyWith(
                          color: colorScheme.primary, fontWeight: FontWeight.bold,
                          fontFamily: 'custom')),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primary.withOpacity(0.15),
                        colorScheme.secondary.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.primary.withOpacity(0.4), width: 1.5),
                  ),
                  child: Text(q.question,
                      textAlign: TextAlign.start,
                      style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.5,
                          fontSize: 16,
                          fontFamily: 'custom')),
                ),
                const SizedBox(height: 20),
                ...q.options.asMap().entries.map((opt) {
                  final isSelected = _selectedOptionIndex == opt.key;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected
                          ? (_isCorrect ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2))
                          : theme.cardColor,
                      border: Border.all(
                          color: isSelected
                              ? (_isCorrect ? Colors.green : Colors.red)
                              : colorScheme.primary.withOpacity(0.2)),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _showResult ? null : () {
                        setState(() {
                          _selectedOptionIndex = opt.key;
                          _showResult = true;
                          _isCorrect = opt.value == q.answer;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 22, height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: isSelected
                                        ? (_isCorrect ? Colors.green : Colors.red)
                                        : Colors.grey,
                                    width: 2),
                              ),
                              child: isSelected
                                  ? Icon(_isCorrect ? Icons.check : Icons.close,
                                  size: 14, color: _isCorrect ? Colors.green : Colors.red)
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(opt.value,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 15, fontFamily: 'custom')),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                if (_showResult) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _isCorrect ? Colors.green : Colors.red),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_isCorrect ? Icons.check_circle : Icons.error,
                            color: _isCorrect ? Colors.green : Colors.red),
                        const SizedBox(width: 8),
                        Text(_isCorrect ? 'Correct!' : 'Incorrect. Try Again!',
                            style: TextStyle(
                                color: _isCorrect ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                fontFamily: 'custom')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: !_isCorrect
                        ? () => setState(_clearQuizState)
                        : _handleQuizNavigation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                        !_isCorrect
                            ? 'Try Again'
                            : _currentQuizIndex < day.quiz.length - 1
                            ? 'Next Question'
                            : (day.interactiveTasks.isNotEmpty ? 'Proceed to Tasks' : 'Finish Day'),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildNavButtons(),
      ],
    );
  }

  Widget _buildNavButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _goToPreviousStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, size: 18),
                  SizedBox(width: 6),
                  Text("Previous", style: TextStyle(fontFamily: 'custom')),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _goToNextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Next", style: TextStyle(fontFamily: 'custom')),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleButton(String text, IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(text, style: const TextStyle(fontSize: 15, fontFamily: 'custom')),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _course == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 20),
              Text('Loading Course...', style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      );
    }

    final day = _course!.days[_currentDay];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_course!.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold, fontFamily: 'custom')),
            Text('Day ${day.day}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600], fontFamily: 'custom')),
          ],
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          _buildStepIndicator(),
          _buildDayBadge(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Padding(
                key: ValueKey(_currentStep * 1000 + _currentQuizIndex + _currentTaskIndex),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: _currentStep == 0
                    ? _buildDefinitionView(day)
                    : _currentStep == 1
                    ? _buildExplanationView(day)
                    : _currentStep == 2
                    ? _buildCodeExampleView(day)
                    : _currentStep == 3
                    ? _buildRealWorldView(day)
                    : _currentStep == 4
                    ? _buildQuizView(day)
                    : _buildTaskView(day),
              ),
            ),
          ),
        ],
      ),
    );
  }
}