// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/navigator.dart';
import 'package:sky/widgets/raised_button.dart';

List<Route> routes = [
  new Route(
    name: 'safety',
    builder: (navigator) => new RaisedButton(
      child: new Text('PRESS FORWARD'),
      onPressed: () => navigator.pushNamedRoute('adventure')
    )
  ),
  new Route(
    name: 'adventure',
    builder: (navigator) => new RaisedButton(
      child: new Text('NO WAIT! GO BACK!'),
      onPressed: () => navigator.pushRoute(routes[0])
    )
  )
];

class NavigationExampleApp extends App {
  UINode build() {
    return new Navigator(routes: routes);
  }
}

void main() {
  App app = new NavigationExampleApp();
}
