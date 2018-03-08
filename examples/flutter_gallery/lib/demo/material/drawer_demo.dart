// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

const String _kAsset0 = 'shrine/vendors/zach.jpg';
const String _kAsset1 = 'shrine/vendors/16c477b.jpg';
const String _kAsset2 = 'shrine/vendors/sandra-adams.jpg';
const String _kGalleryAssetsPackage = 'flutter_gallery_assets';

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
  Animation<Offset> _drawerDetailsPosition;
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
    _drawerDetailsPosition = new Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
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
          alignment: Alignment.centerLeft,
          tooltip: 'Back',
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Navigation drawer'),
      ),
      drawer: new Drawer(
        child: new Column(
          children: <Widget>[
            new UserAccountsDrawerHeader(
              accountName: const Text('Zach Widget'),
              accountEmail: const Text('zach.widget@example.com'),
              currentAccountPicture: const CircleAvatar(
                backgroundImage: const AssetImage(
                  _kAsset0,
                  package: _kGalleryAssetsPackage,
                ),
              ),
              otherAccountsPictures: <Widget>[
                new GestureDetector(
                  onTap: () {
                    _onOtherAccountsTap(context);
                  },
                  child: new Semantics(
                    label: 'Switch to Account B',
                    child: const CircleAvatar(
                      backgroundImage: const AssetImage(
                        _kAsset1,
                        package: _kGalleryAssetsPackage,
                      ),
                    ),
                  ),
                ),
                new GestureDetector(
                  onTap: () {
                    _onOtherAccountsTap(context);
                  },
                  child: new Semantics(
                    label: 'Switch to Account C',
                    child: const CircleAvatar(
                      backgroundImage: const AssetImage(
                        _kAsset2,
                        package: _kGalleryAssetsPackage,
                      ),
                    ),
                  ),
                ),
              ],
              margin: EdgeInsets.zero,
              onDetailsPressed: () {
                _showDrawerContents = !_showDrawerContents;
                if (_showDrawerContents)
                  _controller.reverse();
                else
                  _controller.forward();
              },
            ),
            new MediaQuery.removePadding(
              context: context,
              // DrawerHeader consumes top MediaQuery padding.
              removeTop: true,
              child: new Expanded(
                child: new ListView(
                  padding: const EdgeInsets.only(top: 8.0),
                  children: <Widget>[
                    new Stack(
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
                  ],
                ),
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
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: const DecorationImage(
                    image: const AssetImage(
                      _kAsset0,
                      package: _kGalleryAssetsPackage,
                    ),
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

  void _onOtherAccountsTap(BuildContext context) {
    showDialog<Null>(
      context: context,
      builder: (BuildContext context) {
        return new AlertDialog(
          title: const Text('Account switching not implemented.'),
          actions: <Widget>[
            new FlatButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
