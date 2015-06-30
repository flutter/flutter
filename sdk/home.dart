// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky';

import 'package:mojom/intents/intents.mojom.dart';
import 'package:sky/mojo/shell.dart' as shell;
import 'package:sky/painting/box_painter.dart';
import 'package:sky/theme/colors.dart' as colors;
import 'package:sky/theme/edges.dart';
import 'package:sky/theme/typography.dart' as typography;
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/card.dart';
import 'package:sky/widgets/fixed_height_scrollable.dart';
import 'package:sky/widgets/flat_button.dart';
import 'package:sky/widgets/material.dart';
import 'package:sky/widgets/scaffold.dart';
import 'package:sky/widgets/theme.dart';
import 'package:sky/widgets/tool_bar.dart';

void launch(String relativeUrl) {
  Uri url = Uri.base.resolve(relativeUrl);
  url = url.replace(scheme: 'sky');

  ActivityManagerProxy activityManager = new ActivityManagerProxy.unbound();
  Intent intent = new Intent()
    ..action = 'android.intent.action.VIEW'
    ..url = url.toString();
  shell.requestService(null, activityManager);
  activityManager.ptr.startActivity(intent);
}

class SkyDemo {
  String name;
  String href;
  String description;
  typography.TextTheme textTheme;
  BoxDecoration decoration;
  SkyDemo({ this.name, this.href, this.description, this.textTheme, this.decoration });
}

List<Widget> demos = [
  new SkyDemo(
    name: 'Stocks',
    href: 'example/stocks/lib/main.dart',
    description: 'Multi-screen app with scrolling list',
    textTheme: typography.black,
    decoration: new BoxDecoration(
      backgroundImage: new BackgroundImage(
        src: 'example/stocks/thumbnail.png',
        fit: BackgroundFit.cover
      )
    )
  ),
  new SkyDemo(
    name: 'Asteroids',
    href: 'example/game/main.dart',
    description: '2D game using sprite sheets to achieve high performance',
    textTheme: typography.white,
    decoration: new BoxDecoration(
      backgroundImage: new BackgroundImage(
        src: 'example/game/res/thumbnail.png',
        fit: BackgroundFit.cover
      )
    )
  ),
  new SkyDemo(
    name: 'Interactive Flex',
    href: 'example/rendering/interactive_flex.dart',
    description: 'Swipe to adjust the layout of the app',
    textTheme: typography.white,
    decoration: new BoxDecoration(
      backgroundColor: const Color(0xFF0081C6)
    )
  ),
  new SkyDemo(
    name: 'Sector',
    href: 'example/widgets/sector.dart',
    description: 'Demo of alternative layouts',
    textTheme: typography.black,
    decoration: new BoxDecoration(
      backgroundColor: colors.Black,
      backgroundImage: new BackgroundImage(
        src: 'example/widgets/sector_thumbnail.png',
        fit: BackgroundFit.cover
      )
    )
  ),
  // new SkyDemo(
  //   'Touch Demo', 'examples/rendering/touch_demo.dart', 'Simple example showing handling of touch events at a low level'),
  new SkyDemo(
    name: 'Minedigger Game',
    href: 'example/mine_digger/mine_digger.dart',
    description: 'Clone of the classic Minesweeper game',
    textTheme: typography.white
  ),

  // TODO(eseidel): We could use to separate these groups?
  // new SkyDemo('Old Stocks App', 'examples/stocks/main.sky'),
  // new SkyDemo('Old Touch Demo', 'examples/raw/touch-demo.sky'),
  // new SkyDemo('Old Spinning Square', 'examples/raw/spinning-square.sky'),

  // TODO(jackson): This doesn't seem to be working
  // new SkyDemo('Licenses', 'LICENSES.sky'),
];

const double kCardHeight = 120.0;
const EdgeDims kListPadding = const EdgeDims.all(4.0);

class DemoList extends FixedHeightScrollable {
  DemoList({ String key }) : super(key: key, itemHeight: kCardHeight, padding: kListPadding) {
    itemCount = demos.length;
  }

  Widget buildDemo(SkyDemo demo) {
    return new Listener(
      key: demo.name,
      onGestureTap: (_) => launch(demo.href),
      child: new Container(
        height: kCardHeight,
        child: new Card(
          child: new Flex([
            new Flexible(
              child: new Stack([
                new Container(
                  decoration: demo.decoration,
                  child: new Container()
                ),
                new Container(
                  margin: const EdgeDims.all(24.0),
                  child: new Block([
                    new Text(demo.name, style: demo.textTheme.title),
                    new Text(demo.description, style: demo.textTheme.subhead)
                  ])
                )
              ])
            ),
          ], direction: FlexDirection.vertical)
        )
      )
    );
  }

  List<Widget> buildItems(int start, int count) {
    return demos
      .skip(start)
      .take(count)
      .map(buildDemo)
      .toList(growable: false);
  }
}

class SkyHome extends App {
  Widget build() {
    return new Theme(
      data: new ThemeData.dark(
        primary: colors.Teal,
        accent: colors.Orange
      ),
      child: new Scaffold(
        toolbar: new ToolBar(center: new Text('Sky Demos')),
        body: new Material(
          edge: MaterialEdge.canvas,
          child: new DemoList()
        )
      )
    );
  }
}

void main() {
  runApp(new SkyHome());
}
