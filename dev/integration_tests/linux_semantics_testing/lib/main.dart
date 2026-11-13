// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';

import 'pages.dart';

/// The page currently being shown, controlled by the driver test.
final ValueNotifier<String?> _currentPage = ValueNotifier<String?>(null);

Future<String> _handleDriverMessage(String? message) async {
  // Messages are of the form 'show:<page>', or 'show:' to show no page.
  final List<String> parts = (message ?? '').split(':');
  if (parts.length != 2 ||
      parts[0] != 'show' ||
      (parts[1].isNotEmpty && !pages.containsKey(parts[1]))) {
    throw ArgumentError('Unknown message: $message');
  }
  _currentPage.value = parts[1].isEmpty ? null : parts[1];
  await WidgetsBinding.instance.endOfFrame;
  return 'ok';
}

void main() {
  enableFlutterDriverExtension(handler: _handleDriverMessage);
  runApp(const LinuxSemanticsTestingApp());
}

class LinuxSemanticsTestingApp extends StatelessWidget {
  const LinuxSemanticsTestingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Linux Semantics Testing',
      home: ValueListenableBuilder<String?>(
        valueListenable: _currentPage,
        builder: (BuildContext context, String? page, Widget? child) {
          return Scaffold(
            body: Center(child: page == null ? const Text('Ready') : pages[page]!(context)),
          );
        },
      ),
    );
  }
}
