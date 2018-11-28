// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'playground_demo.dart';

class PlaygroundScaffold extends StatelessWidget {
  const PlaygroundScaffold({
    Key key,
    @required this.title,
    @required this.demos,
  });

  final String title;
  final List<PlaygroundDemo> demos;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: demos.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: IconButton(
            icon: const BackButtonIcon(),
            tooltip: 'Back',
            onPressed: () {
              Navigator.maybePop(context);
            },
          ),
          bottom: TabBar(
            isScrollable: true,
            tabs: demos.map<Widget>(
              (PlaygroundDemo demo) {
                return Tab(text: demo.tabName());
              },
            ).toList(),
          ),
        ),
        body: TabBarView(children: demos),
      ),
    );
  }
}
