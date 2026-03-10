import 'package:flutter/material.dart';
import 'package:skill_tracker/screens/user/user_pathways_screen.dart';
import 'package:skill_tracker/screens/user/search_screen.dart'; // Import
import 'package:skill_tracker/services/auth_service.dart';
import 'package:skill_tracker/screens/user/profile_screen.dart'; // Import
import '../auth/login_page.dart';

class UserMainLayout extends StatefulWidget {
  const UserMainLayout({super.key});

  @override
  State<UserMainLayout> createState() => _UserMainLayoutState();
}

class _UserMainLayoutState extends State<UserMainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const UserPathwaysScreen(), // Home
    const SearchScreen(), // UPDATED
    const Center(child: Text("My Skills Placeholder")),
    const ProfileScreen(), 
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'My Skills',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
