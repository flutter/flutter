// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class TabsDemo extends StatelessComponent {
  final List<IconData> icons = <IconData>[
    Icons.event,
    Icons.home,
    Icons.android,
    Icons.alarm,
    Icons.face,
    Icons.language,
  ];

  final Map<IconData, String> labels = <IconData, String>{
    Icons.event: 'EVENT',
    Icons.home: 'HOME',
    Icons.android: 'ANDROID',
    Icons.alarm: 'ALARM',
    Icons.face: 'FACE',
    Icons.language: 'LANGUAGE',
  };

  Widget build(BuildContext context) {
    final Color iconColor = Theme.of(context).accentColor;
    return new TabBarSelection(
      values: icons,
      child: new Scaffold(
        toolBar: new ToolBar(
          center: new Text("Scrollable Tabs"),
          tabBar: new TabBar<String>(
            isScrollable: true,
            labels: new Map.fromIterable(
              icons,
              value: (IconData icon) => new TabLabel(text: labels[icon], icon: icon)
            )
          )
        ),
        body: new TabBarView(
          children: icons.map((IconData icon) {
            return new Container(
              key: new ObjectKey(icon),
              padding: const EdgeDims.all(12.0),
              child: new Card(
                child: new Center(
                  child: new Icon(
                    icon: icon,
                    color: iconColor,
                    size: 128.0
                  )
                )
              )
            );
          }).toList()
        )
      )
    );
  }
}
