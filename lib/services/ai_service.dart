import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../env.dart';

class AiService {
  final GenerativeModel _model;

  AiService()
      : _model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: Env.geminiApiKey,
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
          ),
        );

  /// Generates a syllabus and estimates the total hours required to learn a skill.
  /// Returns a Map with 'estimatedHours' (int) and 'syllabus' (List of Maps with 'topic' and 'description').
  Future<Map<String, dynamic>> generateSyllabusAndEstimate(
    String skillName,
    String targetLevel,
    int hoursPerDay,
  ) async {
    if (Env.geminiApiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      throw Exception('Please set your Gemini API key in lib/env.dart');
    }

    final prompt = '''
You are an expert curriculum designer. A user wants to learn the skill "$skillName" to a "$targetLevel" level, dedicating $hoursPerDay hours per day.

First, strictly validate if "$skillName" is a real, learnable skill. If it is nonsense or impossible to teach (like "skill 1", "asdf"), return STRICTLY:
{"error": "Invalid skill"}

If it IS a valid skill:
1. Realistically estimate how many TOTAL hours it will take for them to reach this level. Be generous with time estimates; complex topics like Data Structures & Algorithms should be a minimum of 48-100 hours depending on the level.
2. Break down the entire learning path into a structured syllabus of distinct topics.
3. Assign a specific estimated hour count to each topic.
4. For each topic, provide a list of high-quality, stable "resourceLinks". 
   - CRITICAL: Use ONLY canonical, permanent URLs from top-tier educational sites like GeeksForGeeks, W3Schools, MDN Web Docs, freeCodeCamp, or official documentation.
   - AVOID ephemeral search results, tutorial blogs that might move, or indirect links.
   - PREFER URLs that you are 100% certain exist and are correctly formatted (e.g., https://www.geeksforgeeks.org/arrays-in-java/).
   - Ensure these links directly cover the topic in question.

Return the result STRICTLY as a JSON object with this exact structure:
{
  "estimatedHours": <integer total hours>,
  "syllabus": [
    {
      "topic": "<topic name, e.g. Arrays, Recursion, etc.>",
      "description": "<short description of what to learn in this topic>",
      "hours": <integer estimated hours for this specific topic>,
      "resourceLinks": ["<url1>", "<url2>"]
    }
  ]
}
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text;
      if (text == null) throw Exception('No response from AI');

      // The response should be pure JSON due to responseMimeType
      final result = jsonDecode(text) as Map<String, dynamic>;
      if (result.containsKey('error')) {
        throw Exception(result['error']);
      }
      return result;
    } catch (e) {
      print('AI Service Error generating syllabus: $e');
      rethrow;
    }
  }

  /// Generates a dynamic quiz for a specific topic based on the user's progress.
  /// Returns a List of Maps containing the question, options, and correctAnswer.
  Future<List<Map<String, dynamic>>> generateQuiz(
    String skillName,
    String topic,
    int currentHoursLearned,
    int totalEstimatedHours,
    List<String> resourceLinks,
  ) async {
    if (Env.geminiApiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      throw Exception('Please set your Gemini API key in lib/env.dart');
    }

    // Determine difficulty based on ratio of current hours to total hours
    double progressRatio = totalEstimatedHours > 0 ? (currentHoursLearned / totalEstimatedHours) : 0;
    String difficultyContext = "Beginner (Easy)";
    if (progressRatio > 0.3 && progressRatio <= 0.7) {
      difficultyContext = "Intermediate (Medium)";
    } else if (progressRatio > 0.7) {
      difficultyContext = "Advanced (Hard)";
    }
    
    String resourcesContext = resourceLinks.isNotEmpty 
        ? "The user presumably studied from these resources: \n" + resourceLinks.join('\n') + "\nIncorporate or adapt concepts specifically covered in these links."
        : "";

    final prompt = '''
You are an expert examiner in "$skillName". The user has recently studied the topic "$topic".
They have spent $currentHoursLearned hours out of $totalEstimatedHours total learning this skill.
$resourcesContext

STRICT QUIZ REQUIREMENTS:
1. Generate a short 5-question quiz at a $difficultyContext difficulty level about the topic "$topic".
2. If resources are provided above, you MUST strictly base the quiz questions, terminology, and concepts on the content typically found in those specific resource links.
3. If "$skillName" or "$topic" is related to programming, include relevant code snippets in the questions or options that align with the provided study materials.
4. Ensure the questions are unambiguous and the "answer" field matches one of the "options" exactly.

Return the result STRICTLY as a JSON array with this exact structure:
[
  {
    "question": "<The question text>",
    "options": ["<Option A>", "<Option B>", "<Option C>", "<Option D>"],
    "answer": "<The exact text of the correct option>"
  }
]
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text;
      if (text == null) throw Exception('No response from AI');

      final resultList = jsonDecode(text) as List<dynamic>;
      List<Map<String, dynamic>> quizQuestions = [];
      for (var item in resultList) {
        if (item is Map<String, dynamic>) {
          quizQuestions.add(item);
        }
      }
      return quizQuestions;
    } catch (e) {
      print('AI Service Error generating quiz: $e');
      rethrow;
    }
  }
}
