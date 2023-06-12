extension FormatString on Duration {
  String get mmSSFormat {
    String twoDigits(int n) {
      if (n >= 10) return '$n';
      return '0$n';
    }

    final twoDigitMinutes =
        twoDigits(inMinutes.remainder(Duration.minutesPerHour));
    final twoDigitSeconds =
        twoDigits(inSeconds.remainder(Duration.secondsPerMinute));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }
}
