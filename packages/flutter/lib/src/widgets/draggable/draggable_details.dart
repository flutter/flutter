import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

/// Represents the details when a specific pointer event occurred on
/// the [Draggable].
///
/// This includes the [Velocity] at which the pointer was moving and [Offset]
/// when the draggable event occurred, and whether its [DragTarget] accepted it.
///
/// Also, this is the details object for callbacks that use [DragEndCallback].
class DraggableDetails {
  /// Creates details for a [DraggableDetails].
  ///
  /// If [wasAccepted] is not specified, it will default to `false`.
  ///
  /// The [velocity] or [offset] arguments must not be `null`.
  DraggableDetails({
    this.wasAccepted = false,
    required this.velocity,
    required this.offset,
  }) : assert(velocity != null),
        assert(offset != null);

  /// Determines whether the [DragTarget] accepted this draggable.
  final bool wasAccepted;

  /// The velocity at which the pointer was moving when the specific pointer
  /// event occurred on the draggable.
  final Velocity velocity;

  /// The global position when the specific pointer event occurred on
  /// the draggable.
  final Offset offset;
}
