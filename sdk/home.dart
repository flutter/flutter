// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky';

import 'package:mojom/intents/intents.mojom.dart';
import 'package:sky/framework/shell.dart' as shell;
import 'package:sky/theme/colors.dart' as colors;
import 'package:sky/theme/edges.dart';
import 'package:sky/theme/typography.dart' as typography;
import 'package:sky/widgets/material.dart';
import 'package:sky/widgets/raised_button.dart';
import 'package:sky/widgets/scaffold.dart';
import 'package:sky/widgets/tool_bar.dart';
import 'package:sky/widgets/basic.dart';

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

class SkyDemo extends Component {
  String text;
  String href;

  SkyDemo(String text, this.href) : this.text = text, super(key: text);

  void _handlePress() {
    launch(href);
  }

  Widget build() {
    return new ConstrainedBox(
      constraints: const BoxConstraints.expandWidth(),
      child: new RaisedButton(
        child: new Text(text),
        onPressed: _handlePress
      )
    );
  }
}

class SkyHome extends App {
  Widget build() {
    List<Widget> children = [
      new SkyDemo('Stocks App', 'example/stocks/lib/main.dart'),
      new SkyDemo('Asteroids Game', 'example/game/main.dart'),
      new SkyDemo('Interactive Flex', 'example/rendering/interactive_flex.dart'),
      new SkyDemo('Sector Layout', 'example/widgets/sector.dart'),
      new SkyDemo('Touch Demo', 'example/rendering/touch_demo.dart'),
      new SkyDemo('Minedigger Game', 'example/mine_digger/lib/main.dart'),

      new SkyDemo('Licences (Old)', 'LICENSES.sky'),
    ];

    return new Scaffold(
      toolbar: new ToolBar(
          center: new Text('Sky Demos', style: typography.white.title),
          backgroundColor: colors.Blue[500]),
      body: new Material(
        edge: MaterialEdge.canvas,
        child: new Flex(
          children,
          direction: FlexDirection.vertical,
          justifyContent: FlexJustifyContent.spaceAround
        )
      )
    );
  }
}

void main() {
  runApp(new SkyHome());
}
