// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/animation.dart';
import 'package:flutter/gestures.dart';
import 'package:mojo/bindings.dart' as bindings;
import 'package:mojo/core.dart' as core;
import 'package:sky_services/pointer/pointer.mojom.dart';

import 'box.dart';
import 'debug.dart';
import 'hit_test.dart';
import 'object.dart';
import 'view.dart';

typedef void EventListener(InputEvent event);
typedef void MetricListener(Size size);

int _hammingWeight(int value) {
  if (value == 0)
    return 0;
  int weight = 0;
  for (int i = 0; i < value.bitLength; ++i) {
    if (value & (1 << i) != 0)
      ++weight;
  }
  return weight;
}

/// State used in converting PointerPackets to PointerInputEvents
class _PointerState {
  _PointerState({ this.pointer, this.lastPosition });
  int pointer;
  Point lastPosition;
}

class _PointerEventConverter {
  // Map actual input pointer value to a unique value
  // Since events are serialized we can just use a counter
  static Map<int, _PointerState> _stateForPointer = new Map<int, _PointerState>();
  static int _pointerCount = 0;

  static List<PointerInputEvent> convertPointerPacket(PointerPacket packet) {
    return packet.pointers.map(_convertPointer).toList();
  }

  static PointerInputEvent _convertPointer(Pointer pointer) {
    Point position = new Point(pointer.x, pointer.y);

    _PointerState state = _stateForPointer[pointer.pointer];
    double dx = 0.0;
    double dy = 0.0;
    String eventType;
    switch (pointer.type) {
      case PointerType.DOWN:
        eventType = 'pointerdown';
        if (state == null) {
          state = new _PointerState(lastPosition: position);
          _stateForPointer[pointer.pointer] = state;
        }
        state.pointer = _pointerCount;
        _pointerCount++;
        break;
      case PointerType.MOVE:
        eventType = 'pointermove';
        // state == null means the pointer is hovering
        if (state != null) {
          dx = position.x - state.lastPosition.x;
          dy = position.y - state.lastPosition.y;
          state.lastPosition = position;
        }
        break;
      case PointerType.UP:
      case PointerType.CANCEL:
        eventType = (pointer.type == PointerType.UP) ? 'pointerup' : 'pointercancel';
        // state == null indicates spurious events
        if (state != null) {
          // Only remove the pointer state when the last button has been released.
          if (_hammingWeight(pointer.buttons) <= 1)
            _stateForPointer.remove(pointer.pointer);
        }
        break;
    }

    int pointerIndex = (state == null) ? pointer.pointer : state.pointer;

    return new PointerInputEvent(
       type: eventType,
       timeStamp: new Duration(microseconds: pointer.timeStamp),
       pointer: pointerIndex,
       kind: _mapPointerKindToString(pointer.kind),
       x: pointer.x,
       y: pointer.y,
       dx: dx,
       dy: dy,
       buttons: pointer.buttons,
       down: pointer.down,
       primary: pointer.primary,
       obscured: pointer.obscured,
       pressure: pointer.pressure,
       pressureMin: pointer.pressureMin,
       pressureMax: pointer.pressureMax,
       distance: pointer.distance,
       distanceMin: pointer.distanceMin,
       distanceMax: pointer.distanceMax,
       radiusMajor: pointer.radiusMajor,
       radiusMinor: pointer.radiusMinor,
       radiusMin: pointer.radiusMin,
       radiusMax: pointer.radiusMax,
       orientation: pointer.orientation,
       tilt: pointer.tilt
     );
  }

  static String _mapPointerKindToString(PointerKind kind) {
    switch (kind) {
      case PointerKind.TOUCH:
        return 'touch';
      case PointerKind.MOUSE:
        return 'mouse';
      case PointerKind.STYLUS:
        return 'stylus';
      case PointerKind.INVERTED_STYLUS:
        return 'invertedStylus';
    }
    assert(false);
    return '';
  }
}

class BindingObserver {
  bool didPopRoute() => false;
  void didChangeSize(Size size) { }
}

/// The glue between the render tree and the Flutter engine
class FlutterBinding extends HitTestTarget {

  FlutterBinding({ RenderBox root: null, RenderView renderViewOverride }) {
    assert(_instance == null);
    _instance = this;

    ui.window.onPointerPacket = _handlePointerPacket;
    ui.window.onMetricsChanged = _handleMetricsChanged;
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
    bindings.Message message = new bindings.Message(
        serializedPacket,
        <core.MojoHandle>[],
        serializedPacket.lengthInBytes,
        0);
    PointerPacket packet = PointerPacket.deserialize(message);
    for (PointerInputEvent event in _PointerEventConverter.convertPointerPacket(packet)) {
      _handlePointerInputEvent(event);
    }
  }

  /// A router that routes all pointer events received from the engine
  final PointerRouter pointerRouter = new PointerRouter();

  /// State for all pointers which are currently down.
  /// We do not track the state of hovering pointers because we need
  /// to hit-test them on each movement.
  Map<int, HitTestResult> _resultForPointer = new Map<int, HitTestResult>();

  void _handlePointerInputEvent(PointerInputEvent event) {
    HitTestResult result = _resultForPointer[event.pointer];
    switch (event.type) {
      case 'pointerdown':
        if (result == null) {
          result = hitTest(new Point(event.x, event.y));
          _resultForPointer[event.pointer] = result;
        }
        break;
      case 'pointermove':
        if (result == null) {
          // The pointer is hovering, ignore it for now since we don't
          // know what to do with it yet.
          return;
        }
        break;
      case 'pointerup':
      case 'pointercancel':
        if (result == null) {
          // This seems to be a spurious event.  Ignore it.
          return;
        }
        // Only remove the hit test result when the last button has been released.
        if (_hammingWeight(event.buttons) <= 1)
          _resultForPointer.remove(event.pointer);
        break;
    }
    dispatchEvent(event, result);
  }

  /// Determine which [HitTestTarget] objects are located at a given position
  HitTestResult hitTest(Point position) {
    HitTestResult result = new HitTestResult();
    _renderView.hitTest(result, position: position);
    result.add(new HitTestEntry(this));
    return result;
  }

  /// Dispatch the given event to the path of the given hit test result
  void dispatchEvent(InputEvent event, HitTestResult result) {
    assert(result != null);
    for (HitTestEntry entry in result.path)
      entry.target.handleEvent(event, entry);
  }

  void handleEvent(InputEvent e, HitTestEntry entry) {
    if (e is PointerInputEvent) {
      PointerInputEvent event = e;
      pointerRouter.route(event);
      if (event.type == 'pointerdown')
        GestureArena.instance.close(event.pointer);
      else if (event.type == 'pointerup')
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
