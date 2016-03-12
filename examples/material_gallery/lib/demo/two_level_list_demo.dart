// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class TwoLevelListDemo extends StatelessComponent {
  Widget build(BuildContext context) {
    return new Scaffold(
      toolBar: new ToolBar(center: new Text('Expand/Collapse List Control')),
      body: new Padding(
        padding: const EdgeInsets.all(0.0),
        child: new TwoLevelList(
          type: MaterialListType.oneLine,
          items: <Widget>[
            new TwoLevelListItem(center: new Text('Top')),
            new TwoLevelSublist(
              center: new Text('Sublist'),
              children: <Widget>[
                new TwoLevelListItem(center: new Text('One')),
                new TwoLevelListItem(center: new Text('Two')),
                new TwoLevelListItem(center: new Text('Free')),
                new TwoLevelListItem(center: new Text('Four'))
              ]
            ),
            new TwoLevelListItem(center: new Text('Bottom'))
          ]
        )
      )
    );
  }
}
