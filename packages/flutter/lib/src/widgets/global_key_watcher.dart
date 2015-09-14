// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/src/widgets/framework.dart';

abstract class GlobalKeyWatcher extends StatefulComponent {
  GlobalKeyWatcher({
    Key key,
    this.watchedKey
  });

  GlobalKey watchedKey;

  void syncConstructorArguments(GlobalKeyWatcher source) {
    if (watchedKey != source.watchedKey) {
      if (watchedKey != null)
        _removeListeners();
      watchedKey = source.watchedKey;
      if (mounted && watchedKey != null) {
        _setWatchedWidget(GlobalKey.getWidget(watchedKey));
        _addListeners();
      }
    }
  }

  Widget get watchedWidget => _watchedWidget;
  Widget _watchedWidget;
  void _setWatchedWidget(Widget value) {
    assert(mounted || value == null);
    if (watchedWidget != value) {
      if (watchedWidget != null)
        stopWatching();
      assert(value == null || debugValidateWatchedWidget(value));
      setState(() {
        _watchedWidget = value;
      });
      if (watchedWidget != null)
        startWatching();
    }
  }

  bool debugValidateWatchedWidget(Widget candidate) => true;

  void didMount() {
    super.didMount();
    if (watchedKey != null) {
      _setWatchedWidget(GlobalKey.getWidget(watchedKey));
      _addListeners();
    }
  }

  void didUnmount() {
    super.didUnmount();
    if (watchedKey != null)
      _removeListeners();
    _setWatchedWidget(null);
  }

  void _addListeners() {
    GlobalKey.registerSyncListener(watchedKey, didSyncWatchedKey);
    GlobalKey.registerRemoveListener(watchedKey, didRemoveWatchedKey);
  }

  void _removeListeners() {
    GlobalKey.unregisterSyncListener(watchedKey, didSyncWatchedKey);
    GlobalKey.unregisterRemoveListener(watchedKey, didRemoveWatchedKey);
  }

  void didSyncWatchedKey(GlobalKey key, Widget widget) {
    assert(key == watchedKey);
    _setWatchedWidget(widget);
  }

  void didRemoveWatchedKey(GlobalKey key) {
    assert(key == watchedKey);
    _setWatchedWidget(null);
  }

  void stopWatching() { }
  void startWatching() { }

}
