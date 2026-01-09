/*
import 'package:flutter/material.dart';

import 'widgets/bottom_nav_bar.dart';
import 'home_screen.dart';
import 'progress_screen.dart';
import 'profile_screen.dart';
import 'all_courses_screen.dart';

// Global key to control bottom nav selection from child screens
final GlobalKey<_NavbarscreenState> navBarKey = GlobalKey<_NavbarscreenState>();

class Navbarscreen extends StatefulWidget {
  const Navbarscreen({super.key});

  @override
  State<Navbarscreen> createState() => _NavbarscreenState();
}

class _NavbarscreenState extends State<Navbarscreen> {
  int _selectedIndex = 0;

  void _onNavTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  // Public method to allow external screens to change tab
  void setIndex(int index) => _onNavTapped(index);

  final List<Widget> _screens = [
    HomeScreen(),
    const ProgressScreen(),
    const AllCoursesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onNavTapped,
      ),
    );
  }
}
*/
import 'package:flutter/material.dart';
import '../services/analytics_helper.dart';
import 'widgets/bottom_nav_bar.dart';
import 'home_screen.dart';
import 'progress_screen.dart';
import 'profile_screen.dart';
import 'all_courses_screen.dart';
import 'compiler_screen.dart';

// Global key to control bottom nav selection from child screens
final GlobalKey<_NavbarscreenState> navBarKey = GlobalKey<_NavbarscreenState>();

class Navbarscreen extends StatefulWidget {
  const Navbarscreen({super.key});

  @override
  State<Navbarscreen> createState() => _NavbarscreenState();
}

class _NavbarscreenState extends State<Navbarscreen> {
  int _selectedIndex = 0;

  /*void _onNavTapped(int index) {
    setState(() => _selectedIndex = index);
  }
*/
  void _onNavTapped(int index) {
    setState(() => _selectedIndex = index);


    if (index == 1) {
      AnalyticsHelper.trackProgressClick();
    }

    if (index == 2) {
      AnalyticsHelper.trackCompilerClick();
    }
  }

  // Public method to allow external screens to change tab
  void setIndex(int index) => _onNavTapped(index);

  // Order as per original logic
  final List<Widget> _screens = [
    HomeScreen(),
    const ProgressScreen(), // Index 1
    const CompilerScreen(), // Index 2 - Center (3rd position)
    const AllCoursesScreen(), // Index 3
    const ProfileScreen(), // Index 4
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onNavTapped,
      ),
    );
  }
}