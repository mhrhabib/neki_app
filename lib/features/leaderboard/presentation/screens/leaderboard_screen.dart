import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/set_up_di.dart';
import '../../../../components/app_background_widget.dart';
import '../cubit/leaderboard_cubit.dart';
import '../../domain/entities/leaderboard_entry_entity.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LeaderboardCubit>()..load(),
      child: const _LeaderboardView(),
    );
  }
}

class _LeaderboardView extends StatefulWidget {
  const _LeaderboardView();

  @override
  State<_LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends State<_LeaderboardView> {
  String _activeTab = 'global';

  Color _getRankColor(int rank) {
    if (rank == 1) return const Color(0xFFD4AF37);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return const Color(0xFF6B7280);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          appBackgroundWidget(),
          BlocBuilder<LeaderboardCubit, LeaderboardState>(
            builder: (context, state) {
              return CustomScrollView(
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
                                'Top performers of all time',
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
                  if (state is LeaderboardLoading)
                    SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    )
                  else if (state is LeaderboardError)
                    SliverFillRemaining(
                      child: _buildError(context, state.message),
                    )
                  else if (state is LeaderboardLoaded)
                    _buildContent(state)
                  else
                    SliverFillRemaining(child: const SizedBox()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent(LeaderboardLoaded state) {
    if (_activeTab == 'country') {
      return SliverFillRemaining(child: _buildCountryComingSoon());
    }

    final entries = state.globalEntries;
    if (entries.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Text(
            'No data yet. Be the first!',
            style: TextStyle(color: Colors.white54, fontSize: 16.sp),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 100.h),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildTopPerformerCard(entries.first, state.currentUserId),
          SizedBox(height: 25.h),
          // Current user's rank card if not in top list
          if (state.currentUserRank != null &&
              !entries.any((e) => e.userId == state.currentUserId))
            _buildMyRankBanner(state.currentUserRank!),
          if (entries.length > 1) ...[
            _buildLeaderboardHeader(),
            SizedBox(height: 15.h),
            ...entries
                .sublist(1)
                .map((e) => _buildUserCard(e, state.currentUserId)),
          ],
        ]),
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

  Widget _buildTopPerformerCard(LeaderboardEntryEntity user, String currentUserId) {
    final isYou = user.userId == currentUserId;
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
                child: user.photoUrl != null
                    ? ClipOval(
                        child: Image.network(
                          user.photoUrl!,
                          width: 60.w,
                          height: 60.w,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              Text('👑', style: TextStyle(fontSize: 45.sp)),
                        ),
                      )
                    : Text('👑', style: TextStyle(fontSize: 45.sp)),
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
                  child: Icon(Icons.emoji_events, size: 16.sp, color: Colors.black),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                user.userName,
                style: TextStyle(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              if (isYou) ...[
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
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
                  _formatPoints(user.totalPoints),
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'NEKI POINTS',
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

  Widget _buildUserCard(LeaderboardEntryEntity user, String currentUserId) {
    final isYou = user.userId == currentUserId;
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isYou
            ? AppColors.primaryGreen.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isYou
              ? AppColors.primaryGreen.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.08),
          width: isYou ? 2.w : 1.w,
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
                      color: _getRankColor(user.rank).withValues(alpha: 0.3))
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
          // Avatar
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.08),
            ),
            child: user.photoUrl != null
                ? ClipOval(
                    child: Image.network(
                      user.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Center(
                        child: Text(
                          user.userName.isNotEmpty
                              ? user.userName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      user.userName.isNotEmpty
                          ? user.userName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Row(
              children: [
                Text(
                  user.userName,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (isYou) ...[
                  SizedBox(width: 6.w),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
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
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatPoints(user.totalPoints),
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

  Widget _buildMyRankBanner(LeaderboardEntryEntity entry) {
    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Text(
              'Your rank',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            _formatPoints(entry.totalPoints),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            ' pts',
            style: TextStyle(fontSize: 11.sp, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildCountryComingSoon() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🌍', style: TextStyle(fontSize: 60.sp)),
            SizedBox(height: 20.h),
            Text(
              'Country Rankings',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'Coming soon! Country-based rankings will appear here once we collect enough data.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white54,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, color: Colors.white38, size: 48.sp),
            SizedBox(height: 16.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 14.sp),
            ),
            SizedBox(height: 24.h),
            TextButton(
              onPressed: () => context.read<LeaderboardCubit>().load(),
              child: Text(
                'Try again',
                style: TextStyle(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w700,
                  fontSize: 15.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPoints(int points) {
    return points.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}
