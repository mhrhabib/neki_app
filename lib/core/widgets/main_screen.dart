import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.child});

  final Widget child;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const List<String> _routes = ['/home', '/profile', '/leaderboard'];

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _routes.indexOf(location);
    return index >= 0 ? index : 0;
  }

  void _onItemTapped(int index) {
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: widget.child,
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            decoration: BoxDecoration(
              color: (isDark ? const Color(0xFF1C1C1E) : Colors.white).withValues(alpha: 0.8),
              border: Border(
                top: BorderSide(color: isDark ? const Color(0xFF38383A) : const Color(0xFFC6C6C8), width: 0.5),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _getCurrentIndex(context),
              onTap: _onItemTapped,
              backgroundColor: Colors.transparent,
              selectedItemColor: isDark ? AppColors.goldAccent : AppColors.primaryGreen,
              unselectedItemColor: isDark ? const Color(0xFF8E8E93) : const Color(0xFF999999),
              selectedLabelStyle: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w500),
              unselectedLabelStyle: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w500),
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.house),
                  activeIcon: Icon(CupertinoIcons.house_fill),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.person),
                  activeIcon: Icon(CupertinoIcons.person_fill),
                  label: 'Profile',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.graph_square),
                  activeIcon: Icon(CupertinoIcons.graph_square_fill),
                  label: 'Leaderboard',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
