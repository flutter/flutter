// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';

/// Flutter code sample for [CupertinoExpansionTile] showing both
/// fade and scroll transition modes.

void main() => runApp(const CupertinoExpansionTileApp());

class CupertinoExpansionTileApp extends StatelessWidget {
  const CupertinoExpansionTileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      home: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text('Cupertino Expansion Tile')),
        backgroundColor: CupertinoColors.systemGroupedBackground,
        child: SafeArea(child: ExpansionTileExamples()),
      ),
    );
  }
}

class ExpansionTileExamples extends StatelessWidget {
  const ExpansionTileExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      spacing: 10,
      children: <Widget>[
        TransitionTileSection(
          title: 'Fade Transition',
          transitionMode: ExpansionTileTransitionMode.fade,
        ),
        TransitionTileSection(
          title: 'Scroll Transition',
          transitionMode: ExpansionTileTransitionMode.scroll,
        ),
      ],
    );
  }
}

class TransitionTileSection extends StatefulWidget {
  const TransitionTileSection({super.key, required this.title, required this.transitionMode});

  final String title;
  final ExpansionTileTransitionMode transitionMode;

  @override
  State<TransitionTileSection> createState() => _TransitionTileSectionState();
}

class _TransitionTileSectionState extends State<TransitionTileSection> {
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
    return CupertinoExpansionTile(
      title: Text(
        '${widget.title} - ${_isExpanded ? 'Collapse me' : 'Tap to expand'}',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      controller: _controller,
      transitionMode: widget.transitionMode,
      child: CupertinoListSection.insetGrouped(
        children: const <Widget>[
          CupertinoListTile(
            leading: Icon(CupertinoIcons.person),
            backgroundColor: CupertinoColors.white,
            title: Text('Profile', style: TextStyle(color: CupertinoColors.black)),
          ),
          CupertinoListTile(
            leading: Icon(CupertinoIcons.mail),
            backgroundColor: CupertinoColors.white,
            title: Text('Messages', style: TextStyle(color: CupertinoColors.black)),
          ),
          CupertinoListTile(
            leading: Icon(CupertinoIcons.settings),
            backgroundColor: CupertinoColors.white,
            title: Text('Settings', style: TextStyle(color: CupertinoColors.black)),
          ),
        ],
      ),
    );
  }
}
