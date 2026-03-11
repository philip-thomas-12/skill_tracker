import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static String get apiKey => dotenv.env['GEMINI_API_KEY'] ?? "";
  static const int maxRetries = 2; // Reduced from 3
  static const Duration timeoutDuration = Duration(seconds: 30);

  // Longer cache duration to reduce API calls
  static final Map<String, List<Map<String, dynamic>>> _quizCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration cacheDuration =
      Duration(hours: 24); // Increased to 24 hours

  // Track last API call time to prevent quota exceeded
  static DateTime _lastApiCall =
      DateTime.now().subtract(const Duration(minutes: 1));
  static const int minSecondsBetweenCalls =
      30; // Minimum 30 seconds between API calls

  static Future<List<Map<String, dynamic>>> generateQuiz(
    String skill,
    String difficulty, {
    int numberOfQuestions = 10,
    bool forceRefresh = false,
  }) async {
    final cacheKey = "$skill-$difficulty-$numberOfQuestions";

    // Check cache first
    if (!forceRefresh && _isCacheValid(cacheKey)) {
      debugPrint('📦 Using cached quiz for $skill ($difficulty)');
      return _quizCache[cacheKey]!;
    }

    // Check if we're calling API too frequently
    final now = DateTime.now();
    final secondsSinceLastCall = now.difference(_lastApiCall).inSeconds;

    if (secondsSinceLastCall < minSecondsBetweenCalls) {
      debugPrint(
          '⏱️ Too many API calls. Using fallback to avoid quota issues.');
      return _generateFallbackQuestions(skill, difficulty, numberOfQuestions);
    }

    debugPrint('🤖 Generating quiz for $skill ($difficulty)');

    // Try API call
    try {
      _lastApiCall = now;
      final questions =
          await _makeApiRequest(skill, difficulty, numberOfQuestions);

      if (_validateQuizData(questions, numberOfQuestions)) {
        _quizCache[cacheKey] = questions;
        _cacheTimestamps[cacheKey] = DateTime.now();
        return questions;
      }
    } catch (e) {
      debugPrint('❌ API failed: $e');
    }

    // Always have fallback ready
    debugPrint('📚 Using fallback questions for $skill');
    return _generateFallbackQuestions(skill, difficulty, numberOfQuestions);
  }

  // Keep the _makeApiRequest method but make it more robust
  static Future<List<Map<String, dynamic>>> _makeApiRequest(
    String skill,
    String difficulty,
    int numberOfQuestions,
  ) async {
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey",
    );

    final prompt = """
Generate $numberOfQuestions multiple choice questions about $skill at $difficulty level.

Return ONLY this JSON format:
[
  {
    "question": "question text",
    "options": ["option1", "option2", "option3", "option4"],
    "answer": "option1"
  }
]
""";

    final response = await http
        .post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "contents": [
              {
                "parts": [
                  {"text": prompt}
                ]
              }
            ]
          }),
        )
        .timeout(timeoutDuration);

    if (response.statusCode != 200) {
      throw Exception('API returned status ${response.statusCode}');
    }

    final Map<String, dynamic> data = jsonDecode(response.body);
    final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];

    if (text == null) throw Exception('Invalid response');

    final cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();
    return List<Map<String, dynamic>>.from(jsonDecode(cleaned));
  }

  // COMPLETELY REWRITTEN fallback with 10+ templates per difficulty
  static List<Map<String, dynamic>> _generateFallbackQuestions(
    String skill,
    String difficulty,
    int numberOfQuestions,
  ) {
    debugPrint(
        '📚 Generating $numberOfQuestions fallback questions for $skill');

    final List<Map<String, dynamic>> fallbackQuestions = [];

    // Get templates based on difficulty - each has 10+ questions
    List<Map<String, dynamic>> templates;
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        templates = _getBeginnerTemplates(skill);
        break;
      case 'intermediate':
        templates = _getIntermediateTemplates(skill);
        break;
      case 'advanced':
        templates = _getAdvancedTemplates(skill);
        break;
      default:
        templates = _getBeginnerTemplates(skill);
    }

    // Generate requested number of questions by cycling through templates
    for (int i = 0; i < numberOfQuestions; i++) {
      final templateIndex = i % templates.length;
      final template = templates[templateIndex];

      // Make a copy with skill name inserted
      final question = Map<String, dynamic>.from(template);
      question['question'] = template['question'].replaceAll('{skill}', skill);

      fallbackQuestions.add(question);
    }

    return fallbackQuestions;
  }

  // 10+ Beginner templates
  static List<Map<String, dynamic>> _getBeginnerTemplates(String skill) {
    return [
      {
        'question': 'What is the primary purpose of {skill}?',
        'options': [
          'To solve specific problems efficiently',
          'To make code look beautiful',
          'To replace other technologies',
          'To complicate simple tasks'
        ],
        'answer': 'To solve specific problems efficiently',
        'hint': 'Think about why people learn this skill'
      },
      {
        'question':
            'Which of the following is a fundamental concept in {skill}?',
        'options': [
          'Variables and data types',
          'Quantum computing',
          'Neural networks',
          'Blockchain'
        ],
        'answer': 'Variables and data types',
        'hint': 'Start with the basics'
      },
      {
        'question': 'What is the best way to learn {skill}?',
        'options': [
          'Practice regularly',
          'Watch tutorials only',
          'Read books without practicing',
          'Copy-paste from internet'
        ],
        'answer': 'Practice regularly',
        'hint': 'Hands-on experience is key'
      },
      {
        'question': 'What is a variable in {skill}?',
        'options': [
          'A container for storing data',
          'A type of loop',
          'A function name',
          'A comment in code'
        ],
        'answer': 'A container for storing data',
        'hint': 'Think about storing information'
      },
      {
        'question': 'What is a function in {skill}?',
        'options': [
          'A reusable block of code',
          'A type of variable',
          'A programming language',
          'An error message'
        ],
        'answer': 'A reusable block of code',
        'hint': 'Code that performs a specific task'
      },
      {
        'question': 'What is a loop used for in {skill}?',
        'options': [
          'Repeating code multiple times',
          'Storing data',
          'Creating functions',
          'Debugging code'
        ],
        'answer': 'Repeating code multiple times',
        'hint': 'Doing something over and over'
      },
      {
        'question': 'What is an array in {skill}?',
        'options': [
          'A collection of items',
          'A single value',
          'A type of loop',
          'A function name'
        ],
        'answer': 'A collection of items',
        'hint': 'List of similar items'
      },
      {
        'question': 'What is debugging in {skill}?',
        'options': [
          'Finding and fixing errors',
          'Writing new code',
          'Running the program',
          'Installing software'
        ],
        'answer': 'Finding and fixing errors',
        'hint': 'Removing bugs from code'
      },
      {
        'question': 'What is a comment in {skill}?',
        'options': [
          'Text ignored by the computer',
          'Code that runs',
          'An error message',
          'A variable name'
        ],
        'answer': 'Text ignored by the computer',
        'hint': 'Notes for humans reading the code'
      },
      {
        'question': 'What is syntax in {skill}?',
        'options': [
          'Rules for writing code',
          'A type of error',
          'A programming language',
          'A debugging tool'
        ],
        'answer': 'Rules for writing code',
        'hint': 'Grammar of the programming language'
      },
    ];
  }

  // 10+ Intermediate templates
  static List<Map<String, dynamic>> _getIntermediateTemplates(String skill) {
    return [
      {
        'question': 'When would you use {skill} in a real-world project?',
        'options': [
          'For building scalable applications',
          'For creating simple scripts',
          'For hardware programming only',
          'For game development exclusively'
        ],
        'answer': 'For building scalable applications',
        'hint': 'Consider the practical applications'
      },
      {
        'question': 'What is a common design pattern used in {skill}?',
        'options': [
          'MVC (Model-View-Controller)',
          'Singleton',
          'Factory',
          'Observer'
        ],
        'answer': 'MVC (Model-View-Controller)',
        'hint': 'Think about code organization'
      },
      {
        'question': 'What is the difference between == and === in {skill}?',
        'options': [
          'Value vs. value and type comparison',
          'Assignment vs. comparison',
          'String vs. number comparison',
          'There is no difference'
        ],
        'answer': 'Value vs. value and type comparison',
        'hint': 'One checks only value, the other checks value and type'
      },
      {
        'question': 'What is a closure in {skill}?',
        'options': [
          'A function with access to its outer scope',
          'A closed loop',
          'An error state',
          'A type of variable'
        ],
        'answer': 'A function with access to its outer scope',
        'hint': 'Function that remembers its environment'
      },
      {
        'question': 'What is an API in {skill} development?',
        'options': [
          'Application Programming Interface',
          'Advanced Programming Interface',
          'Application Process Integration',
          'Automated Program Installation'
        ],
        'answer': 'Application Programming Interface',
        'hint': 'Way for different software to communicate'
      },
      {
        'question': 'What is version control?',
        'options': [
          'Tracking changes in code',
          'Controlling software versions',
          'Managing dependencies',
          'Testing code versions'
        ],
        'answer': 'Tracking changes in code',
        'hint': 'Git is an example'
      },
      {
        'question': 'What is a framework in {skill}?',
        'options': [
          'A pre-built structure for applications',
          'A programming language',
          'A type of database',
          'A debugging tool'
        ],
        'answer': 'A pre-built structure for applications',
        'hint': 'Provides reusable code and patterns'
      },
      {
        'question': 'What is asynchronous programming?',
        'options': [
          'Code that runs without blocking',
          'Code that runs sequentially',
          'Code that never runs',
          'Code that runs twice'
        ],
        'answer': 'Code that runs without blocking',
        'hint': 'Operations that don\'t wait for each other'
      },
      {
        'question': 'What is a database index used for?',
        'options': [
          'Speeding up queries',
          'Storing data',
          'Deleting data',
          'Backing up data'
        ],
        'answer': 'Speeding up queries',
        'hint': 'Like an index in a book'
      },
      {
        'question': 'What is REST in web development?',
        'options': [
          'An architectural style for APIs',
          'A programming language',
          'A database type',
          'A testing framework'
        ],
        'answer': 'An architectural style for APIs',
        'hint': 'Representational State Transfer'
      },
    ];
  }

  // 10+ Advanced templates
  static List<Map<String, dynamic>> _getAdvancedTemplates(String skill) {
    return [
      {
        'question': 'What is a common performance optimization in {skill}?',
        'options': [
          'Caching and memoization',
          'Adding more comments',
          'Using longer variable names',
          'Avoiding functions'
        ],
        'answer': 'Caching and memoization',
        'hint': 'Store results of expensive operations'
      },
      {
        'question': 'What is memory leak and how to prevent it?',
        'options': [
          'Unused memory not released - use weak references',
          'Too much memory - add more RAM',
          'Slow memory - upgrade hardware',
          'Fragmented memory - restart app'
        ],
        'answer': 'Unused memory not released - use weak references',
        'hint': 'Memory that is no longer needed but not freed'
      },
      {
        'question':
            'What is the difference between concurrency and parallelism?',
        'options': [
          'Concurrency is structure, parallelism is execution',
          'They are the same thing',
          'Parallelism is faster',
          'Concurrency is newer'
        ],
        'answer': 'Concurrency is structure, parallelism is execution',
        'hint':
            'One is about dealing with multiple things, the other is doing multiple things'
      },
      {
        'question': 'What is dependency injection?',
        'options': [
          'Providing dependencies from outside',
          'Creating dependencies inside',
          'Removing dependencies',
          'Testing dependencies'
        ],
        'answer': 'Providing dependencies from outside',
        'hint': 'Inversion of control'
      },
      {
        'question': 'What is a microservices architecture?',
        'options': [
          'Small, independent services',
          'One large application',
          'A database design',
          'A testing strategy'
        ],
        'answer': 'Small, independent services',
        'hint': 'Opposite of monolithic'
      },
      {
        'question': 'What is CI/CD?',
        'options': [
          'Continuous Integration/Continuous Deployment',
          'Code Integration/Core Development',
          'Computer Interface/Computer Design',
          'Central Input/Central Output'
        ],
        'answer': 'Continuous Integration/Continuous Deployment',
        'hint': 'Automated building and deploying'
      },
      {
        'question': 'What is a deadlock in concurrent programming?',
        'options': [
          'Two processes waiting for each other',
          'A crashed program',
          'An infinite loop',
          'A memory error'
        ],
        'answer': 'Two processes waiting for each other',
        'hint': 'Circular waiting'
      },
      {
        'question': 'What is the CAP theorem?',
        'options': [
          'Consistency, Availability, Partition tolerance',
          'Code, API, Protocol',
          'Computer, Application, Program',
          'Cache, Array, Pointer'
        ],
        'answer': 'Consistency, Availability, Partition tolerance',
        'hint': 'You can only have two of three in distributed systems'
      },
      {
        'question': 'What is A/B testing?',
        'options': [
          'Comparing two versions',
          'Testing with two users',
          'Testing two features',
          'Testing two times'
        ],
        'answer': 'Comparing two versions',
        'hint': 'Experiment with different variants'
      },
      {
        'question': 'What is technical debt?',
        'options': [
          'Cost of fixing poor code later',
          'Money owed for software',
          'Time spent coding',
          'Hardware costs'
        ],
        'answer': 'Cost of fixing poor code later',
        'hint': 'Shortcuts now = more work later'
      },
    ];
  }

  static bool _validateQuizData(
      List<Map<String, dynamic>> questions, int expectedCount) {
    if (questions.length != expectedCount) return false;

    for (var q in questions) {
      if (!q.containsKey('question') ||
          !q.containsKey('options') ||
          (q['options'] as List).length != 4 ||
          !q.containsKey('answer')) {
        return false;
      }
    }
    return true;
  }

  static bool _isCacheValid(String key) {
    if (!_quizCache.containsKey(key) || !_cacheTimestamps.containsKey(key)) {
      return false;
    }
    final age = DateTime.now().difference(_cacheTimestamps[key]!);
    return age < cacheDuration;
  }
}
