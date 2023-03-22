// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for [CupertinoRadio].

import 'package:flutter/cupertino.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: _title,
      theme: CupertinoThemeData(brightness: Brightness.light),
      home: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(_title),
        ),
        child: SafeArea(
          child: MyStatefulWidget(),
        ),
      ),
    );
  }
}

enum SingingCharacter { lafayette, jefferson }

class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({super.key});

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  SingingCharacter? _character = SingingCharacter.lafayette;

  @override
  Widget build(BuildContext context) {
    return CupertinoListSection(
      children: <Widget>[
        CupertinoListTile(
          title: const Text('Lafayette'),
          leading: CupertinoRadio<SingingCharacter>(
            value: SingingCharacter.lafayette,
            groupValue: _character,
            onChanged: (SingingCharacter? value) {
              setState(() {
                _character = value;
              });
            },
          ),
        ),
        CupertinoListTile(
          title: const Text('Thomas Jefferson'),
          leading: CupertinoRadio<SingingCharacter>(
            value: SingingCharacter.jefferson,
            groupValue: _character,
            onChanged: (SingingCharacter? value) {
              setState(() {
                _character = value;
              });
            },
          ),
        ),
      ],
    );
  }
}
