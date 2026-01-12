import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/roza_cubit.dart';

class RozaScreen extends StatefulWidget {
  const RozaScreen({super.key});

  @override
  State<RozaScreen> createState() => _RozaScreenState();
}

class _RozaScreenState extends State<RozaScreen> {
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  final Set<DateTime> _selectedDates = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      context.read<RozaCubit>().loadMonthlyRozaData(authState.user.id, _focusedDay.year, _focusedDay.month);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Roza Tracker',
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryGreen),
      ),
      body: BlocConsumer<RozaCubit, RozaState>(
        listener: (context, state) {
          if (state is RozaLoaded) {
            // Update selected dates from loaded state
            setState(() {
              _selectedDates.clear();
              _selectedDates.addAll(state.selectedDates);
            });
          }
        },
        builder: (context, state) {
          return _buildContent(state);
        },
      ),
    );
  }

  Widget _buildContent(RozaState state) {
    final authState = context.watch<AuthCubit>().state;
    if (authState is! Authenticated) {
      return const Center(child: Text('Please login to track Roza'));
    }

    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(state),
              SizedBox(height: 20.h),
              _buildCalendar(state),
              SizedBox(height: 20.h),
              _buildInstructions(),
              SizedBox(height: 20.h),
              _buildSelectedDatesList(state),
            ],
          ),
        ),
        if (state is RozaLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildHeader(RozaState state) {
    final fastCount = state is RozaLoaded ? state.currentMonthFastCount : 0;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.restaurant, color: AppColors.primaryGreen, size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly Fast Count',
                  style: TextStyle(fontSize: 14.sp, color: AppColors.textDark, fontWeight: FontWeight.w500),
                ),
                Text(
                  '$fastCount days',
                  style: TextStyle(fontSize: 24.sp, color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.circular(20.r)),
            child: Text(
              '${fastCount * 100} pts',
              style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(RozaState state) {
    final brokenFastDates = state is RozaLoaded ? state.brokenFastDates : [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) {
          return _selectedDates.any(
            (selectedDate) =>
                selectedDate.year == day.year && selectedDate.month == day.month && selectedDate.day == day.day,
          );
        },
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
          });

          final authState = context.read<AuthCubit>().state;
          if (authState is Authenticated) {
            context.read<RozaCubit>().toggleDateSelection(
              userId: authState.user.id,
              date: selectedDay,
              currentlySelectedDates: _selectedDates.toList(),
            );
          }
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
          _loadInitialData();
        },
        calendarStyle: CalendarStyle(
          selectedDecoration: BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle),
          todayDecoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.3), shape: BoxShape.circle),
          markerDecoration: BoxDecoration(color: AppColors.goldAccent, shape: BoxShape.circle),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            // Check if this date is a broken fast
            final isBrokenFast = brokenFastDates.any(
              (brokenDate) => brokenDate.year == day.year && brokenDate.month == day.month && brokenDate.day == day.day,
            );

            if (isBrokenFast) {
              return Container(
                margin: EdgeInsets.all(4.w),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
              );
            }

            return null;
          },
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: AppColors.softCream, borderRadius: BorderRadius.circular(12.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How it works:',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          SizedBox(height: 12.h),
          _buildInstructionItem('✅', 'Tap dates to mark as fasted (100 points each)', AppColors.primaryGreen),
          SizedBox(height: 8.h),
          _buildInstructionItem('❌', 'Skipped dates between fasts are marked as broken', Colors.red),
          SizedBox(height: 8.h),
          _buildInstructionItem('📅', 'View your monthly fasting progress', AppColors.goldAccent),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String icon, String text, Color color) {
    return Row(
      children: [
        Text(icon, style: TextStyle(fontSize: 16.sp)),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14.sp, color: AppColors.textDark),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedDatesList(RozaState state) {
    if (state is! RozaLoaded || _selectedDates.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedDates = _selectedDates.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fasted Dates This Month:',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: sortedDates.map((date) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
              ),
              child: Text(
                '${date.day}/${date.month}',
                style: TextStyle(fontSize: 12.sp, color: AppColors.primaryGreen, fontWeight: FontWeight.w500),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
