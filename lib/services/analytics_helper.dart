import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsHelper {
  static final FirebaseAnalytics _analytics =
      FirebaseAnalytics.instance;

  static void trackProgressClick() {
    _analytics.logEvent(
      name: 'progress_tab_click',
    );
    print("[TEST] PROGRESS Course Clicked");
  }

  static void trackCompilerClick() {
    _analytics.logEvent(
      name: 'compiler_tab_click',
    );
    print("[TEST] COMPILOR Course Clicked");
  }
  static void trackHtmlCourseClick() {
    _analytics.logEvent(name: 'html_course_click');
    print("[TEST] HTML Course Clicked");
  }

  static void trackCssCourseClick() {
    _analytics.logEvent(name: 'css_course_click');
    print("[TEST] CSS Course Clicked");
  }

  static void trackJsCourseClick() {
    _analytics.logEvent(name: 'javascript_course_click');
    print("[TEST] JS Course Clicked");
  }

  static void trackJavaCourseClick() {
    _analytics.logEvent(name: 'java_course_click');
    print("[TEST] JAVA Course Clicked");
  }

  static void trackCppCourseClick() {
    _analytics.logEvent(name: 'cpp_course_click');
    print("[TEST] CPP Course Clicked");
  }

  static void trackPythonCourseClick() {
    _analytics.logEvent(name: 'python_course_click');
    print("[TEST] PYTHON Course Clicked");
  }
}
