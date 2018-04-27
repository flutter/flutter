// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class ChipColumn extends StatefulWidget {
  const ChipColumn({Key key}) : super(key: key);

  @override
  _ChipColumnState createState() => new _ChipColumnState();
}

class _ChipColumnState extends State<ChipColumn> {
  bool _showChip = true;
  bool _showInputChip = true;
  bool _choiceSelected = false;
  bool _filterSelected = false;

  @override
  Widget build(BuildContext context) {
    final List<Widget> chips = <Widget>[
      ChoiceChip(
        label: const Text('ChoiceChip'),
        selected: _choiceSelected,
        onSelected: (bool value) {
          setState(() {
            _choiceSelected = value;
          });
        },
      ),
      new FilterChip(
        label: const Text('FilterChip'),
        selected: _filterSelected,
        onSelected: (bool value) {
          setState(() {
            _filterSelected = value;
          });
        },
      ),
      new ActionChip(
        label: const Text('ActionChip'),
        onPressed: () {
          setState(() {
            Scaffold.of(context).showSnackBar(const SnackBar(
                  content: const Text('Activate!', textAlign: TextAlign.center),
                ));
          });
        },
      )
    ];

    if (_showChip) {
      chips.add(
        new Chip(
          label: const Text('Chip'),
          onDeleted: () {
            setState(
              () {
                _showChip = false;
              },
            );
          },
        ),
      );
    }
    if (_showInputChip) {
      chips.add(
        new InputChip(
          avatar: const CircleAvatar(
            backgroundImage: const AssetImage(
              'shrine/vendors/sandra-adams.jpg',
              package: 'flutter_gallery_assets',
            ),
          ),
          label: const Text('InputChip'),
          onDeleted: () {
            setState(
              () {
                _showInputChip = false;
              },
            );
          },
        ),
      );
    }

    return new Column(
      children: chips.map<Widget>(
            (Widget chip) => new Padding(padding: const EdgeInsets.all(8.0), child: chip),
      ).toList(),
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
    );
  }
}

class ChipDemo extends StatefulWidget {
  static const String routeName = '/material/chip';

  @override
  _ChipDemoState createState() => new _ChipDemoState();
}

class _ChipDemoState extends State<ChipDemo> {
  bool _showShapeBorder = false;

  @override
  Widget build(BuildContext context) {
    final ChipThemeData chipTheme = Theme.of(context).chipTheme;

    return new Scaffold(
      appBar: new AppBar(
        title: const Text('Chips'),
        actions: <Widget>[
          new IconButton(
            onPressed: () {
              setState(() {
                _showShapeBorder = !_showShapeBorder;
              });
            },
            icon: const Icon(Icons.sentiment_very_satisfied),
          )
        ],
      ),
      body: new Builder(
        builder: (BuildContext context) {
          return new ChipTheme(
            data: _showShapeBorder
                ? chipTheme.copyWith(
                    shape: const BeveledRectangleBorder(
                    side: const BorderSide(
                      width: 1.0,
                      style: BorderStyle.solid,
                      color: Colors.grey,
                    ),
                    borderRadius: const BorderRadius.all(const Radius.circular(10.0)),
                  ))
                : chipTheme,
            child: const Center(child: const ChipColumn()),
          );
        },
      ),
    );
  }
}
