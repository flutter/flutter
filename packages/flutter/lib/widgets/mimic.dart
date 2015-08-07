// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/widgets/basic.dart';

typedef MimicCallback(Rect globalBounds);

class Mimic extends StatefulComponent {
  Mimic({
    Key key,
    this.original,
    this.callback
  }) : super(key: key);

  GlobalKey original;
  MimicCallback callback;

  void initState() {
    _requestToStartMimic();
  }

  void syncFields(Mimic source) {
    callback = source.callback;
    if (original != source.original) {
      _stopMimic();
      original = source.original;
      _requestToStartMimic();
    }
  }

  void didMount() {
    super.didMount();
    // TODO(abarth): Why is didMount being called without a call to didUnmount?
    if (_mimicable == null)
      _requestToStartMimic();
  }

  void didUnmount() {
    super.didUnmount();
    _stopMimic();
  }

  Mimicable _mimicable;
  bool _mimicking = false;

  void _requestToStartMimic() {
    assert(_mimicable == null);
    assert(!_mimicking);
    if (original == null)
      return;
    _mimicable = GlobalKey.getWidget(original) as Mimicable;
    assert(_mimicable != null);
    _mimicable._requestToStartMimic(this);
  }

  void _startMimic(GlobalKey key, Rect globalBounds) {
    assert(key == original);
    setState(() {
      _mimicking = true;
    });
    callback(globalBounds);
  }

  void _stopMimic() {
    if (_mimicable != null)
      _mimicable._didStopMimic(this);
    _mimicable = null;
    _mimicking = false;
  }

  Widget build() {
    if (!_mimicking || !_mimicable.mounted)
      return new Container();
    return _mimicable.child;
  }
}

class Mimicable extends StatefulComponent {
  Mimicable({ GlobalKey key, this.child }) : super(key: key);

  Widget child;

  Size _size;
  Size get size => _size;

  Mimic _mimic;
  bool _didStartMimic = false;

  void syncFields(Mimicable source) {
    child = source.child;
  }

  void _requestToStartMimic(Mimic mimic) {
    assert(mounted);
    if (_mimic != null)
      return;
    setState(() {
      _mimic = mimic;
      _didStartMimic = false;
    });
  }

  void _didStopMimic(Mimic mimic) {
    assert(_mimic != null);
    assert(mimic == _mimic);
    setState(() {
      _mimic = null;
      _didStartMimic = false;
    });
  }

  void _handleSizeChanged(Size size) {
    setState(() {
      _size = size;
    });
  }

  void _startMimicIfNeeded() {
    if (_didStartMimic)
      return;
    assert(_mimic != null);
    // TODO(abarth): We'll need to convert Point.origin to global coordinates.
    Point globalPosition = Point.origin;
    _mimic._startMimic(key, globalPosition & _size);
    _didStartMimic = true;
  }

  Widget build() {
    if (_mimic != null) {
      _startMimicIfNeeded();
      return new ConstrainedBox(constraints: new BoxConstraints.tight(_size));
    }
    return new SizeObserver(
      callback: _handleSizeChanged,
      child: child
    );
  }
}
