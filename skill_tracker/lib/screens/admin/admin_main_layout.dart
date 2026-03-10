import 'package:flutter/material.dart';
import 'package:skill_tracker/screens/admin/admin_dashboard.dart';
import 'package:skill_tracker/screens/admin/analytics_dashboard.dart';
import '../auth/login_page.dart';

class AdminMainLayout extends StatefulWidget {
  const AdminMainLayout({super.key});

  @override
  State<AdminMainLayout> createState() => _AdminMainLayoutState();
}

class _AdminMainLayoutState extends State<AdminMainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AdminDashboard(), // Manage Skills
    const Center(child: Text("Uploads Placeholder")),
    const Center(child: Text("Users List Placeholder")),
    const AnalyticsDashboard(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
               // Assuming AuthService is accessible or imported, but we can do it directly or import it
               // For now, let's just use the Navigator for valid context usage
               Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()), // Will need import if not there, but LoginPage is usually imported
                  (route) => false,
               );
            },
          )
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt),
            label: 'Skills',
          ),
          NavigationDestination(
            icon: Icon(Icons.upload_file),
            label: 'Uploads',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }
}
