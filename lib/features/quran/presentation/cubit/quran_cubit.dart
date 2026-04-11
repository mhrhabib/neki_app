import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';

enum AudioStatus { initial, loading, playing, paused, stopped, error }

class QuranState extends Equatable {
  final bool showTranslation;
  final bool showBengaliMeaning;
  final bool showPronunciation;
  final bool isAutoPlayEnabled;
  final quran.Reciter selectedReciter;
  final double arabicFontSize;
  final double translationFontSize;
  final String translationLanguage;
  final AudioStatus audioStatus;
  final int? currentlyPlayingAyah;
  final int? currentlyPlayingSurah;
  final int? lastReadSurah;
  final List<String> bookmarks; // Format: "surah:ayah"
  final String? errorMessage;
  final Duration position;
  final Duration duration;

  const QuranState({
    this.showTranslation = true,
    this.showBengaliMeaning = true,
    this.showPronunciation = true,
    this.isAutoPlayEnabled = false,
    this.selectedReciter = quran.Reciter.arAlafasy,
    this.arabicFontSize = 22.0,
    this.translationFontSize = 14.0,
    this.translationLanguage = 'en',
    this.audioStatus = AudioStatus.initial,
    this.currentlyPlayingAyah,
    this.currentlyPlayingSurah,
    this.lastReadSurah,
    this.bookmarks = const [],
    this.errorMessage,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  QuranState copyWith({
    bool? showTranslation,
    bool? showBengaliMeaning,
    bool? showPronunciation,
    bool? isAutoPlayEnabled,
    quran.Reciter? selectedReciter,
    double? arabicFontSize,
    double? translationFontSize,
    String? translationLanguage,
    AudioStatus? audioStatus,
    int? currentlyPlayingAyah,
    int? currentlyPlayingSurah,
    int? lastReadSurah,
    List<String>? bookmarks,
    String? errorMessage,
    Duration? position,
    Duration? duration,
  }) {
    return QuranState(
      showTranslation: showTranslation ?? this.showTranslation,
      showBengaliMeaning: showBengaliMeaning ?? this.showBengaliMeaning,
      showPronunciation: showPronunciation ?? this.showPronunciation,
      isAutoPlayEnabled: isAutoPlayEnabled ?? this.isAutoPlayEnabled,
      selectedReciter: selectedReciter ?? this.selectedReciter,
      arabicFontSize: arabicFontSize ?? this.arabicFontSize,
      translationFontSize: translationFontSize ?? this.translationFontSize,
      translationLanguage: translationLanguage ?? this.translationLanguage,
      audioStatus: audioStatus ?? this.audioStatus,
      currentlyPlayingAyah: currentlyPlayingAyah ?? this.currentlyPlayingAyah,
      currentlyPlayingSurah: currentlyPlayingSurah ?? this.currentlyPlayingSurah,
      lastReadSurah: lastReadSurah ?? this.lastReadSurah,
      bookmarks: bookmarks ?? this.bookmarks,
      errorMessage: errorMessage ?? this.errorMessage,
      position: position ?? this.position,
      duration: duration ?? this.duration,
    );
  }

  @override
  List<Object?> get props => [
    showTranslation,
    showBengaliMeaning,
    showPronunciation,
    isAutoPlayEnabled,
    selectedReciter,
    arabicFontSize,
    translationFontSize,
    translationLanguage,
    audioStatus,
    currentlyPlayingAyah,
    currentlyPlayingSurah,
    lastReadSurah,
    bookmarks,
    errorMessage,
    position,
    duration,
  ];
}

class QuranCubit extends Cubit<QuranState> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  QuranCubit() : super(const QuranState()) {
    _loadSettings();
    _audioPlayer.onPlayerStateChanged.listen((playerState) {
      if (playerState == PlayerState.completed) {
        if (state.isAutoPlayEnabled && state.currentlyPlayingAyah != null && state.currentlyPlayingSurah != null) {
          _playNextAyah();
        } else {
          emit(state.copyWith(audioStatus: AudioStatus.stopped, currentlyPlayingAyah: null, position: Duration.zero));
        }
      }
    });

    _audioPlayer.onPositionChanged.listen((pos) {
      emit(state.copyWith(position: pos));
    });

    _audioPlayer.onDurationChanged.listen((dur) {
      emit(state.copyWith(duration: dur));
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList('quran_bookmarks') ?? [];
    final arabicFontSize = prefs.getDouble('quran_arabic_font_size') ?? 22.0;
    final translationFontSize = prefs.getDouble('quran_translation_font_size') ?? 14.0;
    final isAutoPlay = prefs.getBool('quran_auto_play') ?? false;
    final reciterIndex = prefs.getInt('quran_reciter_index') ?? 0;
    final lastRead = prefs.getInt('quran_last_read_surah');

    emit(
      state.copyWith(
        bookmarks: bookmarks,
        arabicFontSize: arabicFontSize,
        translationFontSize: translationFontSize,
        isAutoPlayEnabled: isAutoPlay,
        selectedReciter: quran.Reciter.values[reciterIndex],
        lastReadSurah: lastRead,
      ),
    );
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('quran_bookmarks', state.bookmarks);
    await prefs.setDouble('quran_arabic_font_size', state.arabicFontSize);
    await prefs.setDouble('quran_translation_font_size', state.translationFontSize);
    await prefs.setBool('quran_auto_play', state.isAutoPlayEnabled);
    await prefs.setInt('quran_reciter_index', state.selectedReciter.index);
    if (state.lastReadSurah != null) {
      await prefs.setInt('quran_last_read_surah', state.lastReadSurah!);
    }
  }

  void updateLastRead(int surahNumber) {
    emit(state.copyWith(lastReadSurah: surahNumber));
    _saveSettings();
  }

  void toggleTranslation() {
    emit(state.copyWith(showTranslation: !state.showTranslation));
  }

  void toggleBengaliMeaning() {
    emit(state.copyWith(showBengaliMeaning: !state.showBengaliMeaning));
  }

  void togglePronunciation() {
    emit(state.copyWith(showPronunciation: !state.showPronunciation));
  }

  void toggleBookmark(int surah, int ayah) {
    final key = "$surah:$ayah";
    final updatedBookmarks = List<String>.from(state.bookmarks);
    if (updatedBookmarks.contains(key)) {
      updatedBookmarks.remove(key);
    } else {
      updatedBookmarks.add(key);
    }
    emit(state.copyWith(bookmarks: updatedBookmarks));
    _saveSettings();
  }

  void toggleAutoPlay() {
    emit(state.copyWith(isAutoPlayEnabled: !state.isAutoPlayEnabled));
    _saveSettings();
  }

  void setReciter(quran.Reciter reciter) {
    emit(state.copyWith(selectedReciter: reciter));
    _saveSettings();
  }

  void setArabicFontSize(double size) {
    emit(state.copyWith(arabicFontSize: size));
    _saveSettings();
  }

  void setTranslationFontSize(double size) {
    emit(state.copyWith(translationFontSize: size));
    _saveSettings();
  }

  Future<void> playAudio(String url, {int? ayahNumber, int? surahNumber}) async {
    try {
      if (state.currentlyPlayingAyah == ayahNumber &&
          state.currentlyPlayingSurah == surahNumber &&
          state.audioStatus == AudioStatus.playing) {
        await _audioPlayer.pause();
        emit(state.copyWith(audioStatus: AudioStatus.paused));
        return;
      }

      emit(
        state.copyWith(
          audioStatus: AudioStatus.loading,
          currentlyPlayingAyah: ayahNumber,
          currentlyPlayingSurah: surahNumber,
          position: Duration.zero,
          duration: Duration.zero,
        ),
      );

      await _audioPlayer.play(UrlSource(url));
      emit(state.copyWith(audioStatus: AudioStatus.playing));
    } catch (e) {
      emit(state.copyWith(audioStatus: AudioStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> seek(Duration pos) async {
    await _audioPlayer.seek(pos);
  }

  Future<void> stopAudio() async {
    await _audioPlayer.stop();
    emit(
      state.copyWith(
        audioStatus: AudioStatus.stopped,
        currentlyPlayingAyah: null,
        currentlyPlayingSurah: null,
        position: Duration.zero,
      ),
    );
  }

  void _playNextAyah() {
    final currentAyah = state.currentlyPlayingAyah;
    final currentSurah = state.currentlyPlayingSurah;

    if (currentAyah != null && currentSurah != null) {
      final totalVerses = quran.getVerseCount(currentSurah);
      if (currentAyah < totalVerses) {
        final nextAyah = currentAyah + 1;
        playAudio(
          quran.getAudioURLByVerse(currentSurah, nextAyah, reciter: state.selectedReciter),
          ayahNumber: nextAyah,
          surahNumber: currentSurah,
        );
      } else {
        // End of Surah
        emit(
          state.copyWith(
            audioStatus: AudioStatus.stopped,
            currentlyPlayingAyah: null,
            currentlyPlayingSurah: null,
            position: Duration.zero,
          ),
        );
      }
    }
  }

  @override
  Future<void> close() {
    _audioPlayer.dispose();
    return super.close();
  }
}
