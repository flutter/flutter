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
      RegularWindow(
        controller: RegularWindowController(
          preferredSize: const Size(800, 600),
          preferredConstraints: const BoxConstraints(
            minWidth: 640,
            minHeight: 480,
          ),
          title: 'Example Window',
        ),
        child: const MaterialApp(home: MyApp()),
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

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[
      ElevatedButton(
        onPressed: () {
          setState(() {
            _satelliteController ??= SatelliteWindowController(
              parent: WindowScope.of(context),
              initialPositioner: const WindowPositioner(
                parentAnchor: WindowPositionerAnchor.right,
                childAnchor: WindowPositionerAnchor.left,
              ),
              preferredSize: const Size(300, 200),
              title: 'Satellite Window',
              delegate: _CallbackSatelliteDelegate(
                onDestroyCallback: () {
                  setState(() {
                    _satelliteController = null;
                  });
                },
              ),
            );
          });
        },
        child: const Text('Show Satellite'),
      ),
    ];

    if (_satelliteController != null) {
      children.add(
        SatelliteWindow(
          controller: _satelliteController!,
          child: Container(
            padding: const EdgeInsets.all(8),
            color: Colors.black,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'This is a satellite window',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _satelliteController?.destroy();
                    });
                  },
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: Row(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}
