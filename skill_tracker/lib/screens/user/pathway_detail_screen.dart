import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/pathway_model.dart';
import '../../models/user_progress_model.dart';
import '../../services/progress_service.dart';

class PathwayDetailScreen extends StatefulWidget {
  final Pathway pathway;

  const PathwayDetailScreen({super.key, required this.pathway});

  @override
  State<PathwayDetailScreen> createState() => _PathwayDetailScreenState();
}

class _PathwayDetailScreenState extends State<PathwayDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String _userId = FirebaseAuth.instance.currentUser!.uid;
  Timer? _timer;
  int _secondsSpent = 0;
  List<String> _completedItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _startTimer();
    _loadProgress();
  }

  void _loadProgress() {
    ProgressService().getProgressStream(_userId, widget.pathway.id).listen((progress) {
      if (mounted) {
        setState(() {
          if (progress != null) {
            _completedItems = progress.completedSyllabusItems;
          }
          _isLoading = false;
        });
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsSpent++;
        });
      }
    });
  }

  void _saveTimeProgress() async {
    if (_secondsSpent > 0) {
      try {
        final docRef = FirebaseFirestore.instance.collection('usage_logs').doc();
        await docRef.set({
          'userId': _userId,
          'pathwayId': widget.pathway.id,
          'pathwayTitle': widget.pathway.title,
          'secondsSpent': _secondsSpent,
          'timestamp': FieldValue.serverTimestamp(),
        });
        print("Progress saved: $_secondsSpent seconds");
      } catch (e) {
        print("Error saving progress: $e");
      }
    }
  }

  void _toggleSyllabusItem(String title, bool? value) {
    if (value == true) {
      _completedItems.add(title);
    } else {
      _completedItems.remove(title);
    }
    // Optimistic update
    setState(() {});
    
    // Save to Firestore
    ProgressService().updateProgress(_userId, widget.pathway.id, _completedItems);
  }

  @override
  void dispose() {
    _saveTimeProgress();
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Could not launch $url")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressPercent = widget.pathway.syllabus.isNotEmpty 
        ? _completedItems.length / widget.pathway.syllabus.length 
        : 0.0;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(widget.pathway.title, style: const TextStyle(color: Colors.white, fontSize: 16)),
                background: Container(
                  color: Colors.blue.shade800,
                  child: Center(
                    child: Icon(Icons.code, size: 80, color: Colors.white.withOpacity(0.5)),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.pathway.description, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: progressPercent,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    const SizedBox(height: 4),
                    Text("${(progressPercent * 100).toInt()}% Completed", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Theme.of(context).primaryColor,
                  tabs: const [
                    Tab(text: "Syllabus"),
                    Tab(text: "Materials"),
                    Tab(text: "Roadmap"),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Syllabus Tab
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.pathway.syllabus.length,
              itemBuilder: (context, index) {
                final item = widget.pathway.syllabus[index];
                final isCompleted = _completedItems.contains(item.title);
                return CheckboxListTile(
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    item.title,
                    style: TextStyle(
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      color: isCompleted ? Colors.grey : Colors.black,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.description.isNotEmpty) Text(item.description),
                      if (item.materialUrl != null && item.materialUrl!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: InkWell(
                            onTap: () => _launchURL(item.materialUrl!),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.description, size: 16, color: Theme.of(context).primaryColor),
                                const SizedBox(width: 4),
                                Text(
                                  "View ${item.materialType?.toUpperCase() ?? 'Material'}",
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  value: isCompleted,
                  onChanged: (val) => _toggleSyllabusItem(item.title, val),
                );
              },
            ),

            // Materials Tab
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.pathway.materials.length,
              itemBuilder: (context, index) {
                final material = widget.pathway.materials[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      material.type == 'pdf' ? Icons.picture_as_pdf :
                      material.type == 'video' ? Icons.play_circle : Icons.link,
                      color: Colors.blue,
                    ),
                    title: Text(material.title),
                    subtitle: Text(material.type.toUpperCase()),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => _launchURL(material.url),
                  ),
                );
              },
            ),

            // Roadmap Tab (Visual Timeline)
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.pathway.syllabus.length,
              itemBuilder: (context, index) {
                final item = widget.pathway.syllabus[index];
                final isCompleted = _completedItems.contains(item.title);
                final isLast = index == widget.pathway.syllabus.length - 1;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Column(
                       children: [
                         Container(
                           width: 24, height: 24,
                           decoration: BoxDecoration(
                             color: isCompleted ? Colors.green : Colors.grey[300],
                             shape: BoxShape.circle,
                           ),
                           child: isCompleted ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                         ),
                         if (!isLast)
                           Container(
                             width: 2,
                             height: 50,
                             color: isCompleted ? Colors.green : Colors.grey[300],
                           ),
                       ],
                     ),
                     const SizedBox(width: 16),
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                           if (item.description.isNotEmpty)
                             Text(item.description, style: TextStyle(color: Colors.grey[600])),
                           if (item.materialUrl != null && item.materialUrl!.isNotEmpty)
                             Padding(
                               padding: const EdgeInsets.only(top: 8),
                               child: OutlinedButton.icon(
                                 onPressed: () => _launchURL(item.materialUrl!),
                                 icon: const Icon(Icons.open_in_new, size: 16),
                                 label: Text("View ${item.materialType?.toUpperCase() ?? 'Material'}"),
                                 style: OutlinedButton.styleFrom(
                                   visualDensity: VisualDensity.compact,
                                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                 ),
                               ),
                             ),
                           const SizedBox(height: 32),
                         ],
                       ),
                     ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
