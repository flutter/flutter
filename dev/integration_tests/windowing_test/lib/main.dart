// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/_window.dart';
import 'package:flutter_driver/driver_extension.dart';

class _MainRegularWindowControllerDelegate
    extends RegularWindowControllerDelegate {
  @override
  void onWindowDestroyed() {
    super.onWindowDestroyed();

    exit(0);
  }
}

late final RegularWindowController controller;
final ValueNotifier<DialogWindowController?> dialogController = ValueNotifier(
  null,
);

void main() {
  final Completer<void> windowCreated = Completer();
  enableFlutterDriverExtension(
    handler: (String? message) async {
      await windowCreated.future;
      if (message == null) {
        return '';
      }

      final jsonMap = jsonDecode(message);
      if (!jsonMap.containsKey('type')) {
        throw ArgumentError('Message must contain a "type" field.');
      }

      if (jsonMap['type'] == 'get_size') {
        return jsonEncode({
          'width': controller.contentSize.width,
          'height': controller.contentSize.height,
        });
      } else if (jsonMap['type'] == 'set_size') {
        final Size size = Size(
          jsonMap['width'].toDouble(),
          jsonMap['height'].toDouble(),
        );
        controller.setSize(size);
        await Future.delayed(Duration(milliseconds: 50));
      } else if (jsonMap['type'] == 'set_constraints') {
        final BoxConstraints constraints = BoxConstraints(
          minWidth: jsonMap['min_width'].toDouble(),
          minHeight: jsonMap['min_height'].toDouble(),
          maxWidth: jsonMap['max_width'].toDouble(),
          maxHeight: jsonMap['max_height'].toDouble(),
        );
        controller.setConstraints(constraints);
        await Future.delayed(Duration(milliseconds: 50));
      } else if (jsonMap['type'] == 'set_fullscreen') {
        controller.setFullscreen(true);
        await Future.delayed(Duration(milliseconds: 1000));
      } else if (jsonMap['type'] == 'unset_fullscreen') {
        controller.setFullscreen(false);
        await Future.delayed(Duration(milliseconds: 1000));
      } else if (jsonMap['type'] == 'get_fullscreen') {
        return jsonEncode({'isFullscreen': controller.isFullscreen});
      } else if (jsonMap['type'] == 'set_maximized') {
        controller.setMaximized(true);
        await Future.delayed(Duration(milliseconds: 1000));
      } else if (jsonMap['type'] == 'unset_maximized') {
        controller.setMaximized(false);
        await Future.delayed(Duration(milliseconds: 1000));
      } else if (jsonMap['type'] == 'get_maximized') {
        return jsonEncode({'isMaximized': controller.isMaximized});
      } else if (jsonMap['type'] == 'set_minimized') {
        controller.setMinimized(true);
        await Future.delayed(Duration(milliseconds: 1000));
      } else if (jsonMap['type'] == 'unset_minimized') {
        controller.setMinimized(false);
        await Future.delayed(Duration(milliseconds: 1000));
      } else if (jsonMap['type'] == 'get_minimized') {
        return jsonEncode({'isMinimized': controller.isMinimized});
      } else if (jsonMap['type'] == 'set_title') {
        final String title = jsonMap['title'];
        await Future.delayed(Duration(milliseconds: 50));
        controller.setTitle(title);
      } else if (jsonMap['type'] == 'get_title') {
        return jsonEncode({'title': controller.title});
      } else if (jsonMap['type'] == 'set_activated') {
        controller.activate();
        await Future.delayed(Duration(milliseconds: 50));
      } else if (jsonMap['type'] == 'get_activated') {
        return jsonEncode({'isActivated': controller.isActivated});
      } else if (jsonMap['type'] == 'open_dialog') {
        if (dialogController.value != null) {
          return jsonEncode({'result': false});
        }
        dialogController.value = DialogWindowController(
          preferredSize: const Size(200, 200),
          parent: controller,
          delegate: MyDialogWindowControllerDelegate(
            onDestroyed: () {
              dialogController.value = null;
            },
          ),
        );
        return jsonEncode({'result': true});
      } else if (jsonMap['type'] == 'close_dialog') {
        dialogController.value?.destroy();
        return jsonEncode({'result': true});
      } else {
        throw ArgumentError('Unknown message type: ${jsonMap['type']}');
      }
      return '';
    },
  );
  controller = RegularWindowController(
    preferredSize: Size(640, 480),
    title: 'Integration Test',
    delegate: _MainRegularWindowControllerDelegate(),
  );
  windowCreated.complete();

  runWidget(RegularWindow(controller: controller, child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class MyDialogWindowControllerDelegate extends DialogWindowControllerDelegate {
  MyDialogWindowControllerDelegate({required this.onDestroyed});

  final VoidCallback onDestroyed;

  @override
  void onWindowDestroyed() {
    onDestroyed();
    super.onWindowDestroyed();
  }
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: dialogController,
      builder:
          (
            BuildContext context,
            DialogWindowController? dialogController,
            Widget? child,
          ) {
            return ViewAnchor(
              view: dialogController != null
                  ? DialogWindow(
                      controller: dialogController,
                      child: MyDialogPage(controller: dialogController),
                    )
                  : null,
              child: Scaffold(
                appBar: AppBar(
                  backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                  title: Text(widget.title),
                ),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[const Text('This is the main window.')],
                  ),
                ),
              ),
            );
          },
    );
  }
}

class MyDialogPage extends StatelessWidget {
  const MyDialogPage({super.key, required this.controller});

  final DialogWindowController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text('Dialog'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('This is a dialog window.'),
              ElevatedButton(
                key: const ValueKey<String>('close_dialog'),
                onPressed: () {
                  controller.destroy();
                },
                child: Text('Close Dialog'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
