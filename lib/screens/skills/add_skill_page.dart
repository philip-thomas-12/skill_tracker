import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_input_field.dart';

class AddSkillPage extends StatefulWidget {
  final DatabaseService dbService;

  const AddSkillPage({super.key, required this.dbService});

  @override
  State<AddSkillPage> createState() => _AddSkillPageState();
}

class _AddSkillPageState extends State<AddSkillPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _targetHoursController = TextEditingController();
  bool _isLoading = false;

  Future<void> _saveSkill() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final targetHours = double.tryParse(_targetHoursController.text) ?? 10.0;
        await widget.dbService.addSkill(
          _nameController.text.trim(),
          _categoryController.text.trim(),
          targetHours,
        );
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${e.toString()}")),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Skill')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomInputField(
                label: 'Skill Name',
                controller: _nameController,
                prefixIcon: Icons.fitness_center,
                validator: (val) => val != null && val.isNotEmpty ? null : 'Required',
              ),
              CustomInputField(
                label: 'Category (e.g., Coding, Music)',
                controller: _categoryController,
                prefixIcon: Icons.category,
                validator: (val) => val != null && val.isNotEmpty ? null : 'Required',
              ),
              CustomInputField(
                label: 'Target Hours',
                controller: _targetHoursController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.timer,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (double.tryParse(val) == null) return 'Must be a number';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveSkill,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Add Skill'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
