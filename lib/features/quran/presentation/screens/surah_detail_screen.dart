import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;
import 'package:al_quran/al_quran.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../cubit/quran_cubit.dart';

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
        backgroundColor: isDark ? const Color(0xFF0A0E27) : const Color(0xFFF9FAFB),
        appBar: AppBar(
          title: Column(
            children: [
              Text(
                quran.getSurahName(surahNumber),
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                ),
              ),
              Text(
                '${quran.getPlaceOfRevelation(surahNumber)} • $verseCount Ayahs',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey[600],
                  fontSize: 12.sp,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: isDark ? Colors.white : AppColors.textDark),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            BlocBuilder<QuranCubit, QuranState>(
              builder: (context, state) {
                final isPlayingSurah = state.audioStatus == AudioStatus.playing && state.currentlyPlayingAyah == null;
                final isLoadingSurah = state.audioStatus == AudioStatus.loading && state.currentlyPlayingAyah == null;

                return Row(
                  children: [
                    IconButton(
                      icon: isLoadingSurah
                          ? SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryGreen),
                            )
                          : Icon(
                              isPlayingSurah ? Icons.pause_circle_filled : Icons.play_circle_filled,
                              color: AppColors.primaryGreen,
                            ),
                      onPressed: () {
                        if (isPlayingSurah) {
                          context.read<QuranCubit>().stopAudio();
                        } else {
                          context.read<QuranCubit>().playAudio(
                            quran.getAudioURLBySurah(surahNumber),
                            surahNumber: surahNumber,
                          );
                        }
                      },
                    ),
                    _buildSettingsMenu(context, state),
                  ],
                );
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                if (surahNumber != 1 && surahNumber != 9)
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 20.h),
                    child: Text(
                      quran.basmala,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Amiri',
                        color: isDark ? Colors.white : AppColors.textDark,
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 100.h),
                    itemCount: verseCount,
                    separatorBuilder: (context, index) =>
                        Divider(height: 32.h, color: isDark ? Colors.white10 : Colors.black12),
                    itemBuilder: (context, index) {
                      final verseNumber = index + 1;
                      return _buildVerseItem(context, verseNumber, isDark);
                    },
                  ),
                ),
              ],
            ),
            _buildAudioPersistentPlayer(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsMenu(BuildContext context, QuranState state) {
    return IconButton(
      icon: Icon(Icons.settings, color: AppColors.primaryGreen),
      onPressed: () => _showSettingsSheet(context),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    final cubit = context.read<QuranCubit>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (context) {
        return BlocProvider.value(
          value: cubit,
          child: BlocBuilder<QuranCubit, QuranState>(
            builder: (context, state) {
              return Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Display Settings",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
                    ),
                    SwitchListTile(
                      title: Text("English Meaning"),
                      value: state.showTranslation,
                      onChanged: (_) => cubit.toggleTranslation(),
                      activeThumbColor: AppColors.primaryGreen,
                    ),
                    SwitchListTile(
                      title: Text("Bengali Meaning"),
                      value: state.showBengaliMeaning,
                      onChanged: (_) => cubit.toggleBengaliMeaning(),
                      activeThumbColor: AppColors.primaryGreen,
                    ),
                    SwitchListTile(
                      title: Text("Bengali Pronunciation"),
                      value: state.showPronunciation,
                      onChanged: (_) => cubit.togglePronunciation(),
                      activeThumbColor: AppColors.primaryGreen,
                    ),
                    Divider(),
                    Text(
                      "Audio Settings",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
                    ),
                    SwitchListTile(
                      title: Text("Auto-play Next Ayah"),
                      value: state.isAutoPlayEnabled,
                      onChanged: (_) => cubit.toggleAutoPlay(),
                      activeThumbColor: AppColors.primaryGreen,
                    ),
                    ListTile(
                      title: Text("Reciter"),
                      trailing: DropdownButton<quran.Reciter>(
                        value: state.selectedReciter,
                        onChanged: (r) => cubit.setReciter(r!),
                        items: [
                          DropdownMenuItem(value: quran.Reciter.arAlafasy, child: Text("Rashid Alafasy")),
                          DropdownMenuItem(value: quran.Reciter.arMaherMuaiqly, child: Text("Maher Al Muaiqly")),
                          DropdownMenuItem(value: quran.Reciter.arMinshawi, child: Text("Al-Minshawi")),
                        ],
                      ),
                    ),
                    Divider(),
                    Text(
                      "Font Size",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
                    ),
                    Row(
                      children: [
                        Text("Arabic"),
                        Expanded(
                          child: Slider(
                            value: state.arabicFontSize,
                            min: 16,
                            max: 40,
                            onChanged: (v) => cubit.setArabicFontSize(v),
                            activeColor: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAudioPersistentPlayer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<QuranCubit, QuranState>(
      builder: (context, state) {
        if (state.audioStatus == AudioStatus.initial || state.audioStatus == AudioStatus.stopped) {
          return const SizedBox.shrink();
        }

        return Positioned(
          bottom: 20.h,
          left: 20.w,
          right: 20.w,
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      _formatDuration(state.position),
                      style: TextStyle(fontSize: 10.sp, color: isDark ? Colors.white70 : Colors.grey),
                    ),
                    const Spacer(),
                    Text(
                      _formatDuration(state.duration),
                      style: TextStyle(fontSize: 10.sp, color: isDark ? Colors.white70 : Colors.grey),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2.h,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
                    overlayShape: RoundSliderOverlayShape(overlayRadius: 12.r),
                  ),
                  child: Slider(
                    value: state.position.inSeconds.toDouble(),
                    max: state.duration.inSeconds.toDouble() > 0 ? state.duration.inSeconds.toDouble() : 1.0,
                    activeColor: AppColors.primaryGreen,
                    inactiveColor: AppColors.primaryGreen.withValues(alpha: 0.2),
                    onChanged: (value) {
                      context.read<QuranCubit>().seek(Duration(seconds: value.toInt()));
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.stop_rounded),
                      color: Colors.redAccent,
                      onPressed: () => context.read<QuranCubit>().stopAudio(),
                    ),
                    SizedBox(width: 20.w),
                    IconButton(
                      icon: Icon(
                        state.audioStatus == AudioStatus.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      ),
                      iconSize: 32.sp,
                      color: AppColors.primaryGreen,
                      onPressed: () {
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
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  Widget _buildVerseItem(BuildContext context, int verseNumber, bool isDark) {
    return BlocBuilder<QuranCubit, QuranState>(
      builder: (context, state) {
        final isPlayingVerse = state.audioStatus == AudioStatus.playing && state.currentlyPlayingAyah == verseNumber;
        final isLoadingVerse = state.audioStatus == AudioStatus.loading && state.currentlyPlayingAyah == verseNumber;
        final isBookmarked = state.bookmarks.contains("$surahNumber:$verseNumber");

        return Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: isPlayingVerse ? AppColors.primaryGreen.withValues(alpha: 0.05) : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          verseNumber.toString(),
                          style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 12.sp),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      IconButton(
                        icon: isLoadingVerse
                            ? SizedBox(
                                width: 16.w,
                                height: 16.w,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryGreen),
                              )
                            : Icon(
                                isPlayingVerse ? Icons.pause_circle_outline : Icons.play_circle_outline,
                                color: AppColors.primaryGreen.withValues(alpha: 0.6),
                                size: 20.sp,
                              ),
                        onPressed: () {
                          context.read<QuranCubit>().playAudio(
                            quran.getAudioURLByVerse(surahNumber, verseNumber, reciter: state.selectedReciter),
                            ayahNumber: verseNumber,
                            surahNumber: surahNumber,
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      IconButton(
                        icon: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                          color: AppColors.primaryGreen.withValues(alpha: 0.6),
                          size: 20.sp,
                        ),
                        onPressed: () => context.read<QuranCubit>().toggleBookmark(surahNumber, verseNumber),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      quran.getVerse(surahNumber, verseNumber, verseEndSymbol: true),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: state.arabicFontSize.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Amiri',
                        color: isDark ? Colors.white : AppColors.textDark,
                        height: 1.8,
                      ),
                    ),
                  ),
                ],
              ),
              if (state.showPronunciation) ...[
                SizedBox(height: 8.h),
                Text(
                  AlQuran.surahDetails.bySurahNumber(surahNumber).ayahs[verseNumber - 1].pronunciationBn,
                  style: TextStyle(
                    fontSize: state.translationFontSize.sp,
                    color: isDark ? Colors.white60 : Colors.grey[700],
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
              ],
              if (state.showBengaliMeaning) ...[
                SizedBox(height: 12.h),
                Text(
                  quran.getVerseTranslation(surahNumber, verseNumber, translation: quran.Translation.bengali),
                  style: TextStyle(
                    fontSize: (state.translationFontSize + 1).sp,
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ],
              if (state.showTranslation) ...[
                SizedBox(height: 8.h),
                Text(
                  quran.getVerseTranslation(surahNumber, verseNumber),
                  style: TextStyle(
                    fontSize: state.translationFontSize.sp,
                    color: isDark ? Colors.white70 : Colors.grey[800],
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ],
              SizedBox(height: 4.h),
              Text(
                'Juz ${quran.getJuzNumber(surahNumber, verseNumber)}',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: isDark ? Colors.white38 : Colors.grey.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
