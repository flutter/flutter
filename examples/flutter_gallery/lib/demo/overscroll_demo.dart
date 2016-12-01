// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';

enum IndicatorType { overscroll, refresh }

class OverscrollDemo extends StatefulWidget {
  OverscrollDemo({ Key key }) : super(key: key);

  static const String routeName = '/overscroll';

  @override
  OverscrollDemoState createState() => new OverscrollDemoState();
}

class OverscrollDemoState extends State<OverscrollDemo> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();
  static final GlobalKey<ScrollableState> _scrollableKey = new GlobalKey<ScrollableState>();
  static final List<String> _items = <String>[
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N'
  ];

  IndicatorType _type = IndicatorType.refresh;

  Future<Null> refresh() {
    Completer<Null> completer = new Completer<Null>();
    new Timer(new Duration(seconds: 3), () { completer.complete(null); });
    return completer.future.then((_) {
       _scaffoldKey.currentState?.showSnackBar(new SnackBar(
         content: new Text("Refresh complete"),
         action: new SnackBarAction(
           label: 'RETRY',
           onPressed: () {
             _refreshIndicatorKey.currentState.show();
           }
         )
       ));
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body = new MaterialList(
      type: MaterialListType.threeLine,
      padding: const EdgeInsets.all(8.0),
      scrollableKey: _scrollableKey,
      children: _items.map((String item) {
        return new ListItem(
          isThreeLine: true,
          leading: new CircleAvatar(child: new Text(item)),
          title: new Text('This item represents $item.'),
          subtitle: new Text('Even more additional list item information appears on line three.')
        );
      })
    );

    String  indicatorTypeText;
    switch (_type) {
      case IndicatorType.overscroll:
        indicatorTypeText = 'Over-scroll indicator';
        break;
      case IndicatorType.refresh:
        body = new RefreshIndicator(
          key: _refreshIndicatorKey,
          refresh: refresh,
          scrollableKey: _scrollableKey,
          location: RefreshIndicatorLocation.top,
          child: body,
        );
        indicatorTypeText = 'Refresh indicator';
        break;
    }

    return new Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        title: new Text('$indicatorTypeText'),
        actions: <Widget>[
          new IconButton(
            icon: new Icon(Icons.refresh),
            tooltip: 'Pull to refresh',
            onPressed: () {
              setState(() {
                _type = IndicatorType.refresh;
              });
            }
          ),
          new IconButton(
            icon: new Icon(Icons.play_for_work),
            tooltip: 'Over-scroll indicator',
            onPressed: () {
              setState(() {
                _type = IndicatorType.overscroll;
              });
            }
          )
        ]
      ),
      body: body
    );
  }
}
