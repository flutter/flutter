// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(mattkae): remove invalid_use_of_internal_member ignore comment when this API is stable.
// See: https://github.com/flutter/flutter/issues/177586
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/_window.dart';
import 'package:flutter/src/widgets/_window_positioner.dart';

void main() {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    runWidget(
      WindowManager(
        initialWindows: <WindowEntry>[
          WindowEntry(
            controller: WindowController(
              size: const Size(800, 600),
              constraints: const BoxConstraints(minWidth: 640, minHeight: 480),
              title: 'Example Window',
            ),
            builder: (BuildContext context) => const MaterialApp(home: MyApp()),
          ),
        ],
      ),
    );
  } on UnsupportedError catch (_) {
    // TODO(mattkae): Remove this catch block when satellite windows are supported in tests.
    // For now, we need to catch the error so that the API smoke tests pass.
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text('Unsupported'))),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _CallbackSatelliteDelegate extends SatelliteWindowControllerDelegate {
  _CallbackSatelliteDelegate({required this.onDestroyCallback});

  final VoidCallback onDestroyCallback;

  @override
  void onWindowDestroyed() {
    onDestroyCallback();
  }
}

class _MyAppState extends State<MyApp> {
  SatelliteWindowController? _satelliteController;

  void _showSatellite() {
    final SatelliteWindowController controller = SatelliteWindowController(
      parent: WindowScope.of(context),
      initialPositioner: const WindowPositioner(
        parentAnchor: WindowPositionerAnchor.right,
        childAnchor: WindowPositionerAnchor.left,
      ),
      size: const Size(300, 200),
      title: 'Satellite Window',
      delegate: _CallbackSatelliteDelegate(
        onDestroyCallback: () {
          if (mounted) {
            setState(() {
              _satelliteController = null;
            });
          }
        },
      ),
    );
    showToplevelWindow(
      context: context,
      entry: WindowEntry(
        controller: controller,
        builder: (BuildContext context) => MaterialApp(
          home: Material(
            color: Colors.black,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                    'This is a satellite window',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: controller.destroy,
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    setState(() {
      _satelliteController = controller;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: _satelliteController == null ? _showSatellite : null,
          child: const Text('Show Satellite'),
        ),
      ),
    );
  }
}
