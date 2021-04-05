import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/draggable/draggable.dart';

import 'package:flutter/src/widgets/basic.dart';
import 'package:flutter/src/widgets/framework.dart';

/// Makes its child draggable starting from long press.
///
/// See also:
///
///  * [Draggable], similar to the [LongPressDraggable] widget but happens immediately.
///  * [DragTarget], a widget that receives data when a [Draggable] widget is dropped.
class LongPressDraggable<T extends Object> extends Draggable<T> {
  /// Creates a widget that can be dragged starting from long press.
  ///
  /// The [child] and [feedback] arguments must not be null. If
  /// [maxSimultaneousDrags] is non-null, it must be non-negative.
  const LongPressDraggable({
    Key? key,
    required Widget child,
    required Widget feedback,
    T? data,
    Axis? axis,
    Widget? childWhenDragging,
    Offset feedbackOffset = Offset.zero,
    DragAnchor dragAnchor = DragAnchor.child,
    int? maxSimultaneousDrags,
    VoidCallback? onDragStarted,
    DragUpdateCallback? onDragUpdate,
    DraggableCanceledCallback? onDraggableCanceled,
    DragEndCallback? onDragEnd,
    VoidCallback? onDragCompleted,
    this.hapticFeedbackOnStart = true,
    bool ignoringFeedbackSemantics = true,
    this.delay = kLongPressTimeout,
  }) : super(
    key: key,
    child: child,
    feedback: feedback,
    data: data,
    axis: axis,
    childWhenDragging: childWhenDragging,
    feedbackOffset: feedbackOffset,
    dragAnchor: dragAnchor,
    maxSimultaneousDrags: maxSimultaneousDrags,
    onDragStarted: onDragStarted,
    onDragUpdate: onDragUpdate,
    onDraggableCanceled: onDraggableCanceled,
    onDragEnd: onDragEnd,
    onDragCompleted: onDragCompleted,
    ignoringFeedbackSemantics: ignoringFeedbackSemantics,
  );

  /// Whether haptic feedback should be triggered on drag start.
  final bool hapticFeedbackOnStart;

  /// The duration that a user has to press down before a long press is registered.
  ///
  /// Defaults to [kLongPressTimeout].
  final Duration delay;

  @override
  DelayedMultiDragGestureRecognizer createRecognizer(GestureMultiDragStartCallback onStart) {
    return DelayedMultiDragGestureRecognizer(delay: delay)
      ..onStart = (Offset position) {
        final Drag? result = onStart(position);
        if (result != null && hapticFeedbackOnStart)
          HapticFeedback.selectionClick();
        return result;
      };
  }
}
