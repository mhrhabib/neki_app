import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;
import 'package:al_quran/al_quran.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../cubit/quran_cubit.dart';
import '../../../../components/app_background_widget.dart';

class SurahDetailScreen extends StatelessWidget {
  final int surahNumber;

  const SurahDetailScreen({super.key, required this.surahNumber});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final verseCount = quran.getVerseCount(surahNumber);

    return BlocProvider(
      create: (context) => QuranCubit()..updateLastRead(surahNumber),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            appBackgroundWidget(),
            CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 320.h,
                  pinned: true,
                  floating: false,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  leadingWidth: 70.w,
                  leading: Padding(
                    padding: EdgeInsets.only(left: 16.w, top: 8.h, bottom: 8.h),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.chevron_left,
                        size: 28.sp,
                        color: Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    BlocBuilder<QuranCubit, QuranState>(
                      builder: (context, state) {
                        return Padding(
                          padding: EdgeInsets.only(right: 8.w),
                          child: _buildSettingsMenu(context, state),
                        );
                      },
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    background: Padding(
                      padding: EdgeInsets.only(
                        top:
                            kToolbarHeight + MediaQuery.of(context).padding.top,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [_buildSurahHeaderCard(surahNumber)],
                      ),
                    ),
                    centerTitle: true,
                    title: LayoutBuilder(
                      builder: (context, constraints) {
                        final opacity =
                            constraints.biggest.height <=
                                kToolbarHeight +
                                    (MediaQuery.of(context).padding.top) +
                                    20
                            ? 1.0
                            : 0.0;
                        return Opacity(
                          opacity: opacity,
                          child: Text(
                            quran.getSurahName(surahNumber),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18.sp,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (surahNumber != 1 && surahNumber != 9)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 30.h),
                      child: Text(
                        quran.basmala,
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Amiri',
                          color: AppColors.goldAccent,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 120.h),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final verseNumber = index + 1;
                      return Padding(
                        padding: EdgeInsets.only(bottom: 16.h),
                        child: _buildVerseItem(context, verseNumber, isDark),
                      );
                    }, childCount: verseCount),
                  ),
                ),
              ],
            ),
            _buildAudioPersistentPlayer(context, surahNumber),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsMenu(BuildContext context, QuranState state) {
    return IconButton(
      icon: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.settings, color: AppColors.goldAccent, size: 20.sp),
      ),
      onPressed: () => _showSettingsSheet(context),
    );
  }

  Widget _buildSurahHeaderCard(int surahNumber) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      padding: EdgeInsets.all(24.w),
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
        border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            quran.getSurahNameArabic(surahNumber),
            style: TextStyle(
              fontSize: 32.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'Amiri',
              color: AppColors.goldAccent,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            quran.getSurahName(surahNumber),
            style: TextStyle(
              color: Colors.white,
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            quran.getSurahNameEnglish(surahNumber),
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14.sp,
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeaderBadge(
                Icons.location_on,
                quran.getPlaceOfRevelation(surahNumber).toUpperCase(),
              ),
              SizedBox(width: 16.w),
              _buildHeaderBadge(
                Icons.format_list_bulleted,
                '${quran.getVerseCount(surahNumber)} VERSES',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBadge(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.goldAccent, size: 14.sp),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    final cubit = context.read<QuranCubit>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: BlocProvider.value(
            value: cubit,
            child: BlocBuilder<QuranCubit, QuranState>(
              builder: (context, state) {
                return Padding(
                  padding: EdgeInsets.all(24.w),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40.w,
                            height: 4.h,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(2.r),
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),
                        Text(
                          "Display Settings",
                          style: TextStyle(
                            color: AppColors.goldAccent,
                            fontWeight: FontWeight.w800,
                            fontSize: 16.sp,
                            letterSpacing: 1.1,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        _buildSettingsSwitch(
                          "English Translation",
                          state.showTranslation,
                          cubit.toggleTranslation,
                        ),
                        _buildSettingsSwitch(
                          "Bengali Meaning",
                          state.showBengaliMeaning,
                          cubit.toggleBengaliMeaning,
                        ),
                        _buildSettingsSwitch(
                          "Bengali Pronunciation",
                          state.showPronunciation,
                          cubit.togglePronunciation,
                        ),
                        Divider(color: Colors.white10, height: 30.h),
                        Text(
                          "Audio Settings",
                          style: TextStyle(
                            color: AppColors.goldAccent,
                            fontWeight: FontWeight.w800,
                            fontSize: 14.sp,
                            letterSpacing: 1.1,
                          ),
                        ),
                        _buildSettingsSwitch(
                          "Auto-play Next Ayah",
                          state.isAutoPlayEnabled,
                          cubit.toggleAutoPlay,
                        ),
                        Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(canvasColor: const Color(0xFF2C2C2E)),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              "Selected Reciter",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14.sp,
                              ),
                            ),
                            trailing: DropdownButton<quran.Reciter>(
                              value: state.selectedReciter,
                              onChanged: (r) => cubit.setReciter(r!),
                              underline: const SizedBox.shrink(),
                              dropdownColor: const Color(0xFF2C2C2E),
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: AppColors.goldAccent,
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: quran.Reciter.arAlafasy,
                                  child: Text(
                                    "Rashid Alafasy",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: quran.Reciter.arMaherMuaiqly,
                                  child: Text(
                                    "Maher Al Muaiqly",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: quran.Reciter.arMinshawi,
                                  child: Text(
                                    "Al-Minshawi",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsSwitch(
    String title,
    bool value,
    VoidCallback onChanged,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(color: Colors.white, fontSize: 14.sp),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: (_) => onChanged(),
        activeThumbColor: AppColors.goldAccent,
        activeTrackColor: AppColors.goldAccent.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildAudioPersistentPlayer(BuildContext context, int surahNumber) {
    return BlocBuilder<QuranCubit, QuranState>(
      builder: (context, state) {
        if (state.audioStatus == AudioStatus.initial ||
            state.audioStatus == AudioStatus.stopped) {
          return const SizedBox.shrink();
        }

        return Positioned(
          bottom: 20.h,
          left: 20.w,
          right: 20.w,
          child: Container(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: AppColors.goldAccent.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2.h,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 4.r),
                    overlayShape: RoundSliderOverlayShape(overlayRadius: 10.r),
                    activeTrackColor: AppColors.goldAccent,
                    inactiveTrackColor: Colors.white10,
                    thumbColor: AppColors.goldAccent,
                  ),
                  child: Slider(
                    value: state.position.inSeconds.toDouble(),
                    max: state.duration.inSeconds.toDouble() > 0
                        ? state.duration.inSeconds.toDouble()
                        : 1.0,
                    onChanged: (value) {
                      context.read<QuranCubit>().seek(
                        Duration(seconds: value.toInt()),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: GestureDetector(
                          onTap: () => context.read<QuranCubit>().stopAudio(),
                          child: Icon(
                            Icons.stop_rounded,
                            color: Colors.redAccent,
                            size: 20.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.currentlyPlayingAyah != null
                                  ? 'AYAH ${state.currentlyPlayingAyah}'
                                  : 'FULL SURAH',
                              style: TextStyle(
                                color: AppColors.goldAccent,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              quran.getSurahName(surahNumber),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          context.read<QuranCubit>().playAudio(
                            state.currentlyPlayingAyah == null
                                ? quran.getAudioURLBySurah(surahNumber)
                                : quran.getAudioURLByVerse(
                                    surahNumber,
                                    state.currentlyPlayingAyah!,
                                    reciter: state.selectedReciter,
                                  ),
                            ayahNumber: state.currentlyPlayingAyah,
                            surahNumber: surahNumber,
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: AppColors.goldAccent.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            state.audioStatus == AudioStatus.playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: AppColors.goldAccent,
                            size: 26.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVerseItem(BuildContext context, int verseNumber, bool isDark) {
    return BlocBuilder<QuranCubit, QuranState>(
      builder: (context, state) {
        final isPlayingVerse =
            state.audioStatus == AudioStatus.playing &&
            state.currentlyPlayingAyah == verseNumber;
        final isLoadingVerse =
            state.audioStatus == AudioStatus.loading &&
            state.currentlyPlayingAyah == verseNumber;
        final isBookmarked = state.bookmarks.contains(
          "$surahNumber:$verseNumber",
        );

        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isPlayingVerse
                  ? AppColors.goldAccent.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.goldAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      "$surahNumber:$verseNumber",
                      style: TextStyle(
                        color: AppColors.goldAccent,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_outline,
                          color: AppColors.goldAccent.withValues(alpha: 0.6),
                          size: 22.sp,
                        ),
                        onPressed: () => context
                            .read<QuranCubit>()
                            .toggleBookmark(surahNumber, verseNumber),
                        constraints: const BoxConstraints(),
                      ),
                      IconButton(
                        icon: isLoadingVerse
                            ? SizedBox(
                                width: 18.w,
                                height: 18.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.goldAccent,
                                ),
                              )
                            : Icon(
                                isPlayingVerse
                                    ? Icons.pause_circle_outline
                                    : Icons.play_circle_outline,
                                color: AppColors.goldAccent,
                                size: 24.sp,
                              ),
                        onPressed: () {
                          context.read<QuranCubit>().playAudio(
                            quran.getAudioURLByVerse(
                              surahNumber,
                              verseNumber,
                              reciter: state.selectedReciter,
                            ),
                            ayahNumber: verseNumber,
                            surahNumber: surahNumber,
                          );
                        },
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Text(
                quran.getVerse(surahNumber, verseNumber, verseEndSymbol: true),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: state.arabicFontSize.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Amiri',
                  color: Colors.white,
                  height: 2.0,
                ),
              ),
              if (state.showPronunciation) ...[
                SizedBox(height: 16.h),
                Text(
                  AlQuran.surahDetails
                      .bySurahNumber(surahNumber)
                      .ayahs[verseNumber - 1]
                      .pronunciationBn,
                  style: TextStyle(
                    fontSize: state.translationFontSize.sp,
                    color: Colors.white70,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
              ],
              if (state.showBengaliMeaning) ...[
                SizedBox(height: 12.h),
                Text(
                  quran.getVerseTranslation(
                    surahNumber,
                    verseNumber,
                    translation: quran.Translation.bengali,
                  ),
                  style: TextStyle(
                    fontSize: (state.translationFontSize + 1).sp,
                    color: AppColors.goldAccent.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              ],
              if (state.showTranslation) ...[
                SizedBox(height: 12.h),
                Text(
                  quran.getVerseTranslation(surahNumber, verseNumber),
                  style: TextStyle(
                    fontSize: state.translationFontSize.sp,
                    color: Colors.white60,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
