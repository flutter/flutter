// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/mojo/asset_bundle.dart';
import 'package:sky/theme/colors.dart' as colors;
import 'package:sky/rendering/object.dart';
import 'package:sky/painting/text_style.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/button_base.dart';
import 'package:sky/widgets/navigator.dart';
import 'package:sky/widgets/framework.dart';
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
  int _lastScore = 0;

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
    return new Stack([
      new SpriteWidget(new MainScreenBackground()),
      new Flex([
        new TextureButton(
          onPressed: () {
            _game = new GameDemoWorld(
              _app,
              navigator,
              _loader,
              _spriteSheet,
              _spriteSheetUI,
              (lastScore) {
                setState(() {_lastScore = lastScore;});
              }
            );
            navigator.pushNamed('/game');
          },
          texture: _spriteSheetUI["btn_play_up.png"],
          textureDown: _spriteSheetUI["btn_play_down.png"],
          width: 128.0,
          height: 128.0
        ),
        new Text(
          "Last Score: $_lastScore",
          style: new TextStyle(fontSize:20.0)
        )
      ],
      direction: FlexDirection.vertical,
      justifyContent: FlexJustifyContent.center)
    ]);
  }
}

class TextureButton extends ButtonBase {
  TextureButton({
    Key key,
    this.onPressed,
    this.texture,
    this.textureDown,
    this.width: 128.0,
    this.height: 128.0
  }) : super(key: key);

  final Function onPressed;
  final Texture texture;
  final Texture textureDown;
  final double width;
  final double height;

  Widget buildContent() {
    return new Listener(
      child: new Container(
        width: width,
        height: height,
        child: new CustomPaint(
          callback: paintCallback,
          token: new _TextureButtonToken(
            highlight,
            texture,
            textureDown,
            width,
            height
          )
        )
      ),
      onPointerUp: (_) {
        if (onPressed != null) onPressed();
      }
    );
  }

  void paintCallback(PaintingCanvas canvas, Size size) {
    if (texture == null)
      return;

    canvas.save();
    if (highlight && textureDown != null) {
      // Draw down state
      canvas.scale(size.width / textureDown.size.width, size.height / textureDown.size.height);
      textureDown.drawTexture(canvas, Point.origin, new Paint());
    } else {
      // Draw up state
      canvas.scale(size.width / texture.size.width, size.height / texture.size.height);
      texture.drawTexture(canvas, Point.origin, new Paint());
    }
    canvas.restore();
  }
}

class _TextureButtonToken {
  _TextureButtonToken(
    this._highlight,
    this._texture,
    this._textureDown,
    this._width,
    this._height
  );

  final bool _highlight;
  final Texture _texture;
  final Texture _textureDown;
  final double _width;
  final double _height;

  bool operator== (other) {
    return
      other is _TextureButtonToken &&
      _highlight == other._highlight &&
      _texture == other._texture &&
      _textureDown == other._textureDown &&
      _width == other._width &&
      _height == other._height;
  }

  int get hashCode {
    int value = 373;
    value = 37 * value * _highlight.hashCode;
    value = 37 * value * _texture.hashCode;
    value = 37 * value * _textureDown.hashCode;
    value = 37 * value * _width.hashCode;
    value = 37 * value * _height.hashCode;
    return value;
  }
}

class MainScreenBackground extends NodeWithSize {
  MainScreenBackground() : super(new Size(1024.0, 1024.0)) {
    Sprite sprtBackground = new Sprite.fromImage(_loader["assets/starfield.png"]);
    sprtBackground.position = new Point(512.0, 512.0);
    addChild(sprtBackground);

    StarField starField = new StarField(_spriteSheet, 200, true);
    addChild(starField);
  }
}
