// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/widgets/basic.dart';

abstract class GlobalKeyWatcher extends StatefulComponent {
  GlobalKeyWatcher({
    Key key,
    this.watchedKey
  });

  GlobalKey watchedKey;

  void syncConstructorArguments(GlobalKeyWatcher source) {
    if (source != source.watchedKey) {
      _removeListeners();
      watchedKey = source.watchedKey;
      _addListeners();
    }
  }

  void didMount() {
    super.didMount();
    _addListeners();
  }

  void didUnmount() {
    super.didUnmount();
    _removeListeners();
  }

  void didSyncWatchedKey(GlobalKey key, Widget widget) {
    assert(key == watchedKey);
  }

  void didRemoveWatchedKey(GlobalKey key) {
    assert(key == watchedKey);
  }

  void _addListeners() {
    GlobalKey.registerSyncListener(watchedKey, didSyncWatchedKey);
    GlobalKey.registerRemoveListener(watchedKey, didRemoveWatchedKey);
  }

  void _removeListeners() {
    GlobalKey.unregisterSyncListener(watchedKey, didSyncWatchedKey);
    GlobalKey.unregisterRemoveListener(watchedKey, didRemoveWatchedKey);
  }
}

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

  Mimicable _mimicable;

  void didMount() {
    super.didMount();
    if (_mimicable == null)
      _setMimicable(GlobalKey.getWidget(watchedKey));
  }

  void didUnmount() {
    super.didUnmount();
    _stopMimic();
  }

  void didSyncWatchedKey(GlobalKey key, Widget widget) {
    super.didSyncWatchedKey(key, widget);
    _setMimicable(widget);
  }

  void didRemoveWatchedKey(GlobalKey key) {
    super.didRemoveWatchedKey(key);
    _setMimicable(null);
  }

  void _stopMimic() {
    if (_mimicable != null) {
      _mimicable.stopMimic();
      _mimicable = null;
    }
  }

  void _setMimicable(widget) {
    if (_mimicable != widget) {
      _stopMimic();
      widget.startMimic();
    }
    setState(() {
      _mimicable = widget;
    });
    if (onMimicReady != null && _mimicable != null && _mimicable._didBuildPlaceholder)
      onMimicReady();
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
