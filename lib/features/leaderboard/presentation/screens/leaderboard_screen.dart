import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../components/app_background_widget.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _activeTab = 'global';

  final Map<String, List<LeaderboardUser>> _leaderboardData = {
    'global': [
      LeaderboardUser(
        rank: 1,
        name: 'Abdullah',
        country: '🇸🇦',
        points: 12500,
      ),
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
      LeaderboardUser(
        rank: 2,
        name: 'Habib',
        country: '🇧🇩',
        points: 4582,
        isYou: true,
      ),
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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          appBackgroundWidget(),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 180.h,
                pinned: true,
                stretch: true,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.blurBackground,
                    StretchMode.zoomBackground,
                  ],
                  background: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 20.h),
                          Text(
                            'Leaderboard',
                            style: TextStyle(
                              fontSize: 32.sp,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Top performers of this week',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          _buildTabSwitcher(),
                          SizedBox(height: 20.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 100.h),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (data.isNotEmpty) ...[
                      _buildTopPerformerCard(data[0]),
                      SizedBox(height: 25.h),
                      _buildLeaderboardHeader(),
                      SizedBox(height: 15.h),
                    ],
                    ...data.sublist(1).map((user) => _buildUserCard(user)),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      height: 48.h,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          _buildTabButton('Global', 'global'),
          _buildTabButton('Country', 'country'),
        ],
      ),
    );
  }

  Widget _buildLeaderboardHeader() {
    return Row(
      children: [
        Container(
          width: 4.w,
          height: 18.h,
          decoration: BoxDecoration(
            color: AppColors.goldAccent,
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        SizedBox(width: 10.w),
        Text(
          'RANKINGS',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w900,
            color: AppColors.goldAccent,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(String label, String tab) {
    final isActive = _activeTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4.r,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              color: isActive ? Colors.white : Colors.white38,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopPerformerCard(LeaderboardUser user) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20.r,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100.w,
                height: 100.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.goldAccent.withValues(alpha: 0.3),
                      AppColors.goldAccent.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.goldAccent.withValues(alpha: 0.3),
                    width: 2.w,
                  ),
                ),
                child: Text('👑', style: TextStyle(fontSize: 45.sp)),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.goldAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 3.w),
                  ),
                  child: Icon(
                    Icons.emoji_events,
                    size: 16.sp,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Text(
            user.name,
            style: TextStyle(
              fontSize: 26.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(user.country, style: TextStyle(fontSize: 18.sp)),
              SizedBox(width: 8.w),
              Text(
                'TOP RECOVERER',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w900,
                  color: AppColors.goldAccent,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 15.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                Text(
                  user.points.toString().replaceAllMapped(
                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                    (Match m) => '${m[1]},',
                  ),
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'RECOVERY POINTS',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white38,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(LeaderboardUser user) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: user.isYou
            ? AppColors.primaryGreen.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: user.isYou
              ? AppColors.primaryGreen.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.08),
          width: user.isYou ? 2.w : 1.w,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 45.w,
            height: 45.w,
            decoration: BoxDecoration(
              color: user.rank <= 3
                  ? _getRankColor(user.rank).withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(15.r),
              border: user.rank <= 3
                  ? Border.all(
                      color: _getRankColor(user.rank).withValues(alpha: 0.3),
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '${user.rank}',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w900,
                color: _getRankColor(user.rank),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.name,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (user.isYou) ...[
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          'YOU',
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Text(user.country, style: TextStyle(fontSize: 14.sp)),
                    SizedBox(width: 6.w),
                    Text(
                      'Recoverer',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white38,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                user.points.toString().replaceAllMapped(
                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                  (Match m) => '${m[1]},',
                ),
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                'pts',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.white30,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
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
