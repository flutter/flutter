// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Flutter code sample for [AlertDialog].

void main() => runApp(const AdaptiveAlertDialogApp());

class AdaptiveAlertDialogApp extends StatelessWidget {
  const AdaptiveAlertDialogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Try this: set the platform to .android and see the difference
      theme: ThemeData(platform: .iOS),
      home: Scaffold(
        appBar: AppBar(title: const Text('AlertDialog Sample')),
        body: const Center(child: AdaptiveDialogExample()),
      ),
    );
  }
}

class AdaptiveDialogExample extends StatelessWidget {
  const AdaptiveDialogExample({super.key});

  Widget adaptiveAction({
    required BuildContext context,
    required VoidCallback onPressed,
    required Widget child,
  }) {
    final ThemeData theme = Theme.of(context);
    switch (theme.platform) {
      case .android:
      case .fuchsia:
      case .linux:
      case .windows:
        return TextButton(onPressed: onPressed, child: child);
      case .iOS:
      case .macOS:
        return CupertinoDialogAction(onPressed: onPressed, child: child);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => showAdaptiveDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog.adaptive(
          title: const Text('AlertDialog Title'),
          content: const Text('AlertDialog description'),
          actions: <Widget>[
            adaptiveAction(
              context: context,
              onPressed: () => Navigator.pop(context, 'Cancel'),
              child: const Text('Cancel'),
            ),
            adaptiveAction(
              context: context,
              onPressed: () => Navigator.pop(context, 'OK'),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
      child: const Text('Show Dialog'),
    );
  }
}
