import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.child});

  final Widget child;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const List<String> _routes = ['/home', '/leaderboard', '/profile'];
  bool _isBottomNavVisible = true;

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _routes.indexOf(location);
    return index >= 0 ? index : 0;
  }

  void _onItemTapped(int index) {
    if (_getCurrentIndex(context) != index) {
      context.go(_routes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);

    return Scaffold(
      extendBody: true,
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.direction == ScrollDirection.reverse) {
            if (_isBottomNavVisible) {
              setState(() => _isBottomNavVisible = false);
            }
          } else if (notification.direction == ScrollDirection.forward) {
            if (!_isBottomNavVisible) {
              setState(() => _isBottomNavVisible = true);
            }
          }
          return false;
        },
        child: Stack(
          children: [
            widget.child,
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedSlide(
                offset: _isBottomNavVisible
                    ? Offset.zero
                    : const Offset(0, 1.5),
                duration: const Duration(milliseconds: 300),
                child: SafeArea(child: _buildBottomNav(currentIndex)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(int currentIndex) {
    return Container(
      height: 64.h,
      margin: EdgeInsets.symmetric(
        horizontal: 40.w,
        vertical: 8.h,
      ).copyWith(bottom: 20.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1A3D26),
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            icon: CupertinoIcons.house_fill,
            isActive: currentIndex == 0,
            onTap: () => _onItemTapped(0),
          ),
          _buildNavItem(
            icon: CupertinoIcons.chart_bar_fill,
            isActive: currentIndex == 1,
            onTap: () => _onItemTapped(1),
          ),
          _buildNavItem(
            icon: CupertinoIcons.person_fill,
            isActive: currentIndex == 2,
            onTap: () => _onItemTapped(2),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF4ADE80).withValues(alpha: 0.15)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? const Color(0xFF4ADE80) : Colors.white38,
          size: 22.sp,
        ),
      ),
    );
  }
}
