import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;
import 'package:al_quran/al_quran.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../cubit/quran_cubit.dart';
import '../../../../components/app_background_widget.dart';
import '../../../../core/widgets/custom_back_button.dart';
import '../../../../core/widgets/custom_icon_button.dart';

// ── Pre-loaded verse data ─────────────────────────────────────────────────────
// Simple data class: all strings resolved once in an isolate.
class _VerseData {
  final String arabic;
  final String pronunciation;
  final String bengaliMeaning;
  final String englishTranslation;
  const _VerseData({
    required this.arabic,
    required this.pronunciation,
    required this.bengaliMeaning,
    required this.englishTranslation,
  });
}

/// Top-level function required by compute() — cannot be a closure or method.
List<_VerseData> _loadVerseData(int surahNumber) {
  final verseCount = quran.getVerseCount(surahNumber);
  final surahDetails = AlQuran.surahDetails.bySurahNumber(surahNumber);
  return List.generate(verseCount, (i) {
    final verseNumber = i + 1;
    return _VerseData(
      arabic: quran.getVerse(surahNumber, verseNumber, verseEndSymbol: true),
      pronunciation: surahDetails.ayahs[i].pronunciationBn,
      bengaliMeaning: quran.getVerseTranslation(
        surahNumber,
        verseNumber,
        translation: quran.Translation.bengali,
      ),
      englishTranslation: quran.getVerseTranslation(surahNumber, verseNumber),
    );
  });
}

// ── Screen ────────────────────────────────────────────────────────────────────
class SurahDetailScreen extends StatefulWidget {
  final int surahNumber;
  const SurahDetailScreen({super.key, required this.surahNumber});

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  late final QuranCubit _cubit;
  List<_VerseData>? _verses; // null = still loading
  String? _error;

  @override
  void initState() {
    super.initState();
    _cubit = QuranCubit();
    _cubit.updateLastRead(widget.surahNumber);
    // Run all heavy asset parsing in a background isolate.
    _loadInBackground();
  }

  Future<void> _loadInBackground() async {
    try {
      final verses = await compute(_loadVerseData, widget.surahNumber);
      if (mounted) setState(() => _verses = verses);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Stack(
        children: [
          appBackgroundWidget(),
          Scaffold(
            backgroundColor: Colors.transparent,
            body: _error != null
                ? _buildError()
                : _verses == null
                    ? _buildLoading()
                    : _buildContent(_verses!),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: AppColors.goldAccent,
            strokeWidth: 2,
          ),
          SizedBox(height: 16.h),
          Text(
            'Loading ${quran.getSurahName(widget.surahNumber)}…',
            style: TextStyle(color: Colors.white60, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent, size: 48.sp),
            SizedBox(height: 12.h),
            Text(
              'Failed to load surah data.\nPlease go back and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 14.sp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<_VerseData> verses) {
    return Stack(
      children: [
        CustomScrollView(
          cacheExtent: 500, // only cache ~500px beyond viewport
          slivers: [
            // ── App bar ────────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 320.h,
              pinned: true,
              floating: false,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leadingWidth: 70.w,
              leading: const CustomBackButton(),
              actions: [
                CustomIconButton(
                  icon: Icons.settings,
                  onPressed: () => _showSettingsSheet(context),
                  baseColor: AppColors.goldAccent,
                  size: 44,
                  padding: EdgeInsets.only(right: 16.w),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Padding(
                  padding: EdgeInsets.only(
                    top: kToolbarHeight + MediaQuery.of(context).padding.top,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [_buildSurahHeaderCard(widget.surahNumber)],
                  ),
                ),
                centerTitle: true,
                title: LayoutBuilder(builder: (context, constraints) {
                  final collapsed = constraints.biggest.height <=
                      kToolbarHeight +
                          MediaQuery.of(context).padding.top +
                          20;
                  return Opacity(
                    opacity: collapsed ? 1.0 : 0.0,
                    child: Text(
                      quran.getSurahName(widget.surahNumber),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                      ),
                    ),
                  );
                }),
              ),
            ),

            // ── Basmala ────────────────────────────────────────────────────
            if (widget.surahNumber != 1 && widget.surahNumber != 9)
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

            // ── Verse list ─────────────────────────────────────────────────
            // Outer BlocBuilder only fires on display-settings changes —
            // NOT on every audio position tick.
            BlocBuilder<QuranCubit, QuranState>(
              buildWhen: (p, c) =>
                  p.showTranslation != c.showTranslation ||
                  p.showBengaliMeaning != c.showBengaliMeaning ||
                  p.showPronunciation != c.showPronunciation ||
                  p.arabicFontSize != c.arabicFontSize ||
                  p.translationFontSize != c.translationFontSize ||
                  p.bookmarks != c.bookmarks,
              builder: (context, displayState) {
                return SliverPadding(
                  padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 120.h),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      addAutomaticKeepAlives: false,
                      addRepaintBoundaries: true,
                      (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 16.h),
                          child: _VerseItem(
                            surahNumber: widget.surahNumber,
                            verseNumber: index + 1,
                            data: verses[index],
                            displayState: displayState,
                          ),
                        );
                      },
                      childCount: verses.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),

        // ── Persistent audio player ────────────────────────────────────────
        _buildAudioPlayer(context, widget.surahNumber),
      ],
    );
  }

  // ── Sub-widgets ─────────────────────────────────────────────────────────────

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
              _headerBadge(Icons.location_on,
                  quran.getPlaceOfRevelation(surahNumber).toUpperCase()),
              SizedBox(width: 16.w),
              _headerBadge(Icons.format_list_bulleted,
                  '${quran.getVerseCount(surahNumber)} VERSES'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerBadge(IconData icon, String label) {
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

  Widget _buildAudioPlayer(BuildContext context, int surahNumber) {
    return BlocBuilder<QuranCubit, QuranState>(
      buildWhen: (p, c) =>
          p.audioStatus != c.audioStatus ||
          p.currentlyPlayingAyah != c.currentlyPlayingAyah ||
          p.position != c.position ||
          p.duration != c.duration,
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
                  color: AppColors.goldAccent.withValues(alpha: 0.2)),
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
                    thumbShape:
                        RoundSliderThumbShape(enabledThumbRadius: 4.r),
                    overlayShape:
                        RoundSliderOverlayShape(overlayRadius: 10.r),
                    activeTrackColor: AppColors.goldAccent,
                    inactiveTrackColor: Colors.white10,
                    thumbColor: AppColors.goldAccent,
                  ),
                  child: Slider(
                    value: state.position.inSeconds.toDouble(),
                    max: state.duration.inSeconds > 0
                        ? state.duration.inSeconds.toDouble()
                        : 1.0,
                    onChanged: (v) => context
                        .read<QuranCubit>()
                        .seek(Duration(seconds: v.toInt())),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () =>
                            context.read<QuranCubit>().stopAudio(),
                        child: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.stop_rounded,
                              color: Colors.redAccent, size: 20.sp),
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
                            color:
                                AppColors.goldAccent.withValues(alpha: 0.1),
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

  void _showSettingsSheet(BuildContext context) {
    final cubit = context.read<QuranCubit>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: BlocProvider.value(
          value: cubit,
          child: BlocBuilder<QuranCubit, QuranState>(
            builder: (context, state) => Padding(
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
                    Text('Display Settings',
                        style: TextStyle(
                            color: AppColors.goldAccent,
                            fontWeight: FontWeight.w800,
                            fontSize: 16.sp,
                            letterSpacing: 1.1)),
                    SizedBox(height: 10.h),
                    _settingsSwitch('English Translation',
                        state.showTranslation, cubit.toggleTranslation),
                    _settingsSwitch('Bengali Meaning',
                        state.showBengaliMeaning, cubit.toggleBengaliMeaning),
                    _settingsSwitch('Bengali Pronunciation',
                        state.showPronunciation, cubit.togglePronunciation),
                    Divider(color: Colors.white10, height: 30.h),
                    Text('Audio Settings',
                        style: TextStyle(
                            color: AppColors.goldAccent,
                            fontWeight: FontWeight.w800,
                            fontSize: 14.sp,
                            letterSpacing: 1.1)),
                    _settingsSwitch('Auto-play Next Ayah',
                        state.isAutoPlayEnabled, cubit.toggleAutoPlay),
                    Theme(
                      data: Theme.of(ctx)
                          .copyWith(canvasColor: const Color(0xFF2C2C2E)),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Selected Reciter',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 14.sp)),
                        trailing: DropdownButton<quran.Reciter>(
                          value: state.selectedReciter,
                          onChanged: (r) => cubit.setReciter(r!),
                          underline: const SizedBox.shrink(),
                          dropdownColor: const Color(0xFF2C2C2E),
                          icon: Icon(Icons.arrow_drop_down,
                              color: AppColors.goldAccent),
                          items: [
                            _reciterItem(
                                quran.Reciter.arAlafasy, 'Rashid Alafasy'),
                            _reciterItem(quran.Reciter.arMaherMuaiqly,
                                'Maher Al Muaiqly'),
                            _reciterItem(
                                quran.Reciter.arMinshawi, 'Al-Minshawi'),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  DropdownMenuItem<quran.Reciter> _reciterItem(
          quran.Reciter value, String label) =>
      DropdownMenuItem(
        value: value,
        child: Text(label,
            style: TextStyle(color: Colors.white, fontSize: 14.sp)),
      );

  Widget _settingsSwitch(String title, bool value, VoidCallback onChanged) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title,
          style: TextStyle(color: Colors.white, fontSize: 14.sp)),
      trailing: Switch.adaptive(
        value: value,
        onChanged: (_) => onChanged(),
        activeThumbColor: AppColors.goldAccent,
        activeTrackColor: AppColors.goldAccent.withValues(alpha: 0.3),
      ),
    );
  }
}

// ── Verse Item ────────────────────────────────────────────────────────────────
// Separate widget with a tightly-scoped BlocBuilder — only rebuilds when the
// audio highlight for THIS specific verse changes, not on position ticks.
class _VerseItem extends StatelessWidget {
  final int surahNumber;
  final int verseNumber;
  final _VerseData data;
  final QuranState displayState;

  const _VerseItem({
    required this.surahNumber,
    required this.verseNumber,
    required this.data,
    required this.displayState,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuranCubit, QuranState>(
      buildWhen: (p, c) {
        final wasPlaying = p.audioStatus == AudioStatus.playing &&
            p.currentlyPlayingAyah == verseNumber;
        final isPlaying = c.audioStatus == AudioStatus.playing &&
            c.currentlyPlayingAyah == verseNumber;
        final wasLoading = p.audioStatus == AudioStatus.loading &&
            p.currentlyPlayingAyah == verseNumber;
        final isLoading = c.audioStatus == AudioStatus.loading &&
            c.currentlyPlayingAyah == verseNumber;
        return wasPlaying != isPlaying ||
            wasLoading != isLoading ||
            p.bookmarks != c.bookmarks;
      },
      builder: (context, audioState) {
        final isPlaying = audioState.audioStatus == AudioStatus.playing &&
            audioState.currentlyPlayingAyah == verseNumber;
        final isLoading = audioState.audioStatus == AudioStatus.loading &&
            audioState.currentlyPlayingAyah == verseNumber;
        final isBookmarked =
            audioState.bookmarks.contains('$surahNumber:$verseNumber');

        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isPlaying
                  ? AppColors.goldAccent.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: AppColors.goldAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      '$surahNumber:$verseNumber',
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
                        icon: isLoading
                            ? SizedBox(
                                width: 18.w,
                                height: 18.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.goldAccent,
                                ),
                              )
                            : Icon(
                                isPlaying
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
                                  reciter: audioState.selectedReciter,
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

              // Arabic text (pre-loaded — no asset parsing here)
              SizedBox(height: 16.h),
              Text(
                data.arabic,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: displayState.arabicFontSize.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Amiri',
                  color: Colors.white,
                  height: 2.0,
                ),
              ),

              // Bengali Pronunciation
              if (displayState.showPronunciation) ...[
                SizedBox(height: 16.h),
                Text(
                  data.pronunciation,
                  style: TextStyle(
                    fontSize: displayState.translationFontSize.sp,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
              ],

              // Bengali Meaning
              if (displayState.showBengaliMeaning) ...[
                SizedBox(height: 12.h),
                Text(
                  data.bengaliMeaning,
                  style: TextStyle(
                    fontSize: (displayState.translationFontSize + 1).sp,
                    color: AppColors.goldAccent.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              ],

              // English Translation
              if (displayState.showTranslation) ...[
                SizedBox(height: 12.h),
                Text(
                  data.englishTranslation,
                  style: TextStyle(
                    fontSize: displayState.translationFontSize.sp,
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
