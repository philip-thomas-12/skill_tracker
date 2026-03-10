import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/pathway_model.dart';
import 'pathway_detail_screen.dart';

class UserPathwaysScreen extends StatefulWidget {
  const UserPathwaysScreen({super.key});

  @override
  State<UserPathwaysScreen> createState() => _UserPathwaysScreenState();
}

class _UserPathwaysScreenState extends State<UserPathwaysScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  final List<String> _categories = ['All', 'Programming', 'Design', 'Data Science', 'Marketing', 'Business'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Discover Skills"),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: "Search skills...",
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),

          // Categories Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (selected) => setState(() => _selectedCategory = cat),
                    backgroundColor: Colors.white,
                    selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.black,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 16),

          // Skills Grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('pathways').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final docs = snapshot.data?.docs ?? [];
                
                // Filter locally
                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  final category = data['category'] ?? 'General';
                  
                  final matchesSearch = title.contains(_searchQuery);
                  final matchesCategory = _selectedCategory == 'All' || category == _selectedCategory;
                  
                  return matchesSearch && matchesCategory;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text("No skills found matching your criteria."));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8, // Taller cards
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final data = filteredDocs[index].data() as Map<String, dynamic>;
                    final pathway = Pathway.fromMap(data, filteredDocs[index].id);
                    
                    return InkWell(
                      onTap: () {
                         Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => PathwayDetailScreen(pathway: pathway)),
                        );
                      },
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              ),
                              child: Center(
                                child: Text(
                                  pathway.title[0],
                                  style: TextStyle(fontSize: 40, color: Theme.of(context).primaryColor),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pathway.category.toUpperCase(),
                                    style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    pathway.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getDifficultyColor(pathway.difficulty).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      pathway.difficulty,
                                      style: TextStyle(fontSize: 10, color: _getDifficultyColor(pathway.difficulty), fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner': return Colors.green;
      case 'intermediate': return Colors.orange;
      case 'advanced': return Colors.red;
      default: return Colors.blue;
    }
  }
}
