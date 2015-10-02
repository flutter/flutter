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
      '/': (navigator, route) {
        return new SpriteWidget(
          new TestBed(),
          SpriteBoxTransformMode.letterbox
        );
      }
    }
  ));
}

class TestBed extends NodeWithSize {
  Sprite _ship;
  Sprite _obstacle;

  TestBed() : super(new Size(1024.0, 1024.0)) {
    PhysicsNode physicsNode = new PhysicsNode(new Offset(0.0, 100.0));

    _ship = new Sprite(_spriteSheet["ship.png"]);
    _ship.position = new Point(512.0, 512.0);
    _ship.size = new Size(64.0, 64.0);
    _ship.physicsBody = new PhysicsBody(
      new PhysicsShapeGroup([
        new PhysicsShapeCircle(Point.origin, 32.0),
        new PhysicsShapePolygon([new Point(0.0, 0.0), new Point(50.0, 0.0), new Point(50.0, 50.0), new Point(0.0, 50.0)])
      ]),
      friction: 0.5,
      tag: "ship"
    );
    physicsNode.addChild(_ship);

    _obstacle = new Sprite(_spriteSheet["ship.png"]);
    _obstacle.position = new Point(532.0, 800.0);
    _obstacle.size = new Size(64.0, 64.0);
    _obstacle.physicsBody = new PhysicsBody(
      new PhysicsShapeCircle(Point.origin, 32.0),
      type: PhysicsBodyType.static,
      friction: 0.5,
      tag: "obstacle"
    );
    physicsNode.addChild(_obstacle);
    physicsNode.addContactCallback(myCallback, "obstacle", "ship", PhysicsContactType.begin);

    addChild(physicsNode);

    userInteractionEnabled = true;
  }

  void myCallback(PhysicsContactType type, PhysicsContact contact) {
    print("CONTACT type: $type");
  }

  bool handleEvent(SpriteBoxEvent event) {
    if (event.type == "pointerdown") {
      Point pos = convertPointToNodeSpace(event.boxPosition);
      _ship.position = pos;
    }
    return true;
  }
}
