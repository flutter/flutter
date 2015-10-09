// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/material.dart';

final Map<String, RouteBuilder> routes = <String, RouteBuilder>{
  '/': (RouteArguments args) => new Container(
    padding: const EdgeDims.all(30.0),
    decoration: new BoxDecoration(backgroundColor: const Color(0xFFCCCCCC)),
    child: new Column([
      new Text("You are at home"),
      new RaisedButton(
        child: new Text('GO SHOPPING'),
        onPressed: () => args.navigator.pushNamed('/shopping')
      ),
      new RaisedButton(
        child: new Text('START ADVENTURE'),
        onPressed: () => args.navigator.pushNamed('/adventure')
      )],
      justifyContent: FlexJustifyContent.center
    )
  ),
  '/shopping': (RouteArguments args) => new Container(
    padding: const EdgeDims.all(20.0),
    decoration: new BoxDecoration(backgroundColor: const Color(0xFFBF5FFF)),
    child: new Column([
      new Text("Village Shop"),
      new RaisedButton(
        child: new Text('RETURN HOME'),
        onPressed: () => args.navigator.pop()
      ),
      new RaisedButton(
        child: new Text('GO TO DUNGEON'),
        onPressed: () => args.navigator.pushNamed('/adventure')
      )],
      justifyContent: FlexJustifyContent.center
    )
  ),
  '/adventure': (RouteArguments args) => new Container(
    padding: const EdgeDims.all(20.0),
    decoration: new BoxDecoration(backgroundColor: const Color(0xFFDC143C)),
    child: new Column([
      new Text("Monster's Lair"),
      new RaisedButton(
        child: new Text('RUN!!!'),
        onPressed: () => args.navigator.pop()
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
  runApp(new MaterialApp(
    title: 'Navigation Example',
    theme: theme,
    routes: routes
  ));
}
