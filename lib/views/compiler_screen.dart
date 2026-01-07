/*
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:provider/provider.dart';
import 'package:coding_tutor/in_app_purchase/credit_manager.dart';
import 'package:coding_tutor/in_app_purchase/credit_purchase_screen.dart';

class CompilerScreen extends StatelessWidget {
  const CompilerScreen({super.key, this.initialCode});

  final String? initialCode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Coding Compiler',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: CompilerPane(initialCode: initialCode),
    );
  }
}

class CompilerPane extends StatefulWidget {
  const CompilerPane({
    super.key,
    this.initialCode,
    this.embedMode = false,
    this.forcedLanguage,
    this.isReadOnly = false,
  });

  final String? initialCode;
  final bool embedMode;
  final String? forcedLanguage;
  final bool isReadOnly;

  @override
  State<CompilerPane> createState() => _CompilerPaneState();
}

class _CompilerPaneState extends State<CompilerPane> with SingleTickerProviderStateMixin {
  static const _starterCode = '''// Simple Fibonacci Calculator
function fibonacci(n) {
  if (n <= 1) {
    return n;
  }
  return fibonacci(n - 1) +
fibonacci(n - 2);
}
const n = 10;
console.log(`Fib(\${n}) = \${fibonacci(n)}`);''';

  final TextEditingController _codeController = TextEditingController(text: _starterCode);
  final ScrollController _codeScrollController = ScrollController();
  final ScrollController _lineNumberScrollController = ScrollController();
  late final WebViewController _webViewController;
  late TabController _tabController;

  bool _isPreviewLoading = true;
  bool _showPreviewPanel = false;
  String _selectedLanguage = 'javascript';
  bool _isExecuting = false;
  String? _executionOutput;
  String? _executionError;
  String? _forcedLanguageValue;

  static const _apiEndpoint = 'https://tgeazxxujp.ap-south-1.awsapprunner.com/api/code/execute';

  static const Map<String, String> _languageAliases = {
    'html': 'html',
    'css': 'css',
    'javascript': 'javascript',
    'js': 'javascript',
    'python': 'python',
    'java': 'java',
    'c++': 'cpp',
    'cpp': 'cpp',
  };

  final List<String> _quickInsertButtons = [
    '{', '}', '(', ')', ';', '=', 'const', 'log'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _showPreviewPanel = _tabController.index == 1;
      });
    });

    _initializeWebView();
    _codeController.text = widget.initialCode ?? _starterCode;
    _forcedLanguageValue = _resolveLanguageValue(widget.forcedLanguage);
    if (_forcedLanguageValue != null) {
      _selectedLanguage = _forcedLanguageValue!;
    }
    _codeScrollController.addListener(_syncLineNumberScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_usesWebView) _loadPreview();
    });
  }

  @override
  void didUpdateWidget(covariant CompilerPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCode != widget.initialCode && widget.initialCode != null) {
      _codeController.text = widget.initialCode!;
    }
    final newForced = _resolveLanguageValue(widget.forcedLanguage);
    if (newForced != _forcedLanguageValue) {
      _forcedLanguageValue = newForced;
      if (_forcedLanguageValue != null) {
        setState(() {
          _selectedLanguage = _forcedLanguageValue!;
        });
      }
    }
  }

  void _syncLineNumberScroll() {
    if (_lineNumberScrollController.hasClients) {
      _lineNumberScrollController.jumpTo(_codeScrollController.offset);
    }
  }

  void _initializeWebView() {
    late final PlatformWebViewControllerCreationParams params;

    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params);
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isPreviewLoading = true),
          onPageFinished: (_) => setState(() => _isPreviewLoading = false),
        ),
      );

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController).setMediaPlaybackRequiresUserGesture(false);
    }

    _webViewController = controller;
  }

  Future<void> _loadPreview() async {
    final fullHtml = '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body {
          margin: 0;
          padding: 24px;
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
          background: #f9fafb;
          color: #111;
        }
      </style>
    </head>
    <body>
      ${_codeController.text}
    </body>
    </html>
    ''';

    setState(() {
      _isPreviewLoading = true;
      _showPreviewPanel = true;
      _tabController.animateTo(1);
    });
    await _webViewController.loadHtmlString(fullHtml);
  }

  bool get _usesWebView => _selectedLanguage == 'html' || _selectedLanguage == 'css';

  Future<void> _runCode() async {
    final hasEnoughCredits = await _checkAndDeductCredit();
    if (!hasEnoughCredits) return;

    if (_usesWebView) {
      await _loadPreview();
    } else {
      await _executeCode();
    }
  }

  Future<bool> _checkAndDeductCredit() async {
    try {
      final creditManager = context.read<CreditManager>();

      if (creditManager.isLoading) {
        await Future.delayed(const Duration(milliseconds: 300));
      }

      final currentCredits = creditManager.credits;

      if (currentCredits < 1) {
        _showNotEnoughCreditsDialog(context);
        return false;
      }

      final success = await creditManager.deductCredits(
        1,
        reason: 'compiler_run_$_selectedLanguage',
      );

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to deduct credit. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
        return false;
      }

      debugPrint('✅ 1 credit deducted for compiler usage');
      return true;
    } catch (e) {
      debugPrint('❌ Error checking/deducting credit: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error processing credit. Please try again.'),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }
  }

  void _showNotEnoughCreditsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Insufficient Credits'),
        content: const Text(
          'You need at least 1 credit to run code in the compiler.\n\nGet more credits from the profile screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CreditsPurchaseScreen(),
                ),
              );
            },
            child: const Text('Get Credits'),
          ),
        ],
      ),
    );
  }

  void _onRefreshPressed() async {
    final hasEnoughCredits = await _checkAndDeductCredit();
    if (hasEnoughCredits) {
      await _loadPreview();
    }
  }

  Future<void> _executeCode() async {
    setState(() {
      _isExecuting = true;
      _executionOutput = null;
      _executionError = null;
      _showPreviewPanel = true;
      _tabController.animateTo(1);
    });

    final headers = {'Content-Type': 'application/json'};
    final payload = {
      'code': _codeController.text,
      'language': _selectedLanguage == 'cpp' ? 'cpp' : _selectedLanguage,
      'input': '',
    };

    debugPrint('🚀 [Compiler] Executing with language: ${payload['language']}, _selectedLanguage: $_selectedLanguage');

    try {
      debugPrint('🔄 Executing code payload: ${jsonEncode(payload)}');
      final response = await http.post(
        Uri.parse(_apiEndpoint),
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ API response: ${response.body}');
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _executionOutput = body['output'] as String?;
          _executionError = body['error'] as String?;
        });
      } else {
        debugPrint('⚠️ API error ${response.statusCode}: ${response.body}');
        final errorMessage = response.statusCode == 400
            ? 'Please select the correct language before running the code.'
            : 'Server error (${response.statusCode}): ${response.reasonPhrase}';
        setState(() {
          _executionError = errorMessage;
        });
      }
    } catch (e) {
      debugPrint('❌ Execution exception: $e');
      setState(() {
        _executionError = 'Execution failed: $e';
      });
    } finally {
      setState(() {
        _isExecuting = false;
      });
    }
  }

  void _insertText(String text) {
    final currentText = _codeController.text;
    final selection = _codeController.selection;
    final newText = currentText.replaceRange(
      selection.start,
      selection.end,
      text,
    );
    _codeController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + text.length,
      ),
    );
  }

  String? _resolveLanguageValue(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.toLowerCase();
    for (final entry in _languageAliases.entries) {
      if (normalized.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  String _languageDisplayName(String code) {
    switch (code) {
      case 'html': return 'HTML';
      case 'css': return 'CSS';
      case 'javascript': return 'JavaScript (Node.js 18.x)';
      case 'python': return 'Python 3.x';
      case 'java': return 'Java 11';
      case 'cpp': return 'C++ 17';
      default: return code.toUpperCase();
    }
  }

  List<String> _codeLines() {
    return _codeController.text.split('\n');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    _codeScrollController.dispose();
    _lineNumberScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Bar (Code/Preview)
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.code, size: 20),
                  text: 'Code',
                  height: 50,
                ),
                Tab(
                  icon: Icon(Icons.preview, size: 20),
                  text: 'Preview',
                  height: 50,
                ),
              ],
            ),
          ),
        ),

        // Language Selector (only in Code tab)
        if (!_showPreviewPanel)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: DropdownButton<String>(
                value: _selectedLanguage,
                isExpanded: true,
                underline: const SizedBox(),
                icon: const Icon(Icons.keyboard_arrow_down),
                items: const [
                  DropdownMenuItem(value: 'javascript', child: Text('JavaScript (Node.js 18.x)')),
                  DropdownMenuItem(value: 'python', child: Text('Python 3.x')),
                  DropdownMenuItem(value: 'java', child: Text('Java 11')),
                  DropdownMenuItem(value: 'cpp', child: Text('C++ 17')),
                  DropdownMenuItem(value: 'html', child: Text('HTML')),
                  DropdownMenuItem(value: 'css', child: Text('CSS')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedLanguage = value;
                    });
                  }
                },
              ),
            ),
          ),

        // Main Content Area
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBarView(
              controller: _tabController,
              children: [
                // Code Tab
                Column(
                  children: [
                    // File Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.insert_drive_file, size: 18, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          const Text(
                            'main.js',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          Text(
                            'Last saved: 2m ago',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),

                    // Code Editor with Line Numbers
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Line Numbers
                          Container(
                            width: 40,
                            color: Colors.grey.shade50,
                            child: SingleChildScrollView(
                              controller: _lineNumberScrollController,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: List.generate(
                                    _codeLines().length,
                                        (index) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2.5),
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'monospace',
                                          color: Colors.grey,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Code Editor
                          Expanded(
                            child: TextField(
                              controller: _codeController,
                              scrollController: _codeScrollController,
                              maxLines: null,
                              expands: true,
                              readOnly: widget.isReadOnly,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 14,
                                height: 1.5,
                              ),
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.all(16),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Preview Tab
                _buildPreviewContent(),
              ],
            ),
          ),
        ),

        // Quick Insert Buttons (only in Code tab)
        if (!_showPreviewPanel)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickInsertButtons.map((button) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Material(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: () => _insertText(button),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Text(
                            button,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

        // Warning Message
        Container(
          color: const Color(0xFFFFF4E6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You will be charged 1 credit for each run.',
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Run Button
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: ElevatedButton(
            onPressed: _runCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.play_arrow, size: 24),
                SizedBox(width: 8),
                Text('Run Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(width: 8),
                Text('1 credit', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewContent() {
    if (_usesWebView) {
      return Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          if (_isPreviewLoading)
            Container(
              color: Colors.white.withOpacity(0.7),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      );
    }

    // Output Display for non-web languages
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Output:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              if (_isExecuting)
                Row(
                  children: const [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Running...', style: TextStyle(fontSize: 12)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_executionOutput != null)
                      Text(
                        _executionOutput!,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                      ),
                    if (_executionError != null) ...[
                      if (_executionOutput != null) const SizedBox(height: 8),
                      Text(
                        'Error:\n$_executionError',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          color: Colors.redAccent,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    if (_executionOutput == null && _executionError == null)
                      Text(
                        'Run code to see output...',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}*/
/*
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class CompilerScreen extends StatelessWidget {
  const CompilerScreen({super.key, this.initialCode});

  final String? initialCode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Compiler'),
      ),
      body: CompilerPane(
        initialCode: initialCode,
      ),
    );
  }
}

class CompilerPane extends StatefulWidget {
  const CompilerPane({
    super.key,
    this.initialCode,
    this.embedMode = false,
    this.forcedLanguage,
    this.isReadOnly = false,
  });

  final String? initialCode;
  final bool embedMode;
  final String? forcedLanguage;
  final bool isReadOnly;

  @override
  State<CompilerPane> createState() => _CompilerPaneState();
}

class _CompilerPaneState extends State<CompilerPane> {
  static const _starterCode = '''
<h1>Hello, world!</h1>
<p>This snippet runs inside the live preview. Update the HTML and press Run.</p>
''';

  final TextEditingController _codeController =
      TextEditingController(text: _starterCode);
  final ScrollController _codeScrollController = ScrollController();
  final ScrollController _lineNumberScrollController = ScrollController();
  late final WebViewController _webViewController;
  bool _isPreviewLoading = true;
  bool _showPreviewPanel = false;
  String _selectedLanguage = 'html';
  bool _isExecuting = false;
  String? _executionOutput;
  String? _executionError;
  static const _apiEndpoint =
      'https://tgeazxxujp.ap-south-1.awsapprunner.com/api/code/execute';
  String? _forcedLanguageValue;
  static const Map<String, String> _languageAliases = {
    'html': 'html',
    'css': 'css',
    'javascript': 'javascript',
    'js': 'javascript',
    'python': 'python',
    'java': 'java',
    'c++': 'cpp',
    'cpp': 'cpp',
  };

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _codeController.text = widget.initialCode ?? _starterCode;
    _forcedLanguageValue = _resolveLanguageValue(widget.forcedLanguage);
    if (_forcedLanguageValue != null) {
      _selectedLanguage = _forcedLanguageValue!;
    }
    _codeScrollController.addListener(_syncLineNumberScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPreview());
  }

  @override
  void didUpdateWidget(covariant CompilerPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCode != widget.initialCode &&
        widget.initialCode != null) {
      _codeController.text = widget.initialCode!;
    }
    final newForced = _resolveLanguageValue(widget.forcedLanguage);
    if (newForced != _forcedLanguageValue) {
      _forcedLanguageValue = newForced;
      if (_forcedLanguageValue != null) {
        setState(() {
          _selectedLanguage = _forcedLanguageValue!;
        });
      }
    }
  }

  void _syncLineNumberScroll() {
    if (_lineNumberScrollController.hasClients) {
      _lineNumberScrollController.jumpTo(_codeScrollController.offset);
    }
  }

  void _initializeWebView() {
    late final PlatformWebViewControllerCreationParams params;

    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params);
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isPreviewLoading = true),
          onPageFinished: (_) => setState(() => _isPreviewLoading = false),
        ),
      );

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _webViewController = controller;
  }

  Future<void> _loadPreview() async {
    final fullHtml = '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body {
          margin: 0;
          padding: 24px;
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
          background: #f9fafb;
          color: #111;
        }
      </style>
    </head>
    <body>
      ${_codeController.text}
    </body>
    </html>
    ''';

    setState(() {
      _isPreviewLoading = true;
      _showPreviewPanel = true;
    });
    await _webViewController.loadHtmlString(fullHtml);
  }

  bool get _usesWebView =>
      _selectedLanguage == 'html' || _selectedLanguage == 'css';

  Future<void> _runCode() async {
    if (_usesWebView) {
      await _loadPreview();
      return;
    }

    await _executeCode();
  }

  Future<void> _executeCode() async {
    setState(() {
      _isExecuting = true;
      _executionOutput = null;
      _executionError = null;
      _showPreviewPanel = true;
    });

    final headers = {'Content-Type': 'application/json'};

    final payload = {
      'code': _codeController.text,
      'language': _selectedLanguage == 'cpp' ? 'cpp' : _selectedLanguage,
      'input': '',
    };

    try {
      debugPrint('🔄 Executing code payload: ${jsonEncode(payload)}');
      final response = await http.post(
        Uri.parse(_apiEndpoint),
        headers: headers,
        body: jsonEncode(payload),
      );
      if (response.statusCode == 200) {
        debugPrint('✅ API response: ${response.body}');
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _executionOutput = body['output'] as String?;
          _executionError = body['error'] as String?;
        });
      } else {
        debugPrint('⚠️ API error ${response.statusCode}: ${response.body}');
        final errorMessage = response.statusCode == 400
            ? 'Please select the correct language before running the code.'
            : 'Server error (${response.statusCode}): ${response.reasonPhrase}';
        setState(() {
          _executionError = errorMessage;
        });
      }
    } catch (e) {
      debugPrint('❌ Execution exception: $e');
      setState(() {
        _executionError = 'Execution failed: $e';
      });
    } finally {
      setState(() {
        _isExecuting = false;
      });
    }
  }

  Widget _buildPanelToggle({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: active ? Colors.white : Colors.transparent,
          foregroundColor: active ? Colors.black : Colors.grey[600],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildEditorBody(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.background,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            padding: EdgeInsets.zero,
            child: Scrollbar(
              controller: _lineNumberScrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _lineNumberScrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(
                    _codeLines().length,
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.5),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'Monospace',
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Scrollbar(
              controller: _codeScrollController,
              thumbVisibility: true,
          child: TextField(
                controller: _codeController,
                scrollController: _codeScrollController,
                style: const TextStyle(
                  fontFamily: 'Monospace',
                  fontSize: 14,
                  height: 1.6,
                ),
                maxLines: null,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Type your HTML code here...',
                  hintStyle: TextStyle(color: Colors.grey),
                  isDense: true,
                ),
                keyboardType: TextInputType.multiline,
            readOnly: widget.isReadOnly,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _resolveLanguageValue(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.toLowerCase();
    for (final entry in _languageAliases.entries) {
      if (normalized.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  String _languageDisplayName(String code) {
    switch (code) {
      case 'html':
        return 'HTML';
      case 'css':
        return 'CSS';
      case 'javascript':
        return 'JavaScript';
      case 'python':
        return 'Python';
      case 'java':
        return 'Java';
      case 'cpp':
        return 'C++';
      default:
        return code.toUpperCase();
    }
  }

  Widget _buildPreviewBody(
      ThemeData theme, ColorScheme colorScheme, Color previewHeaderColor) {
    if (_usesWebView) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: previewHeaderColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.visibility, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Live Preview',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      tooltip: 'Refresh preview',
                      onPressed: _loadPreview,
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 320,
                child: Stack(
                  children: [
                    WebViewWidget(controller: _webViewController),
                    if (_isPreviewLoading)
                      Positioned.fill(
                        child: Container(
                          color: Colors.white.withOpacity(0.7),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _buildExecutionResultBody(theme, colorScheme);
  }

  Widget _buildExecutionResultBody(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Execution Output',
                style: theme.textTheme.titleSmall,
              ),
              if (_isExecuting)
                Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text('Running...', style: theme.textTheme.bodySmall),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_executionOutput != null)
                  Text(
                    'Output:\n${_executionOutput}',
                    style: const TextStyle(fontFamily: 'Monospace'),
                  ),
                if (_executionError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Error:\n${_executionError}',
                    style: const TextStyle(
                      fontFamily: 'Monospace',
                      color: Colors.redAccent,
                    ),
                  ),
                ],
                if (_executionOutput == null && _executionError == null)
                  Text(
                    'No execution results yet.',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  List<String> _codeLines() {
    return _codeController.text.split('\n');
  }

  @override
  void dispose() {
    _codeController.dispose();
    _codeScrollController.dispose();
    _lineNumberScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final previewHeaderColor = colorScheme.primary;

    final content = Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          _buildPanelToggle(
                            label: 'Code',
                            active: !_showPreviewPanel,
                            onTap: () =>
                                setState(() => _showPreviewPanel = false),
                          ),
                          _buildPanelToggle(
                            label: 'Preview',
                            active: _showPreviewPanel,
                            onTap: () =>
                                setState(() => _showPreviewPanel = true),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _runCode,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Run'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: previewHeaderColor,
                      ),
                    ),
                  ],
                ),
                        const SizedBox(height: 12),
                        if (!widget.embedMode)
                          InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Language',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedLanguage,
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'html',
                                    child: Text('HTML'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'css',
                                    child: Text('CSS'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'javascript',
                                    child: Text('JavaScript'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'python',
                                    child: Text('Python'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'java',
                                    child: Text('Java'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'cpp',
                                    child: Text('C++'),
                                  ),
                                ],
                                onChanged: (value) => setState(() {
                                  _selectedLanguage = value!;
                                  if (_usesWebView) {
                                    _showPreviewPanel = true;
                                  }
                                }),
                              ),
                            ),
                          )
                        else
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Language: ${_languageDisplayName(_selectedLanguage)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
              ],
            ),
          ),
          AnimatedCrossFade(
            firstChild: _buildEditorBody(theme, colorScheme),
            secondChild:
                _buildPreviewBody(theme, colorScheme, previewHeaderColor),
            crossFadeState: _showPreviewPanel
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );

    if (widget.embedMode) {
      return content;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [content],
      ),
    );
  }
}*/
/*
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:provider/provider.dart';
import 'package:coding_tutor/in_app_purchase/credit_manager.dart';
import 'package:coding_tutor/in_app_purchase/credit_purchase_screen.dart'; // Add this import

class CompilerScreen extends StatelessWidget {
  const CompilerScreen({super.key, this.initialCode});

  final String? initialCode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Compiler'),
      ),
      body: CompilerPane(
        initialCode: initialCode,
      ),
    );
  }
}

class CompilerPane extends StatefulWidget {
  const CompilerPane({
    super.key,
    this.initialCode,
    this.embedMode = false,
    this.forcedLanguage,
    this.isReadOnly = false,
  });

  final String? initialCode;
  final bool embedMode;
  final String? forcedLanguage;
  final bool isReadOnly;

  @override
  State<CompilerPane> createState() => _CompilerPaneState();
}

class _CompilerPaneState extends State<CompilerPane> {
  static const _starterCode = '''
<h1>Hello, world!</h1>
<p>This snippet runs inside the live preview. Update the HTML and press Run.</p>
''';

  final TextEditingController _codeController =
  TextEditingController(text: _starterCode);
  final ScrollController _codeScrollController = ScrollController();
  final ScrollController _lineNumberScrollController = ScrollController();
  late final WebViewController _webViewController;
  bool _isPreviewLoading = true;
  bool _showPreviewPanel = false;
  String _selectedLanguage = 'html';
  bool _isExecuting = false;
  String? _executionOutput;
  String? _executionError;
  static const _apiEndpoint =
      'https://tgeazxxujp.ap-south-1.awsapprunner.com/api/code/execute';
  String? _forcedLanguageValue;
  static const Map<String, String> _languageAliases = {
    'html': 'html',
    'css': 'css',
    'javascript': 'javascript',
    'js': 'javascript',
    'python': 'python',
    'java': 'java',
    'c++': 'cpp',
    'cpp': 'cpp',
  };

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _codeController.text = widget.initialCode ?? _starterCode;
    _forcedLanguageValue = _resolveLanguageValue(widget.forcedLanguage);
    if (_forcedLanguageValue != null) {
      _selectedLanguage = _forcedLanguageValue!;
    }
    _codeScrollController.addListener(_syncLineNumberScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPreview());
  }

  @override
  void didUpdateWidget(covariant CompilerPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCode != widget.initialCode &&
        widget.initialCode != null) {
      _codeController.text = widget.initialCode!;
    }
    final newForced = _resolveLanguageValue(widget.forcedLanguage);
    if (newForced != _forcedLanguageValue) {
      _forcedLanguageValue = newForced;
      if (_forcedLanguageValue != null) {
        setState(() {
          _selectedLanguage = _forcedLanguageValue!;
        });
      }
    }
  }

  void _syncLineNumberScroll() {
    if (_lineNumberScrollController.hasClients) {
      _lineNumberScrollController.jumpTo(_codeScrollController.offset);
    }
  }

  void _initializeWebView() {
    late final PlatformWebViewControllerCreationParams params;

    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params);
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isPreviewLoading = true),
          onPageFinished: (_) => setState(() => _isPreviewLoading = false),
        ),
      );

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _webViewController = controller;
  }

  Future<void> _loadPreview() async {
    final fullHtml = '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body {
          margin: 0;
          padding: 24px;
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
          background: #f9fafb;
          color: #111;
        }
      </style>
    </head>
    <body>
      ${_codeController.text}
    </body>
    </html>
    ''';

    setState(() {
      _isPreviewLoading = true;
      _showPreviewPanel = true;
    });
    await _webViewController.loadHtmlString(fullHtml);
  }

  bool get _usesWebView =>
      _selectedLanguage == 'html' || _selectedLanguage == 'css';

  // ✅ Modified: Add credit check before running code
  Future<void> _runCode() async {
    // First check if user has enough credits
    final hasEnoughCredits = await _checkAndDeductCredit();

    if (!hasEnoughCredits) {
      return; // Stop if not enough credits
    }

    // Now run the code
    if (_usesWebView) {
      await _loadPreview();
    } else {
      await _executeCode();
    }
  }

  // ✅ New method: Check and deduct 1 credit
  Future<bool> _checkAndDeductCredit() async {
    try {
      final creditManager = context.read<CreditManager>();

      // Check current credits
      if (creditManager.isLoading) {
        // Wait a bit if credits are still loading
        await Future.delayed(const Duration(milliseconds: 300));
      }

      final currentCredits = creditManager.credits;

      if (currentCredits < 1) {
        _showNotEnoughCreditsDialog(context);
        return false;
      }

      // Deduct 1 credit
      final success = await creditManager.deductCredits(
          1,
          reason: 'compiler_run_${_selectedLanguage}'
      );

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to deduct credit. Please try again.'),
            duration: const Duration(seconds: 2),
          ),
        );
        return false;
      }

      debugPrint('✅ 1 credit deducted for compiler usage');
      return true;

    } catch (e) {
      debugPrint('❌ Error checking/deducting credit: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error processing credit. Please try again.'),
          duration: const Duration(seconds: 2),
        ),
      );
      return false;
    }
  }

  // ✅ New method: Show insufficient credits dialog
  void _showNotEnoughCreditsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Insufficient Credits'),
        content: const Text(
          'You need at least 1 credit to run code in the compiler.\n\nGet more credits from the profile screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              // Navigate to credit purchase screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CreditsPurchaseScreen(),
                ),
              );
            },
            child: const Text('Get Credits'),
          ),
        ],
      ),
    );
  }

  // ✅ Modified: Also check credits for refresh button
  void _onRefreshPressed() async {
    final hasEnoughCredits = await _checkAndDeductCredit();
    if (hasEnoughCredits) {
      await _loadPreview();
    }
  }

  Future<void> _executeCode() async {
    setState(() {
      _isExecuting = true;
      _executionOutput = null;
      _executionError = null;
      _showPreviewPanel = true;
    });

    final headers = {'Content-Type': 'application/json'};

    final payload = {
      'code': _codeController.text,
      'language': _selectedLanguage == 'cpp' ? 'cpp' : _selectedLanguage,
      'input': '',
    };
    
    debugPrint('🚀 [Compiler] Executing with language: ${payload['language']}, _selectedLanguage: $_selectedLanguage');

    try {
      debugPrint('🔄 Executing code payload: ${jsonEncode(payload)}');
      final response = await http.post(
        Uri.parse(_apiEndpoint),
        headers: headers,
        body: jsonEncode(payload),
      );
      if (response.statusCode == 200) {
        debugPrint('✅ API response: ${response.body}');
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _executionOutput = body['output'] as String?;
          _executionError = body['error'] as String?;
        });
      } else {
        debugPrint('⚠️ API error ${response.statusCode}: ${response.body}');
        final errorMessage = response.statusCode == 400
            ? 'Please select the correct language before running the code.'
            : 'Server error (${response.statusCode}): ${response.reasonPhrase}';
        setState(() {
          _executionError = errorMessage;
        });
      }
    } catch (e) {
      debugPrint('❌ Execution exception: $e');
      setState(() {
        _executionError = 'Execution failed: $e';
      });
    } finally {
      setState(() {
        _isExecuting = false;
      });
    }
  }

  Widget _buildPanelToggle({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: active ? Colors.white : Colors.transparent,
          foregroundColor: active ? Colors.black : Colors.grey[600],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildEditorBody(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.background,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            padding: EdgeInsets.zero,
            child: Scrollbar(
              controller: _lineNumberScrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _lineNumberScrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(
                    _codeLines().length,
                        (index) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.5),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'Monospace',
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Scrollbar(
              controller: _codeScrollController,
              thumbVisibility: true,
              child: TextField(
                controller: _codeController,
                scrollController: _codeScrollController,
                style: const TextStyle(
                  fontFamily: 'Monospace',
                  fontSize: 14,
                  height: 1.6,
                ),
                maxLines: null,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Type your HTML code here...',
                  hintStyle: TextStyle(color: Colors.grey),
                  isDense: true,
                ),
                keyboardType: TextInputType.multiline,
                readOnly: widget.isReadOnly,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _resolveLanguageValue(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.toLowerCase();
    for (final entry in _languageAliases.entries) {
      if (normalized.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  String _languageDisplayName(String code) {
    switch (code) {
      case 'html':
        return 'HTML';
      case 'css':
        return 'CSS';
      case 'javascript':
        return 'JavaScript';
      case 'python':
        return 'Python';
      case 'java':
        return 'Java';
      case 'cpp':
        return 'C++';
      default:
        return code.toUpperCase();
    }
  }

  Widget _buildPreviewBody(
      ThemeData theme, ColorScheme colorScheme, Color previewHeaderColor) {
    if (_usesWebView) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: previewHeaderColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.visibility, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Live Preview',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      tooltip: 'Refresh preview',
                      onPressed: _onRefreshPressed, // ✅ Changed to use new method
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 320,
                child: Stack(
                  children: [
                    WebViewWidget(controller: _webViewController),
                    if (_isPreviewLoading)
                      Positioned.fill(
                        child: Container(
                          color: Colors.white.withOpacity(0.7),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _buildExecutionResultBody(theme, colorScheme);
  }
  Widget _creditNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.yellow[700],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        "⚠ Running the code will deduct 1 credit from your account.",
        style: TextStyle(color: Colors.black, fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildExecutionResultBody(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Execution Output',
                style: theme.textTheme.titleSmall,
              ),
              if (_isExecuting)
                Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text('Running...', style: theme.textTheme.bodySmall),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_executionOutput != null)
                  Text(
                    'Output:\n${_executionOutput}',
                    style: const TextStyle(fontFamily: 'Monospace'),
                  ),
                if (_executionError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Error:\n${_executionError}',
                    style: const TextStyle(
                      fontFamily: 'Monospace',
                      color: Colors.redAccent,
                    ),
                  ),
                ],
                if (_executionOutput == null && _executionError == null)
                  Text(
                    'No execution results yet.',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  List<String> _codeLines() {
    return _codeController.text.split('\n');
  }

  @override
  void dispose() {
    _codeController.dispose();
    _codeScrollController.dispose();
    _lineNumberScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final previewHeaderColor = colorScheme.primary;

    final content = Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _creditNotice(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          _buildPanelToggle(
                            label: 'Code',
                            active: !_showPreviewPanel,
                            onTap: () =>
                                setState(() => _showPreviewPanel = false),
                          ),
                          _buildPanelToggle(
                            label: 'Preview',
                            active: _showPreviewPanel,
                            onTap: () =>
                                setState(() => _showPreviewPanel = true),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _runCode,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Run'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: previewHeaderColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (!widget.embedMode)
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Language',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedLanguage,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: 'html',
                            child: Text('HTML'),
                          ),
                          DropdownMenuItem(
                            value: 'css',
                            child: Text('CSS'),
                          ),
                          DropdownMenuItem(
                            value: 'javascript',
                            child: Text('JavaScript'),
                          ),
                          DropdownMenuItem(
                            value: 'python',
                            child: Text('Python'),
                          ),
                          DropdownMenuItem(
                            value: 'java',
                            child: Text('Java'),
                          ),
                          DropdownMenuItem(
                            value: 'cpp',
                            child: Text('C++'),
                          ),
                        ],
                        onChanged: (value) => setState(() {
                          _selectedLanguage = value!;
                          if (_usesWebView) {
                            _showPreviewPanel = true;
                          }
                        }),
                      ),
                    ),
                  )
                else
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Language: ${_languageDisplayName(_selectedLanguage)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
              ],
            ),
          ),
          AnimatedCrossFade(
            firstChild: _buildEditorBody(theme, colorScheme),
            secondChild:
            _buildPreviewBody(theme, colorScheme, previewHeaderColor),
            crossFadeState: _showPreviewPanel
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );

    if (widget.embedMode) {
      return content;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [content],
      ),
    );
  }
}
*/
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:provider/provider.dart';
import 'package:coding_tutor/in_app_purchase/credit_manager.dart';
import 'package:coding_tutor/in_app_purchase/credit_purchase_screen.dart';

class CompilerScreen extends StatelessWidget {
  const CompilerScreen({super.key, this.initialCode});

  final String? initialCode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Compiler'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: CompilerPane(
        initialCode: initialCode,
      ),
    );
  }
}

class CompilerPane extends StatefulWidget {
  const CompilerPane({
    super.key,
    this.initialCode,
    this.embedMode = false,
    this.forcedLanguage,
    this.isReadOnly = false,
  });

  final String? initialCode;
  final bool embedMode;
  final String? forcedLanguage;
  final bool isReadOnly;

  @override
  State<CompilerPane> createState() => _CompilerPaneState();
}

class _CompilerPaneState extends State<CompilerPane> {
  static const _starterCode = '''
<h1>Hello, world!</h1>
<p>This snippet runs inside the live preview. Update the HTML and press Run.</p>
''';

  final TextEditingController _codeController =
  TextEditingController(text: _starterCode);
  final ScrollController _codeScrollController = ScrollController();
  final ScrollController _lineNumberScrollController = ScrollController();
  late final WebViewController _webViewController;
  bool _isPreviewLoading = true;
  bool _showPreviewPanel = false;
  String _selectedLanguage = 'html';
  bool _isExecuting = false;
  String? _executionOutput;
  String? _executionError;
  static const _apiEndpoint =
      'https://tgeazxxujp.ap-south-1.awsapprunner.com/api/code/execute';
  String? _forcedLanguageValue;
  static const Map<String, String> _languageAliases = {
    'html': 'html',
    'css': 'css',
    'javascript': 'javascript',
    'js': 'javascript',
    'python': 'python',
    'java': 'java',
    'c++': 'cpp',
    'cpp': 'cpp',
  };

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _codeController.text = widget.initialCode ?? _starterCode;
    _forcedLanguageValue = _resolveLanguageValue(widget.forcedLanguage);
    if (_forcedLanguageValue != null) {
      _selectedLanguage = _forcedLanguageValue!;
    }
    _codeScrollController.addListener(_syncLineNumberScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPreview());
  }

  @override
  void didUpdateWidget(covariant CompilerPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCode != widget.initialCode &&
        widget.initialCode != null) {
      _codeController.text = widget.initialCode!;
    }
    final newForced = _resolveLanguageValue(widget.forcedLanguage);
    if (newForced != _forcedLanguageValue) {
      _forcedLanguageValue = newForced;
      if (_forcedLanguageValue != null) {
        setState(() {
          _selectedLanguage = _forcedLanguageValue!;
        });
      }
    }
  }

  void _syncLineNumberScroll() {
    if (_lineNumberScrollController.hasClients) {
      _lineNumberScrollController.jumpTo(_codeScrollController.offset);
    }
  }

  void _initializeWebView() {
    late final PlatformWebViewControllerCreationParams params;

    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params);
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isPreviewLoading = true),
          onPageFinished: (_) => setState(() => _isPreviewLoading = false),
        ),
      );

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _webViewController = controller;
  }

  Future<void> _loadPreview() async {
    final fullHtml = '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body {
          margin: 0;
          padding: 24px;
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
          background: #f9fafb;
          color: #111;
        }
      </style>
    </head>
    <body>
      ${_codeController.text}
    </body>
    </html>
    ''';

    setState(() {
      _isPreviewLoading = true;
      _showPreviewPanel = true;
    });
    await _webViewController.loadHtmlString(fullHtml);
  }

  bool get _usesWebView =>
      _selectedLanguage == 'html' || _selectedLanguage == 'css';

  Future<void> _runCode() async {
    final hasEnoughCredits = await _checkAndDeductCredit();

    if (!hasEnoughCredits) {
      return;
    }

    if (_usesWebView) {
      await _loadPreview();
    } else {
      await _executeCode();
    }
  }

  Future<bool> _checkAndDeductCredit() async {
    try {
      final creditManager = context.read<CreditManager>();

      if (creditManager.isLoading) {
        await Future.delayed(const Duration(milliseconds: 300));
      }

      final currentCredits = creditManager.credits;

      if (currentCredits < 1) {
        _showNotEnoughCreditsDialog(context);
        return false;
      }

      final success = await creditManager.deductCredits(1,
          reason: 'compiler_run_$_selectedLanguage');

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to deduct credit. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
        return false;
      }

      debugPrint('✅ 1 credit deducted for compiler usage');
      return true;
    } catch (e) {
      debugPrint('❌ Error checking/deducting credit: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error processing credit. Please try again.'),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }
  }

  void _showNotEnoughCreditsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Insufficient Credits'),
        content: const Text(
          'You need at least 1 credit to run code in the compiler.\n\nGet more credits from the profile screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CreditsPurchaseScreen(),
                ),
              );
            },
            child: const Text('Get Credits'),
          ),
        ],
      ),
    );
  }

  void _onRefreshPressed() async {
    final hasEnoughCredits = await _checkAndDeductCredit();
    if (hasEnoughCredits) {
      await _loadPreview();
    }
  }

  Future<void> _executeCode() async {
    setState(() {
      _isExecuting = true;
      _executionOutput = null;
      _executionError = null;
      _showPreviewPanel = true;
    });

    final headers = {'Content-Type': 'application/json'};

    final payload = {
      'code': _codeController.text,
      'language': _selectedLanguage == 'cpp' ? 'cpp' : _selectedLanguage,
      'input': '',
    };

    debugPrint(
        '🚀 [Compiler] Executing with language: ${payload['language']}, _selectedLanguage: $_selectedLanguage');

    try {
      debugPrint('🔄 Executing code payload: ${jsonEncode(payload)}');
      final response = await http.post(
        Uri.parse(_apiEndpoint),
        headers: headers,
        body: jsonEncode(payload),
      );
      if (response.statusCode == 200) {
        debugPrint('✅ API response: ${response.body}');
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _executionOutput = body['output'] as String?;
          _executionError = body['error'] as String?;
        });
      } else {
        debugPrint('⚠️ API error ${response.statusCode}: ${response.body}');
        final errorMessage = response.statusCode == 400
            ? 'Please select the correct language before running the code.'
            : 'Server error (${response.statusCode}): ${response.reasonPhrase}';
        setState(() {
          _executionError = errorMessage;
        });
      }
    } catch (e) {
      debugPrint('❌ Execution exception: $e');
      setState(() {
        _executionError = 'Execution failed: $e';
      });
    } finally {
      setState(() {
        _isExecuting = false;
      });
    }
  }

  String? _resolveLanguageValue(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.toLowerCase();
    for (final entry in _languageAliases.entries) {
      if (normalized.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  String _languageDisplayName(String code) {
    switch (code) {
      case 'html':
        return 'HTML';
      case 'css':
        return 'CSS';
      case 'javascript':
        return 'JavaScript';
      case 'python':
        return 'Python';
      case 'java':
        return 'Java';
      case 'cpp':
        return 'C++';
      default:
        return code.toUpperCase();
    }
  }

  List<String> _codeLines() {
    return _codeController.text.split('\n');
  }

  Widget _buildCodeShortcutButton(String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        final currentText = _codeController.text;
        final selection = _codeController.selection;
        final newText = currentText.substring(0, selection.baseOffset) +
            label +
            currentText.substring(selection.extentOffset);
        _codeController.text = newText;
        _codeController.selection = TextSelection.collapsed(
          offset: selection.baseOffset + label.length,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colorScheme.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Monospace',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _codeScrollController.dispose();
    _lineNumberScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // If embed mode, show simplified version without tabs and bottom buttons
    if (widget.embedMode) {
      return Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outline.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with language and run button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Language: ${_languageDisplayName(_selectedLanguage)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isExecuting ? null : _runCode,
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Run'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),

            // Code/Preview tabs
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _showPreviewPanel = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: !_showPreviewPanel
                              ? colorScheme.primary.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.code,
                              size: 18,
                              color: !_showPreviewPanel
                                  ? colorScheme.primary
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Code',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: !_showPreviewPanel
                                    ? colorScheme.primary
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _showPreviewPanel = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _showPreviewPanel
                              ? colorScheme.primary.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.visibility_outlined,
                              size: 18,
                              color: _showPreviewPanel
                                  ? colorScheme.primary
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Preview',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _showPreviewPanel
                                    ? colorScheme.primary
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Code/Preview Content
            SizedBox(
              height: 320,
              child: _showPreviewPanel
                  ? _buildPreviewContent()
                  : _buildCodeEditor(),
            ),

            // Code Shortcuts Bar (only show in code view)
            if (!_showPreviewPanel)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.background,
                  border: Border(
                    top: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCodeShortcutButton('{'),
                      const SizedBox(width: 8),
                      _buildCodeShortcutButton('}'),
                      const SizedBox(width: 8),
                      _buildCodeShortcutButton('('),
                      const SizedBox(width: 8),
                      _buildCodeShortcutButton(')'),
                      const SizedBox(width: 8),
                      _buildCodeShortcutButton(';'),
                      const SizedBox(width: 8),
                      _buildCodeShortcutButton('='),
                      const SizedBox(width: 8),
                      _buildCodeShortcutButton('const'),
                      const SizedBox(width: 8),
                      _buildCodeShortcutButton('log'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // Full screen mode (standalone CompilerScreen)
    return Column(
      children: [
        // Tab Bar Section
        Container(
          color: colorScheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _showPreviewPanel = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !_showPreviewPanel
                          ? colorScheme.primary.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.code,
                          size: 20,
                          color: !_showPreviewPanel
                              ? colorScheme.primary
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Code',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: !_showPreviewPanel
                                ? colorScheme.primary
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _showPreviewPanel = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _showPreviewPanel
                          ? colorScheme.primary.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          size: 20,
                          color: _showPreviewPanel
                              ? colorScheme.primary
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Preview',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _showPreviewPanel
                                ? colorScheme.primary
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Main Content Area
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outline.withOpacity(0.4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                // Language Selector
                if (!widget.embedMode)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
                      ),
                    ),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Language',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedLanguage,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                              value: 'html',
                              child: Text('HTML'),
                            ),
                            DropdownMenuItem(
                              value: 'css',
                              child: Text('CSS'),
                            ),
                            DropdownMenuItem(
                              value: 'javascript',
                              child: Text('JavaScript'),
                            ),
                            DropdownMenuItem(
                              value: 'python',
                              child: Text('Python'),
                            ),
                            DropdownMenuItem(
                              value: 'java',
                              child: Text('Java'),
                            ),
                            DropdownMenuItem(
                              value: 'cpp',
                              child: Text('C++'),
                            ),
                          ],
                          onChanged: (value) => setState(() {
                            _selectedLanguage = value!;
                            if (_usesWebView) {
                              _showPreviewPanel = true;
                            }
                          }),
                        ),
                      ),
                    ),
                  ),

                // Code/Preview Content
                Expanded(
                  child: _showPreviewPanel
                      ? _buildPreviewContent()
                      : _buildCodeEditor(),
                ),

                // Code Shortcuts Bar (only show in code view)
                if (!_showPreviewPanel)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.background,
                      border: Border(
                        top: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
                      ),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildCodeShortcutButton('{'),
                          const SizedBox(width: 8),
                          _buildCodeShortcutButton('}'),
                          const SizedBox(width: 8),
                          _buildCodeShortcutButton('('),
                          const SizedBox(width: 8),
                          _buildCodeShortcutButton(')'),
                          const SizedBox(width: 8),
                          _buildCodeShortcutButton(';'),
                          const SizedBox(width: 8),
                          _buildCodeShortcutButton('='),
                          const SizedBox(width: 8),
                          _buildCodeShortcutButton('const'),
                          const SizedBox(width: 8),
                          _buildCodeShortcutButton('log'),
                        ],
                      ),
                    ),
                  ),

                // Warning and Run Button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border(
                      top: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Warning
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Colors.orange[700], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'You will be charged 1 credit for each run.',
                                style: TextStyle(
                                  color: Colors.orange[900],
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Run Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isExecuting ? null : _runCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isExecuting
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          )
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.play_arrow, size: 24),
                              const SizedBox(width: 8),
                              const Text(
                                'Run Code',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '1 credit',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildCodeEditor() {
    final colorScheme = Theme.of(context).colorScheme;
    final codeLines = _codeLines(); // Get current code lines

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Line numbers
          Container(
            padding: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: colorScheme.outline.withOpacity(0.12),
                  width: 1.5,
                ),
              ),
            ),
            child: SingleChildScrollView(
              controller: _lineNumberScrollController,
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(
                  codeLines.length,
                      (index) => Container(
                    height: 21, // Match TextField line height
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'Monospace',
                        color: Colors.grey[400],
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Code editor
          Expanded(
            child: TextField(
              controller: _codeController,
              scrollController: _codeScrollController,
              style: TextStyle(
                fontFamily: 'Monospace',
                fontSize: 14,
                height: 1.5,
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w400,
              ),
              maxLines: null, // Allow unlimited lines
              minLines: 1, // Start with at least 1 line
              expands: false, // Important: false to allow growing
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: 'Type your code here...',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontFamily: 'Monospace',
                  fontWeight: FontWeight.w400,
                ),
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              keyboardType: TextInputType.multiline,
              readOnly: widget.isReadOnly,
              cursorColor: colorScheme.primary,
              cursorWidth: 2,
              onChanged: (value) {
                // Force rebuild when lines change
                setState(() {
                  // This will trigger rebuild and update line numbers
                });
              },
            ),
          ),
        ],
      ),
    );
  }
/*
  Widget _buildCodeEditor() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Line numbers
          Container(
            padding: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: colorScheme.outline.withOpacity(0.12),
                  width: 1.5,
                ),
              ),
            ),
            child: SingleChildScrollView(
              controller: _lineNumberScrollController,
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(
                  _codeLines().length,
                      (index) => Container(
                    height: 21, // Match TextField line height
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'Monospace',
                        color: Colors.grey[400],
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Code editor
          Expanded(
            child: TextField(
              controller: _codeController,
              scrollController: _codeScrollController,
              style: TextStyle(
                fontFamily: 'Monospace',
                fontSize: 14,
                height: 1.5,
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w400,
              ),
              maxLines: null,
              expands: false,
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: 'Type your code here...',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontFamily: 'Monospace',
                  fontWeight: FontWeight.w400,
                ),
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              keyboardType: TextInputType.multiline,
              readOnly: widget.isReadOnly,
              cursorColor: colorScheme.primary,
              cursorWidth: 2,
            ),
          ),
        ],
      ),
    );
  }
*/

  Widget _buildPreviewContent() {
    if (_usesWebView) {
      return Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          if (_isPreviewLoading)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      );
    }

    // Execution output for non-webview languages
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Execution Output',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              if (_isExecuting)
                Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Running...',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_executionOutput != null && _executionOutput!.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Output:',
                            style: TextStyle(
                              fontFamily: 'Monospace',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _executionOutput!,
                            style: TextStyle(
                              fontFamily: 'Monospace',
                              fontSize: 13,
                              color: colorScheme.onBackground,
                            ),
                          ),
                        ],
                      ),
                    if (_executionError != null && _executionError!.isNotEmpty) ...[
                      if (_executionOutput != null && _executionOutput!.isNotEmpty)
                        const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Error:',
                            style: TextStyle(
                              fontFamily: 'Monospace',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _executionError!,
                            style: const TextStyle(
                              fontFamily: 'Monospace',
                              fontSize: 13,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if ((_executionOutput == null || _executionOutput!.isEmpty) &&
                        (_executionError == null || _executionError!.isEmpty))
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.code_off,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No output yet',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Run your code to see results',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
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
        ],
      ),
    );
  }
}