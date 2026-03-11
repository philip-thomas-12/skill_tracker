import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/skill_service.dart';
import '../services/ai_service.dart';

class AddSkillPage extends StatefulWidget {
  const AddSkillPage({super.key});

  @override
  State<AddSkillPage> createState() => _AddSkillPageState();
}

class _AddSkillPageState extends State<AddSkillPage> {
  final _nameController = TextEditingController();

  String _selectedCategory = 'Development';
  String _selectedDifficulty = 'Beginner';
  int _hoursPerDay = 2; // Default hours per day
  
  bool _isLoading = false;

  final List<String> _categories = [
    'Development',
    'Design',
    'Business',
    'Marketing',
    'Soft Skills',
    'Languages',
    'Other'
  ];

  final List<String> _difficultyLevels = [
    'Beginner',
    'Intermediate',
    'Advanced'
  ];

  final SkillService _skillService = SkillService();
  final AiService _aiService = AiService();

  Future<void> _saveSkill() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar("Please enter a skill name", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    _showSnackBar("AI is generating your custom syllabus...", const Color(0xFF2ECC71));

    try {
      final aiResult = await _aiService.generateSyllabusAndEstimate(
        _nameController.text.trim(),
        _selectedDifficulty,
        _hoursPerDay,
      );

      final estimatedHours = aiResult['estimatedHours'] as int;
      final syllabusList = aiResult['syllabus'] as List<dynamic>;
      
      int derivedTargetLevel = _selectedDifficulty == 'Advanced' ? 10 : (_selectedDifficulty == 'Intermediate' ? 6 : 3);

      await _skillService.addSkill(
        name: _nameController.text.trim(),
        category: _selectedCategory,
        difficulty: _selectedDifficulty,
        targetLevel: derivedTargetLevel,
        targetHours: estimatedHours,
        hoursPerDay: _hoursPerDay,
        syllabus: syllabusList,
      );

      if (mounted) {
        _showSnackBar("Skill added successfully!", Colors.green);
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Error: ${e.toString()}", Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1014),
      appBar: AppBar(
        title: Text(
          "Add New Skill",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with illustration
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF2ECC71).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_chart,
                  color: Color(0xFF2ECC71),
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Skill Name Field
            _buildTextField(
              label: "Skill Name",
              controller: _nameController,
              icon: Icons.psychology,
              hint: "e.g., Flutter, Python, UI Design",
            ),
            const SizedBox(height: 20),

            // Category Dropdown
            _buildDropdown(
              label: "Category",
              value: _selectedCategory,
              items: _categories,
              icon: Icons.category,
              onChanged: (val) {
                setState(() => _selectedCategory = val!);
              },
            ),
            const SizedBox(height: 20),

            // Difficulty Dropdown
            _buildDropdown(
              label: "Difficulty Level",
              value: _selectedDifficulty,
              items: _difficultyLevels,
              icon: Icons.trending_up,
              onChanged: (val) {
                setState(() => _selectedDifficulty = val!);
              },
            ),
            const SizedBox(height: 20),
            
            // Hours per day Slider
            _buildHoursPerDaySlider(),
            const SizedBox(height: 30),

            // Save Button
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF2ECC71),
                    ),
                  )
                : Column(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2ECC71),
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _saveSkill,
                        child: const Text(
                          "Save Skill",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1E24),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white10),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white24),
              prefixIcon: Icon(icon, color: const Color(0xFF2ECC71), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1E24),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF2ECC71), size: 20),
              const SizedBox(width: 15),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1C1E24),
                    style: const TextStyle(color: Colors.white),
                    icon: const Icon(Icons.arrow_drop_down,
                        color: Colors.white54),
                    items: items.map((e) {
                      return DropdownMenuItem(
                        value: e,
                        child: Text(
                          e,
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: onChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }



  Widget _buildHoursPerDaySlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Hours per day",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF3498DB).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF3498DB).withOpacity(0.3)),
              ),
              child: Text(
                "$_hoursPerDay hrs",
                style: const TextStyle(
                  color: Color(0xFF3498DB),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1E24),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white10),
          ),
          child: Slider(
            value: _hoursPerDay.toDouble(),
            min: 1,
            max: 12,
            divisions: 11,
            activeColor: const Color(0xFF3498DB),
            inactiveColor: Colors.white10,
            onChanged: (value) {
              setState(() {
                _hoursPerDay = value.round();
              });
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}