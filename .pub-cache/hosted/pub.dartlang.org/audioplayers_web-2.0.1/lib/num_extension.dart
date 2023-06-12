extension NumExtension on num {
  /// Converts [num] (expected in seconds) to the duration.
  Duration fromSecondsToDuration() => Duration(
        seconds: (isNaN || isInfinite ? 0 : this).round(),
      );
}
