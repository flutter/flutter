// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'package:flutter/src/widgets/_window.dart';
import 'package:flutter/src/widgets/_window_positioner.dart';
import 'package:flutter/widgets.dart';

class TooltipSettings {}

/// Settings that control the behavior of newly created windows.
class WindowSettings {
  WindowSettings({
    this.regularSize = const Size(800, 600),
    this.dialogSize = const Size(400, 400),
    this.positioner = const WindowPositioner(
      parentAnchor: WindowPositionerAnchor.right,
      childAnchor: WindowPositionerAnchor.left,
    ),
  });

  /// The initial size for newly created regular windows.
  Size regularSize;

  /// The initial size of the dialog window.
  Size dialogSize;

  /// The positioner used to determine where new tooltips and popups are placed.
  WindowPositioner positioner;
}

/// Provides access to the [WindowSettings] from the widget tree.
class WindowSettingsAccessor extends InheritedWidget {
  const WindowSettingsAccessor({super.key, required super.child, required this.windowSettings});

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

class CallbackDialogWindowControllerDelegate with DialogWindowControllerDelegate {
  CallbackDialogWindowControllerDelegate({required this.onDestroyed});

  @override
  void onWindowDestroyed() {
    onDestroyed();
    super.onWindowDestroyed();
  }

  final VoidCallback onDestroyed;
}

String anchorToString(WindowPositionerAnchor anchor) {
  return switch (anchor) {
    WindowPositionerAnchor.center => 'Center',
    WindowPositionerAnchor.top => 'Top',
    WindowPositionerAnchor.bottom => 'Bottom',
    WindowPositionerAnchor.left => 'Left',
    WindowPositionerAnchor.right => 'Right',
    WindowPositionerAnchor.topLeft => 'Top Left',
    WindowPositionerAnchor.bottomLeft => 'Bottom Left',
    WindowPositionerAnchor.topRight => 'Top Right',
    WindowPositionerAnchor.bottomRight => 'Bottom Right',
  };
}
