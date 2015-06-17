// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/navigator.dart';
import 'package:sky/widgets/transition.dart';
import 'package:sky/widgets/raised_button.dart';

List<Route> routes = [
  new Route(
    name: 'home',
    builder: (navigator) => new Container(
      padding: const EdgeDims.all(20.0),
      decoration: new BoxDecoration(backgroundColor: const Color(0xFFCCCCCC)),
      child: new Block([
        new Text("You are at home"),
        new RaisedButton(
          child: new Text('GO SHOPPING'),
          onPressed: () => navigator.pushNamed('shopping')
        ),
        new RaisedButton(
          child: new Text('START ADVENTURE'),
          onPressed: () => navigator.pushNamed('adventure')
        )
      ])
    )
  ),
  new Route(
    name: 'shopping',
    builder: (navigator) => new Container(
      padding: const EdgeDims.all(20.0),
      decoration: new BoxDecoration(backgroundColor: const Color(0xFFBF5FFF)),
      child: new Block([
        new Text("Village Shop"),
        new RaisedButton(
          child: new Text('RETURN HOME'),
          onPressed: () => navigator.back()
        ),
        new RaisedButton(
          child: new Text('GO TO DUNGEON'),
          onPressed: () => navigator.push(routes[2])
        )
      ])
    )
  ),
  new Route(
    name: 'adventure',
    builder: (navigator) => new Container(
      padding: const EdgeDims.all(20.0),
      decoration: new BoxDecoration(backgroundColor: const Color(0xFFDC143C)),
      child: new Block([
        new Text("Monster's Lair"),
        new RaisedButton(
          child: new Text('NO WAIT! GO BACK!'),
          onPressed: () => navigator.pop()
        )
      ])
    )
  )
];

class NavigationExampleApp extends App {
  NavigationState _navState = new NavigationState(routes);

  Widget build() {
    return new Flex([new Navigator(_navState)]);
  }
}

void main() {
  runApp(new NavigationExampleApp());
}
