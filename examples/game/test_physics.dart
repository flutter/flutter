import 'dart:ui';

import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_sprites/flutter_sprites.dart';

AssetBundle _initBundle() {
  if (rootBundle != null)
    return rootBundle;
  return new NetworkAssetBundle(Uri.base);
}

final AssetBundle _bundle = _initBundle();

ImageMap _images;
SpriteSheet _spriteSheet;

main() async {
  _images = new ImageMap(_bundle);

  await _images.load(<String>[
    'assets/sprites.png'
  ]);

  String json = await _bundle.loadString('assets/sprites.json');
  _spriteSheet = new SpriteSheet(_images['assets/sprites.png'], json);

  runApp(new MaterialApp(
    title: 'Test Physics',
    theme: new ThemeData(
      brightness: ThemeBrightness.light,
      primarySwatch: Colors.purple
    ),
    routes: <String, RouteBuilder>{
      '/': (RouteArguments args) {
        return new SpriteWidget(
          new TestBed(),
          SpriteBoxTransformMode.letterbox
        );
      }
    }
  ));
}

class TestBed extends NodeWithSize {
  Sprite _obstacle;
  PhysicsWorld _world;
  PhysicsGroup _group;
  PhysicsGroup _group2;

  TestBed() : super(new Size(1024.0, 1024.0)) {
    _world = new PhysicsWorld(new Offset(0.0, 100.0));
    _world.drawDebug = true;
    _group = new PhysicsGroup();
    _group2 = new PhysicsGroup();
    _group2.position = new Point(50.0, 50.0);
    _world.addChild(_group);
    _world.addChild(_group2);

    _obstacle = new Sprite(_spriteSheet["ship.png"]);
    _obstacle.position = new Point(512.0, 800.0);
    _obstacle.size = new Size(64.0, 64.0);
    _obstacle.scale = 2.0;
    _obstacle.physicsBody = new PhysicsBody(
      new PhysicsShapeCircle(Point.origin, 32.0),
      type: PhysicsBodyType.static,
      friction: 0.5,
      tag: "obstacle"
    );
    _group.addChild(_obstacle);
    _world.addContactCallback(myCallback, "obstacle", "ship", PhysicsContactType.begin);

    // Animate group
    ActionSequence seq = new ActionSequence(<Action>[
      new ActionTween((Point a) { _group.position = a; }, new Point(-256.0, 0.0), new Point(256.0, 0.0), 1.0, Curves.easeInOut),
      new ActionTween((Point a) { _group.position = a; }, new Point(256.0, 0.0), new Point(-256.0, 0.0), 1.0, Curves.easeInOut)
    ]);
    _group.actions.run(new ActionRepeatForever(seq));

    addChild(_world);

    userInteractionEnabled = true;
  }

  void myCallback(PhysicsContactType type, PhysicsContact contact) {
  }

  bool handleEvent(SpriteBoxEvent event) {
    if (event.type == "pointerdown") {
      Point pos = convertPointToNodeSpace(event.boxPosition);

      PhysicsGroup group = new PhysicsGroup();
      group.position = pos;
      _world.addChild(group);

      Sprite shipA;
      shipA = new Sprite(_spriteSheet["ship.png"]);
      shipA.opacity = 0.3;
      shipA.position = new Point(-40.0, 0.0);
      shipA.size = new Size(64.0, 64.0);
      shipA.physicsBody = new PhysicsBody(new PhysicsShapeCircle(Point.origin, 32.0),
        friction: 0.5,
        restitution: 0.5,
        tag: "ship"
      );
      group.addChild(shipA);

      Sprite shipB;
      shipB = new Sprite(_spriteSheet["ship.png"]);
      shipB.opacity = 0.3;
      shipB.position = new Point(40.0, 0.0);
      shipB.size = new Size(64.0, 64.0);
      shipB.physicsBody = new PhysicsBody(new PhysicsShapePolygon(<Point>[new Point(-25.0, -25.0), new Point(25.0, -25.0), new Point(25.0, 25.0), new Point(-25.0, 25.0)]),
        friction: 0.5,
        restitution: 0.5,
        tag: "ship"
      );
      group.addChild(shipB);
    }
    return true;
  }
}
