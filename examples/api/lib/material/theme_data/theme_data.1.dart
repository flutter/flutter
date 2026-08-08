// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

void main() {
  runApp(const ThemeDataExampleApp());
}

//
// This app's theme provides a custom context menu in the TextSelectionThemeData.
//

class ThemeDataExampleApp extends StatefulWidget {
  const ThemeDataExampleApp({super.key});

  @override
  State<ThemeDataExampleApp> createState() => _ThemeDataExampleAppState();
}

class _ThemeDataExampleAppState extends State<ThemeDataExampleApp> {
  late ColorScheme colorScheme;

  void _showDialog(BuildContext context) {
    Navigator.of(context).push(
      DialogRoute<void>(
        context: context,
        builder: (BuildContext context) =>
            const AlertDialog(title: Text('You clicked print!')),
      ),
    );
  }

  Color _getRandomColor() {
    return Color.fromARGB(
      255,
      Random().nextInt(256),
      Random().nextInt(256),
      Random().nextInt(256),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    colorScheme = ColorScheme.fromSeed(
      brightness: MediaQuery.platformBrightnessOf(context),
      seedColor: _getRandomColor(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ThemeData Demo',
      theme: ThemeData(
        colorScheme: colorScheme,
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: colorScheme.tertiary,
          selectionColor: colorScheme.tertiary.withAlpha(128),
          selectionHandleColor: colorScheme.tertiary,
          contextMenuBuilder: (context, editableTextState) =>
              AdaptiveTextSelectionToolbar.buttonItems(
                anchors: editableTextState.contextMenuAnchors,
                buttonItems: <ContextMenuButtonItem>[
                  ContextMenuButtonItem(
                    onPressed: () {
                      ContextMenuController.removeAny();
                      _showDialog(context);
                    },
                    label: 'Print',
                  ),
                  ContextMenuButtonItem(
                    onPressed: () {
                      ContextMenuController.removeAny();
                      setState(() {
                        colorScheme = ColorScheme.fromSeed(
                          brightness: MediaQuery.platformBrightnessOf(context),
                          seedColor: _getRandomColor(),
                        );
                      });
                    },
                    label: 'Generate a new ColorScheme',
                  ),
                ],
              ),
        ),
      ),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int textFieldValue = 8;

  @override
  void initState() {
    super.initState();
    // On web, disable the browser's context menu since this example uses a custom
    // Flutter-rendered context menu.
    if (kIsWeb) {
      BrowserContextMenu.disableContextMenu();
    }
  }

  @override
  void dispose() {
    if (kIsWeb) {
      BrowserContextMenu.enableContextMenu();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final double pointCount = textFieldValue.toDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bring up the context menu on the text field to see the customized menu items.  Valid range for points is 8-13.',
        ),
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        alignment: .center,
        decoration: ShapeDecoration(
          color: colorScheme.tertiaryContainer,
          shape: StarBorder(
            points: pointCount,
            pointRounding: 0.4,
            valleyRounding: 0.6,
            side: BorderSide(width: 9, color: colorScheme.tertiary),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Points: ',
              style: theme.textTheme.titleLarge!.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            IntrinsicWidth(
              child: TextField(
                textAlign: TextAlign.left,
                decoration: InputDecoration(border: OutlineInputBorder()),
                controller: TextEditingController(
                  text: textFieldValue.toString(),
                ),
                onChanged: (value) {
                  final int? parsedValue = int.tryParse(value);
                  if (parsedValue != null &&
                      parsedValue >= 8 &&
                      parsedValue <= 13) {
                    setState(() {
                      textFieldValue = parsedValue;
                    });
                  }
                },
                style: theme.textTheme.titleLarge!.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
