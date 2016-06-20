// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

enum TabsDemoStyle {
  iconsAndText,
  iconsOnly,
  textOnly
}

class ScrollableTabsDemo extends StatefulWidget {
  static const String routeName = '/scrollable-tabs';

  @override
  ScrollableTabsDemoState createState() => new ScrollableTabsDemoState();
}

class ScrollableTabsDemoState extends State<ScrollableTabsDemo> {
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

  TabsDemoStyle _demoStyle = TabsDemoStyle.iconsAndText;

  void changeDemoStyle(TabsDemoStyle style) {
    setState(() {
      _demoStyle = style;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color iconColor = Theme.of(context).accentColor;
    return new TabBarSelection<IconData>(
      values: icons,
      child: new Scaffold(
        appBar: new AppBar(
          title: new Text('Scrollable tabs'),
          actions: <Widget>[
            new PopupMenuButton<TabsDemoStyle>(
              onSelected: changeDemoStyle,
              itemBuilder: (BuildContext context) => <PopupMenuItem<TabsDemoStyle>>[
                new PopupMenuItem<TabsDemoStyle>(
                  value: TabsDemoStyle.iconsAndText,
                  child: new Text('Icons and text')
                ),
                new PopupMenuItem<TabsDemoStyle>(
                  value: TabsDemoStyle.iconsOnly,
                  child: new Text('Icons only')
                ),
                new PopupMenuItem<TabsDemoStyle>(
                  value: TabsDemoStyle.textOnly,
                  child: new Text('Text only')
                ),
              ]
            )
          ],
          bottom: new TabBar<IconData>(
            isScrollable: true,
            labels: new Map<IconData, TabLabel>.fromIterable(
              icons,
              value: (IconData icon) {
                switch(_demoStyle) {
                  case TabsDemoStyle.iconsAndText:
                    return new TabLabel(text: labels[icon], icon: icon);
                  case TabsDemoStyle.iconsOnly:
                    return new TabLabel(icon: icon);
                  case TabsDemoStyle.textOnly:
                    return new TabLabel(text: labels[icon]);
                }
              }
            )
          )
        ),
        body: new TabBarView<IconData>(
          children: icons.map((IconData icon) {
            return new Container(
              key: new ObjectKey(icon),
              padding: const EdgeInsets.all(12.0),
              child:new Card(
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
