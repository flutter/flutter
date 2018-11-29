// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class PlaygroundScaffold extends StatelessWidget {
  const PlaygroundScaffold({
    Key key,
    @required this.title,
    @required this.demos,
  })  : assert(title != null),
        assert(demos != null),
        super(key: key);

  final String title;
  final Map<String, Widget> demos;

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
            tabs: demos.keys
                .map<Tab>((String title) => Tab(text: title))
                .toList(),
          ),
        ),
        body: TabBarView(children: demos.values.toList()),
      ),
    );
  }
}
