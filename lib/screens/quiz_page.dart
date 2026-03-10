import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/gemini_service.dart';
import 'result_page.dart';

class QuizPage extends StatefulWidget {
  final String skillName;
  final String difficulty;

  const QuizPage({
    super.key,
    required this.skillName,
    required this.difficulty,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> questions = [];
  Map<int, String> selectedAnswers = {};
  Map<int, bool> answerSubmitted = {};
  
  bool loading = true;
  bool submitting = false;
  int currentQuestionIndex = 0;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late PageController _pageController;  // PageController declared here

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _pageController = PageController();  // Initialize here
    loadQuiz();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();  // Don't forget to dispose
    super.dispose();
  }

  Future<void> loadQuiz() async {
    setState(() => loading = true);

    try {
      final result = await GeminiService.generateQuiz(
        widget.skillName,
        widget.difficulty,
      );

      if (!mounted) return;

      setState(() {
        questions = result;
        loading = false;
      });
      
      _animationController.forward();
    } catch (e) {
      if (!mounted) return;
      
      setState(() => loading = false);
      
      _showErrorDialog("Failed to load quiz: $e");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1E24),
        title: const Text(
          "Error",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              "OK",
              style: TextStyle(color: Color(0xFF2ECC71)),
            ),
          ),
        ],
      ),
    );
  }

  void _submitAnswer(int index) {
    if (selectedAnswers[index] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select an answer"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      answerSubmitted[index] = true;
    });

    // Show feedback
    final isCorrect = selectedAnswers[index] == questions[index]['answer'];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isCorrect ? "✅ Correct!" : "❌ Incorrect"),
        backgroundColor: isCorrect ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  void submitQuiz() {
    // Check if all questions are answered
    if (selectedAnswers.length < questions.length) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1C1E24),
          title: const Text(
            "Incomplete Quiz",
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            "Please answer all questions before submitting.",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "OK",
                style: TextStyle(color: Color(0xFF2ECC71)),
              ),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => submitting = true);

    // Calculate score
    int score = 0;
    List<Map<String, dynamic>> results = [];

    for (int i = 0; i < questions.length; i++) {
      final isCorrect = selectedAnswers[i] == questions[i]['answer'];
      if (isCorrect) score++;
      
      results.add({
        'question': questions[i]['question'],
        'userAnswer': selectedAnswers[i],
        'correctAnswer': questions[i]['answer'],
        'isCorrect': isCorrect,
        'options': questions[i]['options'],
      });
    }

    // Navigate to results page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultPage(
          skillName: widget.skillName,
          score: score,
          totalQuestions: questions.length,
          results: results,
        ),
      ),
    );
  }

  void _showHintDialog(String hint) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1E24),
        title: const Text(
          "Hint",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          hint,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Got it",
              style: TextStyle(color: Color(0xFF2ECC71)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1014),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${widget.skillName} Quiz",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            Text(
              widget.difficulty,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!loading && questions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "${selectedAnswers.length}/${questions.length}",
                style: const TextStyle(
                  color: Color(0xFF2ECC71),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: loading
          ? _buildLoadingState()
          : questions.isEmpty
              ? _buildEmptyState()
              : _buildQuizContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF2ECC71),
          ),
          const SizedBox(height: 20),
          Text(
            "Generating quiz questions...",
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Using AI to create questions for ${widget.skillName}",
            style: GoogleFonts.poppins(
              color: Colors.white38,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz_outlined,
            size: 80,
            color: Colors.white24,
          ),
          const SizedBox(height: 20),
          Text(
            "No questions available",
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Try again later",
            style: GoogleFonts.poppins(
              color: Colors.white38,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: loadQuiz,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2ECC71),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "Retry",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (currentQuestionIndex + 1) / questions.length,
            backgroundColor: Colors.white10,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2ECC71)),
          ),
          
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                return _buildQuestionCard(index);
              },
              onPageChanged: (index) {
                setState(() {
                  currentQuestionIndex = index;
                });
              },
            ),
          ),
          
          // Navigation buttons
          _buildNavigation(),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int index) {
    final q = questions[index];
    final isAnswered = selectedAnswers[index] != null;
    final isSubmitted = answerSubmitted[index] ?? false;
    final isCorrect = isSubmitted && selectedAnswers[index] == q['answer'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Question number
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1E24),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSubmitted
                    ? (isCorrect ? Colors.green : Colors.red)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Question ${index + 1}/${questions.length}",
                      style: const TextStyle(
                        color: Color(0xFF2ECC71),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isSubmitted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isCorrect ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isCorrect ? "Correct!" : "Incorrect",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  q['question'],
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Options
          ...List.generate(q['options'].length, (i) {
            final option = q['options'][i];
            final isSelected = selectedAnswers[index] == option;
            final isCorrectOption = isSubmitted && option == q['answer'];
            final isWrongSelection = isSubmitted && isSelected && option != q['answer'];

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isSubmitted ? null : () {
                    setState(() {
                      selectedAnswers[index] = option;
                    });
                  },
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSubmitted
                          ? (isCorrectOption
                              ? Colors.green.withOpacity(0.2)
                              : isWrongSelection
                                  ? Colors.red.withOpacity(0.2)
                                  : const Color(0xFF1C1E24))
                          : (isSelected
                              ? const Color(0xFF2ECC71).withOpacity(0.2)
                              : const Color(0xFF1C1E24)),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: isSubmitted
                            ? (isCorrectOption
                                ? Colors.green
                                : isWrongSelection
                                    ? Colors.red
                                    : Colors.transparent)
                            : (isSelected
                                ? const Color(0xFF2ECC71)
                                : Colors.transparent),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSubmitted
                                ? (isCorrectOption
                                    ? Colors.green
                                    : isWrongSelection
                                        ? Colors.red
                                        : Colors.white10)
                                : (isSelected
                                    ? const Color(0xFF2ECC71)
                                    : Colors.white10),
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + i),
                              style: TextStyle(
                                color: isSubmitted
                                    ? (isCorrectOption || isWrongSelection
                                        ? Colors.white
                                        : Colors.white70)
                                    : (isSelected
                                        ? Colors.black
                                        : Colors.white70),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              color: isSubmitted
                                  ? (isCorrectOption
                                      ? Colors.green
                                      : isWrongSelection
                                          ? Colors.red
                                          : Colors.white70)
                                  : (isSelected
                                      ? const Color(0xFF2ECC71)
                                      : Colors.white70),
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (isSubmitted && isCorrectOption)
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                        if (isSubmitted && isWrongSelection)
                          const Icon(
                            Icons.cancel,
                            color: Colors.red,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          
          const SizedBox(height: 20),
          
          // Submit button for this question
          if (!isSubmitted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _submitAnswer(index),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ECC71),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  "Submit Answer",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          
          // Hint button (if available)
          if (q['hint'] != null && !isSubmitted)
            TextButton.icon(
              onPressed: () => _showHintDialog(q['hint']),
              icon: const Icon(Icons.lightbulb_outline, color: Colors.amber),
              label: const Text(
                "Need a hint?",
                style: TextStyle(color: Colors.amber),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E24),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          // Previous button
          if (currentQuestionIndex > 0)
            Expanded(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    currentQuestionIndex--;
                  });
                  _pageController.animateToPage(
                    currentQuestionIndex,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: const BorderSide(color: Colors.white24),
                ),
                child: const Text(
                  "Previous",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
          
          if (currentQuestionIndex > 0) const SizedBox(width: 10),
          
          // Next/Submit button
          Expanded(
            child: ElevatedButton(
              onPressed: currentQuestionIndex == questions.length - 1
                  ? (submitting ? null : submitQuiz)
                  : () {
                      // Check if current question is answered
                      if (selectedAnswers[currentQuestionIndex] == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please select an answer first"),
                            backgroundColor: Colors.orange,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      
                      // Check if answer is submitted
                      if (answerSubmitted[currentQuestionIndex] != true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please submit your answer first"),
                            backgroundColor: Colors.orange,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      
                      // Move to next question
                      setState(() {
                        currentQuestionIndex++;
                      });
                      
                      _pageController.animateToPage(
                        currentQuestionIndex,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: currentQuestionIndex == questions.length - 1
                    ? Colors.orange
                    : const Color(0xFF2ECC71),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : Text(
                      currentQuestionIndex == questions.length - 1
                          ? "Submit Quiz"
                          : "Next Question",
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}