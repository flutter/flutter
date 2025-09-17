// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'package:flutter/widgets.dart';
import 'package:flutter/src/widgets/_window.dart';

class KeyedWindow {
  KeyedWindow({
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

/// Provides access to the windows created by the application.
///
/// The window manager manages a flat list of all of the [BaseWindowController]s
/// that have been created by the application as well as which controller is
/// currently selected by the UI.
class WindowManager extends ChangeNotifier {
  final List<KeyedWindow> _windows = <KeyedWindow>[];
  List<KeyedWindow> get windows => _windows;
  int? _selectedViewId;
  BaseWindowController? get selected {
    if (_selectedViewId == null) {
      return null;
    }

    for (final KeyedWindow window in _windows) {
      if (window.controller.rootView.viewId == _selectedViewId) {
        return window.controller;
      }
    }

    return null;
  }

  void add(KeyedWindow window) {
    _windows.add(window);
    notifyListeners();
  }

  void remove(UniqueKey key) {
    _windows.removeWhere((KeyedWindow window) => window.key == key);
    notifyListeners();
  }

  void select(int? viewId) {
    _selectedViewId = viewId;
    notifyListeners();
  }
}

/// Provides access to the [WindowManager] from the widget tree.
class WindowManagerAccessor extends InheritedWidget {
  const WindowManagerAccessor({
    super.key,
    required super.child,
    required this.windowManager,
  });

  final WindowManager windowManager;

  static WindowManager of(BuildContext context) {
    final WindowManagerAccessor? result = context
        .dependOnInheritedWidgetOfExactType<WindowManagerAccessor>();
    assert(result != null, 'No WindowManager found in context');
    return result!.windowManager;
  }

  @override
  bool updateShouldNotify(WindowManagerAccessor oldWidget) {
    return windowManager != oldWidget.windowManager;
  }
}

/// Settings that control the behavior of newly created windows.
class WindowSettings {
  WindowSettings({this.regularSize = const Size(400, 300)});

  /// The initial size for newly created regular windows.
  Size regularSize;
}

/// Provides access to the [WindowSettings] from the widget tree.
class WindowSettingsAccessor extends InheritedWidget {
  const WindowSettingsAccessor({
    super.key,
    required super.child,
    required this.windowSettings,
  });

  final WindowSettings windowSettings;

  static WindowSettings of(BuildContext context) {
    final WindowSettingsAccessor? result = context
        .dependOnInheritedWidgetOfExactType<WindowSettingsAccessor>();
    assert(result != null, 'No WindowSettings found in context');
    return result!.windowSettings;
  }

  @override
  bool updateShouldNotify(WindowSettingsAccessor oldWidget) {
    return windowSettings != oldWidget.windowSettings;
  }
}
