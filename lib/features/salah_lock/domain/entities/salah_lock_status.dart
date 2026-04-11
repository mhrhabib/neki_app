class SalahLockStatus {
  final bool isLocked;
  final String salahName;
  final int verseIndex;
  final bool prayedToday;

  SalahLockStatus({
    this.isLocked = false,
    this.salahName = '',
    this.verseIndex = 0,
    this.prayedToday = false,
  });

  SalahLockStatus copyWith({
    bool? isLocked,
    String? salahName,
    int? verseIndex,
    bool? prayedToday,
  }) {
    return SalahLockStatus(
      isLocked: isLocked ?? this.isLocked,
      salahName: salahName ?? this.salahName,
      verseIndex: verseIndex ?? this.verseIndex,
      prayedToday: prayedToday ?? this.prayedToday,
    );
  }
}
