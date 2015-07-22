// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/mojo/asset_bundle.dart';
import 'package:sky/theme/colors.dart' as colors;
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/raised_button.dart';
import 'package:sky/widgets/navigator.dart';
import 'package:sky/widgets/widget.dart';
import 'package:sky/widgets/task_description.dart';
import 'package:sky/widgets/theme.dart';

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
SpriteSheet _spriteSheetUI;
GameDemoApp _app;

main() async {
  _loader = new ImageMap(_bundle);

  await _loader.load([
    'assets/nebula.png',
    'assets/sprites.png',
    'assets/starfield.png',
    'assets/game_ui.png',
  ]);

  String json = await _bundle.loadString('assets/sprites.json');
  _spriteSheet = new SpriteSheet(_loader['assets/sprites.png'], json);

  json = await _bundle.loadString('assets/game_ui.json');
  _spriteSheetUI = new SpriteSheet(_loader["assets/game_ui.png"], json);

  _app = new GameDemoApp();

  runApp(_app);
}

class GameDemoApp extends App {

  NavigationState _navigationState;
  GameDemoWorld _game;

  void initState() {
    _navigationState = new NavigationState([
      new Route(
        name: '/',
        builder: _buildMainScene
      ),
      new Route(
        name: '/game',
        builder: _buildGameScene
      ),
    ]);
    super.initState();
  }

  Widget build() {
    // TODO(viktork): The task bar purple is the wrong purple, we may need
    // a custom theme swatch to match the purples in the sprites.
    ThemeData theme = new ThemeData(
      brightness: ThemeBrightness.light,
      primarySwatch: colors.Purple
    );

    return new Theme(
      data: theme,
      child: new TaskDescription(
        label: 'Asteroids',
        child: new Navigator(_navigationState)
      )
    );
  }

  Widget _buildGameScene(navigator, route) {
    return new SpriteWidget(_game);
  }

  Widget _buildMainScene(navigator, route) {
    return new Center(
      child: new RaisedButton(
        child: new Text("Play"),
        onPressed: () {
          _game = new GameDemoWorld(_app, navigator, _loader, _spriteSheet, _spriteSheetUI);
          navigator.pushNamed('/game');
        }
      )
    );
  }
}
