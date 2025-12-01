import 'package:flutter/material.dart';
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
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: const Color(0xFFE5E7EB), width: 1.w),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _getCurrentIndex(context),
          onTap: _onItemTapped,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primaryGreen,
          unselectedItemColor: const Color(0xFF6B7280),
          selectedLabelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_outlined),
              activeIcon: Icon(Icons.emoji_events),
              label: 'Leaderboard',
            ),
          ],
        ),
      ),
    );
  }
}
