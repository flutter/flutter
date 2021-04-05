import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

import 'package:flutter/src/widgets/basic.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/overlay.dart';

import 'drag_avatar.dart';
import 'draggable.dart';

/// State for Draggable
class DraggableState<T extends Object> extends State<Draggable<T>> {
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

  DragAvatar<T>? _startDrag(Offset position) {
    if (widget.maxSimultaneousDrags != null && _activeCount >= widget.maxSimultaneousDrags!)
      return null;
    final Offset dragStartPoint;
    switch (widget.dragAnchor) {
      case DragAnchor.child:
        final RenderBox renderObject = context.findRenderObject()! as RenderBox;
        dragStartPoint = renderObject.globalToLocal(position);
        break;
      case DragAnchor.pointer:
        dragStartPoint = Offset.zero;
        break;
    }
    setState(() {
      _activeCount += 1;
    });
    final DragAvatar<T> avatar = DragAvatar<T>(
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
    if (widget.onDragStarted != null)
      widget.onDragStarted!();
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
