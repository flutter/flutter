// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

const String _kAsset0 = 'packages/flutter_gallery_assets/shrine/vendors/zach.jpg';
const String _kAsset1 = 'packages/flutter_gallery_assets/shrine/vendors/16c477b.jpg';
const String _kAsset2 = 'packages/flutter_gallery_assets/shrine/vendors/sandra-adams.jpg';

class DrawerDemo extends StatefulWidget {
  static const String routeName = '/material/drawer';

  @override
  _DrawerDemoState createState() => new _DrawerDemoState();
}

class _DrawerDemoState extends State<DrawerDemo> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  static const List<String> _drawerContents = const <String>[
    'A', 'B', 'C', 'D', 'E',
  ];

  AnimationController _controller;
  Animation<double> _drawerContentsOpacity;
  Animation<FractionalOffset> _drawerDetailsPosition;
  bool _showDrawerContents = true;

  @override
  void initState() {
    super.initState();
    _controller = new AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _drawerContentsOpacity = new CurvedAnimation(
      parent: new ReverseAnimation(_controller),
      curve: Curves.fastOutSlowIn,
    );
    _drawerDetailsPosition = new FractionalOffsetTween(
      begin: const FractionalOffset(0.0, -1.0),
      end: const FractionalOffset(0.0, 0.0),
    ).animate(new CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _backIcon() {
    switch (Theme.of(context).platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return Icons.arrow_back;
      case TargetPlatform.iOS:
        return Icons.arrow_back_ios;
    }
    assert(false);
    return null;
  }

  void _showNotImplementedMessage() {
    Navigator.of(context).pop(); // Dismiss the drawer.
    _scaffoldKey.currentState.showSnackBar(const SnackBar(
      content: const Text("The drawer's items don't do anything")
    ));
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        leading: new IconButton(
          icon: new Icon(_backIcon()),
          alignment: FractionalOffset.centerLeft,
          tooltip: 'Back',
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Navigation drawer'),
      ),
      drawer: new Drawer(
        child: new ListView(
          children: <Widget>[
            new UserAccountsDrawerHeader(
              accountName: const Text('Zach Widget'),
              accountEmail: const Text('zach.widget@example.com'),
              currentAccountPicture: new CircleAvatar(backgroundImage: new AssetImage(_kAsset0)),
              otherAccountsPictures: <Widget>[
                new CircleAvatar(backgroundImage: new AssetImage(_kAsset1)),
                new CircleAvatar(backgroundImage: new AssetImage(_kAsset2)),
              ],
              onDetailsPressed: () {
                _showDrawerContents = !_showDrawerContents;
                if (_showDrawerContents)
                  _controller.reverse();
                else
                  _controller.forward();
              },
            ),
            new ClipRect(
              child: new Stack(
                children: <Widget>[
                  // The initial contents of the drawer.
                  new FadeTransition(
                    opacity: _drawerContentsOpacity,
                    child: new Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _drawerContents.map((String id) {
                        return new ListTile(
                          leading: new CircleAvatar(child: new Text(id)),
                          title: new Text('Drawer item $id'),
                          onTap: _showNotImplementedMessage,
                        );
                      }).toList(),
                    ),
                  ),
                  // The drawer's "details" view.
                  new SlideTransition(
                    position: _drawerDetailsPosition,
                    child: new FadeTransition(
                      opacity: new ReverseAnimation(_drawerContentsOpacity),
                      child: new Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          new ListTile(
                            leading: const Icon(Icons.add),
                            title: const Text('Add account'),
                            onTap: _showNotImplementedMessage,
                          ),
                          new ListTile(
                            leading: const Icon(Icons.settings),
                            title: const Text('Manage accounts'),
                            onTap: _showNotImplementedMessage,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: new Center(
        child: new InkWell(
          onTap: () {
            _scaffoldKey.currentState.openDrawer();
          },
          child: new Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new Container(
                width: 100.0,
                height: 100.0,
                decoration: new BoxDecoration(
                  shape: BoxShape.circle,
                  image: new DecorationImage(
                    image: new AssetImage(_kAsset0),
                  ),
                ),
              ),
              new Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: new Text('Tap here to open the drawer',
                  style: Theme.of(context).textTheme.subhead,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
