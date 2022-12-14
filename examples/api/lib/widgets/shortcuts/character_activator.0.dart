// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for CharacterActivator

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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

class HelpMenuIntent extends Intent {
  const HelpMenuIntent();
}

class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({super.key});

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        CharacterActivator('?'): HelpMenuIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          HelpMenuIntent: CallbackAction<HelpMenuIntent>(
            onInvoke: (HelpMenuIntent intent) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Keep calm and carry on!')),
              );
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Column(
            children: const <Widget>[
              Text('Press question mark for help'),
            ],
          ),
        ),
      ),
    );
  }
}
