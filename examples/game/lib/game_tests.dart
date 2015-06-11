part of game;

Math.Random _rand;

class GameTestsBox extends SpriteBox {
  GameTestsBox(Node tests, SpriteBoxTransformMode mode) : super(tests, mode);

  void handleEvent(Event event, BoxHitTestEntry entry) {

    if (event is PointerEvent) {
      Point pointerPos = new Point(event.x, event.y);
      int pointer = event.pointer;

      switch (event.type) {
        case 'pointerdown':
          List sprites = findNodesAtPosition(pointerPos);
          for (Node node in sprites) {
            if (node is Sprite) {
              Sprite sprt = node;
              sprt.colorOverlay = new Color(0x66ff0000);
            }
          }
          break;
      }
    }
  }
}

class GameTestsSimple extends Node {
  Image _imgAsteroid;
  Image _imgBg;
  Image _imgShip;

  GameTestsSimple(ImageMap images) {
    // Setup random number generator
    _rand = new Math.Random();

    // Fetch images
    _imgBg = images["https://raw.githubusercontent.com/slembcke/GalacticGuardian.spritebuilder/GDC/Packages/SpriteBuilder%20Resources.sbpack/resources-auto/BurnTexture.png"];
    _imgAsteroid = images["https://raw.githubusercontent.com/slembcke/GalacticGuardian.spritebuilder/GDC/Packages/SpriteBuilder%20Resources.sbpack/Sprites/resources-auto/asteroid_big_002.png"];
    _imgShip = images["https://raw.githubusercontent.com/slembcke/GalacticGuardian.spritebuilder/GDC/Packages/SpriteBuilder%20Resources.sbpack/Sprites/resources-auto/GG_blueship_Lv3.png"];

    Sprite sprt0 = new Sprite.withImage(_imgBg);
    sprt0.size = new Size(100.0, 100.0);
    sprt0.pivot = new Point(0.0, 0.0);
    sprt0.position = new Point(100.0, 100.0);
    this.addChild(sprt0);

    Sprite sprt1 = new Sprite.withImage(_imgBg);
    sprt1.size = new Size(100.0, 100.0);
    sprt1.pivot = new Point(0.0, 0.0);
    sprt1.position = new Point(100.0, 100.0);
    sprt0.addChild(sprt1);
  }
}

class GameTests extends Node{

  Image _imgAsteroid;
  Image _imgBg;
  Image _imgShip;

  GameTests(ImageMap images) {
    // Setup random number generator
    _rand = new Math.Random();

    // Fetch images
    _imgBg = images["https://raw.githubusercontent.com/slembcke/GalacticGuardian.spritebuilder/GDC/Packages/SpriteBuilder%20Resources.sbpack/resources-auto/BurnTexture.png"];
    _imgAsteroid = images["https://raw.githubusercontent.com/slembcke/GalacticGuardian.spritebuilder/GDC/Packages/SpriteBuilder%20Resources.sbpack/Sprites/resources-auto/asteroid_big_002.png"];
    _imgShip = images["https://raw.githubusercontent.com/slembcke/GalacticGuardian.spritebuilder/GDC/Packages/SpriteBuilder%20Resources.sbpack/Sprites/resources-auto/GG_blueship_Lv3.png"];

    for (int i = 0; i < 100; i++) {
      addSprite(i/100.0);
    }
  }

  void addSprite([double scale = null]) {
    TestAsteroidSprite sprt = new TestAsteroidSprite.withImage(_imgAsteroid);
    sprt.size = new Size(64.0, 64.0);

    if (scale == null) {
      scale = _rand.nextDouble();
    }

    sprt.zPosition = scale;
    sprt.scale = scale;
    sprt.position = new Point(_rand.nextDouble()*1024.0, _rand.nextDouble()*1024.0);

    this.addChild(sprt);

    Sprite sprtMoon0 = new Sprite.withImage(_imgAsteroid);
    sprtMoon0.size = new Size(32.0, 32.0);
    sprtMoon0.position = new Point(32.0, 0.0);
    sprt.addChild(sprtMoon0);

    Sprite sprtMoon1 = new Sprite.withImage(_imgAsteroid);
    sprtMoon1.size = new Size(32.0, 32.0);
    sprtMoon1.position = new Point(-32.0, 0.0);
    sprt.addChild(sprtMoon1);
  }

  void update(double dt) {
    for (Node child in children) {
      child.update(dt);
    }
  }
}

class TestAsteroidSprite extends Sprite {

  Vector2 _movementVector;
  double _rotationalSpeed;

  TestAsteroidSprite.withImage(Image img) : super.withImage(img) {
    _movementVector = new Vector2(_rand.nextDouble() * 4.0 - 2.0, _rand.nextDouble() * 4.0 - 2.0);
    _rotationalSpeed = _rand.nextDouble() * 2.0 - 1.0;
  }

  void update(double dt) {
    Vector2 vPos = new Vector2(position.x, position.y);
    Vector2 vNewPos = vPos + _movementVector * scale;

    position = new Point(vNewPos[0], vNewPos[1]);

    // Bounce at edges
    if (position.x < 0 || position.x > 1024.0) _movementVector[0] = -_movementVector[0];
    if (position.y < 0 || position.y > 1024.0) _movementVector[1] = -_movementVector[1];

    rotation += _rotationalSpeed;
  }
}
