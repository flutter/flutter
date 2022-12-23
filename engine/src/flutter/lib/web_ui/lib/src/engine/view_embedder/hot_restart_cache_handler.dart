// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../dom.dart';
import '../safe_browser_api.dart';

/// Handles [DomElement]s that need to be removed after a hot-restart.
///
/// Elements are stored in an [_elements] list, backed by a global JS variable,
/// named [defaultCacheName].
///
/// When the app hot-restarts (and a new instance of this class is created),
/// everything in [_elements] is removed from the DOM.
class HotRestartCacheHandler {
  HotRestartCacheHandler() {
    if (_elements.isNotEmpty) {
      // We are in a post hot-restart world, clear the elements now.
      _clearAllElements();
    }
  }

  /// The name for the JS global variable backing this cache.
  @visibleForTesting
  static const String defaultCacheName = '__flutter_state';

  /// The js-interop layer backing [_elements].
  ///
  /// Elements are stored in a JS global array named [defaultCacheName].
  late List<DomElement?>? _jsElements;

  /// The elements that need to be cleaned up after hot-restart.
  List<DomElement?> get _elements {
    _jsElements =
        getJsProperty<List<DomElement?>?>(domWindow, defaultCacheName);
    if (_jsElements == null) {
      _jsElements = <DomElement?>[];
      setJsProperty(domWindow, defaultCacheName, _jsElements);
    }
    return _jsElements!;
  }

  /// Removes every element from [_elements] and empties the list.
  void _clearAllElements() {
    for (final DomElement? element in _elements) {
      element?.remove();
    }
    _elements.clear();
  }

  /// Registers a [DomElement] to be removed after hot-restart.
  void registerElement(DomElement element) {
    _elements.add(element);
  }
}
