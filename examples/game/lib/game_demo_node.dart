part of game;

final double _gameSizeWidth = 320.0;
double _gameSizeHeight = 320.0;

final bool _drawDebug = false;

class GameDemoNode extends NodeWithSize {

  GameDemoNode(
    this._images,
    this._spritesGame,
    this._spritesUI,
    this._sounds,
    this._gameOverCallback
  ): super(new Size(320.0, 320.0)) {
    // Add background
    _background = new RepeatedImage(_images["assets/starfield.png"]);
    addChild(_background);

    // Create starfield
    _starField = new StarField(_spritesGame, 200);
    addChild(_starField);

    // Add nebula
    _nebula = new RepeatedImage(_images["assets/nebula.png"], sky.TransferMode.plus);
    addChild(_nebula);

    // Setup game screen, it will always be anchored to the bottom of the screen
    _gameScreen = new Node();
    addChild(_gameScreen);

    // Setup the level and add it to the screen, the level is the node where
    // all our game objects live. It is moved to scroll the game
    _level = new Level();
    _gameScreen.addChild(_level);

    _objectFactory = new GameObjectFactory(_spritesGame, _sounds, _level);

    _level.ship = new Ship(_objectFactory);
    _level.addChild(_level.ship);

    // Add the joystick
    _joystick = new VirtualJoystick();
    _gameScreen.addChild(_joystick);

    // Add HUD
    _hud = new Hud(_spritesUI);
    addChild(_hud);

    // Add initial game objects
    addObjects();
  }

  // Resources
  ImageMap _images;
  Map<String, SoundEffect> _sounds;
  SpriteSheet _spritesGame;
  SpriteSheet _spritesUI;

  // Sounds
  SoundEffectPlayer _effectPlayer = SoundEffectPlayer.sharedInstance();

  // Callback
  Function _gameOverCallback;

  // Game screen nodes
  Node _gameScreen;
  VirtualJoystick _joystick;

  GameObjectFactory _objectFactory;
  Level _level;
  StarField _starField;
  RepeatedImage _background;
  RepeatedImage _nebula;
  Hud _hud;

  // Game properties
  double _scrollSpeed = 2.0;
  double _scroll = 0.0;

  int _framesToFire = 0;
  int _framesBetweenShots = 20;

  bool _gameOver = false;

  void spriteBoxPerformedLayout() {
    _gameSizeHeight = spriteBox.visibleArea.height;
    _gameScreen.position = new Point(0.0, _gameSizeHeight);
  }

  void update(double dt) {
    // Scroll the level
    _scroll = _level.scroll(_scrollSpeed);
    _starField.move(0.0, _scrollSpeed);

    _background.move(_scrollSpeed * 0.1);
    _nebula.move(_scrollSpeed);

    // Add objects
    addObjects();

    // Move the ship
    if (!_gameOver) {
      _level.ship.applyThrust(_joystick.value, _scroll);
    }

    // Add shots
    if (_framesToFire == 0 && _joystick.isDown && !_gameOver) {
      fire();
      _framesToFire = _framesBetweenShots;
    }
    if (_framesToFire > 0) _framesToFire--;

    // Move game objects
    for (Node node in _level.children) {
      if (node is GameObject) {
        node.move();
      }
    }

    // Remove offscreen game objects
    for (int i = _level.children.length - 1; i >= 0; i--) {
      Node node = _level.children[i];
      if (node is GameObject) {
        node.removeIfOffscreen(_scroll);
      }
    }

    if (_gameOver) return;

    // Check for collisions between lasers and objects that can take damage
    List<Laser> lasers = [];
    for (Node node in _level.children) {
      if (node is Laser) lasers.add(node);
    }

    List<GameObject> damageables = [];
    for (Node node in _level.children) {
      if (node is GameObject && node.canBeDamaged) damageables.add(node);
    }

    for (Laser laser in lasers) {
      for (GameObject damageable in damageables) {
        if (laser.collidingWith(damageable)) {
          // Hit something that can take damage
          _hud.score += damageable.addDamage(laser.impact);
          laser.destroy();
        }
      }
    }

    // Check for collsions between ship and objects that can damage the ship
    List<Node> nodes = new List.from(_level.children);
    for (Node node in nodes) {
      if (node is GameObject && node.canDamageShip) {
        if (node.collidingWith(_level.ship)) {
          // The ship was hit :(
          killShip();
          _level.ship.visible = false;
        }
      }
    }
  }

  int _chunk = 0;
  double _chunkSpacing = 640.0;

  void addObjects() {

    while (_scroll + _chunkSpacing >= _chunk * _chunkSpacing) {
      addLevelChunk(
        _chunk,
        -_chunk * _chunkSpacing - _chunkSpacing);

      _chunk += 1;
    }
  }

  void addLevelChunk(int chunk, double yPos) {
    if (chunk == 0) {
      // Leave the first chunk empty
      return;
    } else if (chunk == 1) {
      addLevelAsteroids(10, yPos, 0.0);
    } else {
      addLevelAsteroids(9 + chunk, yPos, 0.5);
    }
  }

  void addLevelAsteroids(int numAsteroids, double yPos, double distribution) {
    for (int i = 0; i < numAsteroids; i++) {
      GameObjectType type = (randomDouble() < distribution) ? GameObjectType.asteroidBig : GameObjectType.asteroidSmall;
      Point pos = new Point(randomSignedDouble() * 160.0,
                            yPos + _chunkSpacing * randomDouble());
      _objectFactory.addGameObject(type, pos);
    }
    _objectFactory.addGameObject(GameObjectType.movingEnemy, new Point(0.0, yPos + 160.0));
  }

  void fire() {
    Laser shot0 = new Laser(_objectFactory);
    shot0.position = _level.ship.position + new Offset(17.0, -10.0);
    _level.addChild(shot0);

    Laser shot1 = new Laser(_objectFactory);
    shot1.position = _level.ship.position + new Offset(-17.0, -10.0);
    _level.addChild(shot1);

    _effectPlayer.play(_sounds["laser"]);
  }

  void killShip() {
    // Hide ship
    _level.ship.visible = false;

    _effectPlayer.play(_sounds["explosion"]);

    // Add explosion
    Explosion explo = new Explosion(_spritesGame);
    explo.scale = 1.5;
    explo.position = _level.ship.position;
    _level.addChild(explo);

    // Add flash
    Flash flash = new Flash(size, 1.0);
    addChild(flash);

    // Set the state to game over
    _gameOver = true;

    // Return to main scene and report the score back in 2 seconds
    new Timer(new Duration(seconds: 2), () { _gameOverCallback(_hud.score); });
  }
}

class Level extends Node {
  Level() {
    position = new Point(160.0, 0.0);
  }

  Ship ship;

  double scroll(double scrollSpeed) {
    position += new Offset(0.0, scrollSpeed);
    return position.y;
  }
}

abstract class GameObject extends Node {
  double radius = 0.0;
  double removeLimit = 1280.0;
  bool canDamageShip = true;
  bool canBeDamaged = true;
  double maxDamage = 3.0;
  double damage = 0.0;

  Paint _paintDebug = new Paint()
    ..color=new Color(0xffff0000)
    ..strokeWidth = 1.0
    ..setStyle(sky.PaintingStyle.stroke);

  bool collidingWith(GameObject obj) {
    return (GameMath.pointQuickDist(position, obj.position)
      < radius + obj.radius);
  }

  void move() {
  }

  void removeIfOffscreen(double scroll) {
    ;
    if (-position.y > scroll + removeLimit ||
        -position.y < scroll - 50.0) {
      removeFromParent();
    }
  }

  void destroy() {
    if (parent != null) {
      Explosion explo = createExplosion();
      if (explo != null) {
        explo.position = position;
        parent.addChild(explo);
      }

      removeFromParent();
    }
  }

  int addDamage(double d) {
    if (!canBeDamaged) return 0;

    damage += d;
    if (damage >= maxDamage) {
      destroy();
      return (maxDamage * 10).ceil();
    }
    return 10;
  }

  Explosion createExplosion() {
    return null;
  }

  void paint(PaintingCanvas canvas) {
    if (_drawDebug) {
      canvas.drawCircle(Point.origin, radius, _paintDebug);
    }
    super.paint(canvas);
  }

  void setupActions() {
  }
}

class Ship extends GameObject {
  Ship(GameObjectFactory f) {
    // Add main ship sprite
    _sprt = new Sprite(f.sheet["ship.png"]);
    _sprt.scale = 0.3;
    _sprt.rotation = -90.0;
    addChild(_sprt);
    radius = 20.0;

    canBeDamaged = false;
    canDamageShip = false;

    // Set start position
    position = new Point(0.0, 50.0);
  }

  Sprite _sprt;

  void applyThrust(Point joystickValue, double scroll) {
    Point oldPos = position;
    Point target = new Point(joystickValue.x * 160.0, joystickValue.y * 220.0 - 250.0 - scroll);
    double filterFactor = 0.2;

    position = new Point(
      GameMath.filter(oldPos.x, target.x, filterFactor),
      GameMath.filter(oldPos.y, target.y, filterFactor));
  }
}

class Laser extends GameObject {
  double impact = 1.0;

  Laser(GameObjectFactory f) {
    // Add sprite
    _sprt = new Sprite(f.sheet["laser.png"]);
    _sprt.scale = 0.3;
    _sprt.transferMode = sky.TransferMode.plus;
    addChild(_sprt);
    radius = 10.0;
    removeLimit = 640.0;

    canDamageShip = false;
    canBeDamaged = false;
  }

  Sprite _sprt;

  void move() {
    position += new Offset(0.0, -10.0);
  }
}

abstract class Obstacle extends GameObject {

  Obstacle(this._f);

  double explosionScale = 1.0;
  GameObjectFactory _f;

  Explosion createExplosion() {
    SoundEffectPlayer.sharedInstance().play(_f.sounds["explosion"]);
    Explosion explo = new Explosion(_f.sheet);
    explo.scale = explosionScale;
    return explo;
  }
}

abstract class Asteroid extends Obstacle {
  Asteroid(GameObjectFactory f) : super(f);

  Sprite _sprt;

  void setupActions() {
    // Rotate obstacle
    int direction = 1;
    if (randomDouble() < 0.5) direction = -1;
    ActionTween rotate = new ActionTween(
      (a) => _sprt.rotation = a,
      0.0, 360.0 * direction, 5.0 + 5.0 * randomDouble());
    _sprt.actions.run(new ActionRepeatForever(rotate));
  }

  set damage(double d) {
    super.damage = d;
    int alpha = ((200.0 * d) ~/ maxDamage).clamp(0, 200);
    _sprt.colorOverlay = new Color.fromARGB(alpha, 255, 3, 86);
  }
}

class AsteroidBig extends Asteroid {
  AsteroidBig(GameObjectFactory f) : super(f) {
    _sprt = new Sprite(f.sheet["asteroid_big_${randomInt(3)}.png"]);
    _sprt.scale = 0.3;
    radius = 25.0;
    maxDamage = 5.0;
    addChild(_sprt);
  }
}

class AsteroidSmall extends Asteroid {
  AsteroidSmall(GameObjectFactory f) : super(f) {
    _sprt = new Sprite(f.sheet["asteroid_small_${randomInt(3)}.png"]);
    _sprt.scale = 0.3;
    radius = 12.0;
    maxDamage = 3.0;
    addChild(_sprt);
  }
}

class MovingEnemy extends Obstacle {
  MovingEnemy(GameObjectFactory f) : super(f) {
    _sprt = new Sprite(f.sheet["ship.png"]);
    _sprt.scale = 0.2;
    radius = 12.0;
    maxDamage = 2.0;
    addChild(_sprt);

    constraints = [new ConstraintRotationToMovement(0.0, 0.5)];
  }

  void setupActions() {
    List<Offset> offsets = [
      new Offset(-160.0, 160.0),
      new Offset(-80.0, -160.0),
      new Offset(0.0, 160.0),
      new Offset(80.0, -160.0),
      new Offset(160.0, 160.0)];

    List<Point> points = [];
    for (Offset offset in offsets) {
      points.add(position + offset);
    }

    ActionSpline spline = new ActionSpline((a) => position = a, points, 4.0);
    actions.run(new ActionRepeatForever(spline));
  }

  Sprite _sprt;
}

enum GameObjectType {
  asteroidBig,
  asteroidSmall,
  movingEnemy,
}

class GameObjectFactory {
  GameObjectFactory(this.sheet, this.sounds, this.level);

  SpriteSheet sheet;
  Map<String,SoundEffect> sounds;
  Level level;

  void addGameObject(GameObjectType type, Point pos) {
    GameObject obj;
    if (type == GameObjectType.asteroidBig)
      obj = new AsteroidBig(this);
    else if (type == GameObjectType.asteroidSmall)
      obj = new AsteroidSmall(this);
    else if (type == GameObjectType.movingEnemy)
      obj = new MovingEnemy(this);

    obj.position = pos;
    obj.setupActions();

    level.addChild(obj);
  }
}

class StarField extends NodeWithSize {
  sky.Image _image;
  SpriteSheet _spriteSheet;
  int _numStars;
  bool _autoScroll;

  List<Point> _starPositions;
  List<double> _starScales;
  List<Rect> _rects;
  List<Color> _colors;

  final double _padding = 50.0;
  Size _paddedSize = Size.zero;

  Paint _paint = new Paint()
    ..setFilterQuality(sky.FilterQuality.low)
    ..isAntiAlias = false
    ..setTransferMode(sky.TransferMode.plus);

  StarField(this._spriteSheet, this._numStars, [this._autoScroll = false]) : super(Size.zero) {
    _image = _spriteSheet.image;
  }

  void addStars() {
    _starPositions = [];
    _starScales = [];
    _colors = [];
    _rects = [];

    size = spriteBox.visibleArea.size;
    _paddedSize = new Size(size.width + _padding * 2.0,
                           size.height + _padding * 2.0);

    for (int i  = 0; i < _numStars; i++) {
      _starPositions.add(new Point(randomDouble() * _paddedSize.width,
                                   randomDouble() * _paddedSize.height));
      _starScales.add(randomDouble() * 0.4);
      _colors.add(new Color.fromARGB((255.0 * (randomDouble() * 0.5 + 0.5)).toInt(), 255, 255, 255));
      _rects.add(_spriteSheet["star_${randomInt(2)}.png"].frame);
    }
  }

  void spriteBoxPerformedLayout() {
    addStars();
  }

  void paint(PaintingCanvas canvas) {
    // Create a transform for each star
    List<sky.RSTransform> transforms = [];
    for (int i = 0; i < _numStars; i++) {
      sky.RSTransform transform = new sky.RSTransform(
        _starScales[i],
        0.0,
        _starPositions[i].x - _padding,
        _starPositions[i].y - _padding);

      transforms.add(transform);
    }

    // Draw the stars
    canvas.drawAtlas(_image, transforms, _rects, _colors, sky.TransferMode.modulate, null, _paint);
  }

  void move(double dx, double dy) {
    for (int i  = 0; i < _numStars; i++) {
      double xPos = _starPositions[i].x;
      double yPos = _starPositions[i].y;
      double scale = _starScales[i];

      xPos += dx * scale;
      yPos += dy * scale;

      if (xPos >= _paddedSize.width) xPos -= _paddedSize.width;
      if (xPos < 0) xPos += _paddedSize.width;
      if (yPos >= _paddedSize.height) yPos -= _paddedSize.height;
      if (yPos < 0) yPos += _paddedSize.height;

      _starPositions[i] = new Point(xPos, yPos);
    }
  }

  void update(double dt) {
    if (_autoScroll) {
      move(0.0, dt * 100.0);
    }
  }
}

class RepeatedImage extends Node {
  Sprite _sprt0;
  Sprite _sprt1;

  RepeatedImage(sky.Image image, [sky.TransferMode mode = null]) {
    _sprt0 = new Sprite.fromImage(image);
    _sprt0.size = new Size(1024.0, 1024.0);
    _sprt0.pivot = Point.origin;
    _sprt1 = new Sprite.fromImage(image);
    _sprt1.size = new Size(1024.0, 1024.0);
    _sprt1.pivot = Point.origin;
    _sprt1.position = new Point(0.0, -1024.0);

    if (mode != null) {
      _sprt0.transferMode = mode;
      _sprt1.transferMode = mode;
    }

    addChild(_sprt0);
    addChild(_sprt1);
  }

  void move(double dy) {
    double yPos = (position.y + dy) % 1024.0;
    position = new Point(0.0, yPos);
  }
}

class Explosion extends Node {
  Explosion(SpriteSheet sheet) {
    // Add particles
    ParticleSystem particlesDebris = new ParticleSystem(
      sheet["explosion_particle.png"],
      rotateToMovement: true,
      startRotation:90.0,
      startRotationVar: 0.0,
      endRotation: 90.0,
      startSize: 0.3,
      startSizeVar: 0.1,
      endSize: 0.3,
      endSizeVar: 0.1,
      numParticlesToEmit: 25,
      emissionRate:1000.0,
      greenVar: 127,
      redVar: 127
    );
    particlesDebris.zPosition = 1010.0;
    addChild(particlesDebris);

    ParticleSystem particlesFire = new ParticleSystem(
      sheet["fire_particle.png"],
      colorSequence: new ColorSequence([new Color(0xffffff33), new Color(0xffff3333), new Color(0x00ff3333)], [0.0, 0.5, 1.0]),
      numParticlesToEmit: 25,
      emissionRate: 1000.0,
      startSize: 0.5,
      startSizeVar: 0.1,
      endSize: 0.5,
      endSizeVar: 0.1,
      posVar: new Point(10.0, 10.0),
      speed: 10.0,
      speedVar: 5.0
    );
    particlesFire.zPosition = 1011.0;
    addChild(particlesFire);

    // Add ring
    Sprite sprtRing = new Sprite(sheet["explosion_ring.png"]);
    sprtRing.transferMode = sky.TransferMode.plus;
    addChild(sprtRing);

    Action scale = new ActionTween( (a) => sprtRing.scale = a, 0.2, 1.0, 1.5);
    Action scaleAndRemove = new ActionSequence([scale, new ActionRemoveNode(sprtRing)]);
    Action fade = new ActionTween( (a) => sprtRing.opacity = a, 1.0, 0.0, 1.5);
    actions.run(scaleAndRemove);
    actions.run(fade);

    // Add streaks
    for (int i = 0; i < 5; i++) {
      Sprite sprtFlare = new Sprite(sheet["explosion_flare.png"]);
      sprtFlare.pivot = new Point(0.3, 1.0);
      sprtFlare.scaleX = 0.3;
      sprtFlare.transferMode = sky.TransferMode.plus;
      sprtFlare.rotation = randomDouble() * 360.0;
      addChild(sprtFlare);

      double multiplier = randomDouble() * 0.3 + 1.0;

      Action scale = new ActionTween( (a) => sprtFlare.scaleY = a, 0.3 * multiplier, 0.8, 1.5 * multiplier);
      Action scaleAndRemove = new ActionSequence([scale, new ActionRemoveNode(sprtFlare)]);
      Action fadeIn = new ActionTween( (a) => sprtFlare.opacity = a, 0.0, 1.0, 0.5 * multiplier);
      Action fadeOut = new ActionTween( (a) => sprtFlare.opacity = a, 1.0, 0.0, 1.0 * multiplier);
      Action fadeInOut = new ActionSequence([fadeIn, fadeOut]);
      actions.run(scaleAndRemove);
      actions.run(fadeInOut);
    }
  }
}

class Hud extends Node {
  SpriteSheet sheet;
  Sprite sprtBgScore;

  bool _dirtyScore = true;
  int _score = 0;

  int get score => _score;

  set score(int score) {
    _score = score;
    _dirtyScore = true;
  }

  Hud(this.sheet) {
    position = new Point(310.0, 10.0);
    scale = 0.6;

    sprtBgScore = new Sprite(sheet["scoreboard.png"]);
    sprtBgScore.pivot = new Point(1.0, 0.0);
    sprtBgScore.scale = 0.6;
    addChild(sprtBgScore);
  }

  void update(double dt) {
    // Update score
    if (_dirtyScore) {

      sprtBgScore.removeAllChildren();

      String scoreStr = _score.toString();
      double xPos = -50.0;
      for (int i = scoreStr.length - 1; i >= 0; i--) {
        String numStr = scoreStr.substring(i, i + 1);
        Sprite numSprt = new Sprite(sheet["number_$numStr.png"]);
        numSprt.position = new Point(xPos, 49.0);
        sprtBgScore.addChild(numSprt);
        xPos -= 37.0;
      }
      _dirtyScore = false;
    }
  }
}

class Flash extends NodeWithSize {
  Flash(Size size, this.duration) : super(size) {
    ActionTween fade = new ActionTween((a) => _opacity = a, 1.0, 0.0, duration);
    ActionSequence seq = new ActionSequence([fade, new ActionRemoveNode(this)]);
    actions.run(seq);
  }

  double duration;
  double _opacity = 1.0;
  Paint _cachedPaint = new Paint();

  void paint(PaintingCanvas canvas) {
    // Update the color
    _cachedPaint.color = new Color.fromARGB((255.0 * _opacity).toInt(),
                                            255, 255, 255);
    // Fill the area
    applyTransformForPivot(canvas);
    canvas.drawRect(new Rect.fromLTRB(0.0, 0.0, size.width, size.height),
      _cachedPaint);
  }
}
