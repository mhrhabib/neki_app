// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../points/presentation/cubit/points_cubit.dart';
import '../cubit/dhikir_cubit.dart';

class DhikirScreen extends StatefulWidget {
  const DhikirScreen({super.key});

  @override
  State<DhikirScreen> createState() => _DhikirScreenState();
}

class _DhikirScreenState extends State<DhikirScreen> with TickerProviderStateMixin {
  late AnimationController _counterAnimationController;
  late Animation<double> _counterAnimation;
  late AnimationController _completionAnimationController;
  late Animation<double> _completionAnimation;

  String? _selectedDhikir;
  int _targetCount = 33; // Default target

  @override
  void initState() {
    super.initState();
    _counterAnimationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _counterAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _counterAnimationController, curve: Curves.elasticOut));

    _completionAnimationController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _completionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _completionAnimationController, curve: Curves.easeOut));

    // Load current session if exists
    final authState = context.read<AuthCubit>().state;
    final userId = authState is Authenticated ? authState.user.id : null;
    if (userId != null) {
      context.read<DhikirCubit>().loadCurrentSession(userId);
    }
  }

  @override
  void dispose() {
    _counterAnimationController.dispose();
    _completionAnimationController.dispose();
    super.dispose();
  }

  void _onCounterTap(String userId, String sessionId) {
    _counterAnimationController.forward().then((_) {
      _counterAnimationController.reverse();
    });
    context.read<DhikirCubit>().incrementCount(userId, sessionId);
  }

  void _startNewSession(String userId) {
    if (_selectedDhikir != null) {
      context.read<DhikirCubit>().startDhikirSession(
        userId: userId,
        dhikirText: _selectedDhikir!,
        targetCount: _targetCount,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dhikir Counter',
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryGreen),
      ),
      body: BlocConsumer<DhikirCubit, DhikirState>(
        listener: (context, state) {
          if (state is DhikirSessionCompleted) {
            _completionAnimationController.forward();
            // Refresh points
            final authState = context.read<AuthCubit>().state;
            if (authState is Authenticated) {
              context.read<PointsCubit>().loadUserPoints(authState.user.id);
            }
            // Show completion dialog
            Future.delayed(const Duration(milliseconds: 500), () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    '🎉 Dhikir Completed!',
                    style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                  ),
                  content: Text(
                    'You earned ${state.pointsEarned} points for completing "${state.dhikirText}"!',
                    style: TextStyle(fontSize: 16.sp),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Continue',
                        style: TextStyle(color: AppColors.primaryGreen, fontSize: 16.sp),
                      ),
                    ),
                  ],
                ),
              );
            });
          }
        },
        builder: (context, state) {
          final authState = context.watch<AuthCubit>().state;
          final userId = authState is Authenticated ? authState.user.id : null;

          if (userId == null) {
            return const Center(child: Text('Please login to use Dhikir counter'));
          }

          if (state is DhikirLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is DhikirSessionActive) {
            return _buildActiveSessionView(
              userId,
              state.sessionId,
              state.dhikirText,
              state.targetCount,
              state.currentCount,
              state.pointsEarned,
              state.isCompleted,
            );
          } else if (state is DhikirSessionCompleted) {
            return _buildCompletionView(state.dhikirText, state.pointsEarned);
          } else if (state is DhikirHistoryLoaded) {
            return _buildHistoryView(state.sessions);
          } else if (state is DhikirError) {
            return _buildErrorView(state.message, userId);
          } else {
            return _buildInitialView(userId);
          }
        },
      ),
    );
  }

  Widget _buildInitialView(String userId) {
    final suggestions = context.read<DhikirCubit>().getDhikirSuggestions();

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 40.h),
          Icon(Icons.mosque, size: 80.w, color: AppColors.primaryGreen),
          SizedBox(height: 24.h),
          Text(
            'Dhikir Counter',
            style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
          ),
          SizedBox(height: 16.h),
          Text(
            'Choose a dhikir and set your target',
            style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32.h),

          // Dhikir Selection
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: DropdownButton<String>(
              value: _selectedDhikir,
              hint: Text('Select Dhikir', style: TextStyle(fontSize: 16.sp)),
              isExpanded: true,
              underline: const SizedBox(),
              items: suggestions.map((dhikir) {
                return DropdownMenuItem<String>(
                  value: dhikir,
                  child: Text(
                    dhikir,
                    style: TextStyle(fontSize: 16.sp),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDhikir = value;
                });
              },
            ),
          ),

          SizedBox(height: 24.h),

          // Target Count Slider
          Text(
            'Target Count: $_targetCount',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: AppColors.primaryGreen),
          ),
          SizedBox(height: 16.h),
          Slider(
            value: _targetCount.toDouble(),
            min: 10,
            max: 100,
            divisions: 9,
            activeColor: AppColors.primaryGreen,
            inactiveColor: AppColors.primaryGreen.withValues(alpha: 0.3),
            onChanged: (value) {
              setState(() {
                _targetCount = value.toInt();
              });
            },
          ),

          SizedBox(height: 40.h),

          // Start Button
          ElevatedButton(
            onPressed: _selectedDhikir != null ? () => _startNewSession(userId) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              padding: EdgeInsets.symmetric(horizontal: 48.w, vertical: 16.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            ),
            child: Text(
              'Start Dhikir Session',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),

          const Spacer(),

          // History Button
          TextButton.icon(
            onPressed: () => context.read<DhikirCubit>().loadDhikirHistory(userId),
            icon: Icon(Icons.history, size: 20.w),
            label: Text('View History', style: TextStyle(fontSize: 16.sp)),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSessionView(
    String userId,
    String sessionId,
    String dhikirText,
    int targetCount,
    int currentCount,
    int pointsEarned,
    bool isCompleted,
  ) {
    final progress = currentCount / targetCount;

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          SizedBox(height: 40.h),

          // Dhikir Text
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3), width: 2.w),
            ),
            child: Text(
              dhikirText,
              style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: 40.h),

          // Animated Counter
          GestureDetector(
            onTap: isCompleted ? null : () => _onCounterTap(userId, sessionId),
            child: AnimatedBuilder(
              animation: _counterAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _counterAnimation.value,
                  child: Container(
                    width: 200.w,
                    height: 200.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.primaryGreen, AppColors.primaryGreen.withValues(alpha: 0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGreen.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$currentCount',
                          style: TextStyle(fontSize: 48.sp, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          '/ $targetCount',
                          style: TextStyle(fontSize: 20.sp, color: Colors.white.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 32.h),

          // Progress Bar
          Container(
            height: 8.h,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4.r)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.circular(4.r)),
              ),
            ),
          ),

          SizedBox(height: 16.h),

          // Progress Text
          Text(
            '${(progress * 100).toInt()}% Complete',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: AppColors.primaryGreen),
          ),

          SizedBox(height: 16.h),

          // Points Earned
          if (pointsEarned > 0)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.goldAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                'Points Earned: $pointsEarned',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.goldAccent),
              ),
            ),

          const Spacer(),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => context.read<DhikirCubit>().completeSession(sessionId),
                icon: Icon(Icons.check, size: 20.w),
                label: Text('Complete', style: TextStyle(fontSize: 16.sp)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => context.read<DhikirCubit>().deleteSession(sessionId),
                icon: Icon(Icons.delete, size: 20.w),
                label: Text('Delete', style: TextStyle(fontSize: 16.sp)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionView(String dhikirText, int pointsEarned) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _completionAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _completionAnimation.value,
                child: Icon(Icons.celebration, size: 120.w, color: AppColors.primaryGreen),
              );
            },
          ),
          SizedBox(height: 32.h),
          Text(
            'Dhikir Completed!',
            style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
          ),
          SizedBox(height: 16.h),
          Text(
            '"$dhikirText"',
            style: TextStyle(fontSize: 20.sp, fontStyle: FontStyle.italic, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: AppColors.goldAccent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Text(
              '+$pointsEarned Points Earned!',
              style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: AppColors.goldAccent),
            ),
          ),
          SizedBox(height: 40.h),
          ElevatedButton(
            onPressed: () {
              final authState = context.read<AuthCubit>().state;
              final userId = authState is Authenticated ? authState.user.id : '';
              context.read<DhikirCubit>().loadDhikirHistory(userId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
            ),
            child: Text(
              'View History',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryView(List<Map<String, dynamic>> sessions) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  final authState = context.read<AuthCubit>().state;
                  final userId = authState is Authenticated ? authState.user.id : '';
                  context.read<DhikirCubit>().loadCurrentSession(userId);
                },
                icon: Icon(Icons.arrow_back, size: 24.w),
              ),
              SizedBox(width: 16.w),
              Text(
                'Dhikir History',
                style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: sessions.isEmpty
                ? Center(
                    child: Text(
                      'No dhikir sessions yet',
                      style: TextStyle(fontSize: 18.sp, color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 12.h),
                        child: ListTile(
                          title: Text(
                            session['dhikirText'],
                            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${session['currentCount']}/${session['targetCount']} • ${session['pointsEarned']} points',
                            style: TextStyle(fontSize: 14.sp),
                          ),
                          trailing: Icon(
                            session['isCompleted'] ? Icons.check_circle : Icons.pending,
                            color: session['isCompleted'] ? AppColors.primaryGreen : Colors.orange,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String message, String userId) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.w, color: Colors.red),
            SizedBox(height: 16.h),
            Text(
              'Error',
              style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () => context.read<DhikirCubit>().loadCurrentSession(userId),
              child: Text('Retry', style: TextStyle(fontSize: 16.sp)),
            ),
          ],
        ),
      ),
    );
  }
}
