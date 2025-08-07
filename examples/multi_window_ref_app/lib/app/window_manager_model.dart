// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member

import 'package:flutter/widgets.dart';
import 'package:flutter/src/widgets/_window.dart';

class KeyedWindowController {
  KeyedWindowController({
    this.parent,
    this.isMainWindow = false,
    required this.key,
    required this.controller,
  });

  final BaseWindowController? parent;
  final bool isMainWindow;
  final UniqueKey key;
  final BaseWindowController controller;
}

/// Manages a flat list of all of the [WindowController]s that have been
/// created by the application as well as which controller is currently
/// selected by the UI.
class WindowManagerModel extends ChangeNotifier {
  final List<KeyedWindowController> _windows = <KeyedWindowController>[];
  List<KeyedWindowController> get windows => _windows;
  int? _selectedViewId;
  BaseWindowController? get selected {
    if (_selectedViewId == null) {
      return null;
    }

    for (final KeyedWindowController controller in _windows) {
      if (controller.controller.rootView.viewId == _selectedViewId) {
        return controller.controller;
      }
    }

    return null;
  }

  void add(KeyedWindowController window) {
    _windows.add(window);
    notifyListeners();
  }

  void remove(UniqueKey key) {
    _windows.removeWhere((KeyedWindowController window) => window.key == key);
    notifyListeners();
  }

  void select(int? viewId) {
    _selectedViewId = viewId;
    notifyListeners();
  }
}
