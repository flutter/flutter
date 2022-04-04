// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for ElevatedButton

import 'package:flutter/material.dart';

void main() => runApp(const ButtonApp());

class ButtonApp extends StatelessWidget {
  const ButtonApp({Key? key}) : super(key: key);

  static const String _title = 'Button Types';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(colorSchemeSeed: const Color(0xff6750a4), useMaterial3: true),
      title: _title,
      home: Scaffold(
        appBar: AppBar(title: const Text(_title)),
        body: const ButtonTypesExample(),
      ),
    );
  }
}

class ButtonTypesExample extends StatelessWidget {
  const ButtonTypesExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          children: const <Widget>[
            SizedBox(height: 10),
            ButtonTypesGroup(enabled: true),
            ButtonTypesGroup(enabled: false),
          ],
        ),
      ),
    );
  }
}

class ButtonTypesGroup extends StatelessWidget {
  const ButtonTypesGroup({ Key? key, required this.enabled }) : super(key: key);

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? onPressed = enabled ? () {} : null;
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          const SizedBox(width: 10),
          ElevatedButton(onPressed: onPressed, child: const Text('Elevated')),
          // Use an ElevatedButton with specific style to implement the
          // 'Filled' type.
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              // Foreground color
              onPrimary: Theme.of(context).colorScheme.onPrimary,
              // Background color
              primary: Theme.of(context).colorScheme.primary,
            ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0)),
            onPressed: onPressed,
            child: const Text('Filled'),
          ),
          // Use an ElevatedButton with specific style to implement the
          // 'Filled Tonal' type.
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              // Foreground color
              onPrimary: Theme.of(context).colorScheme.onSecondaryContainer,
              // Background color
              primary: Theme.of(context).colorScheme.secondaryContainer,
            ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0)),
            onPressed: onPressed,
            child: const Text('Filled Tonal'),
          ),
          OutlinedButton(onPressed: onPressed, child: const Text('Outlined')),
          TextButton(onPressed: onPressed, child: const Text('Text')),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}
