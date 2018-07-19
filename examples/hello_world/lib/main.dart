// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

void main() {
  runApp(new MaterialApp(
      home: new DefaultTabController(
          length: 3,
          child: new SafeArea(
              child: new Scaffold(
                  bottomNavigationBar: new Container(
                    child: new TabBar(
                        labelColor: Colors.black,
                        labelStyle: TextStyle(fontSize: 20.0),
                        tabs: [
                          Text('foo'),
                          Text('bar'),
                          Text('baz'),
                        ]
                    ),
                  ),
                  body: new TabBarView(
                      children: [
                        new FooPage(),
                        new BarPage(),
                        new BazPage(),
                      ]
                  )
              )
          )
      )
  )
  );
}

class FooPage extends StatefulWidget {
  @override
  FooState createState() => new FooState();
}

class FooState extends State<FooPage> with AutomaticKeepAliveClientMixin<FooPage> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    return new Center(
        child: new Text('foo')
    );
  }
}

class BarPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Center(
        child: new Text('bar')
    );
  }
}

class BazPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Center(
        child: new Text('baz')
    );
  }
}