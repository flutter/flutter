// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';

/// Flutter code sample for [CupertinoExpansionTile].
void main() => runApp(const CupertinoExpansionTileFadeApp());

class CupertinoExpansionTileFadeApp extends StatelessWidget {
  const CupertinoExpansionTileFadeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      home: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
            middle: Text('Cupertino Expansion Tile - Fade')),
        child: SafeArea(child: ExpansionTileExample()),
      ),
    );
  }
}

class ExpansionTileExample extends StatefulWidget {
  const ExpansionTileExample({super.key});

  @override
  State<ExpansionTileExample> createState() => _ExpansionTileExampleState();
}

class _ExpansionTileExampleState extends State<ExpansionTileExample> {
  late ExpansibleController _controller;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = ExpansibleController();
    _controller.addListener(() {
      setState(() {
        _isExpanded = _controller.isExpanded;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        CupertinoExpansionTile(
          title: Text(
            _isExpanded ? 'Collapse me' : 'Tap to expand',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          controller: _controller,
          child: Container(
            padding: const EdgeInsets.all(16),
            color: CupertinoColors.white,
            child: const Text(
              'This is the expanded content of the CupertinoExpansionTile. '
              'You can place anything here: text, images, buttons, etc.',
              style: TextStyle(fontSize: 16, color: CupertinoColors.black),
            ),
          ),
        ),
      ],
    );
  }
}
