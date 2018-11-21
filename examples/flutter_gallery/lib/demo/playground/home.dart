// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'playground_demo.dart';

class PlaygroundScaffold extends StatelessWidget {
  const PlaygroundScaffold({
    this.title,
    this.demos,
  });

  static final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  final String title;
  final List<PlaygroundDemo> demos;

  PlaygroundDemo _currentDemo(BuildContext context) =>
      demos[DefaultTabController.of(context).index];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: demos.length,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(title),
          leading: IconButton(
              icon: const BackButtonIcon(),
              tooltip: 'Back',
              onPressed: () {
                Navigator.maybePop(context);
              }),
          bottom: TabBar(
            isScrollable: true,
            tabs: demos.map<Widget>((PlaygroundDemo demo) {
              return Tab(text: demo.tabName());
            }).toList(),
          ),
        ),
        body: TabBarView(
            children: demos.map<Widget>((PlaygroundDemo demo) {
          return demo;
        }).toList()),
      ),
    );
  }
}

