/// Enum representing the edge from which a swipe starts in a back gesture.
///
/// This is used in [AndroidBackEvent] to indicate the starting edge of the
/// swipe.
enum SwipeEdge {
  /// Indicates that the edge swipe starts from the left edge of the screen.
  left,

  /// Indicates that the edge swipe starts from the right edge of the screen.
  right,
}

/// Object used to report back gesture progress in Android.
///
/// Holds information about the touch event, swipe direction and the animation
/// progress that predictive back animations should seek to.
class AndroidBackEvent {
  /// Creates a new [AndroidBackEvent] instance.
  const AndroidBackEvent({
    required this.touchX,
    required this.touchY,
    required this.progress,
    required this.swipeEdge,
  });

  /// Creates an [AndroidBackEvent] from a Map, typically used when converting
  /// data received from a platform channel.
  factory AndroidBackEvent.fromMap(Map<dynamic, dynamic> json) {
    return AndroidBackEvent(
      touchX: (json['touchX'] as num?)?.toDouble(),
      touchY: (json['touchY'] as num?)?.toDouble(),
      progress: (json['progress'] as num).toDouble(),
      swipeEdge: SwipeEdge.values[json['swipeEdge'] as int],
    );
  }

  /// The absolute X location of the touch point, or `null` if the event is from
  /// a button press.
  final double? touchX;

  /// The absolute Y location of the touch point, or `null` if the event is from
  /// a button press.
  final double? touchY;

  /// A value between 0 and 1 on how far along the back gesture is. This value
  /// is driven by the horizontal location of the touch point, and should be
  /// used as the fraction to seek the predictive back animation with.
  /// Specifically,
  /// - The progress is 0 when the touch is at the starting edge of the screen
  ///   (left or right), and animation should seek to its start state.
  /// - The progress is approximately 1 when the touch is at the opposite side
  ///   of the screen, and animation should seek to its end state. Exact end
  ///   value may vary depending on screen size.
  ///
  /// After the gesture finishes in cancel state, this method keeps getting
  /// invoked until the progress value animates back to 0.
  ///
  /// In-between locations are linearly interpolated based on horizontal
  /// distance from the starting edge and smooth clamped to 1 when the distance
  /// exceeds a system-wide threshold.
  final double progress;

  /// The screen edge from which the swipe starts.
  final SwipeEdge swipeEdge;

  @override
  String toString() {
    return 'AndroidBackEvent{touchX: $touchX, touchY: $touchY, progress: $progress, swipeEdge: $swipeEdge}';
  }
}
