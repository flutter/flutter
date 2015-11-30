// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class Home extends StatelessComponent {
  Widget build(BuildContext context) {
    return new Material(
      child: new Center(
        child: new Block(<Widget>[
            new Text(
              'You are at home.',
              style: Theme.of(context).text.display2.copyWith(textAlign: TextAlign.center)
            ),
            new RaisedButton(
              child: new Text('GO SHOPPING'),
              onPressed: () => Navigator.pushNamed(context, '/shopping')
            ),
            new RaisedButton(
              child: new Text('START ADVENTURE'),
              onPressed: () => Navigator.pushNamed(context, '/adventure')
            )
          ],
          padding: const EdgeDims.all(30.0)
        )
      )
    );
  }
}

class Shopping extends StatelessComponent {
  Widget build(BuildContext context) {
    return new Material(
      color: Colors.deepPurple[300],
      child: new Center(
        child: new Block(<Widget>[
            new Text(
              'Village Shop',
              style: Theme.of(context).text.display2.copyWith(textAlign: TextAlign.center)
            ),
            new RaisedButton(
              child: new Text('RETURN HOME'),
              onPressed: () => Navigator.pop(context)
            ),
            new RaisedButton(
              child: new Text('GO TO DUNGEON'),
              onPressed: () => Navigator.pushNamed(context, '/adventure')
            )
          ],
          padding: const EdgeDims.all(30.0)
        )
      )
    );
  }
}

class Adventure extends StatelessComponent {
  Widget build(BuildContext context) {
    return new Material(
      color: Colors.red[300],
      child: new Center(
        child: new Block(<Widget>[
            new Text(
              'Monster\'s Lair',
              style: Theme.of(context).text.display2.copyWith(textAlign: TextAlign.center)
            ),
            new RaisedButton(
              child: new Text('RUN!!!'),
              onPressed: () => Navigator.pop(context)
            )
          ],
          padding: const EdgeDims.all(30.0)
        )
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
