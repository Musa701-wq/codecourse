import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import '../models/course_model.dart';

class CourseService {
  static Future<List<Course>> loadCourses() async {
    final List<Course> courses = [];
    try {
      final datajs = await rootBundle.loadString(
        'assets/javascript_course.json',
      );
      final Map<String, dynamic> jsonJs = jsonDecode(datajs);
      courses.add(Course.fromJsJson(jsonJs));

    } catch (_) {}
    // Load Java course
    try {
      final dataJava = await rootBundle.loadString('assets/java_course.json');
      final Map<String, dynamic> jsonJava = jsonDecode(dataJava);
      courses.add(Course.fromJavaJson(jsonJava));
    } catch (_) {}
    // Load css course
    try {
      final datacss = await rootBundle.loadString('assets/css.json');
      final Map<String, dynamic> jsoncss = jsonDecode(datacss);
      courses.add(Course.fromCssJson(jsoncss));
    } catch (_) {}

    // Load Python course
    try {
      final dataPython = await rootBundle.loadString(
        'assets/python_course.json',
      );
      final Map<String, dynamic> jsonPython = jsonDecode(dataPython);
      courses.add(Course.fromPythonJson(jsonPython));
    } catch (_) {}
    try {
      final dataHtml = await rootBundle.loadString(
        'assets/html_course.json',
      );
      final Map<String, dynamic> jsonHtml = jsonDecode(dataHtml);
      courses.add(Course.fromHtmlJson(jsonHtml));
    } catch (_) {}

    // Load HTML intermediate course
    try {
      final dataHtmlIntermediate = await rootBundle.loadString(
        'assets/inter.json',
      );
      final Map<String, dynamic> jsonHtmlIntermediate =
          jsonDecode(dataHtmlIntermediate);
      final course =
          _courseFromHtmlIntermediateJson(jsonHtmlIntermediate);
      debugPrint('✅ Loaded intermediate course: ${course.title} (from assets/inter.json)');
      courses.add(course);
    } catch (e, stack) {
      debugPrint('❌ Failed to load intermediate course: $e');
      debugPrint('$stack');
    }

    // Load CSS intermediate course
    try {
      final dataCssIntermediate = await rootBundle.loadString(
        'assets/inter_c.json',
      );
      final Map<String, dynamic> jsonCssIntermediate =
          jsonDecode(dataCssIntermediate);
      final course =
          _courseFromCssIntermediateJson(jsonCssIntermediate);
      debugPrint('✅ Loaded CSS intermediate course: ${course.title} (from assets/inter_c.json)');
      courses.add(course);
    } catch (e, stack) {
      debugPrint('❌ Failed to load CSS intermediate course: $e');
      debugPrint('$stack');
    }

    // Load JavaScript intermediate course
    try {
      final dataJsIntermediate = await rootBundle.loadString(
        'assets/inter_j.json',
      );
      final Map<String, dynamic> jsonJsIntermediate =
          jsonDecode(dataJsIntermediate);
      final course =
          _courseFromJsIntermediateJson(jsonJsIntermediate);
      debugPrint('✅ Loaded JS intermediate course: ${course.title} (from assets/inter_j.json)');
      courses.add(course);
    } catch (e, stack) {
      debugPrint('❌ Failed to load JS intermediate course: $e');
      debugPrint('$stack');
    }

    // Load JavaScript advanced course
    try {
      final dataJsAdvanced = await rootBundle.loadString(
        'assets/adv_js.json',
      );
      final Map<String, dynamic> jsonJsAdvanced =
          jsonDecode(dataJsAdvanced);
      final course = _courseFromJsAdvancedJson(jsonJsAdvanced);
      debugPrint('✅ Loaded JS advanced course: ${course.title} (from assets/adv_js.json)');
      courses.add(course);
    } catch (e, stack) {
      debugPrint('❌ Failed to load JS advanced course: $e');
      debugPrint('$stack');
    }

    // Load Python advanced course
    try {
      final dataPythonAdvanced = await rootBundle.loadString(
        'assets/adv_python.json',
      );
      final Map<String, dynamic> jsonPythonAdvanced =
          jsonDecode(dataPythonAdvanced);
      final course = _courseFromPythonAdvancedJson(jsonPythonAdvanced);
      debugPrint('✅ Loaded Python advanced course: ${course.title} (from assets/adv_python.json)');
      courses.add(course);
    } catch (e, stack) {
      debugPrint('❌ Failed to load Python advanced course: $e');
      debugPrint('$stack');
    }

    // Load HTML advanced course
    try {
      final dataHtmlAdvanced =
          await rootBundle.loadString('assets/adv_html.json');
      final Map<String, dynamic> jsonHtmlAdvanced =
          jsonDecode(dataHtmlAdvanced);
      final course = _courseFromHtmlAdvancedJson(jsonHtmlAdvanced);
      debugPrint('✅ Loaded HTML advanced course: ${course.title} (from assets/adv_html.json)');
      courses.add(course);
    } catch (e, stack) {
      debugPrint('❌ Failed to load HTML advanced course: $e');
      debugPrint('$stack');
    }

    // Load CSS advanced course
    try {
      final dataCssAdvanced = await rootBundle.loadString('assets/adv_css.json');
      final Map<String, dynamic> jsonCssAdvanced =
          jsonDecode(dataCssAdvanced);
      final course = _courseFromCssAdvancedJson(jsonCssAdvanced);
      debugPrint('✅ Loaded CSS advanced course: ${course.title} (from assets/adv_css.json)');
      courses.add(course);
    } catch (e, stack) {
      debugPrint('❌ Failed to load CSS advanced course: $e');
      debugPrint('$stack');
    }

    // Load Java advanced course
    try {
      final dataJavaAdvanced =
          await rootBundle.loadString('assets/adv_java.json');
      final Map<String, dynamic> jsonJavaAdvanced =
          jsonDecode(dataJavaAdvanced);
      final course = _courseFromJavaAdvancedJson(jsonJavaAdvanced);
      debugPrint('✅ Loaded Java advanced course: ${course.title} (from assets/adv_java.json)');
      courses.add(course);
    } catch (e, stack) {
      debugPrint('❌ Failed to load Java advanced course: $e');
      debugPrint('$stack');
    }

    // Load C++ advanced course
    try {
      final dataCppAdvanced = await rootBundle.loadString('assets/adv_cpp.json');
      final Map<String, dynamic> jsonCppAdvanced =
          jsonDecode(dataCppAdvanced);
      final course = _courseFromCppAdvancedJson(jsonCppAdvanced);
      debugPrint('✅ Loaded C++ advanced course: ${course.title} (from assets/adv_cpp.json)');
      courses.add(course);
    } catch (e, stack) {
      debugPrint('❌ Failed to load C++ advanced course: $e');
      debugPrint('$stack');
    }

    // Load C++ intermediate course
    try {
      final dataCppIntermediate = await rootBundle.loadString(
        'assets/inter_cpp.json',
      );
      final Map<String, dynamic> jsonCppIntermediate =
          jsonDecode(dataCppIntermediate);
      final course =
          _courseFromCppIntermediateJson(jsonCppIntermediate);
      debugPrint('✅ Loaded C++ intermediate course: ${course.title} (from assets/inter_cpp.json)');
      courses.add(course);
    } catch (e, stack) {
      debugPrint('❌ Failed to load C++ intermediate course: $e');
      debugPrint('$stack');
    }

    // Load Java intermediate course
    try {
      final dataJavaIntermediate = await rootBundle.loadString(
        'assets/inter_java.json',
      );
      final Map<String, dynamic> jsonJavaIntermediate =
          jsonDecode(dataJavaIntermediate);
      final course =
          _courseFromJavaIntermediateJson(jsonJavaIntermediate);
      debugPrint('✅ Loaded Java intermediate course: ${course.title} (from assets/inter_java.json)');
      courses.add(course);
    } catch (e, stack) {
      debugPrint('❌ Failed to load Java intermediate course: $e');
      debugPrint('$stack');
    }

    // Load Python intermediate course
    try {
      final dataPythonIntermediate = await rootBundle.loadString(
        'assets/inter_python.json',
      );
      final Map<String, dynamic> jsonPythonIntermediate =
          jsonDecode(dataPythonIntermediate);
      final course =
          _courseFromPythonIntermediateJson(jsonPythonIntermediate);
      debugPrint('✅ Loaded Python intermediate course: ${course.title} (from assets/inter_python.json)');
      courses.add(course);
    } catch (e, stack) {
      debugPrint('❌ Failed to load Python intermediate course: $e');
      debugPrint('$stack');
    }

    // Load C++ course
    try {
      final dataCpp = await rootBundle.loadString('assets/cpp_course.json');
      final Map<String, dynamic> jsonCpp = jsonDecode(dataCpp);
      courses.add(Course.fromCppJson(jsonCpp));
    } catch (_) {}

    return courses;
  }

  static Future<Course> getCourseByTitle(String title) async {
    final courses = await loadCourses();
    final searchTitle = title.toLowerCase();

    // Prefer exact title matches (HTML Intermediate etc.)
    for (final course in courses) {
      if (course.title.toLowerCase() == searchTitle) {
        debugPrint('🎯 Exact match found: ${course.title}');
      return course;
    }

    if (searchTitle.contains('css')) {
      final cssIntermediate = courses.firstWhere(
        (c) => c.title.toLowerCase().contains('css intermediate'),
        orElse: () => courses.first,
      );
      if (cssIntermediate.title.toLowerCase().contains('css')) {
        debugPrint('🧭 CSS intermediate keyword triggered → ${cssIntermediate.title}');
        return cssIntermediate;
      }
    }
    }

    // If user explicitly asked for intermediate, return that course
    if (searchTitle.contains('intermediate')) {
      final intermediateCourse = courses.firstWhere(
        (c) => c.title.toLowerCase().contains('intermediate'),
        orElse: () => courses.first,
      );
      if (intermediateCourse.title.toLowerCase().contains('intermediate')) {
        debugPrint('🧭 Intermediate keyword triggered → ${intermediateCourse.title}');
        return intermediateCourse;
      }
    }

    if (searchTitle.contains('javascript') && searchTitle.contains('advanced')) {
      final jsAdvanced = courses.firstWhere(
        (c) => c.title.toLowerCase().contains('javascript advanced'),
        orElse: () => courses.first,
      );
      if (jsAdvanced.title.toLowerCase().contains('javascript')) {
        debugPrint('🧭 JavaScript advanced keyword triggered → ${jsAdvanced.title}');
        return jsAdvanced;
      }
    }

    if ((searchTitle.contains('html') ||
            searchTitle.contains('python') ||
            searchTitle.contains('css') ||
            searchTitle.contains('java') ||
            searchTitle.contains('c++') ||
            searchTitle.contains('cpp')) &&
        searchTitle.contains('advanced')) {
      final String? targetLang = searchTitle.contains('html')
          ? 'html'
          : searchTitle.contains('python')
              ? 'python'
              : searchTitle.contains('css')
                  ? 'css'
                  : searchTitle.contains('java')
                      ? 'java'
                      : searchTitle.contains('c++') || searchTitle.contains('cpp')
                          ? 'c++'
                          : null;

      final advancedCourse = courses.firstWhere(
        (c) =>
            c.title.toLowerCase().contains('advanced') &&
            (targetLang == null ||
                c.title.toLowerCase().contains(targetLang)),
        orElse: () => courses.first,
      );
      if (advancedCourse.title.toLowerCase().contains('advanced')) {
        debugPrint(
            '🧭 Advanced keyword triggered → ${advancedCourse.title}');
        return advancedCourse;
      }
    }

    if (searchTitle.contains('javascript')) {
      final jsIntermediate = courses.firstWhere(
        (c) => c.title.toLowerCase().contains('javascript intermediate'),
        orElse: () => courses.first,
      );
      if (jsIntermediate.title.toLowerCase().contains('javascript')) {
        debugPrint('🧭 JavaScript intermediate keyword triggered → ${jsIntermediate.title}');
        return jsIntermediate;
      }
    }

    if (searchTitle.contains('c++') || searchTitle.contains('cpp')) {
      final cppIntermediate = courses.firstWhere(
        (c) => c.title.toLowerCase().contains('c++ intermediate'),
        orElse: () => courses.first,
      );
      if (cppIntermediate.title.toLowerCase().contains('c++')) {
        debugPrint('🧭 C++ intermediate keyword triggered → ${cppIntermediate.title}');
        return cppIntermediate;
      }
    }

    if (searchTitle.contains('java')) {
      final javaIntermediate = courses.firstWhere(
        (c) => c.title.toLowerCase().contains('java intermediate'),
        orElse: () => courses.first,
      );
      if (javaIntermediate.title.toLowerCase().contains('java')) {
        debugPrint('🧭 Java intermediate keyword triggered → ${javaIntermediate.title}');
        return javaIntermediate;
      }
    }

    if (searchTitle.contains('python')) {
      final pythonIntermediate = courses.firstWhere(
        (c) => c.title.toLowerCase().contains('python intermediate'),
        orElse: () => courses.first,
      );
      if (pythonIntermediate.title.toLowerCase().contains('python')) {
        debugPrint('🧭 Python intermediate keyword triggered → ${pythonIntermediate.title}');
        return pythonIntermediate;
      }
    }

    // Fallback to keyword matching
    final course = courses.firstWhere((c) {
      final courseTitle = c.title.toLowerCase();
      if (searchTitle.contains('script') && courseTitle.contains('script')) {
        return true;
      }
      if (searchTitle.contains('c++') && courseTitle.contains('c++')) {
        return true;
      }
      if (searchTitle.contains('html') && courseTitle.contains('html')) {
        return true;
      }
      if (searchTitle.contains('css') && courseTitle.contains('css')) {
        return true;
      }
      if (searchTitle.contains('java') && courseTitle.contains('java')) {
        return true;
      }
      if (searchTitle.contains('python') && courseTitle.contains('python')) {
        return true;
      }
      return false;
    }, orElse: () => courses.first);
    debugPrint('🔁 Fallback matched: ${course.title}');
    return course;
  }
}

Course _courseFromHtmlIntermediateJson(Map<String, dynamic> json) {
  final List<dynamic> daysJson = (json['days'] as List?) ?? [];
  final List<CourseDay> parsedDays = [];
  for (int i = 0; i < daysJson.length; i++) {
    final Map<String, dynamic> dayObj =
        Map<String, dynamic>.from(daysJson[i] as Map);
    parsedDays.add(_courseDayFromHtmlIntermediateJson(dayObj, i + 1));
  }

  return Course(
    id: 'html_intermediate_course',
    title: json['course_title'] as String? ?? 'HTML Intermediate Level',
    language: 'HTML',
    description: (json['course_title'] as String?) ?? 'HTML Intermediate Level',
    days: parsedDays,
  );
}

CourseDay _courseDayFromHtmlIntermediateJson(
  Map<String, dynamic> json,
  int dayNumber,
) {
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

Course _courseFromCppIntermediateJson(Map<String, dynamic> json) {
  final List<dynamic> daysJson = (json['days'] as List?) ?? [];
  final List<CourseDay> parsedDays = [];
  for (int i = 0; i < daysJson.length; i++) {
    final Map<String, dynamic> dayObj =
        Map<String, dynamic>.from(daysJson[i] as Map);
    parsedDays.add(_courseDayFromCppIntermediateJson(dayObj, i + 1));
  }

  return Course(
    id: 'cpp_intermediate_course',
    title: json['course_title'] as String? ?? 'C++ Intermediate Level',
    language: 'C++',
    description: (json['course_description'] as String?) ??
        'C++ intermediate course',
    days: parsedDays,
  );
}

CourseDay _courseDayFromCppIntermediateJson(
  Map<String, dynamic> json,
  int dayNumber,
) {
  final String definition = (json['definition'] as String?) ?? '';
  
  // Handle explanation as either string or Map
  String explanationText = '';
  final dynamic explanationData = json['explanation'];
  if (explanationData is String) {
    explanationText = explanationData;
  } else if (explanationData is Map) {
    final Map<String, dynamic> explanation =
        Map<String, dynamic>.from(explanationData);
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
    explanationText = explanationParts.join('\n\n');
  }

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

Course _courseFromJavaIntermediateJson(Map<String, dynamic> json) {
  final List<dynamic> daysJson = (json['days'] as List?) ?? [];
  final List<CourseDay> parsedDays = [];
  for (int i = 0; i < daysJson.length; i++) {
    final Map<String, dynamic> dayObj =
        Map<String, dynamic>.from(daysJson[i] as Map);
    parsedDays.add(_courseDayFromJavaIntermediateJson(dayObj, i + 1));
  }

  return Course(
    id: 'java_intermediate_course',
    title: json['course_title'] as String? ?? 'Java Intermediate Level',
    language: 'Java',
    description:
        (json['course_description'] as String?) ?? 'Java intermediate course',
    days: parsedDays,
  );
}

CourseDay _courseDayFromJavaIntermediateJson(
  Map<String, dynamic> json,
  int dayNumber,
) {
  final String definition = (json['definition'] as String?) ?? '';
  
  // Handle explanation as either string or Map
  String explanationText = '';
  final dynamic explanationData = json['explanation'];
  if (explanationData is String) {
    explanationText = explanationData;
  } else if (explanationData is Map) {
    final Map<String, dynamic> explanation =
        Map<String, dynamic>.from(explanationData);
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
    explanationText = explanationParts.join('\n\n');
  }

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

Course _courseFromPythonIntermediateJson(Map<String, dynamic> json) {
  final List<dynamic> daysJson = (json['days'] as List?) ?? [];
  final List<CourseDay> parsedDays = [];
  for (int i = 0; i < daysJson.length; i++) {
    final Map<String, dynamic> dayObj =
        Map<String, dynamic>.from(daysJson[i] as Map);
    parsedDays.add(_courseDayFromPythonIntermediateJson(dayObj, i + 1));
  }

  return Course(
    id: 'python_intermediate_course',
    title: json['course_title'] as String? ?? 'Python Intermediate Level',
    language: 'Python',
    description: (json['course_description'] as String?) ??
        'Python intermediate course',
    days: parsedDays,
  );
}

CourseDay _courseDayFromPythonIntermediateJson(
  Map<String, dynamic> json,
  int dayNumber,
) {
  final String definition = (json['definition'] as String?) ?? '';
  
  // Handle explanation as either string or Map
  String explanationText = '';
  final dynamic explanationData = json['explanation'];
  if (explanationData is String) {
    explanationText = explanationData;
  } else if (explanationData is Map) {
    final Map<String, dynamic> explanation =
        Map<String, dynamic>.from(explanationData);
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
    explanationText = explanationParts.join('\n\n');
  }

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

Course _courseFromJsIntermediateJson(Map<String, dynamic> json) {
  final List<dynamic> daysJson = (json['days'] as List?) ?? [];
  final List<CourseDay> parsedDays = [];
  for (int i = 0; i < daysJson.length; i++) {
    final Map<String, dynamic> dayObj =
        Map<String, dynamic>.from(daysJson[i] as Map);
    parsedDays.add(_courseDayFromJsIntermediateJson(dayObj, i + 1));
  }

  return Course(
    id: 'js_intermediate_course',
    title: json['course_title'] as String? ?? 'JavaScript Intermediate Level',
    language: 'JavaScript',
    description: (json['course_description'] as String?) ??
        'JavaScript intermediate course',
    days: parsedDays,
  );
}

CourseDay _courseDayFromJsIntermediateJson(
  Map<String, dynamic> json,
  int dayNumber,
) {
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
  final String jsTips = (json['js_tips'] as String?) ?? '';
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
    if (jsTips.isNotEmpty) 'JS Tips:\n$jsTips',
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

Course _courseFromJsAdvancedJson(Map<String, dynamic> json) {
  final List<dynamic> daysJson = (json['days'] as List?) ?? [];
  final List<CourseDay> parsedDays = [];
  for (int i = 0; i < daysJson.length; i++) {
    final Map<String, dynamic> dayObj =
        Map<String, dynamic>.from(daysJson[i] as Map);
    parsedDays.add(_courseDayFromJsAdvancedJson(dayObj, i + 1));
  }

  return Course(
    id: 'js_advanced_course',
    title: json['course_title'] as String? ?? 'JavaScript Advanced Level',
    language: 'JavaScript',
    description: (json['course_description'] as String?) ??
        'JavaScript advanced course',
    days: parsedDays,
  );
}

CourseDay _courseDayFromJsAdvancedJson(
  Map<String, dynamic> json,
  int dayNumber,
) {
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
  final String jsTips = (json['js_tips'] as String?) ?? '';
  final String advancedTips = (json['advanced_tips'] as String?) ?? '';
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
    if (jsTips.isNotEmpty) 'JS Tips:\n$jsTips',
    if (advancedTips.isNotEmpty) 'Advanced Tips:\n$advancedTips',
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

Course _courseFromPythonAdvancedJson(Map<String, dynamic> json) {
  final List<dynamic> daysJson = (json['days'] as List?) ?? [];
  final List<CourseDay> parsedDays = [];
  for (int i = 0; i < daysJson.length; i++) {
    final Map<String, dynamic> dayObj =
        Map<String, dynamic>.from(daysJson[i] as Map);
    parsedDays.add(_courseDayFromPythonAdvancedJson(dayObj, i + 1));
  }

  return Course(
    id: 'python_advanced_course',
    title: json['course_title'] as String? ?? 'Python Advanced Level',
    language: 'Python',
    description:
        (json['description'] as String?) ?? 'Python advanced course',
    days: parsedDays,
  );
}

CourseDay _courseDayFromPythonAdvancedJson(
  Map<String, dynamic> json,
  int dayNumber,
) {
  final String definition = (json['definition'] as String?) ?? '';
  final String explanation = (json['explanation'] as String?) ?? '';
  final List<String> learningObjectives = List<String>.from(
    (json['learning_objectives'] as List?) ?? [],
  );
  final List<dynamic> sections = (json['sections'] as List?) ?? [];
  final List<String> sectionStrings = sections.map((section) {
    final Map<String, dynamic> sectionMap =
        Map<String, dynamic>.from(section as Map);
    final heading = sectionMap['heading'] as String? ?? 'Section';
    final content = List<String>.from(
      (sectionMap['content'] as List?) ?? [],
    );
    if (content.isEmpty) return heading;
    final formatted = content.map((line) => '• $line').join('\n');
    return '$heading\n$formatted';
  }).toList();
  final List<String> commonPitfalls = List<String>.from(
    (json['common_pitfalls'] as List?) ?? [],
  );

  final String codeExample = (json['code_example'] as String?) ?? '';
  final String realWorld = (json['real_world_example'] as String?) ?? '';
  final List<String> interactiveTasks = List<String>.from(
    (json['interactive_tasks'] as List?) ?? [],
  );
  final List<dynamic> quizJson = (json['quiz'] as List?) ?? [];
  final List<QuizQuestion> parsedQuiz = quizJson
      .map((q) => QuizQuestion.fromJson(Map<String, dynamic>.from(q as Map)))
      .toList();

  final List<String> explanationParts = [];
  if (explanation.isNotEmpty) explanationParts.add(explanation);
  if (learningObjectives.isNotEmpty) {
    explanationParts.add(
      'Learning Objectives:\n${learningObjectives.map((obj) => '• $obj').join('\n')}',
    );
  }
  if (sectionStrings.isNotEmpty) {
    explanationParts.add(sectionStrings.join('\n\n'));
  }
  if (commonPitfalls.isNotEmpty) {
    explanationParts.add(
      'Common Pitfalls:\n${commonPitfalls.map((obj) => '• $obj').join('\n')}',
    );
  }
  final String explanationText = explanationParts.join('\n\n');

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

Course _courseFromHtmlAdvancedJson(Map<String, dynamic> json) {
  final List<dynamic> daysJson = (json['days'] as List?) ?? [];
  final List<CourseDay> parsedDays = [];
  for (int i = 0; i < daysJson.length; i++) {
    final Map<String, dynamic> dayObj =
        Map<String, dynamic>.from(daysJson[i] as Map);
    parsedDays.add(_courseDayFromHtmlAdvancedJson(dayObj, i + 1));
  }

  return Course(
    id: 'html_advanced_course',
    title: json['course_title'] as String? ?? 'HTML Advanced Level',
    language: 'HTML',
    description: (json['description'] as String?) ?? 'HTML advanced course',
    days: parsedDays,
  );
}

CourseDay _courseDayFromHtmlAdvancedJson(
  Map<String, dynamic> json,
  int dayNumber,
) {
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

  final String codeExample = (json['code_example'] as String?) ?? '';
  final String realWorld = (json['real_world_example'] as String?) ?? '';
  final List<String> interactiveTasks = List<String>.from(
    (json['interactive_tasks'] as List?) ?? [],
  );
  final List<dynamic> quizJson = (json['quiz'] as List?) ?? [];
  final List<QuizQuestion> parsedQuiz = quizJson
      .map((q) => QuizQuestion.fromJson(Map<String, dynamic>.from(q as Map)))
      .toList();
  final List<String> references = List<String>.from(
    (json['references'] as List?) ?? [],
  );

  if (references.isNotEmpty) {
    explanationParts.add(
      'References:\n${references.map((ref) => '• $ref').join('\n')}',
    );
  }

  final String explanationText = explanationParts.join('\n\n');

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

Course _courseFromCssAdvancedJson(Map<String, dynamic> json) {
  final List<dynamic> daysJson = (json['days'] as List?) ?? [];
  final List<CourseDay> parsedDays = [];
  for (int i = 0; i < daysJson.length; i++) {
    final Map<String, dynamic> dayObj =
        Map<String, dynamic>.from(daysJson[i] as Map);
    parsedDays.add(_courseDayFromCssAdvancedJson(dayObj, i + 1));
  }

  return Course(
    id: 'css_advanced_course',
    title: json['course_title'] as String? ?? 'CSS Advanced Level',
    language: 'CSS',
    description: (json['description'] as String?) ?? 'CSS advanced course',
    days: parsedDays,
  );
}

CourseDay _courseDayFromCssAdvancedJson(
  Map<String, dynamic> json,
  int dayNumber,
) {
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

  final List<dynamic> sections = (json['sections'] as List?) ?? [];
  if (sections.isNotEmpty) {
    final sectionStrings = sections.map((section) {
      final Map<String, dynamic> sectionMap =
          Map<String, dynamic>.from(section as Map);
      final heading = sectionMap['heading'] as String? ?? 'Section';
      final content = (sectionMap['content'] as List?)
              ?.whereType<String>()
              .toList() ??
          [];
      final formatted = content.map((line) => '• $line').join('\n');
      return content.isEmpty ? heading : '$heading\n$formatted';
    }).toList();
    explanationParts.add(sectionStrings.join('\n\n'));
  }

  final String codeExample = (json['code_example'] as String?) ?? '';
  final String realWorld = (json['real_world_example'] as String?) ?? '';
  final List<String> interactiveTasks = List<String>.from(
    (json['interactive_tasks'] as List?) ?? [],
  );
  final List<dynamic> quizJson = (json['quiz'] as List?) ?? [];
  final List<QuizQuestion> parsedQuiz = quizJson
      .map((q) => QuizQuestion.fromJson(Map<String, dynamic>.from(q as Map)))
      .toList();

  final String explanationText = explanationParts.join('\n\n');

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

Course _courseFromJavaAdvancedJson(Map<String, dynamic> json) {
  final List<dynamic> daysJson = (json['days'] as List?) ?? [];
  final List<CourseDay> parsedDays = [];
  for (int i = 0; i < daysJson.length; i++) {
    final Map<String, dynamic> dayObj =
        Map<String, dynamic>.from(daysJson[i] as Map);
    parsedDays.add(_courseDayFromJavaAdvancedJson(dayObj, i + 1));
  }

  return Course(
    id: 'java_advanced_course',
    title: json['course_title'] as String? ?? 'Java Advanced Level',
    language: 'Java',
    description: (json['description'] as String?) ?? 'Java advanced course',
    days: parsedDays,
  );
}

CourseDay _courseDayFromJavaAdvancedJson(
  Map<String, dynamic> json,
  int dayNumber,
) {
  final String definition = (json['definition'] as String?) ?? '';
  final String codeExample = (json['code_example'] as String?) ?? '';
  final String realWorld = (json['real_world_example'] as String?) ?? '';
  final List<String> learningObjectives = _toStringList(
    (json['learning_objectives'] as List?) ?? [],
  );
  final List<String> interactiveTasks = _toStringList(
    (json['interactive_tasks'] as List?) ?? [],
  );
  final List<String> keySections = _formatSections(
    (json['sections'] as List?) ?? [],
  );
  final List<String> tips = _toStringList(
    (json['tips'] as List?) ?? [],
  );
  final String explanationText = [
    _buildAdvancedExplanation(json['explanation']),
    if (learningObjectives.isNotEmpty)
      'Learning Objectives:\n${learningObjectives.map((item) => '• $item').join('\n')}',
    if (keySections.isNotEmpty) keySections.join('\n\n'),
    if (tips.isNotEmpty)
      'Tips:\n${tips.map((item) => '• $item').join('\n')}',
  ].where((part) => part.isNotEmpty).join('\n\n');

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

Course _courseFromCppAdvancedJson(Map<String, dynamic> json) {
  final List<dynamic> daysJson = (json['days'] as List?) ?? [];
  final List<CourseDay> parsedDays = [];
  for (int i = 0; i < daysJson.length; i++) {
    final Map<String, dynamic> dayObj =
        Map<String, dynamic>.from(daysJson[i] as Map);
    parsedDays.add(_courseDayFromCppAdvancedJson(dayObj, i + 1));
  }

  return Course(
    id: 'cpp_advanced_course',
    title: json['course_title'] as String? ?? 'C++ Advanced Level',
    language: 'C++',
    description: (json['description'] as String?) ?? 'C++ advanced course',
    days: parsedDays,
  );
}

CourseDay _courseDayFromCppAdvancedJson(
  Map<String, dynamic> json,
  int dayNumber,
) {
  final String definition = (json['definition'] as String?) ?? '';
  final String codeExample = (json['code_example'] as String?) ?? '';
  final String realWorld = (json['real_world_example'] as String?) ?? '';
  final List<String> learningObjectives = _toStringList(
    (json['learning_objectives'] as List?) ?? [],
  );
  final List<String> sections = _formatSections(
    (json['sections'] as List?) ?? [],
  );
  final List<String> tips = _toStringList(
    (json['tips'] as List?) ?? [],
  );
  final List<String> interactiveTasks = _toStringList(
    (json['interactive_tasks'] as List?) ?? [],
  );
  final List<dynamic> quizJson = (json['quiz'] as List?) ?? [];
  final List<QuizQuestion> parsedQuiz = quizJson
      .map((q) => QuizQuestion.fromJson(Map<String, dynamic>.from(q as Map)))
      .toList();

  final String explanationText = [
    _buildAdvancedExplanation(json['explanation']),
    if (learningObjectives.isNotEmpty)
      'Learning Objectives:\n${learningObjectives.map((item) => '• $item').join('\n')}',
    if (sections.isNotEmpty) sections.join('\n\n'),
    if (tips.isNotEmpty)
      'Tips:\n${tips.map((item) => '• $item').join('\n')}',
  ].where((part) => part.isNotEmpty).join('\n\n');

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

String _buildAdvancedExplanation(dynamic explanation) {
  if (explanation == null) return '';
  if (explanation is String) return explanation;
  if (explanation is Map) {
    final List<String> parts = [];
    final String main = explanation['main'] as String? ?? '';
    final List<String> keyPoints = _toStringList(
      (explanation['key_points'] as List?) ?? [],
    );
    if (main.isNotEmpty) parts.add(main);
    if (keyPoints.isNotEmpty) {
      parts.add(
        'Key Points:\n${keyPoints.map((point) => '• $point').join('\n')}',
      );
    }
    final List<String> extraSections = _formatSections(
      (explanation['details'] as List?) ?? [],
    );
    if (extraSections.isNotEmpty) {
      parts.add(extraSections.join('\n\n'));
    }
    return parts.where((p) => p.isNotEmpty).join('\n\n');
  }
  return explanation.toString();
}

List<String> _formatSections(List<dynamic> sections) {
  final List<String> formatted = [];
  for (final section in sections) {
    if (section is Map) {
      final heading = section['heading'] as String? ?? 'Section';
      final content = _toStringList(
        (section['content'] as List?) ?? [],
      );
      final buffer = StringBuffer(heading);
      if (content.isNotEmpty) {
        buffer.write('\n${content.map((line) => '• $line').join('\n')}');
      }
      formatted.add(buffer.toString());
    } else if (section is String) {
      formatted.add(section);
    }
  }
  return formatted;
}

List<String> _toStringList(List<dynamic> raw) {
  return raw.whereType<String>().toList();
}

Course _courseFromCssIntermediateJson(Map<String, dynamic> json) {
  final List<dynamic> daysJson = (json['days'] as List?) ?? [];
  final List<CourseDay> parsedDays = [];
  for (int i = 0; i < daysJson.length; i++) {
    final Map<String, dynamic> dayObj =
        Map<String, dynamic>.from(daysJson[i] as Map);
    parsedDays.add(_courseDayFromCssIntermediateJson(dayObj, i + 1));
  }

  return Course(
    id: 'css_intermediate_course',
    title: json['course_title'] as String? ?? 'CSS Intermediate Level',
    language: 'CSS',
    description: (json['course_description'] as String?) ??
        'Intermediate CSS course',
    days: parsedDays,
  );
}

CourseDay _courseDayFromCssIntermediateJson(
  Map<String, dynamic> json,
  int dayNumber,
) {
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
  final String cssTips = (json['css_tips'] as String?) ?? '';
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
    if (cssTips.isNotEmpty) 'CSS Tips:\n$cssTips',
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
