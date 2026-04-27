import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../cubit/quran_cubit.dart';
import '../../../../components/app_background_widget.dart';
import '../../../../core/widgets/custom_back_button.dart';

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

  /// Tracks which surah is currently being navigated to (shows tap loader).
  int? _navigatingToSurah;

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

  /// Navigates to a surah detail screen with a brief loading indicator.
  Future<void> _navigateToSurah(int surahNumber) async {
    if (_navigatingToSurah != null) return; // prevent double-tap
    setState(() => _navigatingToSurah = surahNumber);
    // Let the UI render the loading state before pushing the heavy screen.
    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    await context.push('${RouteNames.quran}/$surahNumber');
    if (mounted) setState(() => _navigatingToSurah = null);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => QuranCubit(),
      child: Stack(
        children: [
          appBackgroundWidget(),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leadingWidth: 70.w,
              leading: const CustomBackButton(),
              title: Text(
                'Holy Qur\'an',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20.sp,
                ),
              ),
              centerTitle: true,
            ),
            body: BlocBuilder<QuranCubit, QuranState>(
              builder: (context, state) {
                return Stack(
                  children: [
                    Column(
                      children: [
                        // ── Last Read Card ───────────────────────────────────
                        // Show only once settings have loaded (lastReadSurah is
                        // populated from SharedPreferences asynchronously).
                        if (state.lastReadSurah != null)
                          _buildLastReadCard(context, state.lastReadSurah!),

                        // ── Search Bar ───────────────────────────────────────
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 10.h,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search Surah...',
                                hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 14.sp,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: AppColors.goldAccent,
                                  size: 20.sp,
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.08),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20.w,
                                  vertical: 15.h,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15.r),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15.r),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15.r),
                                  borderSide: const BorderSide(
                                    color: AppColors.goldAccent,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // ── Surah List ───────────────────────────────────────
                        Expanded(
                          child: _filteredSurahIndices.isEmpty
                              ? Center(
                                  child: Text(
                                    'No Surahs found',
                                    style: TextStyle(
                                      color: Colors.white38,
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
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),

                    // ── Tap-loading overlay ──────────────────────────────────
                    // Shown while the heavy SurahDetailScreen is being pushed.
                    if (_navigatingToSurah != null)
                      Container(
                        color: Colors.black.withValues(alpha: 0.45),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(
                                color: AppColors.goldAccent,
                                strokeWidth: 2.5,
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'Opening ${quran.getSurahName(_navigatingToSurah!)}…',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastReadCard(BuildContext context, int surahNumber) {
    return GestureDetector(
      onTap: () => _navigateToSurah(surahNumber),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1E4D35),
              const Color(0xFF0D2818).withValues(alpha: 0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: AppColors.goldAccent.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20.w,
              top: -20.h,
              child: Opacity(
                opacity: 0.1,
                child: Icon(
                  Icons.auto_stories,
                  color: Colors.white,
                  size: 100.sp,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: AppColors.goldAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.menu_book,
                      color: AppColors.goldAccent,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 15.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CONTINUE READING',
                          style: TextStyle(
                            color: AppColors.goldAccent,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          quran.getSurahName(surahNumber),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Surah No. $surahNumber • ${quran.getVerseCount(surahNumber)} Verses',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.goldAccent,
                    size: 16.sp,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurahCard(BuildContext context, int surahNumber) {
    final isNavigating = _navigatingToSurah == surahNumber;
    return GestureDetector(
      onTap: () => _navigateToSurah(surahNumber),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isNavigating ? 0.10 : 0.05),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isNavigating
                ? AppColors.goldAccent.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.star,
                  color: AppColors.goldAccent.withValues(alpha: 0.2),
                  size: 44.sp,
                ),
                isNavigating
                    ? SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: AppColors.goldAccent,
                        ),
                      )
                    : Text(
                        surahNumber.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
              ],
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
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${quran.getPlaceOfRevelation(surahNumber).toUpperCase()} • ${quran.getVerseCount(surahNumber)} VERSES',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white60,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              quran.getSurahNameArabic(surahNumber),
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Amiri',
                color: AppColors.goldAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
