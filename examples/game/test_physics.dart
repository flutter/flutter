import 'dart:sky';

import 'package:sky/material.dart';
import 'package:sky/rendering.dart';
import 'package:sky/services.dart';
import 'package:sky/widgets.dart';
import 'package:skysprites/skysprites.dart';

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

  runApp(new App(
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
  PhysicsNode _physicsNode;

  TestBed() : super(new Size(1024.0, 1024.0)) {
    _physicsNode = new PhysicsNode(new Offset(0.0, 100.0));

    _obstacle = new Sprite(_spriteSheet["ship.png"]);
    _obstacle.position = new Point(532.0, 800.0);
    _obstacle.size = new Size(64.0, 64.0);
    _obstacle.physicsBody = new PhysicsBody(
      new PhysicsShapeCircle(Point.origin, 32.0),
      type: PhysicsBodyType.static,
      friction: 0.5,
      tag: "obstacle"
    );
    _physicsNode.addChild(_obstacle);
    _physicsNode.addContactCallback(myCallback, "obstacle", "ship", PhysicsContactType.begin);

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
      shipA.position = new Point(pos.x - 40.0, pos.y);
      shipA.size = new Size(64.0, 64.0);
      shipA.physicsBody = new PhysicsBody(new PhysicsShapeCircle(Point.origin, 32.0),
        friction: 0.5,
        tag: "ship"
      );
      _physicsNode.addChild(shipA);
      shipA.physicsBody.applyLinearImpulse(
        new Offset(randomSignedDouble() * 5.0, randomSignedDouble() * 5.0),
        shipA.position
      );

      Sprite shipB;
      shipB = new Sprite(_spriteSheet["ship.png"]);
      shipB.position = new Point(pos.x + 40.0, pos.y);
      shipB.size = new Size(64.0, 64.0);
      shipB.physicsBody = new PhysicsBody(new PhysicsShapePolygon([new Point(-25.0, -25.0), new Point(25.0, -25.0), new Point(25.0, 25.0), new Point(-25.0, 25.0)]),
        friction: 0.5,
        tag: "ship"
      );
      _physicsNode.addChild(shipB);

      new PhysicsJointWeld(shipA.physicsBody, shipB.physicsBody);
    }
    return true;
  }
}
