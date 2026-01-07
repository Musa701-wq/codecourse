
class Course {
  final String id;
  final String title;
  final String language;
  final String description;
  final List<CourseDay> days;

  Course({
    required this.id,
    required this.title,
    required this.language,
    required this.description,
    required this.days,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      title: json['title'],
      language: json['language'],
      description: json['description'],
      days: (json['days'] as List).map((d) => CourseDay.fromJson(d)).toList(),
    );
  }

  // Existing: Support for java_course.json schema
  factory Course.fromJavaJson(Map<String, dynamic> json) {
    final List<dynamic> daysJson = (json['days'] as List?) ?? [];
    final List<CourseDay> parsedDays = [];
    for (int i = 0; i < daysJson.length; i++) {
      final Map<String, dynamic> dayObj = Map<String, dynamic>.from(
        daysJson[i] as Map,
      );
      parsedDays.add(CourseDay.fromJavaJson(dayObj, i + 1));
    }
    return Course(
      id: 'java_course',
      title: 'Java for Beginners',
      language: 'Java',
      description: (json['course_title'] as String?) ?? 'Java course',
      days: parsedDays,
    );
  }

  // Existing: Support for python_course.json schema
  factory Course.fromPythonJson(Map<String, dynamic> json) {
    final List<dynamic> daysJson = (json['days'] as List?) ?? [];
    final List<CourseDay> parsedDays = [];
    for (int i = 0; i < daysJson.length; i++) {
      final Map<String, dynamic> dayObj = Map<String, dynamic>.from(
        daysJson[i] as Map,
      );
      parsedDays.add(CourseDay.fromJavaJson(dayObj, i + 1));
    }
    return Course(
      id: 'python_course',
      title: 'Python for Beginners',
      language: 'Python',
      description: (json['course_title'] as String?) ?? 'Python course',
      days: parsedDays,
    );
  }

  // Existing: Support for cpp_course.json schema
  factory Course.fromCppJson(Map<String, dynamic> json) {
    final List<dynamic> daysJson = (json['days'] as List?) ?? [];
    final List<CourseDay> parsedDays = [];
    for (int i = 0; i < daysJson.length; i++) {
      final Map<String, dynamic> dayObj = Map<String, dynamic>.from(
        daysJson[i] as Map,
      );
      parsedDays.add(CourseDay.fromJavaJson(dayObj, i + 1));
    }
    return Course(
      id: 'cpp_course',
      title: 'C++ for Beginners',
      language: 'C++',
      description: (json['course_title'] as String?) ?? 'C++ course',
      days: parsedDays,
    );
  }

  // Existing: Support for html_course.json schema
  factory Course.fromHtmlJson(Map<String, dynamic> json) {
    final List<dynamic> daysJson = (json['days'] as List?) ?? [];
    final List<CourseDay> parsedDays = [];
    for (int i = 0; i < daysJson.length; i++) {
      final Map<String, dynamic> dayObj = Map<String, dynamic>.from(
        daysJson[i] as Map,
      );
      parsedDays.add(CourseDay.fromHtmlJson(dayObj, i + 1));
    }
    return Course(
      id: 'html_course',
      title: 'HTML for Beginners',
      language: 'HTML',
      description: (json['course_title'] as String?) ?? 'HTML course',
      days: parsedDays,
    );
  }

  // Existing: Support for css_course.json schema
  factory Course.fromCssJson(Map<String, dynamic> json) {
    final List<dynamic> daysJson = (json['days'] as List?) ?? [];
    final List<CourseDay> parsedDays = [];
    for (int i = 0; i < daysJson.length; i++) {
      final Map<String, dynamic> dayObj = Map<String, dynamic>.from(
        daysJson[i] as Map,
      );
      parsedDays.add(CourseDay.fromCssJson(dayObj, i + 1));
    }
    return Course(
      id: 'css_course',
      title: 'CSS for Beginners',
      language: 'CSS',
      description: (json['course_title'] as String?) ?? 'CSS course',
      days: parsedDays,
    );
  }

  // NEW: Support for js_course.json schema (JavaScript)
  factory Course.fromJsJson(Map<String, dynamic> json) {
    final List<dynamic> daysJson = (json['days'] as List?) ?? [];
    final List<CourseDay> parsedDays = [];
    for (int i = 0; i < daysJson.length; i++) {
      final Map<String, dynamic> dayObj = Map<String, dynamic>.from(
        daysJson[i] as Map,
      );
      parsedDays.add(CourseDay.fromJsJson(dayObj, i + 1));
    }
    return Course(
      id: 'js_course',
      title: json['course_title'] as String? ?? 'JavaScript for Beginners',
      language: 'JavaScript',
      description: (json['course_description'] as String?) ??
          'Learn JavaScript programming from basics to advanced concepts',
      days: parsedDays,
    );
  }

  // NEW: Support for HTML intermediate schema
  factory Course.fromHtmlIntermediateJson(Map<String, dynamic> json) {
    final List<dynamic> daysJson = (json['days'] as List?) ?? [];
    final List<CourseDay> parsedDays = [];
    for (int i = 0; i < daysJson.length; i++) {
      final Map<String, dynamic> dayObj = Map<String, dynamic>.from(
        daysJson[i] as Map,
      );
      parsedDays.add(CourseDay.fromHtmlIntermediateJson(dayObj, i + 1));
    }
    return Course(
      id: 'html_intermediate_course',
      title: json['course_title'] as String? ?? 'HTML Intermediate Level',
      language: 'HTML',
      description: (json['course_description'] as String?) ??
          'HTML intermediate course',
      days: parsedDays,
    );
  }
}

class CourseDay {
  final int day;
  final String title;
  final String definition;
  final String explanation;
  final String codeExample;
  final String realWorldExample;
  final List<String> interactiveTasks;
  final List<QuizQuestion> quiz;
  final String content;
  final String interactiveTask;

  CourseDay({
    required this.day,
    required this.title,
    required this.definition,
    required this.explanation,
    required this.codeExample,
    required this.realWorldExample,
    required this.interactiveTasks,
    required this.quiz,
    required this.content,
    required this.interactiveTask,
  });

  factory CourseDay.fromJson(Map<String, dynamic> json) {
    final List<dynamic> quizJson = (json['quiz'] as List?) ?? [];
    final List<QuizQuestion> parsedQuiz = quizJson
        .map((q) => QuizQuestion.fromJson(Map<String, dynamic>.from(q as Map)))
        .toList();

    final String legacyContent = (json['content'] as String?) ?? '';
    final String legacyTask = (json['interactive_task'] as String?) ?? '';

    return CourseDay(
      day: json['day'] ?? 0,
      title: (json['title'] as String?) ?? 'Day',
      definition: legacyContent,
      explanation: '',
      codeExample: '',
      realWorldExample: '',
      interactiveTasks: legacyTask.isNotEmpty ? [legacyTask] : [],
      quiz: parsedQuiz,
      content: legacyContent,
      interactiveTask: legacyTask,
    );
  }

  // Existing: Map java_course.json day object
  factory CourseDay.fromJavaJson(Map<String, dynamic> json, int dayNumber) {
    final List<String> tasks = List<String>.from(
      (json['interactive_tasks'] as List?) ?? [],
    );

    final String definition = (json['definition'] as String?) ?? '';
    final String explanation = (json['explanation'] as String?) ?? '';
    final String codeExample = (json['code_example'] as String?) ?? '';
    final String realWorld = (json['real_world_example'] as String?) ?? '';

    final String combinedContent = [
      definition,
      explanation,
      codeExample,
    ].where((s) => s.isNotEmpty).join('\n\n');
    final String interactiveTaskString = tasks.isNotEmpty
        ? tasks.join('\n\n')
        : '';

    final List<dynamic> quizJson = (json['quiz'] as List?) ?? [];
    final List<QuizQuestion> parsedQuiz = quizJson
        .map((q) => QuizQuestion.fromJson(Map<String, dynamic>.from(q as Map)))
        .toList();

    return CourseDay(
      day: dayNumber,
      title: (json['title'] as String?) ?? 'Day $dayNumber',
      definition: definition,
      explanation: explanation,
      codeExample: codeExample,
      realWorldExample: realWorld,
      interactiveTasks: tasks,
      quiz: parsedQuiz,
      content: combinedContent,
      interactiveTask: interactiveTaskString,
    );
  }

  // Existing: Map html_course.json day object
  factory CourseDay.fromHtmlJson(Map<String, dynamic> json, int dayNumber) {
    final List<String> tasks = List<String>.from(
      (json['interactive_tasks'] as List?) ?? [],
    );

    final String definition = (json['definition'] as String?) ?? '';
    final String explanation = (json['explanation'] as String?) ?? '';
    final String codeExample = (json['code_example'] as String?) ?? '';
    final String realWorld = (json['real_world_example'] as String?) ?? '';

    final String combinedContent = [
      definition,
      explanation,
      codeExample,
    ].where((s) => s.isNotEmpty).join('\n\n');
    final String interactiveTaskString = tasks.isNotEmpty
        ? tasks.join('\n\n')
        : '';

    final List<dynamic> quizJson = (json['quiz'] as List?) ?? [];
    final List<QuizQuestion> parsedQuiz = quizJson
        .map((q) => QuizQuestion.fromJson(Map<String, dynamic>.from(q as Map)))
        .toList();

    return CourseDay(
      day: dayNumber,
      title: (json['title'] as String?) ?? 'Day $dayNumber',
      definition: definition,
      explanation: explanation,
      codeExample: codeExample,
      realWorldExample: realWorld,
      interactiveTasks: tasks,
      quiz: parsedQuiz,
      content: combinedContent,
      interactiveTask: interactiveTaskString,
    );
  }

  factory CourseDay.fromHtmlIntermediateJson(
      Map<String, dynamic> json, int dayNumber) {
    final String definition = (json['definition'] as String?) ?? '';
    final Map<String, dynamic> explanation =
        Map<String, dynamic>.from(json['explanation'] as Map? ?? {});
    final String mainExplanation = (explanation['main'] as String?) ?? '';
    final List<String> keyPoints = (explanation['key_points'] as List?)
            ?.whereType<String>()
            .toList() ??
        [];
    final List<String> explanationParts = [];
    if (mainExplanation.isNotEmpty) explanationParts.add(mainExplanation);
    if (keyPoints.isNotEmpty) {
      explanationParts.add(
        'Key Points:\n${keyPoints.map((point) => '• $point').join('\n')}',
      );
    }
    final String explanationText = explanationParts.join('\n\n');

    final String codeExample = (json['code_example'] as String?) ?? '';
    final String realWorld = (json['real_world_example'] as String?) ?? '';
    final List<String> interactiveTasks = List<String>.from(
      (json['interactive_tasks'] as List?) ?? [],
    );
    final List<dynamic> quizJson = (json['quiz'] as List?) ?? [];
    final List<QuizQuestion> parsedQuiz = quizJson
        .map((q) => QuizQuestion.fromJson(Map<String, dynamic>.from(q as Map)))
        .toList();

    final String combinedContent = [
      if (definition.isNotEmpty) definition,
      if (explanationText.isNotEmpty) explanationText,
      if (codeExample.isNotEmpty) codeExample,
      if (realWorld.isNotEmpty) realWorld,
    ].join('\n\n');

    final String interactiveTaskString =
        interactiveTasks.isNotEmpty ? interactiveTasks.join('\n\n') : '';

    return CourseDay(
      day: dayNumber,
      title: (json['title'] as String?) ?? 'Day $dayNumber',
      definition: definition,
      explanation: explanationText,
      codeExample: codeExample,
      realWorldExample: realWorld,
      interactiveTasks: interactiveTasks,
      quiz: parsedQuiz,
      content: combinedContent,
      interactiveTask: interactiveTaskString,
    );
  }

  // Existing: Map css_course.json day object
  factory CourseDay.fromCssJson(Map<String, dynamic> json, int dayNumber) {
    final List<String> tasks = List<String>.from(
      (json['interactive_tasks'] as List?) ?? [],
    );

    final String definition = (json['definition'] as String?) ?? '';
    final String explanation = (json['explanation'] as String?) ?? '';
    final String codeExample = (json['code_example'] as String?) ?? '';
    final String realWorld = (json['real_world_example'] as String?) ?? '';

    final String combinedContent = [
      if (definition.isNotEmpty) '**Definition:** $definition',
      if (explanation.isNotEmpty) '**Explanation:** $explanation',
      if (codeExample.isNotEmpty) '**Code Example:**\n```css\n$codeExample\n```',
      if (realWorld.isNotEmpty) '**Real World Example:** $realWorld',
    ].where((s) => s.isNotEmpty).join('\n\n');

    final String interactiveTaskString = tasks.isNotEmpty
        ? tasks.join('\n\n')
        : '';

    final List<dynamic> quizJson = (json['quiz'] as List?) ?? [];
    final List<QuizQuestion> parsedQuiz = quizJson
        .map((q) => QuizQuestion.fromJson(Map<String, dynamic>.from(q as Map)))
        .toList();

    return CourseDay(
      day: dayNumber,
      title: (json['title'] as String?) ?? 'Day $dayNumber',
      definition: definition,
      explanation: explanation,
      codeExample: codeExample,
      realWorldExample: realWorld,
      interactiveTasks: tasks,
      quiz: parsedQuiz,
      content: combinedContent,
      interactiveTask: interactiveTaskString,
    );
  }

  // NEW: Map js_course.json day object (JavaScript)
  factory CourseDay.fromJsJson(Map<String, dynamic> json, int dayNumber) {
    final List<String> tasks = List<String>.from(
      (json['interactive_tasks'] as List?) ?? [],
    );

    final String definition = (json['definition'] as String?) ?? '';
    final String explanation = (json['explanation'] as String?) ?? '';
    final String codeExample = (json['code_example'] as String?) ?? '';
    final String realWorld = (json['real_world_example'] as String?) ?? '';

    final String combinedContent = [
      if (definition.isNotEmpty) '**Definition:** $definition',
      if (explanation.isNotEmpty) '**Explanation:** $explanation',
      if (codeExample.isNotEmpty) '**Code Example:**\n```javascript\n$codeExample\n```',
      if (realWorld.isNotEmpty) '**Real World Example:** $realWorld',
    ].where((s) => s.isNotEmpty).join('\n\n');

    final String interactiveTaskString = tasks.isNotEmpty
        ? tasks.join('\n\n')
        : '';

    final List<dynamic> quizJson = (json['quiz'] as List?) ?? [];
    final List<QuizQuestion> parsedQuiz = quizJson
        .map((q) => QuizQuestion.fromJson(Map<String, dynamic>.from(q as Map)))
        .toList();

    return CourseDay(
      day: dayNumber,
      title: (json['title'] as String?) ?? 'Day $dayNumber',
      definition: definition,
      explanation: explanation,
      codeExample: codeExample,
      realWorldExample: realWorld,
      interactiveTasks: tasks,
      quiz: parsedQuiz,
      content: combinedContent,
      interactiveTask: interactiveTaskString,
    );
  }
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final String answer;
  final String? reasoning;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.answer,
    this.reasoning,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'],
      options: List<String>.from(json['options'] ?? const []),
      answer: json['answer'],
      reasoning: json['reasoning'] as String?,
    );
  }
}