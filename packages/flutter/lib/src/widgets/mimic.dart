// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';
import 'overlay.dart';

class MimicableKey {
  MimicableKey._(this._state);

  final MimicableState _state;

  Rect get globalBounds => _state._globalBounds;

  void stopMimic() {
    _state._stopMimic();
  }
}

class MimicOverlayEntry {
  MimicOverlayEntry._(this._key) {
    _overlayEntry = new OverlayEntry(builder: _build);
    _initialGlobalBounds = _key.globalBounds;
  }

  Rect _initialGlobalBounds;

  MimicableKey _key;
  OverlayEntry _overlayEntry;

  // Animation state
  GlobalKey _targetKey;
  Curve _curve;
  Performance _performance;

  Future animateTo({
    GlobalKey targetKey,
    Duration duration,
    Curve curve: Curves.linear
  }) {
    assert(_key != null);
    assert(_overlayEntry != null);
    assert(targetKey != null);
    assert(duration != null);
    assert(curve != null);
    _targetKey = targetKey;
    _curve = curve;
    // TODO(abarth): Support changing the animation target when in flight.
    assert(_performance == null);
    _performance = new Performance(duration: duration)
      ..addListener(_overlayEntry.markNeedsBuild);
    return _performance.play();
  }

  void markNeedsBuild() {
   _overlayEntry?.markNeedsBuild();
 }

  void dispose() {
    _targetKey = null;
    _curve = null;
    _performance?.stop();
    _performance = null;
    _key.stopMimic();
    _key = null;
    _overlayEntry.remove();
    _overlayEntry = null;
  }

  Widget _build(BuildContext context) {
    assert(_key != null);
    assert(_overlayEntry != null);
    Rect globalBounds = _initialGlobalBounds;
    Point globalPosition = globalBounds.topLeft;
    if (_targetKey != null) {
      assert(_performance != null);
      assert(_curve != null);
      RenderBox box = _targetKey.currentContext?.findRenderObject();
      if (box != null) {
        // TODO(abarth): Handle the case where the transform here isn't just a translation.
        Point localPosition = box.localToGlobal(Point.origin);
        double t = _curve.transform(_performance.progress);
        // TODO(abarth): Add Point.lerp.
        globalPosition = new Point(ui.lerpDouble(globalPosition.x, localPosition.x, t),
                                 ui.lerpDouble(globalPosition.y, localPosition.y, t));
      }
    }

    RenderBox stack = context.ancestorRenderObjectOfType(RenderStack);
    // TODO(abarth): Handle the case where the transform here isn't just a translation.
    Point localPosition = stack == null ? globalPosition: stack.globalToLocal(globalPosition);
    return new Positioned(
      left: localPosition.x,
      top: localPosition.y,
      width: globalBounds.width,
      height: globalBounds.height,
      child: new Mimic(original: _key)
    );
  }
}

class Mimic extends StatelessComponent {
  Mimic({ Key key, this.original }) : super(key: key);

  final MimicableKey original;

  Widget build(BuildContext context) {
    if (original != null && original._state._beingMimicked)
      return original._state.config.child;
    return new Container();
  }
}

class Mimicable extends StatefulComponent {
  Mimicable({ Key key, this.child }) : super(key: key);

  final Widget child;

  MimicableState createState() => new MimicableState();
}

class MimicableState extends State<Mimicable> {
  Size _size;
  bool _beingMimicked = false;

  MimicableKey startMimic() {
    assert(!_beingMimicked);
    assert(_size != null);
    setState(() {
      _beingMimicked = true;
    });
    return new MimicableKey._(this);
  }

  MimicOverlayEntry liftToOverlay() {
    OverlayState overlay = Overlay.of(context);
    assert(overlay != null); // You need an overlay to lift into.
    MimicOverlayEntry entry = new MimicOverlayEntry._(startMimic());
    overlay.insert(entry._overlayEntry);
    return entry;
  }

  void _stopMimic() {
    assert(_beingMimicked);
    if (!mounted) {
      _beingMimicked = false;
      return;
    }
    setState(() {
      _beingMimicked = false;
    });
  }

  Rect get _globalBounds {
    RenderBox box = context.findRenderObject();
    return box.localToGlobal(Point.origin) & box.size;
  }

  void _handleSizeChanged(Size size) {
    setState(() {
      _size = size;
    });
  }

  Widget build(BuildContext context) {
    if (_beingMimicked) {
      return new ConstrainedBox(
        constraints: new BoxConstraints.tight(_size)
      );
    }
    return new SizeObserver(
      onSizeChanged: _handleSizeChanged,
      child: config.child
    );
  }
}
