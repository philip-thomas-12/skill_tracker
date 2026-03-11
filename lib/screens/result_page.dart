import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ResultPage extends StatefulWidget {
  final String skillName;
  final int score;
  final int totalQuestions;
  final List<Map<String, dynamic>> results; // Detailed results from quiz

  const ResultPage({
    super.key,
    required this.skillName,
    required this.score,
    required this.totalQuestions,
    required this.results,
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (widget.score / widget.totalQuestions) * 100;
    final isPassed = percentage >= 60;
    final grade = _getGrade(percentage);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1014),
      appBar: AppBar(
        title: Text(
          "Quiz Results",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Score Card
              ScaleTransition(
                scale: _scaleAnimation,
                child: _buildScoreCard(percentage, grade, isPassed),
              ),
              
              const SizedBox(height: 25),
              
              // Stats Row
              _buildStatsRow(),
              
              const SizedBox(height: 25),
              
              // Feedback Message
              _buildFeedbackMessage(isPassed, percentage),
              
              const SizedBox(height: 20),
              
              // Toggle Details Button
              _buildToggleButton(),
              
              // Detailed Results
              if (_showDetails) _buildDetailedResults(),
              
              const SizedBox(height: 20),
              
              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(double percentage, String grade, bool isPassed) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPassed
              ? [const Color(0xFF2ECC71).withOpacity(0.3), const Color(0xFF1C1E24)]
              : [Colors.orange.withOpacity(0.3), const Color(0xFF1C1E24)],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isPassed ? const Color(0xFF2ECC71) : Colors.orange,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            widget.skillName,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 150,
                width: 150,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 12,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isPassed ? const Color(0xFF2ECC71) : Colors.orange,
                  ),
                ),
              ),
              Column(
                children: [
                  Text(
                    "${percentage.toStringAsFixed(1)}%",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    grade,
                    style: GoogleFonts.poppins(
                      color: isPassed ? const Color(0xFF2ECC71) : Colors.orange,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildScoreChip(
                "${widget.score} Correct",
                const Color(0xFF2ECC71),
              ),
              const SizedBox(width: 10),
              _buildScoreChip(
                "${widget.totalQuestions - widget.score} Incorrect",
                Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard(
          icon: Icons.quiz,
          value: "${widget.totalQuestions}",
          label: "Questions",
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: Icons.timer,
          value: "${(widget.totalQuestions * 0.5).toInt()} min",
          label: "Avg. Time",
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: Icons.emoji_events,
          value: _getRank(),
          label: "Rank",
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1E24),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF2ECC71), size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackMessage(bool isPassed, double percentage) {
    String message;
    Color color;

    if (percentage >= 90) {
      message = "Excellent! You're a ${widget.skillName} master! 🎉";
      color = const Color(0xFF2ECC71);
    } else if (percentage >= 70) {
      message = "Great job! You know your ${widget.skillName} well! 👍";
      color = const Color(0xFF2ECC71);
    } else if (percentage >= 60) {
      message = "Good effort! Keep practicing to improve! 💪";
      color = Colors.orange;
    } else if (percentage >= 40) {
      message = "You're getting there! More practice needed. 📚";
      color = Colors.orange;
    } else {
      message = "Don't give up! Review the material and try again. 🎯";
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            percentage >= 60 ? Icons.emoji_events : Icons.trending_up,
            color: color,
            size: 30,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton() {
    return TextButton(
      onPressed: () {
        setState(() {
          _showDetails = !_showDetails;
        });
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _showDetails ? "Hide Details" : "Show Details",
            style: const TextStyle(
              color: Color(0xFF2ECC71),
              fontSize: 16,
            ),
          ),
          Icon(
            _showDetails ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            color: const Color(0xFF2ECC71),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedResults() {
    return Container(
      margin: const EdgeInsets.only(top: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Question Review",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.results.length,
            itemBuilder: (context, index) {
              final result = widget.results[index];
              final isCorrect = result['isCorrect'] ?? false;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1E24),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isCorrect ? Colors.green : Colors.red,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCorrect ? Colors.green : Colors.red,
                          ),
                          child: Center(
                            child: Icon(
                              isCorrect ? Icons.check : Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Question ${index + 1}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      result['question'] ?? "",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          _buildAnswerRow(
                            "Your answer:",
                            result['userAnswer'] ?? "",
                            !isCorrect,
                          ),
                          const SizedBox(height: 5),
                          _buildAnswerRow(
                            "Correct answer:",
                            result['correctAnswer'] ?? "",
                            true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerRow(String label, String answer, bool isCorrect) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            answer,
            style: TextStyle(
              color: isCorrect ? Colors.green : Colors.red,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Back to Skills"),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              // Retry quiz - pop twice to go back to quiz page
              Navigator.pop(context); // Close results
              Navigator.pop(context); // Go back to quiz? or restart?
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2ECC71),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "Try Again",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  String _getGrade(double percentage) {
    if (percentage >= 90) return 'A';
    if (percentage >= 80) return 'B';
    if (percentage >= 70) return 'C';
    if (percentage >= 60) return 'D';
    return 'F';
  }

  String _getRank() {
    final percentage = (widget.score / widget.totalQuestions) * 100;
    if (percentage >= 90) return 'Expert';
    if (percentage >= 70) return 'Advanced';
    if (percentage >= 50) return 'Intermediate';
    return 'Beginner';
  }
}