import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/skill_model.dart';
import '../../widgets/custom_input_field.dart';

class LogSessionDialog extends StatefulWidget {
  final Skill skill;
  final DatabaseService dbService;

  const LogSessionDialog({
    super.key,
    required this.skill,
    required this.dbService,
  });

  @override
  State<LogSessionDialog> createState() => _LogSessionDialogState();
}

class _LogSessionDialogState extends State<LogSessionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  Future<void> _saveSession() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final duration = double.tryParse(_durationController.text) ?? 0.0;
        await widget.dbService.logSession(
          widget.skill.id,
          duration,
          _notesController.text.trim(),
        );
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        // Handle error
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Log: ${widget.skill.name}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomInputField(
                label: 'Duration (Hours)',
                controller: _durationController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.timer,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (double.tryParse(val) == null) return 'Must be a number';
                  return null;
                },
              ),
              CustomInputField(
                label: 'Notes (Optional)',
                controller: _notesController,
                maxLines: 3,
                prefixIcon: Icons.note,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveSession,
          child: const Text('Log'),
        ),
      ],
    );
  }
}
