import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditSkillPage extends StatefulWidget {
  final String docId;
  final String name;
  final String category;
  final int level;

  const EditSkillPage({
    super.key,
    required this.docId,
    required this.name,
    required this.category,
    required this.level,
  });

  @override
  State<EditSkillPage> createState() => _EditSkillPageState();
}

class _EditSkillPageState extends State<EditSkillPage> {
  late TextEditingController nameController;
  late TextEditingController categoryController;
  late TextEditingController levelController;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.name);
    categoryController = TextEditingController(text: widget.category);
    levelController = TextEditingController(text: widget.level.toString());
  }

  Future<void> updateSkill() async {
    await FirebaseFirestore.instance
        .collection('skills')
        .doc(widget.docId)
        .update({
      'name': nameController.text.trim(),
      'category': categoryController.text.trim(),
      'level': int.parse(levelController.text),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Skill")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Skill Name"),
            ),

            TextField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: "Category"),
            ),

            TextField(
              controller: levelController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Level (1–10)"),
            ),

            const SizedBox(height: 25),

            ElevatedButton(
              onPressed: updateSkill,
              child: const Text("Update Skill"),
            )
          ],
        ),
      ),
    );
  }
}
