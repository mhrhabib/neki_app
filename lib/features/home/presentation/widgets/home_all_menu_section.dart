import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/route_names.dart';

/// Horizontal scrollable "All Menu" section with quick-access icon buttons
/// that navigate to major features of the app.
class HomeAllMenuSection extends StatelessWidget {
  const HomeAllMenuSection({super.key});

  static const List<Map<String, dynamic>> _menuItems = [
    {'title': 'Habit Tracker', 'icon': '📋', 'route': RouteNames.habitBuilding},
    {'title': 'Dallu Dua', 'icon': '🤲', 'route': RouteNames.salah},
    {'title': 'Quran', 'icon': '📖', 'route': RouteNames.quran},
    {'title': 'Tasbeeh', 'icon': '📿', 'route': RouteNames.dhikir},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionHeader(),
        SizedBox(height: 14.h),
        _MenuItemList(menuItems: _menuItems),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'All Menu',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Text(
              'See More',
              style: TextStyle(
                color: const Color(0xFF4ADE80),
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItemList extends StatelessWidget {
  final List<Map<String, dynamic>> menuItems;

  const _MenuItemList({required this.menuItems});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          final item = menuItems[index];
          return _MenuIconButton(
            title: item['title'] as String,
            icon: item['icon'] as String,
            route: item['route'] as String,
          );
        },
      ),
    );
  }
}

class _MenuIconButton extends StatelessWidget {
  final String title;
  final String icon;
  final String route;

  const _MenuIconButton({
    required this.title,
    required this.icon,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        width: 72.w,
        margin: EdgeInsets.only(right: 12.w),
        child: Column(
          children: [
            Container(
              width: 56.w,
              height: 56.w,
              decoration: BoxDecoration(
                color: const Color(0xFF1A3D26),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Center(
                child: Text(icon, style: TextStyle(fontSize: 26.sp)),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              title,
              style: TextStyle(color: Colors.white70, fontSize: 10.sp),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
