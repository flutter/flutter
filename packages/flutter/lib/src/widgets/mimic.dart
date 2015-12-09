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

/// An opaque reference to a widget that can be mimicked.
class MimicableHandle {
  MimicableHandle._(this._state);

  final MimicableState _state;

  /// The size and position of the original widget in global coordinates.
  Rect get globalBounds => _state._globalBounds;

  /// Stop the mimicking process, restoring the widget to its original location in the tree.
  void stopMimic() {
    _state._stopMimic();
  }
}

/// An overlay entry that is mimicking another widget.
class MimicOverlayEntry {
  MimicOverlayEntry._(this._key) {
    _overlayEntry = new OverlayEntry(builder: _build);
    _initialGlobalBounds = _key.globalBounds;
  }

  Rect _initialGlobalBounds;

  MimicableHandle _key;
  OverlayEntry _overlayEntry;

  // Animation state
  GlobalKey _targetKey;
  Curve _curve;
  Performance _performance;

  /// Animate the entry to the location of the widget that has the given target key.
  ///
  /// The animation will take place over the given duration and will apply the
  /// given curve.
  ///
  /// This function can only be called once per overlay entry.
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

  /// Cause the overlay entry to rebuild during the next pipeline flush.
  ///
  /// You need to call this function if you rebuild the widget that this entry
  /// is mimicking in order for the overlay entry to pick up the changes that
  /// you've made to the [Mimicable].
  void markNeedsBuild() {
   _overlayEntry?.markNeedsBuild();
 }

  /// Remove this entry from the overlay and restore the widget to its original place in the tree.
  ///
  /// Once removed, the overlay entry cannot be used further.
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

/// A widget that copies the appearance of another widget.
class Mimic extends StatelessComponent {
  Mimic({ Key key, this.original }) : super(key: key);

  /// A handle to the widget that this widget should copy.
  final MimicableHandle original;

  Widget build(BuildContext context) {
    if (original != null && original._state._beingMimicked)
      return original._state.config.child;
    return new Container();
  }
}

/// A widget that can be copied by a [Mimic].
class Mimicable extends StatefulComponent {
  Mimicable({ Key key, this.child }) : super(key: key);

  final Widget child;

  MimicableState createState() => new MimicableState();
}

class MimicableState extends State<Mimicable> {
  Size _size;
  bool _beingMimicked = false;

  /// Start the mimicking process.
  ///
  /// The child of this object will no longer be built at this location in the
  /// tree.  Instead, this widget will build a transparent placeholder with the
  /// same dimensions as the widget had when the mimicking process started.
  MimicableHandle startMimic() {
    assert(!_beingMimicked);
    assert(_size != null);
    setState(() {
      _beingMimicked = true;
    });
    return new MimicableHandle._(this);
  }

  /// Mimic this object in the enclosing overlay.
  ///
  /// The child of this object will no longer be built at this location in the
  /// tree.  Instead, (1) this widget will build a transparent placeholder with
  /// the same dimensions as the widget had when the mimicking process started
  /// and (2) the child will be placed in the enclosing overlay.
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
