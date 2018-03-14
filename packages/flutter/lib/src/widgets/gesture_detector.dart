// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
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

/// Factory for creating gesture recognizers.
///
/// `T` is the type of gesture recognizer this class manages.
///
/// Used by [RawGestureDetector.gestures].
@optionalTypeArgs
abstract class GestureRecognizerFactory<T extends GestureRecognizer> {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const GestureRecognizerFactory();

  /// Must return an instance of T.
  T constructor();

  /// Must configure the given instance (which will have been created by
  /// `constructor`).
  ///
  /// This normally means setting the callbacks.
  void initializer(T instance);

  bool _debugAssertTypeMatches(Type type) {
    assert(type == T, 'GestureRecognizerFactory of type $T was used where type $type was specified.');
    return true;
  }
}

/// Signature for closures that implement [GestureRecognizerFactory.constructor].
typedef T GestureRecognizerFactoryConstructor<T extends GestureRecognizer>();

/// Signature for closures that implement [GestureRecognizerFactory.initializer].
typedef void GestureRecognizerFactoryInitializer<T extends GestureRecognizer>(T instance);

/// Factory for creating gesture recognizers that delegates to callbacks.
///
/// Used by [RawGestureDetector.gestures].
class GestureRecognizerFactoryWithHandlers<T extends GestureRecognizer> extends GestureRecognizerFactory<T> {
  /// Creates a gesture recognizer factory with the given callbacks.
  ///
  /// The arguments must not be null.
  const GestureRecognizerFactoryWithHandlers(this._constructor, this._initializer) :
    assert(_constructor != null),
    assert(_initializer != null);

  final GestureRecognizerFactoryConstructor<T> _constructor;

  final GestureRecognizerFactoryInitializer<T> _initializer;

  @override
  T constructor() => _constructor();

  @override
  void initializer(T instance) => _initializer(instance);
}

/// A widget that detects gestures.
///
/// Attempts to recognize gestures that correspond to its non-null callbacks.
///
/// If this widget has a child, it defers to that child for its sizing behavior.
/// If it does not have a child, it grows to fit the parent instead.
///
/// By default a GestureDetector with an invisible child ignores touches;
/// this behavior can be controlled with [behavior].
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
///
/// ## Sample code
///
/// This example makes a rectangle react to being tapped by setting the
/// `_lights` field:
///
/// ```dart
/// new GestureDetector(
///   onTap: () {
///     setState(() { _lights = true; });
///   },
///   child: new Container(
///     color: Colors.yellow,
///     child: new Text('TURN LIGHTS ON'),
///   ),
/// )
/// ```
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
       }()),
       super(key: key);

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
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
      gestures[TapGestureRecognizer] = new GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
        () => new TapGestureRecognizer(debugOwner: this),
        (TapGestureRecognizer instance) {
          instance
            ..onTapDown = onTapDown
            ..onTapUp = onTapUp
            ..onTap = onTap
            ..onTapCancel = onTapCancel;
        },
      );
    }

    if (onDoubleTap != null) {
      gestures[DoubleTapGestureRecognizer] = new GestureRecognizerFactoryWithHandlers<DoubleTapGestureRecognizer>(
        () => new DoubleTapGestureRecognizer(debugOwner: this),
        (DoubleTapGestureRecognizer instance) {
          instance
            ..onDoubleTap = onDoubleTap;
        },
      );
    }

    if (onLongPress != null) {
      gestures[LongPressGestureRecognizer] = new GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
        () => new LongPressGestureRecognizer(debugOwner: this),
        (LongPressGestureRecognizer instance) {
          instance
            ..onLongPress = onLongPress;
        },
      );
    }

    if (onVerticalDragDown != null ||
        onVerticalDragStart != null ||
        onVerticalDragUpdate != null ||
        onVerticalDragEnd != null ||
        onVerticalDragCancel != null) {
      gestures[VerticalDragGestureRecognizer] = new GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer>(
        () => new VerticalDragGestureRecognizer(debugOwner: this),
        (VerticalDragGestureRecognizer instance) {
          instance
            ..onDown = onVerticalDragDown
            ..onStart = onVerticalDragStart
            ..onUpdate = onVerticalDragUpdate
            ..onEnd = onVerticalDragEnd
            ..onCancel = onVerticalDragCancel;
        },
      );
    }

    if (onHorizontalDragDown != null ||
        onHorizontalDragStart != null ||
        onHorizontalDragUpdate != null ||
        onHorizontalDragEnd != null ||
        onHorizontalDragCancel != null) {
      gestures[HorizontalDragGestureRecognizer] = new GestureRecognizerFactoryWithHandlers<HorizontalDragGestureRecognizer>(
        () => new HorizontalDragGestureRecognizer(debugOwner: this),
        (HorizontalDragGestureRecognizer instance) {
          instance
            ..onDown = onHorizontalDragDown
            ..onStart = onHorizontalDragStart
            ..onUpdate = onHorizontalDragUpdate
            ..onEnd = onHorizontalDragEnd
            ..onCancel = onHorizontalDragCancel;
        },
      );
    }

    if (onPanDown != null ||
        onPanStart != null ||
        onPanUpdate != null ||
        onPanEnd != null ||
        onPanCancel != null) {
      gestures[PanGestureRecognizer] = new GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
        () => new PanGestureRecognizer(debugOwner: this),
        (PanGestureRecognizer instance) {
          instance
            ..onDown = onPanDown
            ..onStart = onPanStart
            ..onUpdate = onPanUpdate
            ..onEnd = onPanEnd
            ..onCancel = onPanCancel;
        },
      );
    }

    if (onScaleStart != null || onScaleUpdate != null || onScaleEnd != null) {
      gestures[ScaleGestureRecognizer] = new GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
        () => new ScaleGestureRecognizer(debugOwner: this),
        (ScaleGestureRecognizer instance) {
          instance
            ..onStart = onScaleStart
            ..onUpdate = onScaleUpdate
            ..onEnd = onScaleEnd;
        },
      );
    }

    return new RawGestureDetector(
      gestures: gestures,
      behavior: behavior,
      excludeFromSemantics: excludeFromSemantics,
      child: child,
    );
  }
}

/// A widget that detects gestures described by the given gesture
/// factories.
///
/// For common gestures, use a [GestureRecognizer].
/// [RawGestureDetector] is useful primarily when developing your
/// own gesture recognizers.
///
/// Configuring the gesture recognizers requires a carefully constructed map, as
/// described in [gestures] and as shown in the example below.
///
/// ## Sample code
///
/// This example shows how to hook up a [TapGestureRecognizer]. It assumes that
/// the code is being used inside a [State] object with a `_last` field that is
/// then displayed as the child of the gesture detector.
///
/// ```dart
/// new RawGestureDetector(
///   gestures: <Type, GestureRecognizerFactory>{
///     TapGestureRecognizer: new GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
///       () => new TapGestureRecognizer(),
///       (TapGestureRecognizer instance) {
///         instance
///           ..onTapDown = (TapDownDetails details) { setState(() { _last = 'down'; }); }
///           ..onTapUp = (TapUpDetails details) { setState(() { _last = 'up'; }); }
///           ..onTap = () { setState(() { _last = 'tap'; }); }
///           ..onTapCancel = () { setState(() { _last = 'cancel'; }); };
///       },
///     ),
///   },
///   child: new Container(width: 300.0, height: 300.0, color: Colors.yellow, child: new Text(_last)),
/// )
/// ```
///
/// See also:
///
///  * [GestureDetector], a less flexible but much simpler widget that does the same thing.
///  * [Listener], a widget that reports raw pointer events.
///  * [GestureRecognizer], the class that you extend to create a custom gesture recognizer.
class RawGestureDetector extends StatefulWidget {
  /// Creates a widget that detects gestures.
  ///
  /// By default, gesture detectors contribute semantic information to the tree
  /// that is used by assistive technology. This can be controlled using
  /// [excludeFromSemantics].
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
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// The gestures that this widget will attempt to recognize.
  ///
  /// This should be a map from [GestureRecognizer] subclasses to
  /// [GestureRecognizerFactory] subclasses specialized with the same type.
  ///
  /// This value can be late-bound at layout time using
  /// [RawGestureDetectorState.replaceGestureRecognizers].
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
  /// layout of the nearest descendant [RenderObjectWidget] of the
  /// gesture detector, to update the list of active gesture
  /// recognizers.
  ///
  /// The typical use case is [Scrollable]s, which put their viewport
  /// in their gesture detector, and then need to know the dimensions
  /// of the viewport and the viewport's child to determine whether
  /// the gesture detector should be enabled.
  ///
  /// The argument should follow the same conventions as
  /// [RawGestureDetector.gestures]. It acts like a temporary replacement for
  /// that value until the next build.
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
    }());
    _syncAll(gestures);
    if (!widget.excludeFromSemantics) {
      final RenderSemanticsGestureHandler semanticsGestureHandler = context.findRenderObject();
      context.visitChildElements((Element element) {
        final _GestureSemantics widget = element.widget;
        widget._updateHandlers(semanticsGestureHandler);
      });
    }
  }

  /// This method can be called outside of the build phase to filter the list of
  /// available semantic actions.
  ///
  /// The actual filtering is happening in the next frame and a frame will be
  /// scheduled if non is pending.
  ///
  /// This is used by [Scrollable] to configure system accessibility tools so
  /// that they know in which direction a particular list can be scrolled.
  ///
  /// If this is never called, then the actions are not filtered. If the list of
  /// actions to filter changes, it must be called again.
  void replaceSemanticsActions(Set<SemanticsAction> actions) {
    assert(() {
      final Element element = context;
      if (element.owner.debugBuilding) {
        throw new FlutterError(
          'Unexpected call to replaceSemanticsActions() method of RawGestureDetectorState.\n'
          'The replaceSemanticsActions() method can only be called outside of the build phase.'
        );
      }
      return true;
    }());
    if (!widget.excludeFromSemantics) {
      final RenderSemanticsGestureHandler semanticsGestureHandler = context.findRenderObject();
      semanticsGestureHandler.validActions = actions; // will call _markNeedsSemanticsUpdate(), if required.
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
      assert(gestures[type] != null);
      assert(gestures[type]._debugAssertTypeMatches(type));
      assert(!_recognizers.containsKey(type));
      _recognizers[type] = oldRecognizers[type] ?? gestures[type].constructor();
      assert(_recognizers[type].runtimeType == type, 'GestureRecognizerFactory of type $type created a GestureRecognizer of type ${_recognizers[type].runtimeType}. The GestureRecognizerFactory must be specialized with the type of the class that it returns from its constructor method.');
      gestures[type].initializer(_recognizers[type]);
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

  void _handleSemanticsTap() {
    final TapGestureRecognizer recognizer = _recognizers[TapGestureRecognizer];
    assert(recognizer != null);
    if (recognizer.onTapDown != null)
      recognizer.onTapDown(new TapDownDetails());
    if (recognizer.onTapUp != null)
      recognizer.onTapUp(new TapUpDetails());
    if (recognizer.onTap != null)
      recognizer.onTap();
  }

  void _handleSemanticsLongPress() {
    final LongPressGestureRecognizer recognizer = _recognizers[LongPressGestureRecognizer];
    assert(recognizer != null);
    if (recognizer.onLongPress != null)
      recognizer.onLongPress();
  }

  void _handleSemanticsHorizontalDragUpdate(DragUpdateDetails updateDetails) {
    {
      final HorizontalDragGestureRecognizer recognizer = _recognizers[HorizontalDragGestureRecognizer];
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
      final PanGestureRecognizer recognizer = _recognizers[PanGestureRecognizer];
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

  void _handleSemanticsVerticalDragUpdate(DragUpdateDetails updateDetails) {
    {
      final VerticalDragGestureRecognizer recognizer = _recognizers[VerticalDragGestureRecognizer];
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
      final PanGestureRecognizer recognizer = _recognizers[PanGestureRecognizer];
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
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    if (_recognizers == null) {
      description.add(new DiagnosticsNode.message('DISPOSED'));
    } else {
      final List<String> gestures = _recognizers.values.map<String>((GestureRecognizer recognizer) => recognizer.debugDescription).toList();
      description.add(new IterableProperty<String>('gestures', gestures, ifEmpty: '<none>'));
      description.add(new IterableProperty<GestureRecognizer>('recognizers', _recognizers.values, level: DiagnosticLevel.fine));
    }
    description.add(new EnumProperty<HitTestBehavior>('behavior', widget.behavior, defaultValue: null));
  }
}

class _GestureSemantics extends SingleChildRenderObjectWidget {
  const _GestureSemantics({
    Key key,
    Widget child,
    this.owner
  }) : super(key: key, child: child);

  final RawGestureDetectorState owner;

  @override
  RenderSemanticsGestureHandler createRenderObject(BuildContext context) {
    return new RenderSemanticsGestureHandler(
      onTap: _onTapHandler,
      onLongPress: _onLongPressHandler,
      onHorizontalDragUpdate: _onHorizontalDragUpdateHandler,
      onVerticalDragUpdate: _onVerticalDragUpdateHandler,
    );
  }

  void _updateHandlers(RenderSemanticsGestureHandler renderObject) {
    renderObject
      ..onTap = _onTapHandler
      ..onLongPress = _onLongPressHandler
      ..onHorizontalDragUpdate = _onHorizontalDragUpdateHandler
      ..onVerticalDragUpdate = _onVerticalDragUpdateHandler;
  }

  @override
  void updateRenderObject(BuildContext context, RenderSemanticsGestureHandler renderObject) {
    _updateHandlers(renderObject);
  }

  GestureTapCallback get _onTapHandler {
    return owner._recognizers.containsKey(TapGestureRecognizer) ? owner._handleSemanticsTap : null;
  }

  GestureTapCallback get _onLongPressHandler {
    return owner._recognizers.containsKey(LongPressGestureRecognizer) ? owner._handleSemanticsLongPress : null;
  }

  GestureDragUpdateCallback get _onHorizontalDragUpdateHandler {
    return owner._recognizers.containsKey(HorizontalDragGestureRecognizer) ||
        owner._recognizers.containsKey(PanGestureRecognizer) ? owner._handleSemanticsHorizontalDragUpdate : null;
  }

  GestureDragUpdateCallback get _onVerticalDragUpdateHandler {
    return owner._recognizers.containsKey(VerticalDragGestureRecognizer) ||
        owner._recognizers.containsKey(PanGestureRecognizer) ? owner._handleSemanticsVerticalDragUpdate : null;
  }
}
