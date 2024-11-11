// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart'
    show
        ButtonStyle,
        ColorScheme,
        Colors,
        InkSparkle,
        MaterialApp,
        MenuButtonThemeData,
        MenuItemButton,
        TextButton,
        Theme,
        ThemeData,
        VisualDensity;
import 'package:flutter/widgets.dart';


/// Flutter code sample for a [CupertinoMenuAnchor] that shows a basic menu.
// void main() => runApp(const CupertinoSimpleMenuApp());

class SimpleMenuExample extends StatefulWidget {
  const SimpleMenuExample({super.key});

  @override
  State<SimpleMenuExample> createState() => _SimpleMenuExampleState();
}

class _SimpleMenuExampleState extends State<SimpleMenuExample> {
  final MenuController controller = MenuController();

  String _selected = '';

  void _handlePressed(String value) {
    setState(() {
      _selected = value;
    });
    controller.close();

  }
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'Selected: $_selected',
            style: Theme.of(context).textTheme.bodyMedium
          ),
          RawMenuAnchor(
            controller: controller,
            constraints: const BoxConstraints(minWidth: 120),
            padding: const EdgeInsets.symmetric(vertical: 5),
            alignmentOffset: const Offset(0, 6),
            surfaceDecoration: RawMenuAnchor.defaultLightOverlayDecoration,
            menuChildren: <Widget>[
              MenuItemButton(
                onPressed: (){
                  _handlePressed('Cut');
                },
                child: const Text('Cut')
              ),
              MenuItemButton(
                onPressed: (){
                  _handlePressed('Copy');
                },
                child: const Text('Copy')
              ),
              MenuItemButton(
                onPressed: (){
                  _handlePressed('Paste');
                },
                child: const Text('Paste')
              ),
            ],
            builder: (
              BuildContext context,
              MenuController controller,
              Widget? child,
            ) {
              return TextButton(
                onPressed: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
                child: const Text('Edit'),
              );
            },
          ),
        ],
      ),
    );
  }
}


class SimpleMenuApp extends StatelessWidget {
  const SimpleMenuApp({super.key});

  static const ButtonStyle menuButtonStyle = ButtonStyle(
    splashFactory: InkSparkle.splashFactory,
    iconSize: WidgetStatePropertyAll<double>(17),
    overlayColor: WidgetStatePropertyAll<Color>(Color(0x0D1A1A1A)),
    padding: WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.symmetric(horizontal: 12)),
    textStyle: WidgetStatePropertyAll<TextStyle>(TextStyle(fontSize: 14)),
    visualDensity: VisualDensity(
      horizontal: VisualDensity.minimumDensity,
      vertical: VisualDensity.minimumDensity,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.from(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ).copyWith(
        menuButtonTheme: const MenuButtonThemeData(style: menuButtonStyle),
      ),
      home: const SimpleMenuExample(),
    );
  }
}
