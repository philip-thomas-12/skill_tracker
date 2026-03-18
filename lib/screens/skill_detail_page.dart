import 'dart:io';
import 'dart:async';
import 'package:dio/dio.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/skill_service.dart';
import '../env.dart';
import '../widgets/camera_dialog.dart';
import 'quiz_page.dart';
import 'package:slide_to_act/slide_to_act.dart';

class SkillDetailPage extends StatefulWidget {
  final String skillId;
  final String skillName;
  final String category;
  final String difficulty;

  const SkillDetailPage({
    super.key,
    required this.skillId,
    required this.skillName,
    required this.category,
    required this.difficulty,
  });

  @override
  State<SkillDetailPage> createState() => _SkillDetailPageState();
}

class _SkillDetailPageState extends State<SkillDetailPage> {
  final SkillService _skillService = SkillService();
  final _noteController = TextEditingController();
  bool _isLogging = false;

  // Practice time options in minutes
  final List<int> _practiceTimes = [15, 30, 45, 60, 90, 120];
  int _selectedMinutes = 30;
  String? _selectedTopic;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1014),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1014),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.skillName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white70),
            onPressed: _showEditDialog,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _showDeleteDialog,
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _skillService.getSkill(widget.skillId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2ECC71)));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Skill not found',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final skillData = snapshot.data!.data() as Map<String, dynamic>;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress Card
                _buildProgressCard(skillData),
                const SizedBox(height: 20),
                
                // Stats Row
                _buildStatsRow(skillData),
                const SizedBox(height: 25),
                
                // Syllabus Section
                _buildSyllabusSection(skillData),
                const SizedBox(height: 25),
                
                // Practice Logs Header
                const Text(
                  "Practice History",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                
                // Practice Logs List
                _buildPracticeLogs(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressCard(Map<String, dynamic> skillData) {
    double progress = (skillData['progress'] ?? 0.0).toDouble();
    int currentLevel = skillData['currentLevel'] ?? 1;
    int targetLevel = skillData['targetLevel'] ?? 5;
    int totalMinutes = skillData['totalMinutes'] ?? 0;
    
    // Calculate next level progress
    int minutesForNextLevel = (currentLevel * 60) - totalMinutes;
    if (minutesForNextLevel < 0) minutesForNextLevel = 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2ECC71).withOpacity(0.2),
            const Color(0xFF1C1E24),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2ECC71).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.skillName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${widget.category} • ${widget.difficulty}",
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2ECC71).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  "$currentLevel/$targetLevel",
                  style: const TextStyle(
                    color: Color(0xFF2ECC71),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Progress Bar
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Progress: ${(progress * 100).toInt()}%",
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              if (currentLevel < targetLevel)
                Text(
                  "$minutesForNextLevel min to level ${currentLevel + 1}",
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(Map<String, dynamic> skillData) {
    int totalMinutes = skillData['totalMinutes'] ?? 0;
    int totalHours = (totalMinutes / 60).floor();
    int remainingMinutes = totalMinutes % 60;
    
    return Row(
      children: [
        _buildStatCard(
          icon: Icons.timer,
          value: totalHours > 0 ? "${totalHours}h ${remainingMinutes}m" : "${totalMinutes}m",
          label: "Total Time",
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: Icons.trending_up,
          value: "${((skillData['progress'] ?? 0.0) * 100).toStringAsFixed(1)}%",
          label: "Progress",
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: Icons.emoji_events,
          value: "${skillData['currentLevel'] ?? 1}",
          label: "Current Level",
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1E24),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF2ECC71), size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPracticeLogs() {
    return StreamBuilder<QuerySnapshot>(
      stream: _skillService.getPracticeLogs(widget.skillId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF2ECC71)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1E24),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Icon(Icons.history, color: Colors.white24, size: 40),
                const SizedBox(height: 10),
                const Text(
                  "No practice logs yet",
                  style: TextStyle(color: Colors.white38),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Start logging your practice sessions!",
                  style: TextStyle(color: Colors.white24, fontSize: 12),
                ),
              ],
            ),
          );
        }

        final logs = snapshot.data!.docs;
        
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index].data() as Map<String, dynamic>;
            final date = (log['date'] as Timestamp).toDate();
            final minutes = log['minutes'] ?? 0;
            final notes = log['notes'] ?? '';
            
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1E24),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2ECC71).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "$minutes",
                      style: const TextStyle(
                        color: Color(0xFF2ECC71),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${minutes} minutes of practice",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (notes.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            notes,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    DateFormat('MMM d, HH:mm').format(date),
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTopicDropdown(Map<String, dynamic> skillData) {
    List<dynamic> syllabus = skillData['syllabus'] ?? [];
    if (syllabus.isEmpty) return const SizedBox.shrink();

    List<String> topics = syllabus.map((e) => e['topic'] as String).toList();
    if (_selectedTopic != null && !topics.contains(_selectedTopic)) {
      _selectedTopic = null; // reset if syllabus changes
    }
    
    // Auto-select first if none selected
    if (_selectedTopic == null && topics.isNotEmpty) {
      _selectedTopic = topics.first;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTopic,
          isExpanded: true,
          hint: const Text("Select topic studied", style: TextStyle(color: Colors.white38)),
          dropdownColor: const Color(0xFF1C1E24),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
          items: topics.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedTopic = newValue;
            });
          },
        ),
      ),
    );
  }

  Widget _buildSyllabusSection(Map<String, dynamic> skillData) {
    List<dynamic> syllabus = skillData['syllabus'] ?? [];
    if (syllabus.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "AI-Generated Syllabus",
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
          itemCount: syllabus.length,
          itemBuilder: (context, index) {
            final topic = syllabus[index];
            return _SyllabusItemWidget(
              topic: topic,
              skillData: skillData,
              skillId: widget.skillId,
              skillName: widget.skillName,
              onQuizTap: () => _launchQuizForTopic(skillData, topic['topic'] ?? ''),
            );
          },
        ),
      ],
    );
  }

  void _launchQuizForTopic(Map<String, dynamic> skillData, String topicName) {
    if (topicName.isEmpty) return;
    
    List<dynamic> syllabus = skillData['syllabus'] ?? [];
    Map<String, dynamic>? selectedTopicData;
    try {
      selectedTopicData = syllabus.firstWhere((t) => t['topic'] == topicName) as Map<String, dynamic>;
    } catch (_) {}
    
    // Fallback topic target hours to 10 if not found
    int targetTopicHours = 10;
    if (selectedTopicData != null && selectedTopicData['hours'] != null) {
      targetTopicHours = (selectedTopicData['hours'] is int) 
          ? selectedTopicData['hours'] 
          : int.tryParse(selectedTopicData['hours'].toString()) ?? 10;
    }
    
    // Minutes completed explicitly for this topic
    Map<String, dynamic> topicProgress = skillData['topicProgress'] ?? {};
    int minCompleted = topicProgress[topicName] ?? 0;
    
    // Get user-defined hoursPerDay to grant upon passing test
    int hoursPerDay = skillData['hoursPerDay'] ?? 2;
    // We pass minites into QuizPage so it correctly logs "hoursPerDay * 60" min upon passing
    int potentialMinutesToGain = hoursPerDay * 60;
    
    List<String> links = [];
    if (selectedTopicData != null && selectedTopicData['resourceLinks'] != null) {
      links = (selectedTopicData['resourceLinks'] as List).map((e) => e.toString()).toList();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Launching Quiz for $topicName..."),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizPage(
          skillId: widget.skillId,
          skillName: widget.skillName,
          topic: topicName,
          currentHours: minCompleted ~/ 60,
          totalHours: targetTopicHours,
          practiceMinutes: potentialMinutesToGain,
          practiceNote: "Passed Quiz: $topicName",
          resourceLinks: links,
        ),
      ),
    );
  }

  void _showEditDialog() {
    final nameController = TextEditingController(text: widget.skillName);
    String selectedCategory = widget.category;
    String selectedDifficulty = widget.difficulty;
    int targetLevel = 5; // You might want to fetch this from skill data

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1E24),
        title: const Text(
          "Edit Skill",
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Skill Name",
                  labelStyle: const TextStyle(color: Colors.white38),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF2ECC71)),
                  ),
                ),
              ),
              // Add more fields as needed
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () async {
              // Implement update logic
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2ECC71),
            ),
            child: const Text("Save", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1E24),
        title: const Text(
          "Delete Skill",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Are you sure you want to delete this skill? All practice history will be lost.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () async {
              await _skillService.deleteSkill(widget.skillId);
              if (mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to skill list
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}

// ============== NEW SYLLABUS ITEM WIDGET ==============

class _SyllabusItemWidget extends StatefulWidget {
  final Map<String, dynamic> topic;
  final Map<String, dynamic> skillData;
  final String skillId;
  final String skillName;
  final VoidCallback onQuizTap;

  const _SyllabusItemWidget({
    required this.topic,
    required this.skillData,
    required this.skillId,
    required this.skillName,
    required this.onQuizTap,
  });

  @override
  State<_SyllabusItemWidget> createState() => _SyllabusItemWidgetState();
}

class _SyllabusItemWidgetState extends State<_SyllabusItemWidget> {
  bool _isExpanded = false;
  bool _isUploading = false;
  final SkillService _skillService = SkillService();

  Future<void> _handleFileUpload(bool fromCamera) async {
    
    Uint8List? fileBytes;
    String? originalFileName;
    String fileType = 'document';

    if (fromCamera) {
      final cameraResult = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => const CameraDialog(),
      );

      if (cameraResult != null) {
        fileBytes = cameraResult['bytes'] as Uint8List;
        originalFileName = cameraResult['name'] as String;
        
        // Sanitize
        originalFileName = originalFileName.replaceAll(RegExp(r'[^a-zA-Z0-9.]'), '_');

        // Ensure camera photo has an extension for Cloudinary
        if (!originalFileName.contains('.')) {
          originalFileName += '.jpg';
        }
        fileType = 'image';
      }
    } else {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg'],
        withData: true, // Need bytes for web compatibility
      );
      if (result != null && result.files.isNotEmpty) {
        fileBytes = result.files.first.bytes;
        originalFileName = result.files.first.name;

        // SANITIZE FILENAME: Remove spaces and special characters for Cloudinary compatibility
        originalFileName = originalFileName.replaceAll(RegExp(r'[^a-zA-Z0-9.]'), '_');
        if (originalFileName.length > 50) {
          final ext = p.extension(originalFileName);
          originalFileName = originalFileName.substring(0, 40) + ext;
        }

        final ext = p.extension(originalFileName).toLowerCase();
        if (ext == '.png' || ext == '.jpg' || ext == '.jpeg') {
          fileType = 'image';
        }
      }
    }

    if (fileBytes == null || originalFileName == null) return;

    // Ask for custom name AFTER the picture is taken/selected
    final nameController = TextEditingController();
    if (mounted) {
      final customName = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1C1E24),
          title: const Text("Name your note", style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "E.g., Lecture 1 Notes",
              hintStyle: TextStyle(color: Colors.white38),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF2ECC71))),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.white38)),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  Navigator.pop(context, nameController.text.trim());
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2ECC71)),
              child: const Text("Upload", style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );

      if (customName == null || customName.isEmpty) return;
      
      setState(() => _isUploading = true);

      try {
        final user = FirebaseAuth.instance.currentUser;
        print("Starting Cloudinary upload process for user: ${user?.uid ?? 'NULL'}");
        if (user == null) {
          throw Exception("You must be logged in to upload notes.");
        }

        // Initialize Cloudinary
        final cloudinary = CloudinaryPublic(
          Env.cloudinaryCloudName,
          Env.cloudinaryUploadPreset,
          cache: false,
        );

        // FORCE Image resource type even for PDFs because Cloudinary serves them 
        // with better preview headers in the 'image' category.
        CloudinaryResourceType resourceType = CloudinaryResourceType.Image;
        
        // Add a unique prefix to filename to avoid collisions and cache issues
        final uniqueId = DateTime.now().millisecondsSinceEpoch;
        final sanitizedName = originalFileName.replaceAll(RegExp(r'[^a-zA-Z0-9.]'), '_');
        final uploadId = "note_${uniqueId}_$sanitizedName";

        print("Uploading to Cloudinary... Cloud: ${Env.cloudinaryCloudName}, Preset: ${Env.cloudinaryUploadPreset}, ID: $uploadId");
        
        CloudinaryResponse response = await cloudinary.uploadFile(
          CloudinaryFile.fromBytesData(
            fileBytes,
            identifier: uploadId,
            resourceType: resourceType,
          ),
        );

        final downloadUrl = response.secureUrl;
        final publicId = response.publicId;
        print("Got Cloudinary URL: $downloadUrl");

        print("Writing metadata to Firestore...");
        await _skillService.uploadTopicNote(
          skillId: widget.skillId,
          topicName: widget.topic['topic'] ?? '',
          customName: customName,
          downloadUrl: downloadUrl,
          storagePath: publicId, // Using Cloudinary publicId as storagePath
          fileType: fileType,
        );
        print("Upload flow fully complete!");

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Note uploaded successfully to Cloudinary!"), backgroundColor: Colors.green),
          );
        }
      } catch (e, stacktrace) {
        print("Upload Error: $e");
        if (e is DioException) {
          print("Cloudinary Response Body: ${e.response?.data}");
          print("Cloudinary Status Code: ${e.response?.statusCode}");
        }
        print("Stacktrace: $stacktrace");
        
        if (mounted) {
          String displayError = e.toString();
          if (e is DioException && e.response?.data != null) {
            final data = e.response?.data;
            if (data is Map && data.containsKey('error')) {
              displayError = "Cloudinary Error: ${data['error']['message']}";
            } else {
              displayError = "Cloudinary Error: $data";
            }
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to upload: $displayError"), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _isExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _isExpanded = expanded;
            });
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          collapsedIconColor: Colors.white54,
          iconColor: const Color(0xFF2ECC71),
          title: Text(
            widget.topic['topic'] ?? '',
            style: const TextStyle(
              color: Color(0xFF2ECC71),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              widget.topic['description'] ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              maxLines: _isExpanded ? null : 2,
              overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Divider(color: Colors.white10),
                   const SizedBox(height: 10),
                   
                   // Target Hours & Progress
                   if (widget.topic['hours'] != null) ...[
                      Builder(
                        builder: (context) {
                          Map<String, dynamic> topicProgress = widget.skillData['topicProgress'] ?? {};
                          int minCompleted = topicProgress[widget.topic['topic']] ?? 0;
                          double hrsCompleted = minCompleted / 60;
                          
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "Target: ${widget.topic['hours']} hr${widget.topic['hours'] == 1 ? '' : 's'}",
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                "${hrsCompleted.toStringAsFixed(1)} hrs completed",
                                style: const TextStyle(
                                  color: Color(0xFF2ECC71),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        }
                      ),
                      const SizedBox(height: 15),
                   ],

                   // Links Section
                   if (widget.topic['resourceLinks'] != null && (widget.topic['resourceLinks'] as List).isNotEmpty) ...[
                      const Text("Resources", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: (widget.topic['resourceLinks'] as List).map<Widget>((link) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: InkWell(
                              onTap: () async {
                                final urlString = link.toString();
                                try {
                                  print("Launching Resource URL: $urlString");
                                  if (!await launchUrl(Uri.parse(urlString), mode: LaunchMode.externalApplication)) {
                                    throw Exception('Could not launch $urlString');
                                  }
                                } catch (e) {
                                  print("Could not launch $urlString: $e");
                                }
                              },
                              child: Row(
                                children: [
                                  const Icon(Icons.link, color: Colors.blueAccent, size: 14),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      link.toString(),
                                      style: const TextStyle(
                                        color: Colors.blueAccent,
                                        fontSize: 12,
                                        decoration: TextDecoration.underline,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 15),
                   ],

                   // Notes & Files Section
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       const Text("Your Notes & Files", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                       Row(
                         children: [
                           IconButton(
                             icon: const Icon(Icons.camera_alt, color: Color(0xFF2ECC71), size: 20),
                             onPressed: _isUploading ? null : () => _handleFileUpload(true),
                             tooltip: "Take Photo",
                             constraints: const BoxConstraints(),
                             padding: const EdgeInsets.symmetric(horizontal: 5),
                           ),
                           IconButton(
                             icon: const Icon(Icons.upload_file, color: Color(0xFF2ECC71), size: 20),
                             onPressed: _isUploading ? null : () => _handleFileUpload(false),
                             tooltip: "Upload File",
                             constraints: const BoxConstraints(),
                             padding: const EdgeInsets.symmetric(horizontal: 5),
                           ),
                         ],
                       )
                     ],
                   ),
                   const SizedBox(height: 5),
                   
                   if (_isUploading)
                     const Padding(
                       padding: EdgeInsets.symmetric(vertical: 10),
                       child: Center(child: LinearProgressIndicator(color: Color(0xFF2ECC71), backgroundColor: Colors.white10)),
                     ),

                   // Notes StreamBuilder
                     StreamBuilder<QuerySnapshot>(
                     stream: _skillService.getTopicNotes(widget.skillId, widget.topic['topic'] ?? ''),
                     builder: (context, snapshot) {
                       if (snapshot.connectionState == ConnectionState.waiting) {
                         return const Center(child: Padding(
                           padding: EdgeInsets.all(8.0),
                           child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Color(0xFF2ECC71), strokeWidth: 2)),
                         ));
                       }
                       if (snapshot.hasError) {
                         print("StreamBuilder notes error: ${snapshot.error}");
                         return Center(child: Padding(
                           padding: const EdgeInsets.symmetric(vertical: 10),
                           child: Text("Error loading notes: ${snapshot.error}", style: const TextStyle(color: Colors.red, fontSize: 12)),
                         ));
                       }
                       if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                         return const Padding(
                           padding: EdgeInsets.symmetric(vertical: 10),
                           child: Text("No notes uploaded yet. Add some!", style: TextStyle(color: Colors.white38, fontSize: 12)),
                         );
                       }

                       final notes = snapshot.data!.docs.toList();
                       // Manually sort notes by createdAt descending since we removed orderBy
                       notes.sort((a, b) {
                         final aData = a.data() as Map<String, dynamic>;
                         final bData = b.data() as Map<String, dynamic>;
                         final aTime = (aData['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
                         final bTime = (bData['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
                         return bTime.compareTo(aTime);
                       });

                       return Wrap(
                         spacing: 10,
                         runSpacing: 10,
                         children: notes.map((doc) {
                           final data = doc.data() as Map<String, dynamic>;
                           final isImage = data['type'] == 'image';
                           return InkWell(
                              onTap: () async {
                                final urlString = data['url'];
                                try {
                                  print("Launching Note URL: $urlString");
                                  if (!await launchUrl(Uri.parse(urlString), mode: LaunchMode.externalApplication)) {
                                    throw Exception('Could not launch $urlString');
                                  }
                                } catch (e) {
                                  print("Could not launch $urlString: $e");
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Error opening file: $e"), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              },
                             onLongPress: () {
                               // Confirm delete
                               showDialog(
                                 context: context,
                                 builder: (context) => AlertDialog(
                                   backgroundColor: const Color(0xFF1C1E24),
                                   title: const Text("Delete Note?", style: TextStyle(color: Colors.white)),
                                   content: Text("Are you sure you want to delete '${data['name']}'?", style: const TextStyle(color: Colors.white70)),
                                   actions: [
                                     TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                                     TextButton(
                                       onPressed: () {
                                         _skillService.deleteTopicNote(widget.skillId, doc.id, data['path']);
                                         Navigator.pop(context);
                                       }, 
                                       child: const Text("Delete", style: TextStyle(color: Colors.red))
                                     )
                                   ],
                                 )
                               );
                             },
                             child: Container(
                               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                               decoration: BoxDecoration(
                                 color: Colors.white.withOpacity(0.05),
                                 borderRadius: BorderRadius.circular(8),
                                 border: Border.all(color: Colors.white10),
                                ),
                               child: Row(
                                 mainAxisSize: MainAxisSize.min,
                                 children: [
                                   Icon(isImage ? Icons.image : Icons.description, color: Colors.blueAccent, size: 16),
                                   const SizedBox(width: 8),
                                   Text(
                                     data['name'] ?? 'Note', 
                                     style: const TextStyle(color: Colors.white, fontSize: 12),
                                   ),
                                 ],
                               ),
                             ),
                           );
                         }).toList(),
                       );
                     },
                   ),
                   const SizedBox(height: 15),

                   // Take Quiz Swipe Button
                   Padding(
                     padding: const EdgeInsets.only(top: 8.0),
                     child: SlideAction(
                       onSubmit: () {
                         widget.onQuizTap();
                         return null;
                       },
                       borderRadius: 12,
                       elevation: 0,
                       innerColor: Colors.white,
                       outerColor: Colors.orange.withOpacity(0.8),
                       sliderButtonIcon: const Icon(Icons.quiz, color: Colors.orange),
                       text: "Swipe to take Quiz",
                       textStyle: const TextStyle(
                         color: Colors.white,
                         fontWeight: FontWeight.bold,
                         fontSize: 15,
                       ),
                       sliderRotate: false,
                     ),
                   )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}