// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui show Image;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sprites/flutter_sprites.dart';

ImageMap _images;
SpriteSheet _sprites;

enum WeatherType {
  sun,
  rain,
  snow
}

class WeatherDemo extends StatefulWidget {
  WeatherDemo({ Key key }) : super(key: key);

  static const String routeName = '/weather';

  @override
  _WeatherDemoState createState() => new _WeatherDemoState();
}

class _WeatherDemoState extends State<WeatherDemo> {

  Future<Null> _loadAssets(AssetBundle bundle) async {
    _images = new ImageMap(bundle);
    await _images.load(<String>[
      'packages/flutter_gallery_assets/clouds-0.png',
      'packages/flutter_gallery_assets/clouds-1.png',
      'packages/flutter_gallery_assets/ray.png',
      'packages/flutter_gallery_assets/sun.png',
      'packages/flutter_gallery_assets/weathersprites.png',
      'packages/flutter_gallery_assets/icon-sun.png',
      'packages/flutter_gallery_assets/icon-rain.png',
      'packages/flutter_gallery_assets/icon-snow.png'
    ]);

    String json = await DefaultAssetBundle.of(context).loadString('packages/flutter_gallery_assets/weathersprites.json');
    _sprites = new SpriteSheet(_images['packages/flutter_gallery_assets/weathersprites.png'], json);
  }

  @override
  void initState() {
    super.initState();

    AssetBundle bundle = DefaultAssetBundle.of(context);
    _loadAssets(bundle).then((_) {
      setState(() {
        assetsLoaded = true;
        weatherWorld = new WeatherWorld();
      });
    });
  }

  bool assetsLoaded = false;

  WeatherWorld weatherWorld;

  @override
  Widget build(BuildContext context) {
    if (!assetsLoaded) {
      return new Scaffold(
        appBar: new AppBar(
          title: new Text('Weather')
        ),
        body: new Container(
          decoration: new BoxDecoration(
            backgroundColor: const Color(0xff4aaafb)
          )
        )
      );
    }

    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Weather')
      ),
      body: new Material(
        child: new Stack(
          children: <Widget>[
            new SpriteWidget(weatherWorld),
            new Align(
              alignment: new FractionalOffset(0.5, 0.8),
              child: new Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  new WeatherButton(
                    onPressed: () {
                      setState(() {
                        weatherWorld.weatherType = WeatherType.sun;
                      });
                    },
                    selected: weatherWorld.weatherType == WeatherType.sun,
                    icon: "packages/flutter_gallery_assets/icon-sun.png"
                  ),
                  new WeatherButton(
                    onPressed: () {
                      setState(() {
                        weatherWorld.weatherType = WeatherType.rain;
                      });
                    },
                    selected: weatherWorld.weatherType == WeatherType.rain,
                    icon: "packages/flutter_gallery_assets/icon-rain.png"
                  ),
                  new WeatherButton(
                    onPressed: () {
                      setState(() {
                        weatherWorld.weatherType = WeatherType.snow;
                      });
                    },
                    selected: weatherWorld.weatherType == WeatherType.snow,
                    icon: "packages/flutter_gallery_assets/icon-snow.png"
                  )
                ]
              )
            )
          ]
        )
      )
    );
  }
}

const double _kWeatherButtonSize = 56.0;
const double _kWeatherIconSize = 36.0;

class WeatherButton extends StatelessWidget {
  WeatherButton({ this.icon, this.selected, this.onPressed, Key key }) : super(key: key);

  final String icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    Color color;
    if (selected)
      color = Theme.of(context).primaryColor;
    else
      color = const Color(0x33000000);

    return new Padding(
      padding: const EdgeInsets.all(15.0),
      child: new Material(
        color: color,
        type: MaterialType.circle,
        elevation: 0,
        child: new Container(
          width: _kWeatherButtonSize,
          height: _kWeatherButtonSize,
          child: new InkWell(
            onTap: onPressed,
            child: new Center(
              child: new AssetImage(
                name: icon,
                width: _kWeatherIconSize,
                height: _kWeatherIconSize
              )
            )
          )
        )
      )
    );
  }
}

const List<Color> _kBackgroundColorsTop = const <Color>[
  const Color(0xff5ebbd5),
  const Color(0xff0b2734),
  const Color(0xffcbced7)
];

const List<Color> _kBackgroundColorsBottom = const <Color>[
  const Color(0xff4aaafb),
  const Color(0xff4c5471),
  const Color(0xffe0e3ec)
];

class WeatherWorld extends NodeWithSize {
  WeatherWorld() : super(const Size(2048.0, 2048.0)) {
    _background = new GradientNode(
      this.size,
      _kBackgroundColorsTop[0],
      _kBackgroundColorsBottom[0]
    );
    addChild(_background);

    _cloudsSharp = new CloudLayer(
      image: _images['packages/flutter_gallery_assets/clouds-0.png'],
      rotated: false,
      dark: false,
      loopTime: 20.0
    );
    addChild(_cloudsSharp);

    _cloudsDark = new CloudLayer(
      image: _images['packages/flutter_gallery_assets/clouds-1.png'],
      rotated: true,
      dark: true,
      loopTime: 40.0
    );
    addChild(_cloudsDark);

    _cloudsSoft = new CloudLayer(
      image: _images['packages/flutter_gallery_assets/clouds-1.png'],
      rotated: false,
      dark: false,
      loopTime: 60.0
    );
    addChild(_cloudsSoft);

    _sun = new Sun();
    _sun.position = const Point(1024.0, 1024.0);
    _sun.scale = 1.5;
    addChild(_sun);

    _rain = new Rain();
    addChild(_rain);

    _snow = new Snow();
    addChild(_snow);
  }

  GradientNode _background;
  CloudLayer _cloudsSharp;
  CloudLayer _cloudsSoft;
  CloudLayer _cloudsDark;
  Sun _sun;
  Rain _rain;
  Snow _snow;

  WeatherType get weatherType => _weatherType;

  WeatherType _weatherType = WeatherType.sun;

  void set weatherType(WeatherType weatherType) {
    if (weatherType == _weatherType)
      return;

    _weatherType = weatherType;

    // Fade the background
    _background.actions.stopAll();

    _background.actions.run(new ActionTween(
      (Color a) => _background.colorTop = a,
      _background.colorTop,
      _kBackgroundColorsTop[weatherType.index],
      1.0
    ));

    _background.actions.run(new ActionTween(
      (Color a) => _background.colorBottom = a,
      _background.colorBottom,
      _kBackgroundColorsBottom[weatherType.index],
      1.0
    ));

    _cloudsDark.active = weatherType != WeatherType.sun;
    _sun.active = weatherType == WeatherType.sun;
    _rain.active = weatherType == WeatherType.rain;
    _snow.active = weatherType == WeatherType.snow;
  }

  @override
  void spriteBoxPerformedLayout() {
    _sun.position = spriteBox.visibleArea.topLeft + const Offset(350.0, 180.0);
  }
}

class GradientNode extends NodeWithSize {
  GradientNode(Size size, this.colorTop, this.colorBottom) : super(size);

  Color colorTop;
  Color colorBottom;

  @override
  void paint(Canvas canvas) {
    applyTransformForPivot(canvas);

    Rect rect = Point.origin & size;
    Paint gradientPaint = new Paint()..shader = new LinearGradient(
      begin: FractionalOffset.topLeft,
      end: FractionalOffset.bottomLeft,
      colors: <Color>[colorTop, colorBottom],
      stops: <double>[0.0, 1.0]
    ).createShader(rect);

    canvas.drawRect(rect, gradientPaint);
  }
}

class CloudLayer extends Node {
  CloudLayer({ ui.Image image, bool dark, bool rotated, double loopTime }) {
    _sprites.add(_createSprite(image, dark, rotated));
    _sprites[0].position = const Point(1024.0, 1024.0);
    addChild(_sprites[0]);

    _sprites.add(_createSprite(image, dark, rotated));
    _sprites[1].position = const Point(3072.0, 1024.0);
    addChild(_sprites[1]);

    actions.run(new ActionRepeatForever(
      new ActionTween(
        (Point a) => position = a,
        Point.origin,
        const Point(-2048.0, 0.0),
        loopTime)
    ));
  }

  List<Sprite> _sprites = <Sprite>[];

  Sprite _createSprite(ui.Image image, bool dark, bool rotated) {
    Sprite sprite = new Sprite.fromImage(image);

    if (rotated)
      sprite.scaleX = -1.0;

    if (dark) {
      sprite.colorOverlay = const Color(0xff000000);
      sprite.opacity = 0.0;
    }

    return sprite;
  }

  void set active(bool active) {
    double opacity;
    if (active) opacity = 1.0;
    else opacity = 0.0;

    for (Sprite sprite in _sprites) {
      sprite.actions.stopAll();
      sprite.actions.run(new ActionTween(
        (double a) => sprite.opacity = a,
        sprite.opacity,
        opacity,
        1.0
      ));
    }
  }
}

const double _kNumSunRays = 50.0;

class Sun extends Node {
  Sun() {
    _sun = new Sprite.fromImage(_images['packages/flutter_gallery_assets/sun.png']);
    _sun.scale = 4.0;
    _sun.transferMode = TransferMode.plus;
    addChild(_sun);

    _rays = <Ray>[];
    for (int i = 0; i < _kNumSunRays; i += 1) {
      Ray ray = new Ray();
      addChild(ray);
      _rays.add(ray);
    }
  }

  Sprite _sun;
  List<Ray> _rays;

  void set active(bool active) {
    actions.stopAll();

    double targetOpacity;
    if (!active) targetOpacity = 0.0;
    else targetOpacity = 1.0;

    actions.run(
      new ActionTween(
        (double a) => _sun.opacity = a,
        _sun.opacity,
        targetOpacity,
        2.0
      )
    );

    if (active) {
      for (Ray ray in _rays) {
        actions.run(new ActionSequence([
          new ActionDelay(1.5),
          new ActionTween(
            (double a) => ray.opacity = a,
            ray.opacity,
            ray.maxOpacity,
            1.5
          )
        ]));
      }
    } else {
      for (Ray ray in _rays) {
        actions.run(new ActionTween(
          (double a) => ray.opacity = a,
          ray.opacity,
          0.0,
          0.2
        ));
      }
    }
  }
}

class Ray extends Sprite {
  double _rotationSpeed;
  double maxOpacity;

  Ray() : super.fromImage(_images['packages/flutter_gallery_assets/ray.png']) {
    pivot = const Point(0.0, 0.5);
    transferMode = TransferMode.plus;
    rotation = randomDouble() * 360.0;
    maxOpacity = randomDouble() * 0.2;
    opacity = maxOpacity;
    scaleX = 2.5 + randomDouble();
    scaleY = 0.3;
    _rotationSpeed = randomSignedDouble() * 2.0;

    // Scale animation
    double scaleTime = randomSignedDouble() * 2.0 + 4.0;

    actions.run(new ActionRepeatForever(
      new ActionSequence([
        new ActionTween((double a) => scaleX = a, scaleX, scaleX * 0.5, scaleTime),
        new ActionTween((double a) => scaleX = a, scaleX * 0.5, scaleX, scaleTime)
      ])
    ));
  }

  @override
  void update(double dt) {
    rotation += dt * _rotationSpeed;
  }
}

class Rain extends Node {
  Rain() {
    _addParticles(1.0);
    _addParticles(1.5);
    _addParticles(2.0);
  }

  List<ParticleSystem> _particles = <ParticleSystem>[];

  void _addParticles(double distance) {
    ParticleSystem particles = new ParticleSystem(
      _sprites['raindrop.png'],
      transferMode: TransferMode.srcATop,
      posVar: const Point(1300.0, 0.0),
      direction: 90.0,
      directionVar: 0.0,
      speed: 1000.0 / distance,
      speedVar: 100.0 / distance,
      startSize: 1.2 / distance,
      startSizeVar: 0.2 / distance,
      endSize: 1.2 / distance,
      endSizeVar: 0.2 / distance,
      life: 1.5 * distance,
      lifeVar: 1.0 * distance
    );
    particles.position = const Point(1024.0, -200.0);
    particles.rotation = 10.0;
    particles.opacity = 0.0;

    _particles.add(particles);
    addChild(particles);
  }

  void set active(bool active) {
    actions.stopAll();
    for (ParticleSystem system in _particles) {
      if (active) {
        actions.run(
          new ActionTween(
            (double a) => system.opacity = a,
            system.opacity,
            1.0,
            2.0
        ));
      } else {
        actions.run(
          new ActionTween(
            (double a) => system.opacity = a,
            system.opacity,
            0.0,
            0.5
        ));
      }
    }
  }
}

class Snow extends Node {
  Snow() {
    _addParticles(_sprites['flake-0.png'], 1.0);
    _addParticles(_sprites['flake-1.png'], 1.0);
    _addParticles(_sprites['flake-2.png'], 1.0);

    _addParticles(_sprites['flake-3.png'], 1.5);
    _addParticles(_sprites['flake-4.png'], 1.5);
    _addParticles(_sprites['flake-5.png'], 1.5);

    _addParticles(_sprites['flake-6.png'], 2.0);
    _addParticles(_sprites['flake-7.png'], 2.0);
    _addParticles(_sprites['flake-8.png'], 2.0);
  }

  List<ParticleSystem> _particles = <ParticleSystem>[];

  void _addParticles(Texture texture, double distance) {
    ParticleSystem particles = new ParticleSystem(
      texture,
      transferMode: TransferMode.srcATop,
      posVar: const Point(1300.0, 0.0),
      direction: 90.0,
      directionVar: 0.0,
      speed: 150.0 / distance,
      speedVar: 50.0 / distance,
      startSize: 1.0 / distance,
      startSizeVar: 0.3 / distance,
      endSize: 1.2 / distance,
      endSizeVar: 0.2 / distance,
      life: 20.0 * distance,
      lifeVar: 10.0 * distance,
      emissionRate: 2.0,
      startRotationVar: 360.0,
      endRotationVar: 360.0,
      radialAccelerationVar: 10.0 / distance,
      tangentialAccelerationVar: 10.0 / distance
    );
    particles.position = const Point(1024.0, -50.0);
    particles.opacity = 0.0;

    _particles.add(particles);
    addChild(particles);
  }

  void set active(bool active) {
    actions.stopAll();
    for (ParticleSystem system in _particles) {
      if (active) {
        actions.run(
          new ActionTween((double a) => system.opacity = a, system.opacity, 1.0, 2.0
        ));
      } else {
        actions.run(
          new ActionTween((double a) => system.opacity = a, system.opacity, 0.0, 0.5
        ));
      }
    }
  }
}
