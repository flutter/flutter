// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Run in a GTK4 Linux runner with the experimental windowing feature enabled.
// ignore_for_file: implementation_imports, invalid_use_of_internal_member

import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:ui' show AppExitType;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/_window.dart';
import 'package:flutter/src/widgets/_window_positioner.dart';
import 'package:flutter/src/widgets/_window_linux.dart';

@ffi.Native<ffi.Int Function(ffi.Pointer<ffi.Void>)>(symbol: 'gtk_widget_get_mapped')
external int mapped(ffi.Pointer<ffi.Void> widget);

@ffi.Native<ffi.Void Function(ffi.Pointer<ffi.Void>)>(symbol: 'gtk_popover_popdown')
external void popdown(ffi.Pointer<ffi.Void> widget);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final root = WindowController(
    size: const Size(800, 600),
    title: 'Popup dialog test',
    delegate: WindowControllerDelegate(),
  );
  runWidget(
    WindowManager(
      initialWindows: [
        WindowEntry(
          controller: root,
          builder: (_) => MaterialApp(
            home: Builder(
              builder: (context) {
                if (!started) {
                  started = true;
                  unawaited(test(WindowRegistry.of(context), root));
                }
                return const Scaffold(body: Text('Parent'));
              },
            ),
          ),
        ),
      ],
    ),
  );
}

bool started = false;

Future<void> test(WindowRegistry registry, WindowController root) async {
  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 600));
  await settle();
  final popup = PopupWindowController(
    parent: root,
    anchorRect: const Rect.fromLTWH(100, 100, 25, 25),
    positioner: const WindowPositioner(),
  ) as PopupWindowControllerLinux;
  final popupEntry = WindowEntry(
    controller: popup,
    builder: (_) =>
        const MaterialApp(home: SizedBox(width: 200, height: 120, child: Text('Popup'))),
  );
  registry.register(popupEntry);
  await settle();
  if (popup.isDestroyed || mapped(popup.windowHandle) == 0) throw StateError('Popup failed to map');
  final dialog = DialogWindowController(
    parent: popup,
    size: const Size(300, 200),
    title: 'Child dialog',
  );
  final dialogEntry = WindowEntry(
    controller: dialog,
    builder: (_) => const MaterialApp(home: Text('Dialog')),
  );
  registry.register(dialogEntry);
  await settle();
  if (popup.isDestroyed ||
      mapped(popup.windowHandle) != 0 ||
      mapped((dialog as DialogWindowControllerLinux).windowHandle) == 0)
    throw StateError('Popup was not suspended for mapped dialog');
  registry.unregister(dialogEntry);
  dialog.destroy();
  await settle();
  if (popup.isDestroyed || mapped(popup.windowHandle) == 0)
    throw StateError('Popup failed to resume');
  registry.unregister(popupEntry);
  popdown(popup.windowHandle);
  await Future<void>.delayed(Duration.zero);
  if (!popup.isDestroyed) {
    throw StateError('Native popup dismissal did not destroy the controller');
  }
  print('POPUP_DIALOG_PASS');
  await ServicesBinding.instance.exitApplication(AppExitType.required);
}
