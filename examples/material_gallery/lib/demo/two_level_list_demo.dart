// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class TwoLevelListDemo extends StatelessWidget {
  Widget build(BuildContext context) {
    return new Scaffold(
      toolBar: new ToolBar(center: new Text('Expand/Collapse List Control')),
      body: new Padding(
        padding: const EdgeInsets.all(0.0),
        child: new TwoLevelList(
          type: MaterialListType.oneLine,
          items: <Widget>[
            new TwoLevelListItem(title: new Text('Top')),
            new TwoLevelSublist(
              center: new Text('Sublist'),
              children: <Widget>[
                new TwoLevelListItem(title: new Text('One')),
                new TwoLevelListItem(title: new Text('Two')),
                new TwoLevelListItem(title: new Text('Free')),
                new TwoLevelListItem(title: new Text('Four'))
              ]
            ),
            new TwoLevelListItem(title: new Text('Bottom'))
          ]
        )
      )
    );
  }
}
