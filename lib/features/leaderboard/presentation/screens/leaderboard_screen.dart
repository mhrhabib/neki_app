import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _activeTab = 'global';

  final Map<String, List<LeaderboardUser>> _leaderboardData = {
    'global': [
      LeaderboardUser(rank: 1, name: 'Abdullah', country: '🇸🇦', points: 12500),
      LeaderboardUser(rank: 2, name: 'Hasan', country: '🇧🇩', points: 9420),
      LeaderboardUser(rank: 3, name: 'Umar', country: '🇮🇩', points: 8900),
      LeaderboardUser(rank: 4, name: 'Fatima', country: '🇵🇰', points: 8200),
      LeaderboardUser(rank: 5, name: 'Aisha', country: '🇹🇷', points: 7850),
      LeaderboardUser(rank: 6, name: 'Ali', country: '🇪🇬', points: 7320),
      LeaderboardUser(rank: 7, name: 'Zainab', country: '🇲🇾', points: 6900),
      LeaderboardUser(rank: 8, name: 'Omar', country: '🇦🇪', points: 6450),
    ],
    'country': [
      LeaderboardUser(rank: 1, name: 'Hasan', country: '🇧🇩', points: 9420),
      LeaderboardUser(rank: 2, name: 'Habib', country: '🇧🇩', points: 4582, isYou: true),
      LeaderboardUser(rank: 3, name: 'Karim', country: '🇧🇩', points: 3890),
      LeaderboardUser(rank: 4, name: 'Nadia', country: '🇧🇩', points: 3200),
      LeaderboardUser(rank: 5, name: 'Rashid', country: '🇧🇩', points: 2950),
    ],
  };

  Color _getRankColor(int rank) {
    if (rank == 1) return const Color(0xFFD4AF37); // Gold
    if (rank == 2) return const Color(0xFFC0C0C0); // Silver
    if (rank == 3) return const Color(0xFFCD7F32); // Bronze
    return const Color(0xFF6B7280); // Gray
  }

  @override
  Widget build(BuildContext context) {
    final data = _leaderboardData[_activeTab]!;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  children: [
                    if (data.isNotEmpty) _buildTopPerformerCard(data[0]),
                    SizedBox(height: 20.h),
                    _buildLeaderboardList(data.sublist(1)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Leaderboard',
            style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.w700, color: AppColors.primaryGreen),
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10.r)),
            child: Row(children: [_buildTabButton('Global', 'global'), _buildTabButton('Country', 'country')]),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, String tab) {
    final isActive = _activeTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = tab),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8.r),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: isActive ? AppColors.primaryGreen : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopPerformerCard(LeaderboardUser user) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 0.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen,
            AppColors.primaryGreen.withValues(alpha: 0.9),
            AppColors.darkGreen.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
            spreadRadius: 2.r,
          ),
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.1),
            blurRadius: 40.r,
            offset: Offset(0, 16.h),
            spreadRadius: 4.r,
          ),
        ],
      ),
      child: Column(
        children: [
          // Trophy with glow effect
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: const Color(0xFFD4AF37).withValues(alpha: 0.3), blurRadius: 15.r, spreadRadius: 2.r),
              ],
            ),
            child: Icon(Icons.emoji_events, size: 36.sp, color: const Color(0xFFD4AF37)),
          ),
          SizedBox(height: 12.h),

          // Crown emoji with animation effect
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.w),
            ),
            child: Text('👑', style: TextStyle(fontSize: 40.sp)),
          ),
          SizedBox(height: 16.h),

          // Name with modern typography
          Text(
            user.name,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
              shadows: [Shadow(color: Colors.black.withValues(alpha: 0.3), offset: Offset(0, 2.h), blurRadius: 4.r)],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6.h),

          // Country and title
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.w),
            ),
            child: Text(
              '${user.country} Top Performer',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFD4AF37),
                letterSpacing: 0.3,
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // Points display with modern styling
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10.r, offset: Offset(0, 4.h)),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'TOTAL POINTS',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6B7280),
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  user.points.toString().replaceAllMapped(
                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                    (Match m) => '${m[1]},',
                  ),
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryGreen,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // Decorative elements
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (index) => Container(
                margin: EdgeInsets.symmetric(horizontal: 3.w),
                width: 6.w,
                height: 6.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList(List<LeaderboardUser> users) {
    return Column(children: users.map((user) => _buildUserCard(user)).toList());
  }

  Widget _buildUserCard(LeaderboardUser user) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: user.isYou ? const Color(0xFF0F5132).withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: user.isYou ? AppColors.primaryGreen : const Color(0xFFE5E7EB),
          width: user.isYou ? 2.w : 1.w,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: user.rank <= 3 ? _getRankColor(user.rank).withValues(alpha: 0.2) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(20.r),
            ),
            alignment: Alignment.center,
            child: Text(
              '#${user.rank}',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: _getRankColor(user.rank)),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.name,
                      style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w600, color: const Color(0xFF1F2937)),
                    ),
                    if (user.isYou) ...[
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          'YOU',
                          style: TextStyle(fontSize: 10.sp, color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  '${user.country} ${user.points.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} points',
                  style: TextStyle(fontSize: 13.sp, color: const Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          if (user.rank <= 3) Icon(Icons.military_tech, size: 24.sp, color: _getRankColor(user.rank)),
        ],
      ),
    );
  }
}

class LeaderboardUser {
  const LeaderboardUser({
    required this.rank,
    required this.name,
    required this.country,
    required this.points,
    this.isYou = false,
  });

  final int rank;
  final String name;
  final String country;
  final int points;
  final bool isYou;
}
