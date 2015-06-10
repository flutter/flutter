part of game;

Math.Random _rand;

class GameTests extends TransformNode{

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
    sprt.width = 64.0;
    sprt.height = 64.0;

    if (scale == null) {
      scale = _rand.nextDouble();
    }

    sprt.zPosition = scale;
    sprt.scale = scale;
    sprt.position = new Vector2(_rand.nextDouble()*1024.0, _rand.nextDouble()*1024.0);

    this.addChild(sprt);
  }

  void update(double dt) {
    for (TransformNode child in children) {
      child.update(dt);
    }
  }
}

class TestAsteroidSprite extends SpriteNode {

  Vector2 _movementVector;
  double _rotationalSpeed;

  TestAsteroidSprite.withImage(Image img) : super.withImage(img) {
    _movementVector = new Vector2(_rand.nextDouble() * 4.0 - 2.0, _rand.nextDouble() * 4.0 - 2.0);
    _rotationalSpeed = _rand.nextDouble() * 2.0 - 1.0;
  }

  void update(double dt) {
    position = position + _movementVector * scale;

    // Bounce at edges
    if (position[0] < 0 || position[0] > 1024.0) _movementVector[0] = -_movementVector[0];
    if (position[1] < 0 || position[1] > 1024.0) _movementVector[1] = -_movementVector[1];

    rotation += _rotationalSpeed;
  }
}
