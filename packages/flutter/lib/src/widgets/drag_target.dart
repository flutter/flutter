// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'basic.dart';
import 'binding.dart';
import 'framework.dart';
import 'media_query.dart';
import 'overlay.dart';

/// Signature for determining whether the given data will be accepted by a [DragTarget].
///
/// Used by [DragTarget.onWillAccept].
typedef DragTargetWillAccept<T> = bool Function(T? data);

/// Signature for causing a [DragTarget] to accept the given data.
///
/// Used by [DragTarget.onAccept].
typedef DragTargetAccept<T> = void Function(T data);

/// Signature for determining information about the acceptance by a [DragTarget].
///
/// Used by [DragTarget.onAcceptWithDetails].
typedef DragTargetAcceptWithDetails<T> = void Function(DragTargetDetails<T> details);

/// Signature for building children of a [DragTarget].
///
/// The `candidateData` argument contains the list of drag data that is hovering
/// over this [DragTarget] and that has passed [DragTarget.onWillAccept]. The
/// `rejectedData` argument contains the list of drag data that is hovering over
/// this [DragTarget] and that will not be accepted by the [DragTarget].
///
/// Used by [DragTarget.builder].
typedef DragTargetBuilder<T> = Widget Function(BuildContext context, List<T?> candidateData, List<dynamic> rejectedData);

/// Signature for when a [Draggable] is dragged across the screen.
///
/// Used by [Draggable.onDragUpdate].
typedef DragUpdateCallback = void Function(DragUpdateDetails details);

/// Signature for when a [Draggable] is dropped without being accepted by a [DragTarget].
///
/// Used by [Draggable.onDraggableCanceled].
typedef DraggableCanceledCallback = void Function(Velocity velocity, Offset offset);

/// Signature for when the draggable is dropped.
///
/// The velocity and offset at which the pointer was moving when the draggable
/// was dropped is available in the [DraggableDetails]. Also included in the
/// `details` is whether the draggable's [DragTarget] accepted it.
///
/// Used by [Draggable.onDragEnd].
typedef DragEndCallback = void Function(DraggableDetails details);

/// Signature for when a [Draggable] leaves a [DragTarget].
///
/// Used by [DragTarget.onLeave].
typedef DragTargetLeave<T> = void Function(T? data);

/// Signature for when a [Draggable] moves within a [DragTarget].
///
/// Used by [DragTarget.onMove].
typedef DragTargetMove<T> = void Function(DragTargetDetails<T> details);

/// Signature for the strategy that determines the drag start point of a [Draggable].
///
/// Used by [Draggable.dragAnchorStrategy].
///
/// There are two built-in strategies:
///
///  * [childDragAnchorStrategy], which displays the feedback anchored at the
///    position of the original child.
///
///  * [pointerDragAnchorStrategy], which displays the feedback anchored at the
///    position of the touch that started the drag.
typedef DragAnchorStrategy = Offset Function(Draggable<Object> draggable, BuildContext context, Offset position);

/// Display the feedback anchored at the position of the original child.
///
/// If feedback is identical to the child, then this means the feedback will
/// exactly overlap the original child when the drag starts.
///
/// This is the default [DragAnchorStrategy] and replaces [DragAnchor.child].
///
/// See also:
///
///  * [DragAnchorStrategy], the typedef that this function implements.
///  * [Draggable.dragAnchorStrategy], for which this is a built-in value.
Offset childDragAnchorStrategy(Draggable<Object> draggable, BuildContext context, Offset position) {
  final RenderBox renderObject = context.findRenderObject()! as RenderBox;
  return renderObject.globalToLocal(position);
}

/// Display the feedback anchored at the position of the touch that started
/// the drag.
///
/// If feedback is identical to the child, then this means the top left of the
/// feedback will be under the finger when the drag starts. This will likely not
/// exactly overlap the original child, e.g. if the child is big and the touch
/// was not centered. This mode is useful when the feedback is transformed so as
/// to move the feedback to the left by half its width, and up by half its width
/// plus the height of the finger, since then it appears as if putting the
/// finger down makes the touch feedback appear above the finger. (It feels
/// weird for it to appear offset from the original child if it's anchored to
/// the child and not the finger.)
///
/// This replaces [DragAnchor.pointer], which has been deprecated.
///
/// See also:
///
///  * [DragAnchorStrategy], the typedef that this function implements.
///  * [Draggable.dragAnchorStrategy], for which this is a built-in value.
Offset pointerDragAnchorStrategy(Draggable<Object> draggable, BuildContext context, Offset position) {
  return Offset.zero;
}

/// Where the [Draggable] should be anchored during a drag.
///
/// This has been replaced by the more configurable [DragAnchorStrategy].
@Deprecated(
  'Use dragAnchorStrategy instead. '
  'This feature was deprecated after v2.1.0-10.0.pre.',
)
enum DragAnchor {
  /// Display the feedback anchored at the position of the original child.
  ///
  /// Replaced by [childDragAnchorStrategy].
  @Deprecated(
    'Use childDragAnchorStrategy instead. '
    'This feature was deprecated after v2.1.0-10.0.pre.',
  )
  child,

  /// Display the feedback anchored at the position of the touch that started
  /// the drag.
  ///
  /// Replaced by [pointerDragAnchorStrategy].
  @Deprecated(
    'Use pointerDragAnchorStrategy instead. '
    'This feature was deprecated after v2.1.0-10.0.pre.',
  )
  pointer,
}

/// A widget that can be dragged from to a [DragTarget].
///
/// When a draggable widget recognizes the start of a drag gesture, it displays
/// a [feedback] widget that tracks the user's finger across the screen. If the
/// user lifts their finger while on top of a [DragTarget], that target is given
/// the opportunity to accept the [data] carried by the draggable.
///
/// On multitouch devices, multiple drags can occur simultaneously because there
/// can be multiple pointers in contact with the device at once. To limit the
/// number of simultaneous drags, use the [maxSimultaneousDrags] property. The
/// default is to allow an unlimited number of simultaneous drags.
///
/// This widget displays [child] when zero drags are under way. If
/// [childWhenDragging] is non-null, this widget instead displays
/// [childWhenDragging] when one or more drags are underway. Otherwise, this
/// widget always displays [child].
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=QzA4c4QHZCY}
///
/// {@tool dartpad}
/// The following example has a [Draggable] widget along with a [DragTarget]
/// in a row demonstrating an incremented `acceptedData` integer value when
/// you drag the element to the target.
///
/// ** See code in examples/api/lib/widgets/drag_target/draggable.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [DragTarget]
///  * [LongPressDraggable]
class Draggable<T extends Object> extends StatefulWidget {
  /// Creates a widget that can be dragged to a [DragTarget].
  ///
  /// The [child] and [feedback] arguments must not be null. If
  /// [maxSimultaneousDrags] is non-null, it must be non-negative.
  const Draggable({
    Key? key,
    required this.child,
    required this.feedback,
    this.data,
    this.axis,
    this.childWhenDragging,
    this.feedbackOffset = Offset.zero,
    @Deprecated(
      'Use dragAnchorStrategy instead. '
      'Replace "dragAnchor: DragAnchor.child" with "dragAnchorStrategy: childDragAnchorStrategy". '
      'Replace "dragAnchor: DragAnchor.pointer" with "dragAnchorStrategy: pointerDragAnchorStrategy". '
      'This feature was deprecated after v2.1.0-10.0.pre.',
    )
    this.dragAnchor = DragAnchor.child,
    this.dragAnchorStrategy,
    this.affinity,
    this.maxSimultaneousDrags,
    this.onDragStarted,
    this.onDragUpdate,
    this.onDraggableCanceled,
    this.onDragEnd,
    this.onDragCompleted,
    this.ignoringFeedbackSemantics = true,
    this.rootOverlay = false,
    this.hitTestBehavior = HitTestBehavior.deferToChild,
  }) : assert(child != null),
       assert(feedback != null),
       assert(ignoringFeedbackSemantics != null),
       assert(maxSimultaneousDrags == null || maxSimultaneousDrags >= 0),
       super(key: key);

  /// The data that will be dropped by this draggable.
  final T? data;

  /// The [Axis] to restrict this draggable's movement, if specified.
  ///
  /// When axis is set to [Axis.horizontal], this widget can only be dragged
  /// horizontally. Behavior is similar for [Axis.vertical].
  ///
  /// Defaults to allowing drag on both [Axis.horizontal] and [Axis.vertical].
  ///
  /// When null, allows drag on both [Axis.horizontal] and [Axis.vertical].
  ///
  /// For the direction of gestures this widget competes with to start a drag
  /// event, see [Draggable.affinity].
  final Axis? axis;

  /// The widget below this widget in the tree.
  ///
  /// This widget displays [child] when zero drags are under way. If
  /// [childWhenDragging] is non-null, this widget instead displays
  /// [childWhenDragging] when one or more drags are underway. Otherwise, this
  /// widget always displays [child].
  ///
  /// The [feedback] widget is shown under the pointer when a drag is under way.
  ///
  /// To limit the number of simultaneous drags on multitouch devices, see
  /// [maxSimultaneousDrags].
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  /// The widget to display instead of [child] when one or more drags are under way.
  ///
  /// If this is null, then this widget will always display [child] (and so the
  /// drag source representation will not change while a drag is under
  /// way).
  ///
  /// The [feedback] widget is shown under the pointer when a drag is under way.
  ///
  /// To limit the number of simultaneous drags on multitouch devices, see
  /// [maxSimultaneousDrags].
  final Widget? childWhenDragging;

  /// The widget to show under the pointer when a drag is under way.
  ///
  /// See [child] and [childWhenDragging] for information about what is shown
  /// at the location of the [Draggable] itself when a drag is under way.
  final Widget feedback;

  /// The feedbackOffset can be used to set the hit test target point for the
  /// purposes of finding a drag target. It is especially useful if the feedback
  /// is transformed compared to the child.
  final Offset feedbackOffset;

  /// Where this widget should be anchored during a drag.
  ///
  /// This property is overridden by the [dragAnchorStrategy] if the latter is provided.
  ///
  /// Defaults to [DragAnchor.child].
  @Deprecated(
    'Use dragAnchorStrategy instead. '
    'This feature was deprecated after v2.1.0-10.0.pre.',
  )
  final DragAnchor dragAnchor;

  /// A strategy that is used by this draggable to get the anchor offset when it
  /// is dragged.
  ///
  /// The anchor offset refers to the distance between the users' fingers and
  /// the [feedback] widget when this draggable is dragged.
  ///
  /// This property's value is a function that implements [DragAnchorStrategy].
  /// There are two built-in functions that can be used:
  ///
  ///  * [childDragAnchorStrategy], which displays the feedback anchored at the
  ///    position of the original child.
  ///
  ///  * [pointerDragAnchorStrategy], which displays the feedback anchored at the
  ///    position of the touch that started the drag.
  ///
  /// Defaults to [childDragAnchorStrategy] if the deprecated [dragAnchor]
  /// property is set to [DragAnchor.child], and [pointerDragAnchorStrategy] if
  /// the [dragAnchor] is set to [DragAnchor.pointer].
  final DragAnchorStrategy? dragAnchorStrategy;

  /// Whether the semantics of the [feedback] widget is ignored when building
  /// the semantics tree.
  ///
  /// This value should be set to false when the [feedback] widget is intended
  /// to be the same object as the [child].  Placing a [GlobalKey] on this
  /// widget will ensure semantic focus is kept on the element as it moves in
  /// and out of the feedback position.
  ///
  /// Defaults to true.
  final bool ignoringFeedbackSemantics;

  /// Controls how this widget competes with other gestures to initiate a drag.
  ///
  /// If affinity is null, this widget initiates a drag as soon as it recognizes
  /// a tap down gesture, regardless of any directionality. If affinity is
  /// horizontal (or vertical), then this widget will compete with other
  /// horizontal (or vertical, respectively) gestures.
  ///
  /// For example, if this widget is placed in a vertically scrolling region and
  /// has horizontal affinity, pointer motion in the vertical direction will
  /// result in a scroll and pointer motion in the horizontal direction will
  /// result in a drag. Conversely, if the widget has a null or vertical
  /// affinity, pointer motion in any direction will result in a drag rather
  /// than in a scroll because the draggable widget, being the more specific
  /// widget, will out-compete the [Scrollable] for vertical gestures.
  ///
  /// For the directions this widget can be dragged in after the drag event
  /// starts, see [Draggable.axis].
  final Axis? affinity;

  /// How many simultaneous drags to support.
  ///
  /// When null, no limit is applied. Set this to 1 if you want to only allow
  /// the drag source to have one item dragged at a time. Set this to 0 if you
  /// want to prevent the draggable from actually being dragged.
  ///
  /// If you set this property to 1, consider supplying an "empty" widget for
  /// [childWhenDragging] to create the illusion of actually moving [child].
  final int? maxSimultaneousDrags;

  /// Called when the draggable starts being dragged.
  final VoidCallback? onDragStarted;

  /// Called when the draggable is dragged.
  ///
  /// This function will only be called while this widget is still mounted to
  /// the tree (i.e. [State.mounted] is true), and if this widget has actually moved.
  final DragUpdateCallback? onDragUpdate;

  /// Called when the draggable is dropped without being accepted by a [DragTarget].
  ///
  /// This function might be called after this widget has been removed from the
  /// tree. For example, if a drag was in progress when this widget was removed
  /// from the tree and the drag ended up being canceled, this callback will
  /// still be called. For this reason, implementations of this callback might
  /// need to check [State.mounted] to check whether the state receiving the
  /// callback is still in the tree.
  final DraggableCanceledCallback? onDraggableCanceled;

  /// Called when the draggable is dropped and accepted by a [DragTarget].
  ///
  /// This function might be called after this widget has been removed from the
  /// tree. For example, if a drag was in progress when this widget was removed
  /// from the tree and the drag ended up completing, this callback will
  /// still be called. For this reason, implementations of this callback might
  /// need to check [State.mounted] to check whether the state receiving the
  /// callback is still in the tree.
  final VoidCallback? onDragCompleted;

  /// Called when the draggable is dropped.
  ///
  /// The velocity and offset at which the pointer was moving when it was
  /// dropped is available in the [DraggableDetails]. Also included in the
  /// `details` is whether the draggable's [DragTarget] accepted it.
  ///
  /// This function will only be called while this widget is still mounted to
  /// the tree (i.e. [State.mounted] is true).
  final DragEndCallback? onDragEnd;

  /// Whether the feedback widget will be put on the root [Overlay].
  ///
  /// When false, the feedback widget will be put on the closest [Overlay]. When
  /// true, the [feedback] widget will be put on the farthest (aka root)
  /// [Overlay].
  ///
  /// Defaults to false.
  final bool rootOverlay;

  /// How to behave during hit test.
  ///
  /// Defaults to [HitTestBehavior.deferToChild].
  final HitTestBehavior hitTestBehavior;

  /// Creates a gesture recognizer that recognizes the start of the drag.
  ///
  /// Subclasses can override this function to customize when they start
  /// recognizing a drag.
  @protected
  MultiDragGestureRecognizer createRecognizer(GestureMultiDragStartCallback onStart) {
    switch (affinity) {
      case Axis.horizontal:
        return HorizontalMultiDragGestureRecognizer()..onStart = onStart;
      case Axis.vertical:
        return VerticalMultiDragGestureRecognizer()..onStart = onStart;
      case null:
        return ImmediateMultiDragGestureRecognizer()..onStart = onStart;
    }
  }

  @override
  State<Draggable<T>> createState() => _DraggableState<T>();
}

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
    @Deprecated(
      'Use dragAnchorStrategy instead. '
      'Replace "dragAnchor: DragAnchor.child" with "dragAnchorStrategy: childDragAnchorStrategy". '
      'Replace "dragAnchor: DragAnchor.pointer" with "dragAnchorStrategy: pointerDragAnchorStrategy". '
      'This feature was deprecated after v2.1.0-10.0.pre.',
    )
    DragAnchor dragAnchor = DragAnchor.child,
    DragAnchorStrategy? dragAnchorStrategy,
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
    dragAnchorStrategy: dragAnchorStrategy,
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

class _DraggableState<T extends Object> extends State<Draggable<T>> {
  @override
  void initState() {
    super.initState();
    _recognizer = widget.createRecognizer(_startDrag);
  }

  @override
  void dispose() {
    _disposeRecognizerIfInactive();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    _recognizer!.gestureSettings = MediaQuery.maybeOf(context)?.gestureSettings;
    super.didChangeDependencies();
  }

  // This gesture recognizer has an unusual lifetime. We want to support the use
  // case of removing the Draggable from the tree in the middle of a drag. That
  // means we need to keep this recognizer alive after this state object has
  // been disposed because it's the one listening to the pointer events that are
  // driving the drag.
  //
  // We achieve that by keeping count of the number of active drags and only
  // disposing the gesture recognizer after (a) this state object has been
  // disposed and (b) there are no more active drags.
  GestureRecognizer? _recognizer;
  int _activeCount = 0;

  void _disposeRecognizerIfInactive() {
    if (_activeCount > 0)
      return;
    _recognizer!.dispose();
    _recognizer = null;
  }

  void _routePointer(PointerDownEvent event) {
    if (widget.maxSimultaneousDrags != null && _activeCount >= widget.maxSimultaneousDrags!)
      return;
    _recognizer!.addPointer(event);
  }

  _DragAvatar<T>? _startDrag(Offset position) {
    if (widget.maxSimultaneousDrags != null && _activeCount >= widget.maxSimultaneousDrags!)
      return null;
    final Offset dragStartPoint;
    if (widget.dragAnchorStrategy == null) {
      switch (widget.dragAnchor) {
        case DragAnchor.child:
          dragStartPoint = childDragAnchorStrategy(widget, context, position);
          break;
        case DragAnchor.pointer:
          dragStartPoint = pointerDragAnchorStrategy(widget, context, position);
          break;
      }
    } else {
      dragStartPoint = widget.dragAnchorStrategy!(widget, context, position);
    }
    setState(() {
      _activeCount += 1;
    });
    final _DragAvatar<T> avatar = _DragAvatar<T>(
      overlayState: Overlay.of(context, debugRequiredFor: widget, rootOverlay: widget.rootOverlay)!,
      data: widget.data,
      axis: widget.axis,
      initialPosition: position,
      dragStartPoint: dragStartPoint,
      feedback: widget.feedback,
      feedbackOffset: widget.feedbackOffset,
      ignoringFeedbackSemantics: widget.ignoringFeedbackSemantics,
      onDragUpdate: (DragUpdateDetails details) {
        if (mounted && widget.onDragUpdate != null) {
          widget.onDragUpdate!(details);
        }
      },
      onDragEnd: (Velocity velocity, Offset offset, bool wasAccepted) {
        if (mounted) {
          setState(() {
            _activeCount -= 1;
          });
        } else {
          _activeCount -= 1;
          _disposeRecognizerIfInactive();
        }
        if (mounted && widget.onDragEnd != null) {
          widget.onDragEnd!(DraggableDetails(
              wasAccepted: wasAccepted,
              velocity: velocity,
              offset: offset,
          ));
        }
        if (wasAccepted && widget.onDragCompleted != null)
          widget.onDragCompleted!();
        if (!wasAccepted && widget.onDraggableCanceled != null)
          widget.onDraggableCanceled!(velocity, offset);
      },
    );
    widget.onDragStarted?.call();
    return avatar;
  }

  @override
  Widget build(BuildContext context) {
    assert(Overlay.of(context, debugRequiredFor: widget, rootOverlay: widget.rootOverlay) != null);
    final bool canDrag = widget.maxSimultaneousDrags == null ||
                         _activeCount < widget.maxSimultaneousDrags!;
    final bool showChild = _activeCount == 0 || widget.childWhenDragging == null;
    return Listener(
      behavior: widget.hitTestBehavior,
      onPointerDown: canDrag ? _routePointer : null,
      child: showChild ? widget.child : widget.childWhenDragging,
    );
  }
}

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

/// Represents the details when a pointer event occurred on the [DragTarget].
class DragTargetDetails<T> {
  /// Creates details for a [DragTarget] callback.
  ///
  /// The [offset] must not be null.
  DragTargetDetails({required this.data, required this.offset}) : assert(offset != null);

  /// The data that was dropped onto this [DragTarget].
  final T data;

  /// The global position when the specific pointer event occurred on
  /// the draggable.
  final Offset offset;
}

/// A widget that receives data when a [Draggable] widget is dropped.
///
/// When a draggable is dragged on top of a drag target, the drag target is
/// asked whether it will accept the data the draggable is carrying. If the user
/// does drop the draggable on top of the drag target (and the drag target has
/// indicated that it will accept the draggable's data), then the drag target is
/// asked to accept the draggable's data.
///
/// See also:
///
///  * [Draggable]
///  * [LongPressDraggable]
class DragTarget<T extends Object> extends StatefulWidget {
  /// Creates a widget that receives drags.
  ///
  /// The [builder] argument must not be null.
  const DragTarget({
    Key? key,
    required this.builder,
    this.onWillAccept,
    this.onAccept,
    this.onAcceptWithDetails,
    this.onLeave,
    this.onMove,
    this.hitTestBehavior = HitTestBehavior.translucent,
  }) : super(key: key);

  /// Called to build the contents of this widget.
  ///
  /// The builder can build different widgets depending on what is being dragged
  /// into this drag target.
  final DragTargetBuilder<T> builder;

  /// Called to determine whether this widget is interested in receiving a given
  /// piece of data being dragged over this drag target.
  ///
  /// Called when a piece of data enters the target. This will be followed by
  /// either [onAccept] and [onAcceptWithDetails], if the data is dropped, or
  /// [onLeave], if the drag leaves the target.
  final DragTargetWillAccept<T>? onWillAccept;

  /// Called when an acceptable piece of data was dropped over this drag target.
  ///
  /// Equivalent to [onAcceptWithDetails], but only includes the data.
  final DragTargetAccept<T>? onAccept;

  /// Called when an acceptable piece of data was dropped over this drag target.
  ///
  /// Equivalent to [onAccept], but with information, including the data, in a
  /// [DragTargetDetails].
  final DragTargetAcceptWithDetails<T>? onAcceptWithDetails;

  /// Called when a given piece of data being dragged over this target leaves
  /// the target.
  final DragTargetLeave<T>? onLeave;

  /// Called when a [Draggable] moves within this [DragTarget].
  ///
  /// Note that this includes entering and leaving the target.
  final DragTargetMove<T>? onMove;

  /// How to behave during hit testing.
  ///
  /// Defaults to [HitTestBehavior.translucent].
  final HitTestBehavior hitTestBehavior;

  @override
  State<DragTarget<T>> createState() => _DragTargetState<T>();
}

List<T?> _mapAvatarsToData<T extends Object>(List<_DragAvatar<Object>> avatars) {
  return avatars.map<T?>((_DragAvatar<Object> avatar) => avatar.data as T?).toList();
}

class _DragTargetState<T extends Object> extends State<DragTarget<T>> {
  final List<_DragAvatar<Object>> _candidateAvatars = <_DragAvatar<Object>>[];
  final List<_DragAvatar<Object>> _rejectedAvatars = <_DragAvatar<Object>>[];

  // On non-web platforms, checks if data Object is equal to type[T] or subtype of [T].
  // On web, it does the same, but requires a check for ints and doubles
  // because dart doubles and ints are backed by the same kind of object on web.
  // JavaScript does not support integers.
  bool isExpectedDataType(Object? data, Type type) {
    if (kIsWeb && ((type == int && T == double) || (type == double && T == int)))
      return false;
    return data is T?;
  }

  bool didEnter(_DragAvatar<Object> avatar) {
    assert(!_candidateAvatars.contains(avatar));
    assert(!_rejectedAvatars.contains(avatar));
    if (widget.onWillAccept == null || widget.onWillAccept!(avatar.data as T?)) {
      setState(() {
        _candidateAvatars.add(avatar);
      });
      return true;
    } else {
      setState(() {
        _rejectedAvatars.add(avatar);
      });
      return false;
    }
  }

  void didLeave(_DragAvatar<Object> avatar) {
    assert(_candidateAvatars.contains(avatar) || _rejectedAvatars.contains(avatar));
    if (!mounted)
      return;
    setState(() {
      _candidateAvatars.remove(avatar);
      _rejectedAvatars.remove(avatar);
    });
    widget.onLeave?.call(avatar.data as T?);
  }

  void didDrop(_DragAvatar<Object> avatar) {
    assert(_candidateAvatars.contains(avatar));
    if (!mounted)
      return;
    setState(() {
      _candidateAvatars.remove(avatar);
    });
    widget.onAccept?.call(avatar.data! as T);
    widget.onAcceptWithDetails?.call(DragTargetDetails<T>(data: avatar.data! as T, offset: avatar._lastOffset!));
  }

  void didMove(_DragAvatar<Object> avatar) {
    if (!mounted)
      return;
    widget.onMove?.call(DragTargetDetails<T>(data: avatar.data! as T, offset: avatar._lastOffset!));
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.builder != null);
    return MetaData(
      metaData: this,
      behavior: widget.hitTestBehavior,
      child: widget.builder(context, _mapAvatarsToData<T>(_candidateAvatars), _mapAvatarsToData<Object>(_rejectedAvatars)),
    );
  }
}

enum _DragEndKind { dropped, canceled }
typedef _OnDragEnd = void Function(Velocity velocity, Offset offset, bool wasAccepted);

// The lifetime of this object is a little dubious right now. Specifically, it
// lives as long as the pointer is down. Arguably it should self-immolate if the
// overlay goes away. _DraggableState has some delicate logic to continue
// needing this object pointer events even after it has been disposed.
class _DragAvatar<T extends Object> extends Drag {
  _DragAvatar({
    required this.overlayState,
    this.data,
    this.axis,
    required Offset initialPosition,
    this.dragStartPoint = Offset.zero,
    this.feedback,
    this.feedbackOffset = Offset.zero,
    this.onDragUpdate,
    this.onDragEnd,
    required this.ignoringFeedbackSemantics,
  }) : assert(overlayState != null),
       assert(ignoringFeedbackSemantics != null),
       assert(dragStartPoint != null),
       assert(feedbackOffset != null),
       _position = initialPosition {
    _entry = OverlayEntry(builder: _build);
    overlayState.insert(_entry!);
    updateDrag(initialPosition);
  }

  final T? data;
  final Axis? axis;
  final Offset dragStartPoint;
  final Widget? feedback;
  final Offset feedbackOffset;
  final DragUpdateCallback? onDragUpdate;
  final _OnDragEnd? onDragEnd;
  final OverlayState overlayState;
  final bool ignoringFeedbackSemantics;

  _DragTargetState<Object>? _activeTarget;
  final List<_DragTargetState<Object>> _enteredTargets = <_DragTargetState<Object>>[];
  Offset _position;
  Offset? _lastOffset;
  OverlayEntry? _entry;

  @override
  void update(DragUpdateDetails details) {
    final Offset oldPosition = _position;
    _position += _restrictAxis(details.delta);
    updateDrag(_position);
    if (onDragUpdate != null && _position != oldPosition) {
      onDragUpdate!(details);
    }
  }

  @override
  void end(DragEndDetails details) {
    finishDrag(_DragEndKind.dropped, _restrictVelocityAxis(details.velocity));
  }


  @override
  void cancel() {
    finishDrag(_DragEndKind.canceled);
  }

  void updateDrag(Offset globalPosition) {
    _lastOffset = globalPosition - dragStartPoint;
    _entry!.markNeedsBuild();
    final HitTestResult result = HitTestResult();
    WidgetsBinding.instance.hitTest(result, globalPosition + feedbackOffset);

    final List<_DragTargetState<Object>> targets = _getDragTargets(result.path).toList();

    bool listsMatch = false;
    if (targets.length >= _enteredTargets.length && _enteredTargets.isNotEmpty) {
      listsMatch = true;
      final Iterator<_DragTargetState<Object>> iterator = targets.iterator;
      for (int i = 0; i < _enteredTargets.length; i += 1) {
        iterator.moveNext();
        if (iterator.current != _enteredTargets[i]) {
          listsMatch = false;
          break;
        }
      }
    }

    // If everything's the same, report moves, and bail early.
    if (listsMatch) {
      for (final _DragTargetState<Object> target in _enteredTargets) {
        target.didMove(this);
      }
      return;
    }

    // Leave old targets.
    _leaveAllEntered();

    // Enter new targets.
    final _DragTargetState<Object>? newTarget = targets.cast<_DragTargetState<Object>?>().firstWhere(
      (_DragTargetState<Object>? target) {
        if (target == null)
          return false;
        _enteredTargets.add(target);
        return target.didEnter(this);
      },
      orElse: () => null,
    );

    // Report moves to the targets.
    for (final _DragTargetState<Object> target in _enteredTargets) {
      target.didMove(this);
    }

    _activeTarget = newTarget;
  }

  Iterable<_DragTargetState<Object>> _getDragTargets(Iterable<HitTestEntry> path) {
    // Look for the RenderBoxes that corresponds to the hit target (the hit target
    // widgets build RenderMetaData boxes for us for this purpose).
    final List<_DragTargetState<Object>> targets = <_DragTargetState<Object>>[];
    for (final HitTestEntry entry in path) {
      final HitTestTarget target = entry.target;
      if (target is RenderMetaData) {
        final dynamic metaData = target.metaData;
        if (metaData is _DragTargetState && metaData.isExpectedDataType(data, T))
          targets.add(metaData);
      }
    }
    return targets;
  }

  void _leaveAllEntered() {
    for (int i = 0; i < _enteredTargets.length; i += 1)
      _enteredTargets[i].didLeave(this);
    _enteredTargets.clear();
  }

  void finishDrag(_DragEndKind endKind, [ Velocity? velocity ]) {
    bool wasAccepted = false;
    if (endKind == _DragEndKind.dropped && _activeTarget != null) {
      _activeTarget!.didDrop(this);
      wasAccepted = true;
      _enteredTargets.remove(_activeTarget);
    }
    _leaveAllEntered();
    _activeTarget = null;
    _entry!.remove();
    _entry = null;
    // TODO(ianh): consider passing _entry as well so the client can perform an animation.
    onDragEnd?.call(velocity ?? Velocity.zero, _lastOffset!, wasAccepted);
  }

  Widget _build(BuildContext context) {
    final RenderBox box = overlayState.context.findRenderObject()! as RenderBox;
    final Offset overlayTopLeft = box.localToGlobal(Offset.zero);
    return Positioned(
      left: _lastOffset!.dx - overlayTopLeft.dx,
      top: _lastOffset!.dy - overlayTopLeft.dy,
      child: IgnorePointer(
        ignoringSemantics: ignoringFeedbackSemantics,
        child: feedback,
      ),
    );
  }

  Velocity _restrictVelocityAxis(Velocity velocity) {
    if (axis == null) {
      return velocity;
    }
    return Velocity(
      pixelsPerSecond: _restrictAxis(velocity.pixelsPerSecond),
    );
  }

  Offset _restrictAxis(Offset offset) {
    if (axis == null) {
      return offset;
    }
    if (axis == Axis.horizontal) {
      return Offset(offset.dx, 0.0);
    }
    return Offset(0.0, offset.dy);
  }
}
