// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/mojo/asset_bundle.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/widget.dart';

import 'lib/game_demo.dart';
import 'lib/sprites.dart';

AssetBundle _initBundle() {
  if (rootBundle != null)
    return rootBundle;
  return new NetworkAssetBundle(Uri.base);
}

final AssetBundle _bundle = _initBundle();

ImageMap _loader;
SpriteSheet _spriteSheet;
GameDemoApp _app;

main() async {
  _loader = new ImageMap(_bundle);

  await _loader.load([
    'assets/nebula.png',
    'assets/sprites.png',
    'assets/starfield.png',
  ]);

  String json = await _bundle.loadString('assets/sprites.json');
  _spriteSheet = new SpriteSheet(_loader['assets/sprites.png'], json);
  _app = new GameDemoApp();

  runApp(_app);
}

class GameDemoApp extends App {

  Widget build() {
    return new Stack([
      new SpriteWidget(new GameDemoWorld(_app, _loader, _spriteSheet)),
//      new StackPositionedChild(
//        new Flex([
//          new FlexExpandingChild(
//            new RaisedButton(child:new Text("Hello")),
//            key: 1
//          ),
//          new FlexExpandingChild(
//            new RaisedButton(child:new Text("Foo!")),
//            key: 2
//          )
//        ]),
//        right:0.0,
//        top: 20.0
//      )
    ]);
  }
}

void resetGame() {
  _app.scheduleBuild();
}
