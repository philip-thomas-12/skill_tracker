// import 'dart:io'; // Removed for Web compatibility
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'dart:typed_data'; // For Uint8List
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/pathway_model.dart';
import '../../services/storage_service.dart';

class ManageSkillScreen extends StatefulWidget {
  final Pathway? pathway; // If null, we are creating a new skill
  const ManageSkillScreen({super.key, this.pathway});

  @override
  State<ManageSkillScreen> createState() => _ManageSkillScreenState();
}

class _ManageSkillScreenState extends State<ManageSkillScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  String _category = 'Programming';
  String _difficulty = 'Beginner';

  List<SyllabusItem> _syllabus = [];
  List<LearningMaterial> _materials = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.pathway?.title ?? '');
    _descCtrl = TextEditingController(text: widget.pathway?.description ?? '');
    if (widget.pathway != null) {
      _category = widget.pathway!.category;
      _difficulty = widget.pathway!.difficulty;
      _syllabus = List.from(widget.pathway!.syllabus);
      _materials = List.from(widget.pathway!.materials);
    }
  }

  // --- SYLLABUS METHODS ---
  // --- SYLLABUS METHODS ---
  void _addSyllabusItem() {
    TextEditingController titleCtrl = TextEditingController();
    TextEditingController descCtrl = TextEditingController();
    String? materialType; // Start empty or default to 'pdf' if a file is picked
    String? pickedFileName; // pickedFilePath removed
    Uint8List? pickedFileBytes; // For Web and Mobile (withData: true)
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Add Syllabus Topic"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Topic Title")),
                  const SizedBox(height: 8),
                  TextField(controller: descCtrl, decoration: const InputDecoration(labelText: "Description (Optional)")),
                  const SizedBox(height: 16),
                  const Text("Attach Study Material (Optional)", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            FilePickerResult? result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['pdf', 'doc', 'docx'],
                              withData: true,
                            );
                            if (result != null) {
                              setDialogState(() {
                                pickedFileName = result.files.single.name;
                                pickedFileBytes = result.files.single.bytes;
                                
                                // Handling Mobile where bytes might be null if not loaded, though withData: true should load it.
                                // If bytes are null, we can't upload without dart:io File, which breaks web build.
                                // Assuming withData: true works for reasonable file sizes.
                                if (pickedFileBytes == null) {
                                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not load file data. Try a smaller file.")));
                                   return; 
                                }

                                materialType = result.files.single.extension ?? 'pdf';
                              });
                            }
                          },
                          icon: const Icon(Icons.attach_file),
                          label: Text(pickedFileName ?? "Upload PDF/Doc"),
                        ),
                      ),
                      if (pickedFileName != null)
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => setDialogState(() {
                            pickedFileName = null;
// pickedFilePath removed
                            pickedFileBytes = null;
                            materialType = null;
                          }),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  if (titleCtrl.text.isNotEmpty) {
                    String? uploadedUrl;
                    
                    if (pickedFileName != null) {
                       // Show loading (simple way for now is just close and show snackbar or block)
                       // Better: Validation before closing
                       Navigator.pop(ctx); 
                       setState(() => _isLoading = true);
                       
                       try {
                         if (pickedFileBytes != null) {
                           uploadedUrl = await StorageService().uploadBytes(pickedFileBytes!, 'syllabus/${DateTime.now().millisecondsSinceEpoch}_$pickedFileName');
                         }
                       } catch (e) {
                         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
                       }
                       
                       setState(() => _isLoading = false);
                    } else {
                       Navigator.pop(ctx);
                    }

                    setState(() {
                      _syllabus.add(SyllabusItem(
                        title: titleCtrl.text, 
                        description: descCtrl.text,
                        materialUrl: uploadedUrl,
                        materialType: materialType,
                      ));
                    });
                  }
                },
                child: const Text("Add"),
              ),
            ],
          );
        }
      ),
    );
  }

  // --- MATERIAL METHODS ---
  void _addMaterial() {
    String type = 'video';
    TextEditingController titleCtrl = TextEditingController();
    TextEditingController urlCtrl = TextEditingController();
    Uint8List? pickedFileBytes;
    String? pickedFileName;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Add Material"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: type,
                    items: ['video', 'article', 'pdf', 'doc', 'quiz']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase())))
                        .toList(),
                    onChanged: (val) => setDialogState(() => type = val!),
                    decoration: const InputDecoration(labelText: "Type"),
                  ),
                  const SizedBox(height: 8),
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Title")),
                  const SizedBox(height: 8),
                  
                  if (type == 'pdf' || type == 'doc') 
                    Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            FilePickerResult? result = await FilePicker.platform.pickFiles(
                              withData: true, // Important for Web and simpler cross-platform
                            );
                            if (result != null) {
                              setDialogState(() {
                                pickedFileBytes = result.files.single.bytes;
                                pickedFileName = result.files.single.name;
                                // On Mobile, bytes might be null even with withData: true if file is huge, but for typical use it works.
                                // If bytes IS null on mobile, we might need path, but let's try to stick to bytes for compatibility.
                                if (pickedFileBytes == null) {
                                   if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not load file data.")));
                                   return;
                                }
                              });
                            }
                          },
                          icon: const Icon(Icons.attach_file),
                          label: Text(pickedFileName ?? "Choose File"),
                        ),
                        if (pickedFileName != null) Text("Selected: $pickedFileName", style: const TextStyle(fontSize: 12, color: Colors.green)),
                      ],
                    )
                  else
                    TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: "URL")),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  if (titleCtrl.text.isNotEmpty) {
                    Navigator.pop(ctx); // Close dialog first to avoid blocking
                    
                    String finalUrl = urlCtrl.text;
                    
                    if ((type == 'pdf' || type == 'doc') && pickedFileName != null && pickedFileBytes != null) {
                       setState(() => _isLoading = true);
                       // Upload file using bytes
                       String? downloadUrl = await StorageService().uploadBytes(pickedFileBytes!, 'materials/${DateTime.now().millisecondsSinceEpoch}_$pickedFileName');
                       setState(() => _isLoading = false);
                       
                       if (downloadUrl != null) {
                         finalUrl = downloadUrl;
                       } else {
                         if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Upload failed")));
                         return;
                       }
                    }

                    setState(() {
                      _materials.add(LearningMaterial(
                        type: type,
                        title: titleCtrl.text,
                        url: finalUrl,
                        content: '', // Optional description
                      ));
                    });
                  }
                },
                child: const Text("Add"),
              ),
            ],
          );
        }
      ),
    );
  }

  void _saveSkill() async {
    if (!_formKey.currentState!.validate()) return;
    if (_syllabus.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please add at least one syllabus topic")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'title': _titleCtrl.text,
        'description': _descCtrl.text,
        'category': _category,
        'difficulty': _difficulty,
        'syllabus': _syllabus.map((s) => s.toMap()).toList(),
        'materials': _materials.map((m) => m.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.pathway == null) {
        // Create
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('pathways').add(data);
      } else {
        // Update
        await FirebaseFirestore.instance.collection('pathways').doc(widget.pathway!.id).update(data);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Skill Saved Successfully!")));
      }

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.pathway == null ? "New Skill" : "Edit Skill")),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Info Section
            _buildSectionHeader("Basic Info"),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: "Skill Name", hintText: "e.g. Python Developer"),
              validator: (v) => v!.isEmpty ? "Required" : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: "Description"),
              maxLines: 3,
              validator: (v) => v!.isEmpty ? "Required" : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _category,
                    items: ['Programming', 'Design', 'Data Science', 'Marketing', 'Business']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _category = v!),
                    decoration: const InputDecoration(labelText: "Category"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _difficulty,
                    items: ['Beginner', 'Intermediate', 'Advanced']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _difficulty = v!),
                    decoration: const InputDecoration(labelText: "Difficulty"),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            // Syllabus Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader("Syllabus / Roadmap"),
                IconButton(onPressed: _addSyllabusItem, icon: const Icon(Icons.add_circle, color: Colors.blue)),
              ],
            ),
            if (_syllabus.isEmpty) const Text("No topics added yet.", style: TextStyle(color: Colors.grey)),
            ..._syllabus.asMap().entries.map((entry) => Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(child: Text("${entry.key + 1}")),
                title: Text(entry.value.title),
                subtitle: entry.value.description.isNotEmpty ? Text(entry.value.description) : null,
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18), 
                  onPressed: () => setState(() => _syllabus.removeAt(entry.key)),
                ),
              ),
            )),

            const SizedBox(height: 24),
            // Materials Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader("Study Materials"),
                IconButton(onPressed: _addMaterial, icon: const Icon(Icons.upload_file, color: Colors.blue)),
              ],
            ),
             if (_materials.isEmpty) const Text("No materials added yet.", style: TextStyle(color: Colors.grey)),
             ..._materials.asMap().entries.map((entry) => ListTile(
               leading: Icon(
                 entry.value.type == 'pdf' ? Icons.picture_as_pdf :
                 entry.value.type == 'video' ? Icons.play_circle : Icons.link,
               ),
               title: Text(entry.value.title),
               subtitle: Text(entry.value.type.toUpperCase()),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.red), 
                  onPressed: () => setState(() => _materials.removeAt(entry.key)),
                ),
             )),

             const SizedBox(height: 40),
             ElevatedButton(
               onPressed: _saveSkill, 
               child: Text(widget.pathway == null ? "Create Skill" : "Update Skill"),
             ),
             const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }
}
