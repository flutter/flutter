// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/material.dart';
import 'package:sky/src/fn3.dart';

final Map<String, RouteBuilder> routes = <String, RouteBuilder>{
  '/': (NavigatorState navigator, Route route) => new Container(
    padding: const EdgeDims.all(30.0),
    decoration: new BoxDecoration(backgroundColor: const Color(0xFFCCCCCC)),
    child: new Column([
      new Text("You are at home"),
      new RaisedButton(
        child: new Text('GO SHOPPING'),
        onPressed: () => navigator.pushNamed('/shopping')
      ),
      new RaisedButton(
        child: new Text('START ADVENTURE'),
        onPressed: () => navigator.pushNamed('/adventure')
      )],
      justifyContent: FlexJustifyContent.center
    )
  ),
  '/shopping': (NavigatorState navigator, Route route) => new Container(
    padding: const EdgeDims.all(20.0),
    decoration: new BoxDecoration(backgroundColor: const Color(0xFFBF5FFF)),
    child: new Column([
      new Text("Village Shop"),
      new RaisedButton(
        child: new Text('RETURN HOME'),
        onPressed: () => navigator.pop()
      ),
      new RaisedButton(
        child: new Text('GO TO DUNGEON'),
        onPressed: () => navigator.pushNamed('/adventure')
      )],
      justifyContent: FlexJustifyContent.center
    )
  ),
  '/adventure': (NavigatorState navigator, Route route) => new Container(
    padding: const EdgeDims.all(20.0),
    decoration: new BoxDecoration(backgroundColor: const Color(0xFFDC143C)),
    child: new Column([
      new Text("Monster's Lair"),
      new RaisedButton(
        child: new Text('RUN!!!'),
        onPressed: () => navigator.pop()
      )],
      justifyContent: FlexJustifyContent.center
    )
  )
};

final ThemeData theme = new ThemeData(
  brightness: ThemeBrightness.light,
  primarySwatch: Colors.purple
);

void main() {
  runApp(new App(
    title: 'Navigation Example',
    theme: theme,
    routes: routes
  ));
}
