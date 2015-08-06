// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/widgets/basic.dart';

class Mimic extends StatefulComponent {
  Mimic({ Key key, this.original }) : super(key: key);

  GlobalKey original;

  void initState() {
    _requestToStartMimic();
  }

  void syncFields(Mimic source) {
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
  Size _size;

  void _requestToStartMimic() {
    assert(_mimicable == null);
    assert(_size == null);
    if (original == null)
      return;
    _mimicable = GlobalKey.getWidget(original) as Mimicable;
    assert(_mimicable != null);
    _mimicable._requestToStartMimic(this);
  }

  void _startMimic(GlobalKey key, Size size) {
    assert(key == original);
    setState(() {
      _size = size;
    });
  }

  void _stopMimic() {
    if (_mimicable != null)
      _mimicable._didStopMimic(this);
    _mimicable = null;
    _size = null;
  }

  Widget build() {
    if (_size == null || !_mimicable.mounted)
      return new Container();
    return new ConstrainedBox(
      constraints: new BoxConstraints.tight(_size),
      child: _mimicable.child
    );
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
    _mimic._startMimic(key, _size);
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
