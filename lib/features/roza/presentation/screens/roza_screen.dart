import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/roza_cubit.dart';
import '../../../../components/app_background_widget.dart';

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
      context.read<RozaCubit>().loadMonthlyRozaData(
        authState.user.id,
        _focusedDay.year,
        _focusedDay.month,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Roza Tracker',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          appBackgroundWidget(),
          BlocConsumer<RozaCubit, RozaState>(
            listener: (context, state) {
              if (state is RozaLoaded) {
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
        ],
      ),
    );
  }

  Widget _buildContent(RozaState state) {
    final authState = context.watch<AuthCubit>().state;
    if (authState is! Authenticated) {
      return const Center(
        child: Text(
          'Please login to track Roza',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return Stack(
      children: [
        SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(state),
                SizedBox(height: 24.h),
                _buildCalendar(state),
                SizedBox(height: 24.h),
                _buildInstructions(),
                SizedBox(height: 24.h),
                _buildSelectedDatesList(state),
                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
        if (state is RozaLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.4),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(RozaState state) {
    final fastCount = state is RozaLoaded ? state.currentMonthFastCount : 0;

    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              Icons.restaurant,
              color: AppColors.primaryGreen,
              size: 28.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly Progress',
                  style: TextStyle(color: Colors.white60, fontSize: 13.sp),
                ),
                SizedBox(height: 4.h),
                Text(
                  '$fastCount Days Fasted',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rewards',
                style: TextStyle(
                  color: AppColors.goldAccent.withValues(alpha: 0.8),
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.goldAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '+${fastCount * 100}',
                  style: TextStyle(
                    color: AppColors.goldAccent,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(RozaState state) {
    final brokenFastDates = state is RozaLoaded ? state.brokenFastDates : [];

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) {
          return _selectedDates.any(
            (selectedDate) =>
                selectedDate.year == day.year &&
                selectedDate.month == day.month &&
                selectedDate.day == day.day,
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
          defaultTextStyle: const TextStyle(color: Colors.white70),
          weekendTextStyle: const TextStyle(color: Colors.white54),
          outsideTextStyle: const TextStyle(color: Colors.white24),
          selectedDecoration: const BoxDecoration(
            color: AppColors.primaryGreen,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: AppColors.primaryGreen.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: AppColors.goldAccent,
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
          leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white),
          rightChevronIcon: const Icon(
            Icons.chevron_right,
            color: Colors.white,
          ),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: Colors.white54),
          weekendStyle: TextStyle(color: AppColors.goldAccent),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            final isBrokenFast = brokenFastDates.any(
              (brokenDate) =>
                  brokenDate.year == day.year &&
                  brokenDate.month == day.month &&
                  brokenDate.day == day.day,
            );

            if (isBrokenFast) {
              return Container(
                margin: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: Colors.red,
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
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.primaryGreen,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'How it works',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildInstructionItem(
            '✅',
            'Tap dates to mark as fasted (100 points each)',
            Colors.white70,
          ),
          SizedBox(height: 12.h),
          _buildInstructionItem(
            '❌',
            'Skipped days between fasts are marked as broken',
            Colors.white70,
          ),
          SizedBox(height: 12.h),
          _buildInstructionItem(
            '�',
            'Maintain your consistency for higher daily streaks',
            Colors.white70,
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String icon, String text, Color textColor) {
    return Row(
      children: [
        Container(
          width: 32.w,
          alignment: Alignment.centerLeft,
          child: Text(icon, style: TextStyle(fontSize: 18.sp)),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13.sp, color: textColor, height: 1.4),
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
        Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: Text(
            'Fasted Dates This Month',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children: sortedDates.map((date) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 14.sp,
                    color: AppColors.primaryGreen,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    DateFormat('MMM d').format(date),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
