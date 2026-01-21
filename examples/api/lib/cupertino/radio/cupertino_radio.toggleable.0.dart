// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';

/// Flutter code sample for [CupertinoRadio.toggleable].

void main() => runApp(const CupertinoRadioApp());

class CupertinoRadioApp extends StatelessWidget {
  const CupertinoRadioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      home: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text('CupertinoRadio Toggleable Example'),
        ),
        child: SafeArea(child: CupertinoRadioExample()),
      ),
    );
  }
}

enum SingingCharacter { mulligan, hamilton }

class CupertinoRadioExample extends StatefulWidget {
  const CupertinoRadioExample({super.key});

  @override
  State<CupertinoRadioExample> createState() => _CupertinoRadioExampleState();
}

class _CupertinoRadioExampleState extends State<CupertinoRadioExample> {
  SingingCharacter? _character = SingingCharacter.mulligan;

  @override
  Widget build(BuildContext context) {
    return RadioGroup<SingingCharacter>(
      groupValue: _character,
      onChanged: (SingingCharacter? value) {
        setState(() {
          _character = value;
        });
      },
      child: CupertinoListSection(
        children: const <Widget>[
          CupertinoListTile(
            title: Text('Hercules Mulligan'),
            leading: CupertinoRadio<SingingCharacter>(
              value: SingingCharacter.mulligan,
              // TRY THIS: Try setting the toggleable value to false and
              // see how that changes the behavior of the widget.
              toggleable: true,
            ),
          ),
          CupertinoListTile(
            title: Text('Eliza Hamilton'),
            leading: CupertinoRadio<SingingCharacter>(
              value: SingingCharacter.hamilton,
              toggleable: true,
            ),
          ),
        ],
      ),
    );
  }
}
