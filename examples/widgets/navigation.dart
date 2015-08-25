// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/widgets.dart';

List<Route> routes = [
  new Route(
    name: 'home',
    builder: (navigator, route) => new Container(
      padding: const EdgeDims.all(30.0),
      decoration: new BoxDecoration(backgroundColor: const Color(0xFFCCCCCC)),
      child: new Column([
        new Text("You are at home"),
        new RaisedButton(
          child: new Text('GO SHOPPING'),
          onPressed: () => navigator.pushNamed('shopping')
        ),
        new RaisedButton(
          child: new Text('START ADVENTURE'),
          onPressed: () => navigator.pushNamed('adventure')
        )],
        justifyContent: FlexJustifyContent.center
      )
    )
  ),
  new Route(
    name: 'shopping',
    builder: (navigator, route) => new Container(
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
          onPressed: () => navigator.push(routes[2])
        )],
        justifyContent: FlexJustifyContent.center
      )
    )
  ),
  new Route(
    name: 'adventure',
    builder: (navigator, route) => new Container(
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
  )
];

class NavigationExampleApp extends App {
  NavigationState _navState = new NavigationState(routes);

  void onBack() {
    if (_navState.hasPrevious()) {
      setState(() {
        _navState.pop();
      });
    } else {
      super.onBack();
    }
  }

  Widget build() {
    return new Row([new Navigator(_navState)]);
  }
}

void main() {
  runApp(new NavigationExampleApp());
}
