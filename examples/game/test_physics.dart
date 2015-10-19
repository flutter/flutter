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

  await _images.load([
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
    routes: {
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
  PhysicsWorld _physicsNode;

  TestBed() : super(new Size(1024.0, 1024.0)) {
    _physicsNode = new PhysicsWorld(new Offset(0.0, 100.0));

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
    _physicsNode.addChild(_obstacle);
    _physicsNode.addContactCallback(myCallback, "obstacle", "ship", PhysicsContactType.begin);

    // Animate obstacle
    ActionSequence seq = new ActionSequence([
      new ActionTween((a) => _obstacle.position = a, new Point(256.0, 800.0), new Point(768.0, 800.0), 1.0, easeInOut),
      new ActionTween((a) => _obstacle.position = a, new Point(768.0, 800.0), new Point(256.0, 800.0), 1.0, easeInOut)
    ]);
    _obstacle.actions.run(new ActionRepeatForever(seq));

    seq = new ActionSequence([
      new ActionTween((a) => _obstacle.scale = a, 1.0, 2.0, 2.0, easeInOut),
      new ActionTween((a) => _obstacle.scale = a, 2.0, 1.0, 2.0, easeInOut)
    ]);
    _obstacle.actions.run(new ActionRepeatForever(seq));

    addChild(_physicsNode);

    userInteractionEnabled = true;
  }

  void myCallback(PhysicsContactType type, PhysicsContact contact) {
    print("CONTACT type: $type");
  }

  bool handleEvent(SpriteBoxEvent event) {
    if (event.type == "pointerdown") {
      Point pos = convertPointToNodeSpace(event.boxPosition);

      Sprite shipA;
      shipA = new Sprite(_spriteSheet["ship.png"]);
      shipA.opacity = 0.3;
      shipA.position = new Point(pos.x - 40.0, pos.y);
      shipA.size = new Size(64.0, 64.0);
      shipA.physicsBody = new PhysicsBody(new PhysicsShapeCircle(Point.origin, 32.0),
        friction: 0.5,
        restitution: 0.5,
        tag: "ship"
      );
      _physicsNode.addChild(shipA);
      shipA.physicsBody.applyLinearImpulse(
        new Offset(randomSignedDouble() * 5000.0, randomSignedDouble() * 5000.0),
        shipA.position
      );

      Sprite shipB;
      shipB = new Sprite(_spriteSheet["ship.png"]);
      shipB.opacity = 0.3;
      shipB.position = new Point(pos.x + 40.0, pos.y);
      shipB.size = new Size(64.0, 64.0);
      shipB.physicsBody = new PhysicsBody(new PhysicsShapePolygon([new Point(-25.0, -25.0), new Point(25.0, -25.0), new Point(25.0, 25.0), new Point(-25.0, 25.0)]),
        friction: 0.5,
        restitution: 0.5,
        tag: "ship"
      );
      _physicsNode.addChild(shipB);

      new PhysicsJointRevolute(shipA.physicsBody, shipB.physicsBody, pos);
    }
    return true;
  }
}
