// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';

enum IndicatorType { overscroll, refresh }

class OverscrollDemo extends StatefulWidget {
  const OverscrollDemo({ Key key }) : super(key: key);

  static const String routeName = '/material/overscroll';

  @override
  OverscrollDemoState createState() => new OverscrollDemoState();
}

class OverscrollDemoState extends State<OverscrollDemo> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();
  static final List<String> _items = <String>[
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N'
  ];

  Future<Null> _handleRefresh() {
    final Completer<Null> completer = new Completer<Null>();
    new Timer(const Duration(seconds: 3), () { completer.complete(null); });
    return completer.future.then((_) {
       _scaffoldKey.currentState?.showSnackBar(new SnackBar(
         content: const Text('Refresh complete'),
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
    return new Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        title: const Text('Pull to refresh'),
        actions: <Widget>[
          new IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              _refreshIndicatorKey.currentState.show();
            }
          ),
        ]
      ),
      body: new RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _handleRefresh,
        child: new ListView.builder(
          padding: kMaterialListPadding,
          itemCount: _items.length,
          itemBuilder: (BuildContext context, int index) {
            final String item = _items[index];
            return new ListTile(
              isThreeLine: true,
              leading: new CircleAvatar(child: new Text(item)),
              title: new Text('This item represents $item.'),
              subtitle: const Text('Even more additional list item information appears on line three.'),
            );
          },
        ),
      ),
    );
  }
}
