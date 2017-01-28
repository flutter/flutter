// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class _ContactCategory extends StatelessWidget {
  _ContactCategory({ Key key, this.icon, this.children }) : super(key: key);

  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    return new Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      decoration: new BoxDecoration(
        border: new Border(bottom: new BorderSide(color: themeData.dividerColor))
      ),
      child: new DefaultTextStyle(
        style: Theme.of(context).textTheme.subhead,
        child: new Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Container(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              width: 72.0,
              child: new Icon(icon, color: themeData.primaryColor)
            ),
            new Expanded(child: new Column(children: children))
          ]
        )
      )
    );
  }
}

class _ContactItem extends StatelessWidget {
  _ContactItem({ Key key, this.icon, this.lines, this.tooltip, this.onPressed }) : super(key: key) {
    assert(lines.length > 1);
  }

  final IconData icon;
  final List<String> lines;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    List<Widget> columnChildren = lines.sublist(0, lines.length - 1).map((String line) => new Text(line)).toList();
    columnChildren.add(new Text(lines.last, style: themeData.textTheme.caption));

    List<Widget> rowChildren = <Widget>[
      new Expanded(
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: columnChildren
        )
      )
    ];
    if (icon != null) {
      rowChildren.add(new SizedBox(
        width: 72.0,
        child: new IconButton(
          icon: new Icon(icon),
          color: themeData.primaryColor,
          onPressed: onPressed
        )
      ));
    }
    return new Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: new Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: rowChildren
      )
    );
  }
}

class ContactsDemo extends StatefulWidget {
  static const String routeName = '/contacts';

  @override
  ContactsDemoState createState() => new ContactsDemoState();
}

class ContactsDemoState extends State<ContactsDemo> {
  static final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  static final GlobalKey<ScrollableState> _scrollableKey = new GlobalKey<ScrollableState>();
  final double _appBarHeight = 256.0;
  AppBarBehavior _appBarBehavior = AppBarBehavior.under;

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    return new Theme(
      data: new ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.indigo,
        platform: Theme.of(context).platform,
      ),
      child: new Scaffold(
        key: _scaffoldKey,
        scrollableKey: _scrollableKey,
        appBarBehavior: _appBarBehavior,
        appBar: new AppBar(
          expandedHeight: _appBarHeight,
          actions: <Widget>[
            new IconButton(
              icon: new Icon(Icons.create),
              tooltip: 'Edit',
              onPressed: () {
                _scaffoldKey.currentState.showSnackBar(new SnackBar(
                  content: new Text('This is actually just a demo. Editing isn\'t supported.')
                ));
              }
            ),
            new PopupMenuButton<AppBarBehavior>(
              onSelected: (AppBarBehavior value) {
                setState(() {
                  _appBarBehavior = value;
                });
              },
              itemBuilder: (BuildContext context) => <PopupMenuItem<AppBarBehavior>>[
                new PopupMenuItem<AppBarBehavior>(
                  value: AppBarBehavior.scroll,
                  child: new Text('App bar scrolls away')
                ),
                new PopupMenuItem<AppBarBehavior>(
                  value: AppBarBehavior.under,
                  child: new Text('App bar stays put')
                )
              ]
            )
          ],
          flexibleSpace: new FlexibleSpaceBar(
            title : new Text('Ali Connors'),
            background: new Stack(
              children: <Widget>[
                new Image.asset(
                  'packages/flutter_gallery_assets/ali_connors.jpg',
                  fit: ImageFit.cover,
                  height: _appBarHeight
                ),
                // This gradient ensures that the toolbar icons are distinct
                // against the background image.
                new DecoratedBox(
                  decoration: new BoxDecoration(
                    gradient: new LinearGradient(
                      begin: const FractionalOffset(0.5, 0.0),
                      end: const FractionalOffset(0.5, 0.30),
                      colors: <Color>[const Color(0x60000000), const Color(0x00000000)]
                    )
                  )
                )
              ]
            )
          )
        ),
        body: new Block(
          padding: new EdgeInsets.only(top: _appBarHeight + statusBarHeight),
          scrollableKey: _scrollableKey,
          children: <Widget>[
            new _ContactCategory(
              icon: Icons.call,
              children: <Widget>[
                new _ContactItem(
                  icon: Icons.message,
                  tooltip: 'Send message',
                  onPressed: () {
                    _scaffoldKey.currentState.showSnackBar(new SnackBar(
                      content: new Text('Pretend that this opened your SMS application.')
                    ));
                  },
                  lines: <String>[
                    '(650) 555-1234',
                    'Mobile'
                  ]
                ),
                new _ContactItem(
                  icon: Icons.message,
                  tooltip: 'Send message',
                  onPressed: () {
                    _scaffoldKey.currentState.showSnackBar(new SnackBar(
                      content: new Text('In this demo, this button doesn\'t do anything.')
                    ));
                  },
                  lines: <String>[
                    '(323) 555-6789',
                    'Work'
                  ]
                ),
                new _ContactItem(
                  icon: Icons.message,
                  tooltip: 'Send message',
                  onPressed: () {
                    _scaffoldKey.currentState.showSnackBar(new SnackBar(
                      content: new Text('Imagine if you will, a messaging application.')
                    ));
                  },
                  lines: <String>[
                    '(650) 555-6789',
                    'Home'
                  ]
                ),
              ]
            ),
            new _ContactCategory(
              icon: Icons.contact_mail,
              children: <Widget>[
                new _ContactItem(
                  icon: Icons.email,
                  tooltip: 'Send personal e-mail',
                  onPressed: () {
                    _scaffoldKey.currentState.showSnackBar(new SnackBar(
                      content: new Text('Here, your e-mail application would open.')
                    ));
                  },
                  lines: <String>[
                    'ali_connors@example.com',
                    'Personal'
                  ]
                ),
                new _ContactItem(
                  icon: Icons.email,
                  tooltip: 'Send work e-mail',
                  onPressed: () {
                    _scaffoldKey.currentState.showSnackBar(new SnackBar(
                      content: new Text('This is a demo, so this button does not actually work.')
                    ));
                  },
                  lines: <String>[
                    'aliconnors@example.com',
                    'Work'
                  ]
                )
              ]
            ),
            new _ContactCategory(
              icon: Icons.location_on,
              children: <Widget>[
                new _ContactItem(
                  icon: Icons.map,
                  tooltip: 'Open map',
                  onPressed: () {
                    _scaffoldKey.currentState.showSnackBar(new SnackBar(
                      content: new Text('This would show a map of San Francisco.')
                    ));
                  },
                  lines: <String>[
                    '2000 Main Street',
                    'San Francisco, CA',
                    'Home'
                  ]
                ),
                new _ContactItem(
                  icon: Icons.map,
                  tooltip: 'Open map',
                  onPressed: () {
                    _scaffoldKey.currentState.showSnackBar(new SnackBar(
                      content: new Text('This would show a map of Mountain View.')
                    ));
                  },
                  lines: <String>[
                    '1600 Amphitheater Parkway',
                    'Mountain View, CA',
                    'Work'
                  ]
                ),
                new _ContactItem(
                  icon: Icons.map,
                  tooltip: 'Open map',
                  onPressed: () {
                    _scaffoldKey.currentState.showSnackBar(new SnackBar(
                      content: new Text('This would also show a map, if this was not a demo.')
                    ));
                  },
                  lines: <String>[
                    '126 Severyns Ave',
                    'Mountain View, CA',
                    'Jet Travel'
                  ]
                )
              ]
            ),
            new _ContactCategory(
              icon: Icons.today,
              children: <Widget>[
                new _ContactItem(
                  lines: <String>[
                    'Birthday',
                    'January 9th, 1989'
                  ]
                ),
                new _ContactItem(
                  lines: <String>[
                    'Wedding anniversary',
                    'June 21st, 2014'
                  ]
                ),
                new _ContactItem(
                  lines: <String>[
                    'First day in office',
                    'January 20th, 2015'
                  ]
                ),
                new _ContactItem(
                  lines: <String>[
                    'Last day in office',
                    'August 9th, 2015'
                  ]
                )
              ]
            )
          ]
        )
      )
    );
  }
}
