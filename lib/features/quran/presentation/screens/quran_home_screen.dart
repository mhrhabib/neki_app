import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../cubit/quran_cubit.dart';
import '../../../../components/app_background_widget.dart';

class QuranHomeScreen extends StatefulWidget {
  const QuranHomeScreen({super.key});

  @override
  State<QuranHomeScreen> createState() => _QuranHomeScreenState();
}

class _QuranHomeScreenState extends State<QuranHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<int> _filteredSurahIndices = List.generate(
    quran.totalSurahCount,
    (index) => index + 1,
  );

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSurahIndices =
          List.generate(quran.totalSurahCount, (index) => index + 1)
              .where(
                (index) =>
                    quran.getSurahName(index).toLowerCase().contains(query) ||
                    quran
                        .getSurahNameEnglish(index)
                        .toLowerCase()
                        .contains(query) ||
                    index.toString().contains(query),
              )
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (context) => QuranCubit(),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(
            'Holy Qur\'an',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 20.sp,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: isDark ? Colors.white : AppColors.textDark,
            ),
            onPressed: () => context.pop(),
          ),
        ),
        body: Stack(
          children: [
            appBackgroundWidget(),
            BlocBuilder<QuranCubit, QuranState>(
              builder: (context, state) {
                return Column(
                  children: [
                    if (state.lastReadSurah != null)
                      _buildLastReadCard(context, state.lastReadSurah!, isDark),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 10.h,
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.textDark,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search Surah...',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white38 : Colors.grey,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppColors.primaryGreen,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 15.h,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.r),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.r),
                            borderSide: isDark
                                ? BorderSide.none
                                : BorderSide(color: Colors.grey[200]!),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _filteredSurahIndices.isEmpty
                          ? Center(
                              child: Text(
                                'No Surahs found',
                                style: TextStyle(
                                  color: isDark ? Colors.white38 : Colors.grey,
                                  fontSize: 16.sp,
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 10.h,
                              ),
                              itemCount: _filteredSurahIndices.length,
                              separatorBuilder: (context, index) =>
                                  SizedBox(height: 12.h),
                              itemBuilder: (context, index) {
                                final surahNumber =
                                    _filteredSurahIndices[index];
                                return _buildSurahCard(
                                  context,
                                  surahNumber,
                                  isDark,
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastReadCard(
    BuildContext context,
    int surahNumber,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => context.push('${RouteNames.quran}/$surahNumber'),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryGreen,
              AppColors.primaryGreen.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.menu_book, color: Colors.white, size: 30.sp),
            SizedBox(width: 15.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Continue Reading',
                  style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                ),
                Text(
                  quran.getSurahName(surahNumber),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildSurahCard(BuildContext context, int surahNumber, bool isDark) {
    return GestureDetector(
      onTap: () => context.push('${RouteNames.quran}/$surahNumber'),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  surahNumber.toString(),
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quran.getSurahName(surahNumber),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${quran.getPlaceOfRevelation(surahNumber)} • ${quran.getVerseCount(surahNumber)} Verses',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isDark ? Colors.white38 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              quran.getSurahNameArabic(surahNumber),
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Amiri',
                color: AppColors.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
