// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for [CupertinoRadio.toggleable].

import 'package:flutter/cupertino.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: _title,
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

enum SingingCharacter { mulligan, hamilton }

class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({super.key});

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  SingingCharacter? _character = SingingCharacter.mulligan;

  @override
  Widget build(BuildContext context) {
    return CupertinoListSection(
      children: <Widget>[
        CupertinoListTile(
          title: const Text('Hercules Mulligan'),
          leading: CupertinoRadio<SingingCharacter>(
            value: SingingCharacter.mulligan,
            groupValue: _character,
            // TRY THIS: Try setting the toggleable value to false and
            // see how that changes the behavior of the widget.
            toggleable: true,
            onChanged: (SingingCharacter? value) {
              setState(() {
                _character = value;
              });
            },
          ),
        ),
        CupertinoListTile(
          title: const Text('Eliza Hamilton'),
          leading: CupertinoRadio<SingingCharacter>(
            value: SingingCharacter.hamilton,
            groupValue: _character,
            toggleable: true,
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
