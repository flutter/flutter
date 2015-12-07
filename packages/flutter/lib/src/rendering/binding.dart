// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:mojo/bindings.dart' as mojo_bindings;
import 'package:mojo/core.dart' as mojo_core;
import 'package:sky_services/pointer/pointer.mojom.dart';

import 'box.dart';
import 'debug.dart';
import 'hit_test.dart';
import 'object.dart';
import 'view.dart';

typedef void MetricListener(Size size);

class _PointerState {
  _PointerState(this.lastPosition);

  int get pointer => _pointer; // the identifier used in PointerEvent objects
  int _pointer;
  static int _pointerCount = 0;
  void startNewPointer() {
    _pointerCount += 1;
    _pointer = _pointerCount;
  }
  
  bool get down => _down;
  bool _down = false;
  void setDown() {
    assert(!_down);
    _down = true;
  }
  void setUp() {
    assert(_down);
    _down = false;
  }

  Point lastPosition;
}

class _PointerEventConverter {
  // map from platform pointer identifiers to PointerEvent pointer identifiers
  static Map<int, _PointerState> _pointers = <int, _PointerState>{};

  static Iterable<PointerEvent> expand(Iterable<Pointer> packet) sync* {
    for (Pointer datum in packet) {
      Point position = new Point(datum.x, datum.y);
      Duration timeStamp = new Duration(microseconds: datum.timeStamp);
      assert(_pointerKindMap.containsKey(datum.kind));
      PointerDeviceKind kind = _pointerKindMap[datum.kind];
      switch (datum.type) {
        case PointerType.DOWN:
          _PointerState state = _pointers.putIfAbsent(
            datum.pointer,
            () => new _PointerState(position)
          );
          state.startNewPointer();
          state.setDown();
          yield new PointerAddedEvent(
            timeStamp: timeStamp,
            pointer: state.pointer,
            kind: kind,
            position: position,
            obscured: datum.obscured,
            pressureMin: datum.pressureMin,
            pressureMax: datum.pressureMax,
            distance: datum.distance,
            distanceMax: datum.distanceMax,
            radiusMin: datum.radiusMin,
            radiusMax: datum.radiusMax,
            orientation: datum.orientation,
            tilt: datum.tilt
          );
          yield new PointerDownEvent(
            timeStamp: timeStamp,
            pointer: state.pointer,
            kind: kind,
            position: position,
            obscured: datum.obscured,
            pressure: datum.pressure,
            pressureMin: datum.pressureMin,
            pressureMax: datum.pressureMax,
            distanceMax: datum.distanceMax,
            radiusMajor: datum.radiusMajor,
            radiusMinor: datum.radiusMajor,
            radiusMin: datum.radiusMin,
            radiusMax: datum.radiusMax,
            orientation: datum.orientation,
            tilt: datum.tilt
          );
          break;
        case PointerType.MOVE:
          _PointerState state = _pointers[datum.pointer];
          // If the service starts supporting hover pointers, then it must also
          // start sending us ADDED and REMOVED data points. In the meantime, we
          // only support "down" moves, and ignore spurious moves.
          // See also: https://github.com/flutter/flutter/issues/720
          if (state == null)
            break;
          assert(state.down);
          Offset offset = position - state.lastPosition;
          state.lastPosition = position;
          yield new PointerMoveEvent(
            timeStamp: timeStamp,
            pointer: state.pointer,
            kind: kind,
            position: position,
            delta: offset,
            down: state.down,
            obscured: datum.obscured,
            pressure: datum.pressure,
            pressureMin: datum.pressureMin,
            pressureMax: datum.pressureMax,
            distance: datum.distance,
            distanceMax: datum.distanceMax,
            radiusMajor: datum.radiusMajor,
            radiusMinor: datum.radiusMajor,
            radiusMin: datum.radiusMin,
            radiusMax: datum.radiusMax,
            orientation: datum.orientation,
            tilt: datum.tilt
          );
          break;
        case PointerType.UP:
        case PointerType.CANCEL:
          _PointerState state = _pointers[datum.pointer];
          assert(state != null);
          assert(position == state.lastPosition);
          state.setUp();
          if (datum.type == PointerType.UP) {
            yield new PointerUpEvent(
              timeStamp: timeStamp,
              pointer: state.pointer,
              kind: kind,
              position: position,
              obscured: datum.obscured,
              pressureMax: datum.pressureMax,
              distance: datum.distance,
              distanceMax: datum.distanceMax,
              radiusMin: datum.radiusMin,
              radiusMax: datum.radiusMax,
              orientation: datum.orientation,
              tilt: datum.tilt
            );
          } else {
            yield new PointerCancelEvent(
              timeStamp: timeStamp,
              pointer: state.pointer,
              kind: kind,
              position: position,
              obscured: datum.obscured,
              pressureMin: datum.pressureMin,
              pressureMax: datum.pressureMax,
              distance: datum.distance,
              distanceMax: datum.distanceMax,
              radiusMin: datum.radiusMin,
              radiusMax: datum.radiusMax,
              orientation: datum.orientation,
              tilt: datum.tilt
            );
          }
          yield new PointerRemovedEvent(
            timeStamp: timeStamp,
            pointer: state.pointer,
            kind: kind,
            obscured: datum.obscured,
            pressureMin: datum.pressureMin,
            pressureMax: datum.pressureMax,
            distanceMax: datum.distanceMax,
            radiusMin: datum.radiusMin,
            radiusMax: datum.radiusMax
          );
          _pointers.remove(datum.pointer);
          break;
        default:
          // TODO(ianh): once https://github.com/flutter/flutter/issues/720 is
          // done, add real support for PointerAddedEvent and PointerRemovedEvent
          assert(false);
      }
    }
  }

  static const Map<PointerKind, PointerDeviceKind> _pointerKindMap = const <PointerKind, PointerDeviceKind>{
    PointerKind.TOUCH: PointerDeviceKind.touch,
    PointerKind.MOUSE: PointerDeviceKind.mouse,
    PointerKind.STYLUS: PointerDeviceKind.stylus,
    PointerKind.INVERTED_STYLUS: PointerDeviceKind.invertedStylus,
  };
}

class BindingObserver {
  bool didPopRoute() => false;
  void didChangeSize(Size size) { }
  void didChangeLocale(ui.Locale locale) { }
}

/// The glue between the render tree and the Flutter engine
class FlutterBinding extends HitTestTarget {

  FlutterBinding({ RenderBox root: null, RenderView renderViewOverride }) {
    assert(_instance == null);
    _instance = this;

    ui.window.onPointerPacket = _handlePointerPacket;
    ui.window.onMetricsChanged = _handleMetricsChanged;
    ui.window.onLocaleChanged = _handleLocaleChanged;
    ui.window.onPopRoute = _handlePopRoute;

    if (renderViewOverride == null) {
      _renderView = new RenderView(child: root);
      _renderView.attach();
      _handleMetricsChanged();
      _renderView.scheduleInitialFrame();
    } else {
      _renderView = renderViewOverride;
    }
    assert(_renderView != null);
    scheduler.addPersistentFrameCallback(_handlePersistentFrameCallback);

    assert(_instance == this);
  }

  /// The singleton instance of the binding
  static FlutterBinding get instance => _instance;
  static FlutterBinding _instance;

  /// The render tree that's attached to the output surface
  RenderView get renderView => _renderView;
  RenderView _renderView;

  final List<BindingObserver> _observers = new List<BindingObserver>();

  void addObserver(BindingObserver observer) => _observers.add(observer);
  bool removeObserver(BindingObserver observer) => _observers.remove(observer);

  void _handleMetricsChanged() {
    Size size = ui.window.size;
    _renderView.rootConstraints = new ViewConstraints(size: size);
    for (BindingObserver observer in _observers)
      observer.didChangeSize(size);
  }

  void _handleLocaleChanged() {
    for (BindingObserver observer in _observers)
      observer.didChangeLocale(ui.window.locale);
  }

  void _handlePersistentFrameCallback(Duration timeStamp) {
    beginFrame();
  }

  /// Pump the rendering pipeline to generate a frame for the given time stamp
  void beginFrame() {
    RenderObject.flushLayout();
    _renderView.updateCompositingBits();
    RenderObject.flushPaint();
    _renderView.compositeFrame();
  }

  void _handlePopRoute() {
    for (BindingObserver observer in _observers) {
      if (observer.didPopRoute())
        return;
    }
  }

  void _handlePointerPacket(ByteData serializedPacket) {
    final mojo_bindings.Message message = new mojo_bindings.Message(
      serializedPacket,
      <mojo_core.MojoHandle>[],
      serializedPacket.lengthInBytes,
      0
    );
    final PointerPacket packet = PointerPacket.deserialize(message);
    for (PointerEvent event in _PointerEventConverter.expand(packet.pointers))
      _handlePointerEvent(event);
  }

  /// A router that routes all pointer events received from the engine
  final PointerRouter pointerRouter = new PointerRouter();

  /// State for all pointers which are currently down.
  /// The state of hovering pointers is not tracked because that would require
  /// hit-testing on every fram.e
  Map<int, HitTestResult> _hitTests = <int, HitTestResult>{};

  void _handlePointerEvent(PointerEvent event) {
    if (event is PointerDownEvent) {
      assert(!_hitTests.containsKey(event.pointer));
      _hitTests[event.pointer] = hitTest(event.position);
    } else if (event is! PointerUpEvent) {
      assert(event.down == _hitTests.containsKey(event.pointer));
      if (!event.down)
        return; // we currently ignore add, remove, and hover move events
    }
    assert(_hitTests[event.pointer] != null);
    dispatchEvent(event, _hitTests[event.pointer]);
    if (event is PointerUpEvent) {
      assert(_hitTests.containsKey(event.pointer));
      _hitTests.remove(event.pointer);
    }
  }

  /// Determine which [HitTestTarget] objects are located at a given position
  HitTestResult hitTest(Point position) {
    HitTestResult result = new HitTestResult();
    _renderView.hitTest(result, position: position);
    result.add(new HitTestEntry(this));
    return result;
  }

  /// Dispatch the given event to the path of the given hit test result
  void dispatchEvent(PointerEvent event, HitTestResult result) {
    assert(result != null);
    for (HitTestEntry entry in result.path)
      entry.target.handleEvent(event, entry);
  }

  void handleEvent(PointerEvent event, HitTestEntry entry) {
    pointerRouter.route(event);
    if (event is PointerDownEvent) {
      GestureArena.instance.close(event.pointer);
    } else if (event is PointerUpEvent) {
      GestureArena.instance.sweep(event.pointer);
    }
  }
}

/// Prints a textual representation of the entire render tree
void debugDumpRenderTree() {
  debugPrint(FlutterBinding.instance.renderView.toStringDeep());
}

/// Prints a textual representation of the entire layer tree
void debugDumpLayerTree() {
  debugPrint(FlutterBinding.instance.renderView.layer.toStringDeep());
}
