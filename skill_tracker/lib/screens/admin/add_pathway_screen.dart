import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/pathway_model.dart';

class AddPathwayScreen extends StatefulWidget {
  const AddPathwayScreen({super.key});

  @override
  State<AddPathwayScreen> createState() => _AddPathwayScreenState();
}

class _AddPathwayScreenState extends State<AddPathwayScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  // List to hold materials as they are added
  List<LearningMaterial> _materials = [];

  void _addMaterial() {
    showDialog(
      context: context,
      builder: (context) {
        String type = 'video';
        TextEditingController titleCtrl = TextEditingController();
        TextEditingController urlCtrl = TextEditingController();
        TextEditingController contentCtrl = TextEditingController();

        return AlertDialog(
          title: const Text("Add Learning Material"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: type,
                  items: ['video', 'article', 'quiz', 'coding_challenge']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase())))
                      .toList(),
                  onChanged: (val) => type = val!,
                  decoration: const InputDecoration(labelText: "Type"),
                ),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Title")),
                TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: "URL (Optional)")),
                TextField(controller: contentCtrl, decoration: const InputDecoration(labelText: "Content/Description (Optional)"), maxLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.isNotEmpty) {
                  setState(() {
                    _materials.add(LearningMaterial(
                      type: type,
                      title: titleCtrl.text,
                      url: urlCtrl.text,
                      content: contentCtrl.text,
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void _savePathway() async {
    if (_formKey.currentState!.validate()) {
      if (_materials.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Add at least one material")));
        return;
      }

      try {
        final collection = FirebaseFirestore.instance.collection('pathways');
        // Create a new pathway object, ID will be generated
        // We'll trust Firestore to generate ID
        DocumentReference ref = await collection.add({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'materials': _materials.map((m) => m.toMap()).toList(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pathway Created!")));
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Pathway")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Pathway Title", border: OutlineInputBorder()),
              validator: (val) => val!.isEmpty ? "Required" : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder()),
              maxLines: 3,
              validator: (val) => val!.isEmpty ? "Required" : null,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Materials", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(onPressed: _addMaterial, icon: const Icon(Icons.add_circle, color: Colors.blue)),
              ],
            ),
            ..._materials.map((m) => Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: Icon(
                  m.type == 'video' ? Icons.play_circle : 
                  m.type == 'article' ? Icons.article : Icons.code,
                ),
                title: Text(m.title),
                subtitle: Text(m.type),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _materials.remove(m);
                    });
                  },
                ),
              ),
            )),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _savePathway,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text("Save Pathway"),
            ),
          ],
        ),
      ),
    );
  }
}
