// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_driver/driver_extension.dart';

import 'keys.dart' as keys;

/// Integration test host application for measuring soft keyboard animation smoothness.
///
/// What it tests:
/// Hosts an edge-to-edge text editing UI and samples FlutterView.viewInsets.bottom
/// on every frame via persistent frame callbacks, exposing frame-by-frame history and deltas
/// over FlutterDriverExtension.
///
/// Why it was added:
/// Provides an end-to-end integration target for testing fix of flutter/flutter#190974
/// on live Android emulators/devices.
void main() {
  final recordedDeltas = <double>[];
  final recordedInsets = <double>[];
  double? lastInset;

  enableFlutterDriverExtension(
    enableTextEntryEmulation: false,
    handler: (String? message) async {
      if (message == 'get_history') {
        return jsonEncode(<String, dynamic>{'insets': recordedInsets, 'deltas': recordedDeltas});
      }
      if (message == 'reset_history') {
        recordedDeltas.clear();
        recordedInsets.clear();
        lastInset = null;
        return 'ok';
      }
      return 'unknown_command';
    },
  );

  SchedulerBinding.instance.addPersistentFrameCallback((Duration _) {
    final ui.FlutterView? view = WidgetsBinding.instance.platformDispatcher.views.firstOrNull;
    if (view == null) {
      return;
    }
    final double insets = view.viewInsets.bottom / view.devicePixelRatio;
    if (lastInset == null || (insets - lastInset!).abs() > 0.01) {
      final double delta = lastInset == null ? 0.0 : (insets - lastInset!).abs();
      recordedInsets.add(insets);
      recordedDeltas.add(delta);
      lastInset = insets;
    }
  });

  runApp(const KeyboardInsetJumpApp());
}

class KeyboardInsetJumpApp extends StatefulWidget {
  const KeyboardInsetJumpApp({super.key});

  @override
  State<KeyboardInsetJumpApp> createState() => _KeyboardInsetJumpAppState();
}

class _KeyboardInsetJumpAppState extends State<KeyboardInsetJumpApp> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Default to edge-to-edge system UI mode for testing issue #190974
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double insetsBottom = MediaQuery.viewInsetsOf(context).bottom;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: insetsBottom),
            child: Column(
              children: <Widget>[
                const SizedBox(height: 40),
                Text(
                  insetsBottom.toStringAsFixed(1),
                  key: const Key(keys.kInsetsText),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  key: const Key(keys.kEdgeToEdgeButton),
                  onPressed: () {
                    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                  },
                  child: const Text('Enable EdgeToEdge'),
                ),
                const Spacer(),
                Container(height: 8, color: Colors.red),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    key: const Key(keys.kDefaultTextField),
                    controller: _controller,
                    focusNode: _focusNode,
                    decoration: const InputDecoration(
                      hintText: 'Tap to open soft keyboard',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          key: const Key(keys.kUnfocusButton),
          onPressed: () {
            _focusNode.unfocus();
          },
          child: const Icon(Icons.keyboard_hide),
        ),
      ),
    );
  }
}
