///  Copyright 2018 The Chromium Authors. All rights reserved.
///  Use of this source code is governed by a BSD-style license that can be
///  found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

import 'annotated_region.dart';
import 'framework.dart';

/// A widget that detects changes in mouse pointer positions when a mouse button
/// is not pressed. This only applies to mouse pointers: touch pointers cannot
/// be detected unless their "button" is down.
///
/// If this widget has a child, it defers to that child for its sizing behavior.
/// If it does not have a child, it grows to fit the parent instead.
///
/// {@tool snippet --template=stateful_widget}
/// This example makes a [Column] react to being entered by the mouse pointer,
/// showing a count of the number of entries and exits.
///
/// ```dart imports
/// import 'package:flutter/gestures.dart';
/// ```
///
/// ```dart
/// int _enterCounter = 0;
/// int _exitCounter = 0;
/// double x = 0.0;
/// double y = 0.0;
///
/// void _incrementCounter(MouseEnterDetails details) {
///   setState(() {
///     _enterCounter++;
///   });
/// }
///
/// void _decrementCounter(MouseExitDetails details) {
///   setState(() {
///     _exitCounter++;
///   });
/// }
///
/// void _updateLocation(MouseMoveDetails details) {
///   setState(() {
///     x = details.globalPosition.dx;
///     y = details.globalPosition.dy;
///   });
/// }
///
/// @override
/// Widget build(BuildContext context) {
///   return Scaffold(
///     appBar: AppBar(
///       title: Text('Hover Example'),
///     ),
///     body: Center(
///       child: ConstrainedBox(
///         constraints: new BoxConstraints.tight(Size(300.0, 200.0)),
///         child: MouseDetector(
///           onEnter: _incrementCounter,
///           onMove: _updateLocation,
///           onExit: _decrementCounter,
///           child: Container(
///             color: Colors.lightBlueAccent,
///             child: Column(
///               mainAxisAlignment: MainAxisAlignment.center,
///               children: <Widget>[
///                 Text('You have pointed at this box this many times:'),
///                 Text(
///                   '$_enterCounter Entries\n$_exitCounter Exits',
///                   style: Theme.of(context).textTheme.display1,
///                 ),
///                 Text(
///                   'The cursor is here: (${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)})',
///                 ),
///               ],
///             ),
///           ),
///         ),
///       ),
///     ),
///   );
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [MouseTracker] an object that tracks mouse locations in the [GestureBinding].
///  * [MouseEnterCallback] which describes the type of function that can
///    receive a mouse enter event.
///  * [MouseExitCallback] which describes the type of function that can receive
///    a mouse exit event.
///  * [MouseMoveCallback] which describes the type of function that can receive
///    a mouse move event.
class MouseDetector extends StatefulWidget {
  /// Creates a widget that detects mouse pointer movements.
  ///
  /// At least one of [onEnter], [onMove], or [onExit] must be non-null.
  const MouseDetector({
    Key key,
    this.child,
    this.onEnter,
    this.onMove,
    this.onExit,
  })  : assert(onEnter != null || onMove != null || onExit != null),
        super(key: key);

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// The event that is triggered when a mouse pointer has entered the bounding
  /// box of this widget.
  final MouseEnterCallback onEnter;

  /// The event that is triggered when a mouse pointer moves inside the bounding
  /// box of this widget.
  final MouseMoveCallback onMove;

  /// The event that is triggered when a mouse pointer has left the bounding box
  /// of this widget.
  final MouseExitCallback onExit;

  @override
  _MouseDetectorState createState() => _MouseDetectorState();
}

class _MouseDetectorState extends State<MouseDetector> {
  @override
  void initState() {
    super.initState();
    _annotation = MouseDetectorAnnotation(
      onEnter: widget.onEnter,
      onMove: widget.onMove,
      onExit: widget.onExit,
    );
  }

  MouseDetectorAnnotation _annotation;

  @override
  Widget build(BuildContext context) {
    return _MouseDetectorRenderObjectWidget(
      child: widget.child,
      annotation: _annotation,
    );
  }
}

// The RenderObjectWidget that handles attaching and detaching the annotation.
// We don't need to override updateRenderObject here because AnnotatedRegion
// handles that for us.
class _MouseDetectorRenderObjectWidget
    extends AnnotatedRegion<MouseDetectorAnnotation> {
  const _MouseDetectorRenderObjectWidget({
    Widget child,
    MouseDetectorAnnotation annotation,
  }) : super(value: annotation, child: child, sized: true);

  @override
  RenderObject createRenderObject(BuildContext context) {
    RendererBinding.instance.mouseTracker.attachAnnotation(value);
    return super.createRenderObject(context);
  }

  @override
  void didUnmountRenderObject(RenderObject renderObject) {
    RendererBinding.instance.mouseTracker.detachAnnotation(value);
  }
}
