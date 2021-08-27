// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Template: dev/snippets/config/templates/stateful_widget_scaffold_center.tmpl
//
// Comment lines marked with "▼▼▼" and "▲▲▲" are used for authoring
// of samples, and may be ignored if you are just exploring the sample.

// Flutter code sample for SwitchListTile
//
//***************************************************************************
//* ▼▼▼▼▼▼▼▼ description ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

// ![SwitchListTile sample](https://flutter.github.io/assets-for-api-docs/assets/material/switch_list_tile.png)
//
// This widget shows a switch that, when toggled, changes the state of a [bool]
// member field called `_lights`.

//* ▲▲▲▲▲▲▲▲ description ▲▲▲▲▲▲▲▲ (do not modify or remove section marker)
//***************************************************************************

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

/// This is the main application widget.
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      home: Scaffold(
        appBar: AppBar(title: const Text(_title)),
        body: const Center(
          child: MyStatefulWidget(),
        ),
      ),
    );
  }
}

/// This is the stateful widget that the main application instantiates.
class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({Key? key}) : super(key: key);

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

/// This is the private State class that goes with MyStatefulWidget.
class _MyStatefulWidgetState extends State<MyStatefulWidget> {
//********************************************************************
//* ▼▼▼▼▼▼▼▼ code ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

  bool _lights = false;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: const Text('Lights'),
      value: _lights,
      onChanged: (bool value) {
        setState(() {
          _lights = value;
        });
      },
      secondary: const Icon(Icons.lightbulb_outline),
    );
  }

//* ▲▲▲▲▲▲▲▲ code ▲▲▲▲▲▲▲▲ (do not modify or remove section marker)
//********************************************************************

}
