// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'dart:io';

import 'package:flutter/material.dart';
import 'app/models.dart';
import 'app/window_content.dart';
import 'app/main_window.dart';
import 'package:flutter/src/widgets/_window.dart';

class MainControllerWindowDelegate with RegularWindowControllerDelegate {
  @override
  void onWindowDestroyed() {
    super.onWindowDestroyed();
    exit(0);
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runWidget(MultiWindowApp());
}

class MultiWindowApp extends StatefulWidget {
  const MultiWindowApp({super.key});

  @override
  State<MultiWindowApp> createState() => _MultiWindowAppState();
}

class _MultiWindowAppState extends State<MultiWindowApp> {
  final RegularWindowController controller = RegularWindowController(
    preferredSize: const Size(800, 600),
    title: 'Multi-Window Reference Application',
    delegate: MainControllerWindowDelegate(),
  );
  final WindowSettings settings = WindowSettings();
  late final WindowManager windowManager;

  @override
  void initState() {
    super.initState();
    windowManager = WindowManager(
      initialWindows: <KeyedWindow>[
        KeyedWindow(
          isMainWindow: true,
          key: UniqueKey(),
          controller: controller,
        ),
      ],
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget mainWindowWidget = RegularWindow(
      controller: controller,
      child: MaterialApp(home: MainWindow()),
    );
    return WindowManagerAccessor(
      windowManager: windowManager,
      child: WindowSettingsAccessor(
        windowSettings: settings,
        child: ListenableBuilder(
          listenable: windowManager,
          builder: (BuildContext context, Widget? child) {
            final List<Widget> childViews = <Widget>[mainWindowWidget];
            for (final KeyedWindow window in windowManager.windows) {
              // This check renders windows that are not nested below another window as
              // a child window (e.g. a popup as a child of another window) in addition
              // to the main window, which is special as it is the one that is currently
              // being rendered.
              if (window.parent == null && !window.isMainWindow) {
                childViews.add(
                  WindowContent(
                    controller: window.controller,
                    windowKey: window.key,
                    onDestroyed: () => windowManager.remove(window.key),
                    onError: () => windowManager.remove(window.key),
                  ),
                );
              }
            }

            return ViewCollection(views: childViews);
          },
        ),
      ),
    );
  }
}
