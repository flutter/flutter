// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/src/widgets/basic.dart';
import 'package:sky/src/widgets/framework.dart';
import 'package:sky/src/widgets/global_key_watcher.dart';

typedef MimicReadyCallback();

class Mimic extends GlobalKeyWatcher {
  Mimic({
    Key key,
    GlobalKey original,
    this.onMimicReady
  }) : super(key: key, watchedKey: original);

  MimicReadyCallback onMimicReady;

  void syncConstructorArguments(Mimic source) {
    onMimicReady = source.onMimicReady;
    super.syncConstructorArguments(source);
  }

  bool debugValidateWatchedWidget(Widget candidate) {
    return candidate is Mimicable;
  }

  Mimicable get _mimicable => watchedWidget;

  void didSyncWatchedKey(GlobalKey key, Widget widget) {
    super.didSyncWatchedKey(key, widget); // calls startWatching()
    if (onMimicReady != null && _mimicable._didBuildPlaceholder)
      onMimicReady();
  }

  void startWatching() {
    _mimicable.startMimic();
  }

  void stopWatching() {
    _mimicable.stopMimic();
  }

  Widget build() {
    if (_mimicable == null || !_mimicable._didBuildPlaceholder)
      return new Container();
    return _mimicable.child;
  }
}

class Mimicable extends StatefulComponent {
  Mimicable({ GlobalKey key, this.child }) : super(key: key);

  Widget child;

  Size _size;
  Size get size => _size;

  void syncConstructorArguments(Mimicable source) {
    child = source.child;
  }

  bool _didBuildPlaceholder = false;

  Rect get globalBounds {
    if (_size == null)
      return null;
    return localToGlobal(Point.origin) & _size;
  }

  bool _mimicRequested = false;
  void startMimic() {
    assert(!_mimicRequested);
    setState(() {
      _mimicRequested = true;
    });
  }

  void stopMimic() {
    assert(_mimicRequested);
    setState(() {
      _mimicRequested = false;
    });
  }

  void _handleSizeChanged(Size size) {
    setState(() {
      _size = size;
    });
  }

  Widget build() {
    _didBuildPlaceholder = _mimicRequested && _size != null;
    if (_didBuildPlaceholder) {
      return new ConstrainedBox(
        constraints: new BoxConstraints.tight(_size)
      );
    }
    return new SizeObserver(
      callback: _handleSizeChanged,
      child: child
    );
  }
}
