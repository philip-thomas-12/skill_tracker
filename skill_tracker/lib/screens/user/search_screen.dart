import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/pathway_model.dart';
import 'pathway_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Search skills, topics...",
            border: InputBorder.none,
          ),
          onChanged: (val) => setState(() => _query = val.toLowerCase()),
        ),
      ),
      body: _query.isEmpty 
        ? const Center(child: Text("Type to search...")) 
        : StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('pathways').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              
              final results = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final title = (data['title'] ?? '').toString().toLowerCase();
                final desc = (data['description'] ?? '').toString().toLowerCase();
                return title.contains(_query) || desc.contains(_query);
              }).toList();

              if (results.isEmpty) return const Center(child: Text("No results found."));

              return ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                   final data = results[index].data() as Map<String, dynamic>;
                   final pathway = Pathway.fromMap(data, results[index].id);
                   
                   return ListTile(
                     title: Text(pathway.title),
                     subtitle: Text(pathway.category),
                     onTap: () {
                       Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => PathwayDetailScreen(pathway: pathway)),
                        );
                     },
                   );
                },
              );
            },
        ),
    );
  }
}
