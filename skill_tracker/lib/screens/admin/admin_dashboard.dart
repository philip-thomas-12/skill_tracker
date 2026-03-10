import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/pathway_model.dart';
import '../../services/auth_service.dart';
import '../auth/login_page.dart';
import 'manage_skill_screen.dart'; // UPDATED Import

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('pathways').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No skills found. Start by adding one!"));
          }
          
          final pathways = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pathways.length,
            itemBuilder: (context, index) {
              final data = pathways[index].data() as Map<String, dynamic>;
              final pathway = Pathway.fromMap(data, pathways[index].id);
              
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(pathway.title[0]),
                  ),
                  title: Text(pathway.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${pathway.category} • ${pathway.difficulty}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                           Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ManageSkillScreen(pathway: pathway)),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                           // Confirm delete
                           bool? confirm = await showDialog(
                             context: context, 
                             builder: (c) => AlertDialog(
                                title: const Text("Delete Skill?"),
                                content: const Text("This action cannot be undone."),
                                actions: [
                                  TextButton(onPressed: ()=>Navigator.pop(c, false), child: const Text("Cancel")),
                                  TextButton(onPressed: ()=>Navigator.pop(c, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
                                ],
                             )
                           );
                           if (confirm == true) {
                             await FirebaseFirestore.instance.collection('pathways').doc(pathway.id).delete();
                           }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ManageSkillScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("Add New Skill"),
      ),
    );
  }
}
