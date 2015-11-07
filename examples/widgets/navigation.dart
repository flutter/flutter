// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class Home extends StatelessComponent {
  Widget build(BuildContext context) {
    return new Container(
      padding: const EdgeDims.all(30.0),
      decoration: new BoxDecoration(backgroundColor: const Color(0xFFCCCCCC)),
      child: new Column(<Widget>[
        new Text("You are at home"),
        new RaisedButton(
          child: new Text('GO SHOPPING'),
          onPressed: () => Navigator.of(context).pushNamed('/shopping')
        ),
        new RaisedButton(
          child: new Text('START ADVENTURE'),
          onPressed: () => Navigator.of(context).pushNamed('/adventure')
        )],
        justifyContent: FlexJustifyContent.center
      )
    );
  }
}

class Shopping extends StatelessComponent {
  Widget build(BuildContext context) {
    return new Container(
      padding: const EdgeDims.all(20.0),
      decoration: new BoxDecoration(backgroundColor: const Color(0xFFBF5FFF)),
      child: new Column(<Widget>[
        new Text("Village Shop"),
        new RaisedButton(
          child: new Text('RETURN HOME'),
          onPressed: () => Navigator.of(context).pop()
        ),
        new RaisedButton(
          child: new Text('GO TO DUNGEON'),
          onPressed: () => Navigator.of(context).pushNamed('/adventure')
        )],
        justifyContent: FlexJustifyContent.center
      )
    );
  }
}

class Adventure extends StatelessComponent {
  Widget build(BuildContext context) {
    return new Container(
      padding: const EdgeDims.all(20.0),
      decoration: new BoxDecoration(backgroundColor: const Color(0xFFDC143C)),
      child: new Column(<Widget>[
        new Text("Monster's Lair"),
        new RaisedButton(
          child: new Text('RUN!!!'),
          onPressed: () => Navigator.of(context).pop()
        )],
        justifyContent: FlexJustifyContent.center
      )
    );
  }
}

final Map<String, RouteBuilder> routes = <String, RouteBuilder>{
  '/': (_) => new Home(),
  '/shopping': (_) => new Shopping(),
  '/adventure': (_) => new Adventure(),
};

final ThemeData theme = new ThemeData(
  brightness: ThemeBrightness.light,
  primarySwatch: Colors.purple
);

void main() {
  runApp(new MaterialApp(
    title: 'Navigation Example',
    theme: theme,
    routes: routes
  ));
}
