// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/_window.dart';
import 'package:flutter_driver/driver_extension.dart';

late final RegularWindowController controller;
final ValueNotifier<DialogWindowController?> dialogController = ValueNotifier(null);

void main() {
  final Completer<void> windowCreated = Completer();
  enableFlutterDriverExtension(
    handler: (String? message) async {
      try {
        await windowCreated.future;
        if (message == null) {
          return '';
        }

        final jsonMap = jsonDecode(message) as Map<String, Object?>;
        if (!jsonMap.containsKey('type')) {
          throw ArgumentError('Message must contain a "type" field.');
        }

        /// This helper method registers a listener on the controller,
        /// calls [act] to perform some action on the controller, waits for
        /// the [predicate] to be satisfied, and finally cleans up the listener.
        Future<void> awaitNotification(VoidCallback act, bool Function() predicate) async {
          final StreamController<bool> streamController = StreamController();
          void notificationHandler() {
            streamController.add(true);
          }

          controller.addListener(notificationHandler);

          try {
            act();

            // On macOS, the predicate is immediately true, even though
            // the animation is in progress and next request for state change
            // will be ignored. Easiest way to handle this is to just wait.
            if (defaultTargetPlatform == TargetPlatform.macOS) {
              await Future<void>.delayed(const Duration(seconds: 1));
            }

            // Add a timeout to avoid hanging indefinitely
            await for (final bool _ in streamController.stream.timeout(
              const Duration(seconds: 10),
            )) {
              if (predicate()) {
                break;
              }
            }
          } finally {
            controller.removeListener(notificationHandler);
            await streamController.close();
          }
        }

        if (jsonMap['type'] == 'ping') {
          return jsonEncode({'type': 'pong'});
        } else if (jsonMap['type'] == 'get_size') {
          return jsonEncode({
            'width': controller.contentSize.width,
            'height': controller.contentSize.height,
          });
        } else if (jsonMap['type'] == 'set_size') {
          final size = Size(
            (jsonMap['width']! as num).toDouble(),
            (jsonMap['height']! as num).toDouble(),
          );
          await awaitNotification(() {
            controller.setSize(size);
          }, () => controller.contentSize == size);
        } else if (jsonMap['type'] == 'set_constraints') {
          final constraints = BoxConstraints(
            minWidth: (jsonMap['min_width']! as num).toDouble(),
            minHeight: (jsonMap['min_height']! as num).toDouble(),
            maxWidth: (jsonMap['max_width']! as num).toDouble(),
            maxHeight: (jsonMap['max_height']! as num).toDouble(),
          );
          // We assume that this will cause a resize, which the current tests do.
          final Size initialSize = controller.contentSize;
          await awaitNotification(() {
            controller.setConstraints(constraints);
          }, () => controller.contentSize != initialSize);
        } else if (jsonMap['type'] == 'set_fullscreen') {
          await awaitNotification(() {
            controller.setFullscreen(true);
          }, () => controller.isFullscreen);
        } else if (jsonMap['type'] == 'unset_fullscreen') {
          await awaitNotification(() {
            controller.setFullscreen(false);
          }, () => !controller.isFullscreen);
        } else if (jsonMap['type'] == 'get_fullscreen') {
          return jsonEncode({'isFullscreen': controller.isFullscreen});
        } else if (jsonMap['type'] == 'set_maximized') {
          await awaitNotification(() {
            controller.setMaximized(true);
          }, () => controller.isMaximized);
        } else if (jsonMap['type'] == 'unset_maximized') {
          await awaitNotification(() {
            controller.setMaximized(false);
          }, () => !controller.isMaximized);
        } else if (jsonMap['type'] == 'get_maximized') {
          return jsonEncode({'isMaximized': controller.isMaximized});
        } else if (jsonMap['type'] == 'set_minimized') {
          await awaitNotification(() {
            controller.setMinimized(true);
          }, () => controller.isMinimized);
        } else if (jsonMap['type'] == 'unset_minimized') {
          await awaitNotification(() {
            controller.setMinimized(false);
          }, () => !controller.isMinimized);
        } else if (jsonMap['type'] == 'get_minimized') {
          return jsonEncode({'isMinimized': controller.isMinimized});
        } else if (jsonMap['type'] == 'set_title') {
          final title = jsonMap['title']! as String;
          await awaitNotification(() {
            controller.setTitle(title);
          }, () => controller.title == title);
        } else if (jsonMap['type'] == 'get_title') {
          return jsonEncode({'title': controller.title});
        } else if (jsonMap['type'] == 'set_activated') {
          await awaitNotification(() {
            controller.activate();
          }, () => controller.isActivated);
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
      } catch (e) {
        return jsonEncode({'error': e.toString()});
      }
    },
  );
  controller = RegularWindowController(
    preferredSize: const Size(640, 480),
    title: 'Integration Test',
    delegate: RegularWindowControllerDelegate(),
  );

  runWidget(RegularWindow(controller: controller, child: const MyApp()));
  windowCreated.complete();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
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
      builder: (BuildContext context, DialogWindowController? dialogController, Widget? child) {
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
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[Text('This is the main window.')],
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
          title: const Text('Dialog'),
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
                child: const Text('Close Dialog'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
