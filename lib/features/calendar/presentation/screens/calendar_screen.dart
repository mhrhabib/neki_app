import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  bool _isSunnahFast(DateTime day) {
    // Mondays (1) and Thursdays (4)
    if (day.weekday == DateTime.monday || day.weekday == DateTime.thursday) {
      return true;
    }

    // White Days (13, 14, 15 of Hijri month)
    final hijriDay = HijriCalendar.fromDate(day);
    if (hijriDay.hDay == 13 || hijriDay.hDay == 14 || hijriDay.hDay == 15) {
      return true;
    }

    return false;
  }

  String _getFastingType(DateTime day) {
    String type = "";
    if (day.weekday == DateTime.monday) type += "Monday Fast";
    if (day.weekday == DateTime.thursday) {
      if (type.isNotEmpty) type += " & ";
      type += "Thursday Fast";
    }
    final hj = HijriCalendar.fromDate(day);
    if (hj.hDay == 13 || hj.hDay == 14 || hj.hDay == 15) {
      if (type.isNotEmpty) type += " & ";
      type += "White Day (${hj.hDay})";
    }
    return type;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softCream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Islamic Calendar",
          style: AppTypography.h1.copyWith(color: AppColors.primaryGreen),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildCalendarCard(),
            SizedBox(height: 20.h),
            _buildDayDetail(),
            SizedBox(height: 20.h),
            _buildSunnahFastInfo(),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: AppColors.primaryGreen.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppColors.primaryGreen,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 1,
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: AppTypography.h3.copyWith(
            color: AppColors.primaryGreen,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            if (_isSunnahFast(day)) {
              return Container(
                margin: const EdgeInsets.all(4.0),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.goldAccent, width: 1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  day.day.toString(),
                  style: const TextStyle(color: AppColors.textDark),
                ),
              );
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildDayDetail() {
    if (_selectedDay == null) return const SizedBox.shrink();

    final hj = HijriCalendar.fromDate(_selectedDay!);
    final isFast = _isSunnahFast(_selectedDay!);

    return Container(
      padding: EdgeInsets.all(20.w),
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, MMMM d').format(_selectedDay!),
                    style: AppTypography.h3,
                  ),
                  Text(
                    "${hj.hDay} ${hj.longMonthName} ${hj.hYear} AH",
                    style: AppTypography.body.copyWith(
                      color: AppColors.goldAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (isFast)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.goldAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: AppColors.goldAccent),
                  ),
                  child: Text(
                    "Sunnah Fast",
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: AppColors.goldAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          if (isFast) ...[
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.softCream,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primaryGreen),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      "It's recommended to fast today (${_getFastingType(_selectedDay!)}). Don't forget to log it in your Roza tracker!",
                      style: AppTypography.caption,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSunnahFastInfo() {
    return Container(
      padding: EdgeInsets.all(20.w),
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Sunnah Fasting Guide",
            style: AppTypography.h3.copyWith(color: AppColors.primaryGreen),
          ),
          SizedBox(height: 12.h),
          _buildInfoRow(
            Icons.calendar_view_week,
            "Mondays & Thursdays",
            "The Prophet (ﷺ) used to fast on these days.",
          ),
          SizedBox(height: 8.h),
          _buildInfoRow(
            Icons.brightness_5,
            "White Days (Ayyam al-Bidh)",
            "13th, 14th, and 15th of every Islamic month.",
          ),
          SizedBox(height: 8.h),
          _buildInfoRow(
            Icons.star_outline,
            "Other Key Days",
            "Day of Arafah, Ashura, etc. (Check specific dates)",
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20.sp, color: AppColors.goldAccent),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                subtitle,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textGray,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
