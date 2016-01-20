// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class TabsDemo extends StatelessComponent {
  final List<String> iconNames = <String>["event", "home", "android", "alarm", "face", "language"];

  Widget build(_) {
    return new TabBarSelection(
      values: iconNames,
      child: new Scaffold(
        toolBar: new ToolBar(
          center: new Text("Scrollable Tabs"),
          tabBar: new TabBar<String>(
            isScrollable: true,
            labels: new Map.fromIterable(
              iconNames,
              value: (String iconName) => new TabLabel(text: iconName, icon: "action/$iconName")
            )
          )
        ),
        body: new TabBarView(
          children: iconNames.map((String iconName) {
            return new Container(
              key: new ValueKey<String>(iconName),
              padding: const EdgeDims.all(12.0),
              child: new Card(
                child: new Center(child: new Icon(icon: "action/$iconName", size:IconSize.s48))
              )
            );
          }).toList()
        )
      )
    );
  }
}
