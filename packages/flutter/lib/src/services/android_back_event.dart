import 'package:meta/meta.dart';

/// Enum representing the edge from which a swipe starts in a back gesture.
///
/// This is used in [AndroidBackEvent] to indicate the starting edge of the
/// swipe gesture.
enum SwipeEdge {
  /// Indicates that the swipe starts from the left edge of the screen.
  left,

  /// Indicates that the swipe starts from the right edge of the screen.
  right,
}

/// Object used to report back gesture progress in Android.
///
/// Holds information about the touch event, swipe direction and the animation
/// progress that predictive back animations should seek to.
@immutable
class AndroidBackEvent {
  /// Creates a new [AndroidBackEvent] instance.
  const AndroidBackEvent({
    required this.x,
    required this.y,
    required this.progress,
    required this.swipeEdge,
  });

  /// Creates an [AndroidBackEvent] from a Map, typically used when converting
  /// data received from a platform channel.
  factory AndroidBackEvent.fromMap(Map<dynamic, dynamic> json) {
    return AndroidBackEvent(
      x: (json['x'] as num?)?.toDouble(),
      y: (json['y'] as num?)?.toDouble(),
      progress: (json['progress'] as num).toDouble(),
      swipeEdge: SwipeEdge.values[json['swipeEdge'] as int],
    );
  }

  /// The global X location of the touch point, or `null` if the event is from a
  /// button press.
  final double? x;

  /// The global Y location of the touch point, or `null` if the event is from a
  /// button press.
  final double? y;

  /// Returns a value between 0 and 1 representing how far along the back
  /// gesture is.
  ///
  /// This value is driven by the horizontal location of the touch point, and
  /// should be used as the fraction to seek the predictive back animation with.
  /// Specifically,
  ///
  /// - The progress is 0 when the touch is at the starting edge of the screen
  ///   (left or right), and the animation should seek to its start state.
  /// - The progress is approximately 1 when the touch is at the opposite side
  ///   of the screen, and the animation should seek to its end state. Exact end
  ///   value may vary depending on screen size.
  ///
  /// When the gesture is cancelled, the progress value continues to update,
  /// animating back to 0 until the cancellation animation completes.
  ///
  /// In-between locations are linearly interpolated based on horizontal
  /// distance from the starting edge and smooth clamped to 1 when the distance
  /// exceeds a system-wide threshold.
  final double progress;

  /// The screen edge from which the swipe gesture starts.
  final SwipeEdge swipeEdge;

  /// Determines if the event was triggered by a button press.
  ///
  /// It returns true when the back button is pressed, such as when the user
  /// opts for 3-button navigation. In cases of gesture navigation, it returns
  /// false.
  bool get isButtonEvent =>
      x == null || y == null || (progress == 0 && x == 0 && y == 0);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is AndroidBackEvent &&
        x == other.x &&
        y == other.y &&
        progress == other.progress &&
        swipeEdge == other.swipeEdge;
  }

  @override
  int get hashCode => Object.hash(x, y, progress, swipeEdge);

  @override
  String toString() {
    return 'AndroidBackEvent{x: $x, y: $y, progress: $progress, swipeEdge: $swipeEdge}';
  }
}
