import 'package:flutter/gestures.dart';

import 'scroll_metrics.dart';

/// A description of a scroll event.
sealed class ScrollDetails {
  const ScrollDetails({required this.metrics});

  /// Metrics describing the scroll view associated with this event.
  final ScrollMetrics metrics;
}

/// A description of a pointer scroll event.
final class PointerScrollDetails extends ScrollDetails {
  /// Creates a description of a pointer scroll event.
  const PointerScrollDetails({required super.metrics, required this.delta, required this.kind});

  /// The amount of logical pixels to adjust the current or target scroll position by.
  final double delta;

  /// The kind of a pointer device for which the event was generated.
  final PointerDeviceKind kind;
}

/// A description of a keyboard scroll event.
final class KeyboardScrollDetails extends ScrollDetails {
  /// Creates a description of a keyboard scroll event.
  const KeyboardScrollDetails({required super.metrics, required this.delta});

  /// The amount of logical pixels to adjust the current or target scroll position by.
  final double delta;
}

/// A description of a programmatic scroll event.
final class ProgrammaticScrollDetails extends ScrollDetails {
  /// Creates a description of a programmatic scroll event.
  const ProgrammaticScrollDetails({required super.metrics, required this.target});

  /// The target scroll position, expressed in logical pixels.
  final double target;
}
