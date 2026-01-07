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
