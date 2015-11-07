// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';

class MimicableKey {
  MimicableKey._(this._state);

  final MimicableState _state;

  Rect get globalBounds => _state._globalBounds;

  void stopMimic() {
    _state._stopMimic();
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
