// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';

import 'package:js/js.dart';
import 'package:ui/src/engine.dart';

import '../dom.dart';

/// This is state persistent across hot restarts that indicates what
/// to clear.  Delay removal of old visible state to make the
/// transition appear smooth.
@JS('window.__flutterState')
external JSArray? get _hotRestartStore;
List<Object?>? get hotRestartStore =>
    _hotRestartStore?.toObjectShallow as List<Object?>?;

@JS('window.__flutterState')
external set _hotRestartStore(JSArray? nodes);
set hotRestartStore(List<Object?>? nodes) =>
    _hotRestartStore = nodes?.toJSAnyShallow as JSArray?;

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

  /// The js-interop layer backing [_elements].
  ///
  /// Elements are stored in a JS global array named [defaultCacheName].
  late List<Object?>? _jsElements;

  /// The elements that need to be cleaned up after hot-restart.
  List<Object?> get _elements {
    _jsElements = hotRestartStore;
    if (_jsElements == null) {
      _jsElements = <Object>[];
      hotRestartStore = _jsElements;
    }
    return _jsElements!;
  }

  /// Removes every element from [_elements] and empties the list.
  void _clearAllElements() {
    for (final Object? element in _elements) {
      if (element is DomElement) {
        element.remove();
      }
    }
    hotRestartStore = <Object>[];
  }

  /// Registers a [DomElement] to be removed after hot-restart.
  void registerElement(DomElement element) {
    final List<Object?> elements = _elements;
    elements.add(element);
    hotRestartStore = elements;
  }
}
