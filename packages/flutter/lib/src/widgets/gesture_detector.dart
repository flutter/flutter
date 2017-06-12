// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';

export 'package:flutter/gestures.dart' show
  DragDownDetails,
  DragStartDetails,
  DragUpdateDetails,
  DragEndDetails,
  GestureTapDownCallback,
  GestureTapUpCallback,
  GestureTapCallback,
  GestureTapCancelCallback,
  GestureLongPressCallback,
  GestureDragDownCallback,
  GestureDragStartCallback,
  GestureDragUpdateCallback,
  GestureDragEndCallback,
  GestureDragCancelCallback,
  GestureScaleStartCallback,
  GestureScaleUpdateCallback,
  GestureScaleEndCallback,
  ScaleStartDetails,
  ScaleUpdateDetails,
  ScaleEndDetails,
  TapDownDetails,
  TapUpDetails,
  Velocity;

/// Signature for creating gesture recognizers.
///
/// The `recognizer` argument is the gesture recognizer that currently occupies
/// the slot for which a gesture recognizer is being created.
///
/// Used by [RawGestureDetector.gestures].
typedef GestureRecognizer GestureRecognizerFactory(GestureRecognizer recognizer);

/// A widget that detects gestures.
///
/// Attempts to recognize gestures that correspond to its non-null callbacks.
///
/// If this widget has a child, it defers to that child for its sizing behavior.
/// If it does not have a child, it grows to fit the parent instead.
///
/// GestureDetector also listens for accessibility events and maps
/// them to the callbacks. To ignore accessibility events, set
/// [excludeFromSemantics] to true.
///
/// See <http://flutter.io/gestures/> for additional information.
///
/// Material design applications typically react to touches with ink splash
/// effects. The [InkWell] class implements this effect and can be used in place
/// of a [GestureDetector] for handling taps.
class GestureDetector extends StatelessWidget {
  /// Creates a widget that detects gestures.
  ///
  /// Pan and scale callbacks cannot be used simultaneously because scale is a
  /// superset of pan. Simply use the scale callbacks instead.
  ///
  /// Horizontal and vertical drag callbacks cannot be used simultaneously
  /// because a combination of a horizontal and vertical drag is a pan. Simply
  /// use the pan callbacks instead.
  ///
  /// By default, gesture detectors contribute semantic information to the tree
  /// that is used by assistive technology.
  GestureDetector({
    Key key,
    this.child,
    this.onTapDown,
    this.onTapUp,
    this.onTap,
    this.onTapCancel,
    this.onDoubleTap,
    this.onLongPress,
    this.onVerticalDragDown,
    this.onVerticalDragStart,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
    this.onVerticalDragCancel,
    this.onHorizontalDragDown,
    this.onHorizontalDragStart,
    this.onHorizontalDragUpdate,
    this.onHorizontalDragEnd,
    this.onHorizontalDragCancel,
    this.onPanDown,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onPanCancel,
    this.onScaleStart,
    this.onScaleUpdate,
    this.onScaleEnd,
    this.behavior,
    this.excludeFromSemantics: false
  }) : assert(excludeFromSemantics != null),
       assert(() {
         final bool haveVerticalDrag = onVerticalDragStart != null || onVerticalDragUpdate != null || onVerticalDragEnd != null;
         final bool haveHorizontalDrag = onHorizontalDragStart != null || onHorizontalDragUpdate != null || onHorizontalDragEnd != null;
         final bool havePan = onPanStart != null || onPanUpdate != null || onPanEnd != null;
         final bool haveScale = onScaleStart != null || onScaleUpdate != null || onScaleEnd != null;
         if (havePan || haveScale) {
           if (havePan && haveScale) {
             throw new FlutterError(
               'Incorrect GestureDetector arguments.\n'
               'Having both a pan gesture recognizer and a scale gesture recognizer is redundant; scale is a superset of pan. Just use the scale gesture recognizer.'
             );
           }
           final String recognizer = havePan ? 'pan' : 'scale';
           if (haveVerticalDrag && haveHorizontalDrag) {
             throw new FlutterError(
               'Incorrect GestureDetector arguments.\n'
               'Simultaneously having a vertical drag gesture recognizer, a horizontal drag gesture recognizer, and a $recognizer gesture recognizer '
               'will result in the $recognizer gesture recognizer being ignored, since the other two will catch all drags.'
             );
           }
         }
         return true;
       }),
       super(key: key);

  /// The widget below this widget in the tree.
  final Widget child;

  /// A pointer that might cause a tap has contacted the screen at a particular
  /// location.
  final GestureTapDownCallback onTapDown;

  /// A pointer that will trigger a tap has stopped contacting the screen at a
  /// particular location.
  final GestureTapUpCallback onTapUp;

  /// A tap has occurred.
  final GestureTapCallback onTap;

  /// The pointer that previously triggered [onTapDown] will not end up causing
  /// a tap.
  final GestureTapCancelCallback onTapCancel;

  /// The user has tapped the screen at the same location twice in quick
  /// succession.
  final GestureTapCallback onDoubleTap;

  /// A pointer has remained in contact with the screen at the same location for
  /// a long period of time.
  final GestureLongPressCallback onLongPress;

  /// A pointer has contacted the screen and might begin to move vertically.
  final GestureDragDownCallback onVerticalDragDown;

  /// A pointer has contacted the screen and has begun to move vertically.
  final GestureDragStartCallback onVerticalDragStart;

  /// A pointer that is in contact with the screen and moving vertically has
  /// moved in the vertical direction.
  final GestureDragUpdateCallback onVerticalDragUpdate;

  /// A pointer that was previously in contact with the screen and moving
  /// vertically is no longer in contact with the screen and was moving at a
  /// specific velocity when it stopped contacting the screen.
  final GestureDragEndCallback onVerticalDragEnd;

  /// The pointer that previously triggered [onVerticalDragDown] did not
  /// complete.
  final GestureDragCancelCallback onVerticalDragCancel;

  /// A pointer has contacted the screen and might begin to move horizontally.
  final GestureDragDownCallback onHorizontalDragDown;

  /// A pointer has contacted the screen and has begun to move horizontally.
  final GestureDragStartCallback onHorizontalDragStart;

  /// A pointer that is in contact with the screen and moving horizontally has
  /// moved in the horizontal direction.
  final GestureDragUpdateCallback onHorizontalDragUpdate;

  /// A pointer that was previously in contact with the screen and moving
  /// horizontally is no longer in contact with the screen and was moving at a
  /// specific velocity when it stopped contacting the screen.
  final GestureDragEndCallback onHorizontalDragEnd;

  /// The pointer that previously triggered [onHorizontalDragDown] did not
  /// complete.
  final GestureDragCancelCallback onHorizontalDragCancel;

  /// A pointer has contacted the screen and might begin to move.
  final GestureDragDownCallback onPanDown;

  /// A pointer has contacted the screen and has begun to move.
  final GestureDragStartCallback onPanStart;

  /// A pointer that is in contact with the screen and moving has moved again.
  final GestureDragUpdateCallback onPanUpdate;

  /// A pointer that was previously in contact with the screen and moving
  /// is no longer in contact with the screen and was moving at a specific
  /// velocity when it stopped contacting the screen.
  final GestureDragEndCallback onPanEnd;

  /// The pointer that previously triggered [onPanDown] did not complete.
  final GestureDragCancelCallback onPanCancel;

  /// The pointers in contact with the screen have established a focal point and
  /// initial scale of 1.0.
  final GestureScaleStartCallback onScaleStart;

  /// The pointers in contact with the screen have indicated a new focal point
  /// and/or scale.
  final GestureScaleUpdateCallback onScaleUpdate;

  /// The pointers are no longer in contact with the screen.
  final GestureScaleEndCallback onScaleEnd;

  /// How this gesture detector should behave during hit testing.
  final HitTestBehavior behavior;

  /// Whether to exclude these gestures from the semantics tree. For
  /// example, the long-press gesture for showing a tooltip is
  /// excluded because the tooltip itself is included in the semantics
  /// tree directly and so having a gesture to show it would result in
  /// duplication of information.
  final bool excludeFromSemantics;

  @override
  Widget build(BuildContext context) {
    final Map<Type, GestureRecognizerFactory> gestures = <Type, GestureRecognizerFactory>{};

    if (onTapDown != null || onTapUp != null || onTap != null || onTapCancel != null) {
      gestures[TapGestureRecognizer] = (TapGestureRecognizer recognizer) { // ignore: invalid_assignment, https://github.com/flutter/flutter/issues/5771
        return (recognizer ??= new TapGestureRecognizer())
          ..onTapDown = onTapDown
          ..onTapUp = onTapUp
          ..onTap = onTap
          ..onTapCancel = onTapCancel;
      };
    }

    if (onDoubleTap != null) {
      gestures[DoubleTapGestureRecognizer] = (DoubleTapGestureRecognizer recognizer) { // ignore: invalid_assignment, https://github.com/flutter/flutter/issues/5771
        return (recognizer ??= new DoubleTapGestureRecognizer())
          ..onDoubleTap = onDoubleTap;
      };
    }

    if (onLongPress != null) {
      gestures[LongPressGestureRecognizer] = (LongPressGestureRecognizer recognizer) { // ignore: invalid_assignment, https://github.com/flutter/flutter/issues/5771
        return (recognizer ??= new LongPressGestureRecognizer())
          ..onLongPress = onLongPress;
      };
    }

    if (onVerticalDragDown != null ||
        onVerticalDragStart != null ||
        onVerticalDragUpdate != null ||
        onVerticalDragEnd != null ||
        onVerticalDragCancel != null) {
      gestures[VerticalDragGestureRecognizer] = (VerticalDragGestureRecognizer recognizer) { // ignore: invalid_assignment, https://github.com/flutter/flutter/issues/5771
        return (recognizer ??= new VerticalDragGestureRecognizer())
          ..onDown = onVerticalDragDown
          ..onStart = onVerticalDragStart
          ..onUpdate = onVerticalDragUpdate
          ..onEnd = onVerticalDragEnd
          ..onCancel = onVerticalDragCancel;
      };
    }

    if (onHorizontalDragDown != null ||
        onHorizontalDragStart != null ||
        onHorizontalDragUpdate != null ||
        onHorizontalDragEnd != null ||
        onHorizontalDragCancel != null) {
      gestures[HorizontalDragGestureRecognizer] = (HorizontalDragGestureRecognizer recognizer) { // ignore: invalid_assignment, https://github.com/flutter/flutter/issues/5771
        return (recognizer ??= new HorizontalDragGestureRecognizer())
          ..onDown = onHorizontalDragDown
          ..onStart = onHorizontalDragStart
          ..onUpdate = onHorizontalDragUpdate
          ..onEnd = onHorizontalDragEnd
          ..onCancel = onHorizontalDragCancel;
      };
    }

    if (onPanDown != null ||
        onPanStart != null ||
        onPanUpdate != null ||
        onPanEnd != null ||
        onPanCancel != null) {
      gestures[PanGestureRecognizer] = (PanGestureRecognizer recognizer) { // ignore: invalid_assignment, https://github.com/flutter/flutter/issues/5771
        return (recognizer ??= new PanGestureRecognizer())
          ..onDown = onPanDown
          ..onStart = onPanStart
          ..onUpdate = onPanUpdate
          ..onEnd = onPanEnd
          ..onCancel = onPanCancel;
      };
    }

    if (onScaleStart != null || onScaleUpdate != null || onScaleEnd != null) {
      gestures[ScaleGestureRecognizer] = (ScaleGestureRecognizer recognizer) { // ignore: invalid_assignment, https://github.com/flutter/flutter/issues/5771
        return (recognizer ??= new ScaleGestureRecognizer())
          ..onStart = onScaleStart
          ..onUpdate = onScaleUpdate
          ..onEnd = onScaleEnd;
      };
    }

    return new RawGestureDetector(
      gestures: gestures,
      behavior: behavior,
      excludeFromSemantics: excludeFromSemantics,
      child: child
    );
  }
}

/// A widget that detects gestures described by the given gesture
/// factories.
///
/// For common gestures, use a [GestureRecognizer].
/// RawGestureDetector is useful primarily when developing your
/// own gesture recognizers.
class RawGestureDetector extends StatefulWidget {
  /// Creates a widget that detects gestures.
  ///
  /// By default, gesture detectors contribute semantic information to the tree
  /// that is used by assistive technology.
  const RawGestureDetector({
    Key key,
    this.child,
    this.gestures: const <Type, GestureRecognizerFactory>{},
    this.behavior,
    this.excludeFromSemantics: false
  }) : assert(gestures != null),
       assert(excludeFromSemantics != null),
       super(key: key);

  /// The widget below this widget in the tree.
  final Widget child;

  /// The gestures that this widget will attempt to recognize.
  final Map<Type, GestureRecognizerFactory> gestures;

  /// How this gesture detector should behave during hit testing.
  final HitTestBehavior behavior;

  /// Whether to exclude these gestures from the semantics tree. For
  /// example, the long-press gesture for showing a tooltip is
  /// excluded because the tooltip itself is included in the semantics
  /// tree directly and so having a gesture to show it would result in
  /// duplication of information.
  final bool excludeFromSemantics;

  @override
  RawGestureDetectorState createState() => new RawGestureDetectorState();
}

/// State for a [RawGestureDetector].
class RawGestureDetectorState extends State<RawGestureDetector> {
  Map<Type, GestureRecognizer> _recognizers = const <Type, GestureRecognizer>{};

  @override
  void initState() {
    super.initState();
    _syncAll(widget.gestures);
  }

  @override
  void didUpdateWidget(RawGestureDetector oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAll(widget.gestures);
  }

  /// This method can be called after the build phase, during the
  /// layout of the nearest descendant RenderObjectWidget of the
  /// gesture detector, to update the list of active gesture
  /// recognizers.
  ///
  /// The typical use case is [Scrollable]s, which put their viewport
  /// in their gesture detector, and then need to know the dimensions
  /// of the viewport and the viewport's child to determine whether
  /// the gesture detector should be enabled.
  void replaceGestureRecognizers(Map<Type, GestureRecognizerFactory> gestures) {
    assert(() {
      if (!context.findRenderObject().owner.debugDoingLayout) {
        throw new FlutterError(
          'Unexpected call to replaceGestureRecognizers() method of RawGestureDetectorState.\n'
          'The replaceGestureRecognizers() method can only be called during the layout phase. '
          'To set the gesture recognizers at other times, trigger a new build using setState() '
          'and provide the new gesture recognizers as constructor arguments to the corresponding '
          'RawGestureDetector or GestureDetector object.'
        );
      }
      return true;
    });
    _syncAll(gestures);
    if (!widget.excludeFromSemantics) {
      final RenderSemanticsGestureHandler semanticsGestureHandler = context.findRenderObject();
      context.visitChildElements((Element element) {
        final _GestureSemantics widget = element.widget;
        widget._updateHandlers(semanticsGestureHandler, _recognizers);
      });
    }
  }

  @override
  void dispose() {
    for (GestureRecognizer recognizer in _recognizers.values)
      recognizer.dispose();
    _recognizers = null;
    super.dispose();
  }

  void _syncAll(Map<Type, GestureRecognizerFactory> gestures) {
    assert(_recognizers != null);
    final Map<Type, GestureRecognizer> oldRecognizers = _recognizers;
    _recognizers = <Type, GestureRecognizer>{};
    for (Type type in gestures.keys) {
      assert(!_recognizers.containsKey(type));
      _recognizers[type] = gestures[type](oldRecognizers[type]);
      assert(_recognizers[type].runtimeType == type);
    }
    for (Type type in oldRecognizers.keys) {
      if (!_recognizers.containsKey(type))
        oldRecognizers[type].dispose();
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    assert(_recognizers != null);
    for (GestureRecognizer recognizer in _recognizers.values)
      recognizer.addPointer(event);
  }

  HitTestBehavior get _defaultBehavior {
    return widget.child == null ? HitTestBehavior.translucent : HitTestBehavior.deferToChild;
  }

  @override
  Widget build(BuildContext context) {
    Widget result = new Listener(
      onPointerDown: _handlePointerDown,
      behavior: widget.behavior ?? _defaultBehavior,
      child: widget.child
    );
    if (!widget.excludeFromSemantics)
      result = new _GestureSemantics(owner: this, child: result);
    return result;
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (_recognizers == null) {
      description.add('DISPOSED');
    } else {
      final List<String> gestures = _recognizers.values.map<String>((GestureRecognizer recognizer) => recognizer.toStringShort()).toList();
      if (gestures.isEmpty)
        gestures.add('<none>');
      description.add('gestures: ${gestures.join(", ")}');
    }
    switch (widget.behavior) {
      case HitTestBehavior.translucent:
        description.add('behavior: translucent');
        break;
      case HitTestBehavior.opaque:
        description.add('behavior: opaque');
        break;
      case HitTestBehavior.deferToChild:
        description.add('behavior: defer-to-child');
        break;
    }
  }
}

class _GestureSemantics extends SingleChildRenderObjectWidget {
  const _GestureSemantics({
    Key key,
    Widget child,
    this.owner
  }) : super(key: key, child: child);

  final RawGestureDetectorState owner;

  void _handleTap() {
    final TapGestureRecognizer recognizer = owner._recognizers[TapGestureRecognizer];
    assert(recognizer != null);
    if (recognizer.onTapDown != null)
      recognizer.onTapDown(new TapDownDetails());
    if (recognizer.onTapUp != null)
      recognizer.onTapUp(new TapUpDetails());
    if (recognizer.onTap != null)
      recognizer.onTap();
  }

  void _handleLongPress() {
    final LongPressGestureRecognizer recognizer = owner._recognizers[LongPressGestureRecognizer];
    assert(recognizer != null);
    if (recognizer.onLongPress != null)
      recognizer.onLongPress();
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails updateDetails) {
    {
      final HorizontalDragGestureRecognizer recognizer = owner._recognizers[HorizontalDragGestureRecognizer];
      if (recognizer != null) {
        if (recognizer.onDown != null)
          recognizer.onDown(new DragDownDetails());
        if (recognizer.onStart != null)
          recognizer.onStart(new DragStartDetails());
        if (recognizer.onUpdate != null)
          recognizer.onUpdate(updateDetails);
        if (recognizer.onEnd != null)
          recognizer.onEnd(new DragEndDetails(primaryVelocity: 0.0));
        return;
      }
    }
    {
      final PanGestureRecognizer recognizer = owner._recognizers[PanGestureRecognizer];
      if (recognizer != null) {
        if (recognizer.onDown != null)
          recognizer.onDown(new DragDownDetails());
        if (recognizer.onStart != null)
          recognizer.onStart(new DragStartDetails());
        if (recognizer.onUpdate != null)
          recognizer.onUpdate(updateDetails);
        if (recognizer.onEnd != null)
          recognizer.onEnd(new DragEndDetails());
        return;
      }
    }
  }

  void _handleVerticalDragUpdate(DragUpdateDetails updateDetails) {
    {
      final VerticalDragGestureRecognizer recognizer = owner._recognizers[VerticalDragGestureRecognizer];
      if (recognizer != null) {
        if (recognizer.onDown != null)
          recognizer.onDown(new DragDownDetails());
        if (recognizer.onStart != null)
          recognizer.onStart(new DragStartDetails());
        if (recognizer.onUpdate != null)
          recognizer.onUpdate(updateDetails);
        if (recognizer.onEnd != null)
          recognizer.onEnd(new DragEndDetails(primaryVelocity: 0.0));
        return;
      }
    }
    {
      final PanGestureRecognizer recognizer = owner._recognizers[PanGestureRecognizer];
      if (recognizer != null) {
        if (recognizer.onDown != null)
          recognizer.onDown(new DragDownDetails());
        if (recognizer.onStart != null)
          recognizer.onStart(new DragStartDetails());
        if (recognizer.onUpdate != null)
          recognizer.onUpdate(updateDetails);
        if (recognizer.onEnd != null)
          recognizer.onEnd(new DragEndDetails());
        return;
      }
    }
  }

  @override
  RenderSemanticsGestureHandler createRenderObject(BuildContext context) {
    final RenderSemanticsGestureHandler result = new RenderSemanticsGestureHandler();
    updateRenderObject(context, result);
    return result;
  }

  void _updateHandlers(RenderSemanticsGestureHandler renderObject, Map<Type, GestureRecognizer> recognizers) {
    renderObject
      ..onTap = recognizers.containsKey(TapGestureRecognizer) ? _handleTap : null
      ..onLongPress = recognizers.containsKey(LongPressGestureRecognizer) ? _handleLongPress : null
      ..onHorizontalDragUpdate = recognizers.containsKey(VerticalDragGestureRecognizer) ||
          recognizers.containsKey(PanGestureRecognizer) ? _handleHorizontalDragUpdate : null
      ..onVerticalDragUpdate = recognizers.containsKey(VerticalDragGestureRecognizer) ||
          recognizers.containsKey(PanGestureRecognizer) ? _handleVerticalDragUpdate : null;
  }

  @override
  void updateRenderObject(BuildContext context, RenderSemanticsGestureHandler renderObject) {
    _updateHandlers(renderObject, owner._recognizers);
  }
}
