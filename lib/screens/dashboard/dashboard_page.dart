import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/skill_model.dart';
import '../skills/add_skill_page.dart';
import '../skills/log_session_dialog.dart'; // Will create
import 'skill_list_item.dart';
import '../progress/progress_page.dart'; // Will create

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Access user from Provider or direct from FirebaseAuth since we are inside auth guard
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Not Authenticated")));
    }

    final dbService = DatabaseService(userId: user.uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Skills'),
        actions: [
           IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProgressPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthService>(context, listen: false).signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Skill>>(
        stream: dbService.skills,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final skills = snapshot.data ?? [];

          if (skills.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No skills tracked yet.\nStart by adding one!", textAlign: TextAlign.center),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: skills.length,
            itemBuilder: (context, index) {
              final skill = skills[index];
              return SkillListItem(
                skill: skill,
                onLogSession: () {
                   showDialog(
                    context: context,
                    builder: (_) => LogSessionDialog(skill: skill, dbService: dbService),
                  );
                },
                onDelete: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Skill?'),
                      content: const Text('This action cannot be undone.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await dbService.deleteSkill(skill.id);
                  }
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddSkillPage(dbService: dbService)),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
