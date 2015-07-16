part of game;

const double _steeringThreshold = 0.0;
const double _steeringMax = 150.0;

// Random generator
Math.Random _rand = new Math.Random();

const double _gameSizeWidth = 1024.0;
const double _gameSizeHeight = 1024.0;

const double _shipRadius = 30.0;
const double _lrgAsteroidRadius = 40.0;
const double _medAsteroidRadius = 20.0;
const double _smlAsteroidRadius = 10.0;
const double _maxAsteroidSpeed = 1.0;

const int _lifeTimeLaser = 50;

const int _numStarsInStarField = 150;

const int _numFramesShieldActive = 60 * 5;
const int _numFramesShieldFlickers = 60;

class GameDemoWorld extends NodeWithSize {
  // Images
  sky.Image _imgNebula;

  SpriteSheet _spriteSheet;

  // Inputs
  double _joystickX = 0.0;
  double _joystickY = 0.0;

  Node _gameLayer;

  Ship _ship;
  Sprite _shield;
  List<Asteroid> _asteroids = [];
  List<Laser> _lasers = [];
  StarField _starField;
  Nebula _nebula;

  // Game state
  int _numFrames = 0;
  bool _isGameOver = false;

  GameDemoWorld(App app, ImageMap images, this._spriteSheet) : super(new Size(_gameSizeWidth, _gameSizeHeight)) {

    // Fetch images
    _imgNebula = images["assets/nebula.png"];

    _gameLayer = new Node();
    this.addChild(_gameLayer);

    // Add some asteroids to the game world
    for (int i = 0; i < 5; i++) {
      addAsteroid(AsteroidSize.large);
    }
    for (int i = 0; i < 5; i++) {
      addAsteroid(AsteroidSize.medium);
    }

    // Add ship
    addShip();

    // Add background
    Sprite sprtBackground = new Sprite.fromImage(images["assets/starfield.png"]);
    sprtBackground.position = new Point(512.0, 512.0);
    sprtBackground.zPosition = -3.0;
    addChild(sprtBackground);

    // Add starfield
    _starField = new StarField(_spriteSheet, _numStarsInStarField);
    _starField.zPosition = -2.0;
    addChild(_starField);

    // Add nebula
    addNebula();

    userInteractionEnabled = true;
    handleMultiplePointers = true;
  }

  // Methods for adding game objects

  void addAsteroid(AsteroidSize size, [Point pos]) {
    Asteroid asteroid = new Asteroid(_spriteSheet, size);
    asteroid.zPosition = 1.0;
    if (pos != null) asteroid.position = pos;
    _gameLayer.addChild(asteroid);
    _asteroids.add(asteroid);
  }

  void addShip() {
    Ship ship = new Ship(_spriteSheet["ship.png"]);
    ship.zPosition = 10.0;
    _gameLayer.addChild(ship);
    _ship = ship;

    _shield = new Sprite(_spriteSheet["shield.png"]);
    _shield.zPosition = 11.0;
    _shield.scale = 0.5;
    _shield.transferMode = sky.TransferMode.plus;
    _gameLayer.addChild(_shield);

    Action rotate = new ActionRepeatForever(new ActionTween((a) => _shield.rotation = a, 0.0, 360.0, 1.0));
    actions.run(rotate);
  }

  void addLaser() {
    Laser laser = new Laser(_spriteSheet["laser.png"], _ship);
    laser.zPosition = 8.0;
    laser.constrainProportions = true;
    _lasers.add(laser);
    _gameLayer.addChild(laser);
  }

  void addNebula() {
    _nebula = new Nebula.withImage(_imgNebula);
    _gameLayer.addChild(_nebula);
  }

  void addExplosion(AsteroidSize asteroidSize, Point position) {
    Node explosionNode = new Node();

    // Add particles
    ParticleSystem particlesDebris = new ParticleSystem(
        _spriteSheet["explosion_particle.png"],
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
    explosionNode.addChild(particlesDebris);

    ParticleSystem particlesFire = new ParticleSystem(
      _spriteSheet["fire_particle.png"],
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
    explosionNode.addChild(particlesFire);


    // Add ring
    Sprite sprtRing = new Sprite(_spriteSheet["explosion_ring.png"]);
    sprtRing.transferMode = sky.TransferMode.plus;
    explosionNode.addChild(sprtRing);

    Action scale = new ActionTween( (a) => sprtRing.scale = a, 0.2, 1.0, 1.5);
    Action scaleAndRemove = new ActionSequence([scale, new ActionRemoveNode(sprtRing)]);
    Action fade = new ActionTween( (a) => sprtRing.opacity = a, 1.0, 0.0, 1.5);
    actions.run(scaleAndRemove);
    actions.run(fade);

    // Add streaks
    for (int i = 0; i < 5; i++) {
      Sprite sprtFlare = new Sprite(_spriteSheet["explosion_flare.png"]);
      sprtFlare.pivot = new Point(0.3, 1.0);
      sprtFlare.scaleX = 0.3;
      sprtFlare.transferMode = sky.TransferMode.plus;
      sprtFlare.rotation = _rand.nextDouble() * 360.0;
      explosionNode.addChild(sprtFlare);

      double multiplier = _rand.nextDouble() * 0.3 + 1.0;

      Action scale = new ActionTween( (a) => sprtFlare.scaleY = a, 0.3 * multiplier, 0.8, 1.5 * multiplier);
      Action scaleAndRemove = new ActionSequence([scale, new ActionRemoveNode(sprtFlare)]);
      Action fadeIn = new ActionTween( (a) => sprtFlare.opacity = a, 0.0, 1.0, 0.5 * multiplier);
      Action fadeOut = new ActionTween( (a) => sprtFlare.opacity = a, 1.0, 0.0, 1.0 * multiplier);
      Action fadeInOut = new ActionSequence([fadeIn, fadeOut]);
      actions.run(scaleAndRemove);
      actions.run(fadeInOut);
    }

    explosionNode.position = position;
    explosionNode.zPosition = 1010.0;

    if (asteroidSize == AsteroidSize.large) {
      explosionNode.scale = 1.5;
    }

    _gameLayer.addChild(explosionNode);
  }

  void update(double dt) {
    // Move asteroids
    for (Asteroid asteroid in _asteroids) {
      asteroid.position = pointAdd(asteroid.position, asteroid._movementVector);
    }

    // Move lasers and remove expired lasers
    for (int i = _lasers.length - 1; i >= 0; i--) {
      Laser laser = _lasers[i];
      laser.move();
      if (laser._frameCount > _lifeTimeLaser) {
        laser.removeFromParent();
        _lasers.removeAt(i);
      }
    }

    // Apply thrust to ship
    if (_joystickX != 0.0 || _joystickY != 0.0) {
      _ship.thrust(_joystickX, _joystickY);
    }

    // Move ship
    _ship.move();
    _shield.position = _ship.position;

    // Check collisions between asteroids and lasers
    for (int i = _lasers.length -1; i >= 0; i--) {
      // Iterate over all the lasers
      Laser laser = _lasers[i];

      for (int j = _asteroids.length - 1; j >= 0; j--) {
        // Iterate over all the asteroids
        Asteroid asteroid = _asteroids[j];

        // Check for collision
        if (pointQuickDist(laser.position, asteroid.position) < laser.radius + asteroid.radius) {
          // Remove laser
          laser.removeFromParent();
          _lasers.removeAt(i);

          // Add asteroids and explosions
          if (asteroid._asteroidSize == AsteroidSize.large) {
            for (int a = 0; a < 3; a++) addAsteroid(AsteroidSize.medium, asteroid.position);
          }
          else if (asteroid._asteroidSize == AsteroidSize.medium) {
            for (int a = 0; a < 5; a++) addAsteroid(AsteroidSize.small, asteroid.position);
          }

          addExplosion(asteroid._asteroidSize, asteroid.position);

          // Remove asteroid
          asteroid.removeFromParent();
          _asteroids.removeAt(j);
          break;
        }
      }
    }

    // Check collisions between asteroids and ship
    if (_numFrames > _numFramesShieldActive) {
      // Shield is no longer active

      for (int i = _asteroids.length - 1; i >= 0; i--) {
        // Iterate over all the asteroids
        Asteroid asteroid = _asteroids[i];

        if (pointQuickDist(asteroid.position, _ship.position) < asteroid.radius + _ship.radius) {
          killShip();
        }
      }
    }

    // Move objects to center camera and warp objects around the edges
    centerCamera();
    warpObjects();

    // Update shield
    if (_numFrames > _numFramesShieldActive) _shield.visible = false;
    else if (_numFrames > _numFramesShieldActive - _numFramesShieldFlickers) _shield.visible = !_shield.visible;

    _numFrames++;
  }

  void centerCamera() {
    const cameraDampening = 0.1;
    Point delta = new Point(_gameSizeWidth/2 - _ship.position.x, _gameSizeHeight/2 - _ship.position.y);
    delta = pointMult(delta, cameraDampening);

    for (Node child in _gameLayer.children) {
      child.position = pointAdd(child.position, delta);
    }

    // Update starfield
    _starField.move(delta.x, delta.y);
  }

  void warpObjects() {
    for (Node child in _gameLayer.children) {
      if (child.position.x < 0) child.position = pointAdd(child.position, new Point(_gameSizeWidth, 0.0));
      if (child.position.x >= _gameSizeWidth) child.position = pointAdd(child.position, new Point(-_gameSizeWidth, 0.0));
      if (child.position.y < 0) child.position = pointAdd(child.position, new Point(0.0, _gameSizeHeight));
      if (child.position.y >= _gameSizeHeight) child.position = pointAdd(child.position, new Point(0.0, -_gameSizeHeight));
    }
  }

  void killShip() {
    if (_isGameOver) return;

    // Set game over
    _isGameOver = true;

    // Remove the ship
    _ship.visible = false;

    // Add an explosion
    addExplosion(AsteroidSize.large, _ship.position);
  }

  // Handling controls

  void controlSteering(double x, double y) {
    // Reset controls if it's game over
    if (_isGameOver) {
      x = y = 0.0;
    }

    _joystickX = x;
    _joystickY = y;
  }

  void controlFire() {
    // Don't shoot if it's game over
    if (_isGameOver) return;

    addLaser();
  }

  // Handle pointer events

  int _firstPointer = -1;
  int _secondPointer = -1;
  Point _firstPointerDownPos;

  bool handleEvent(SpriteBoxEvent event) {

    Point pointerPos = convertPointToNodeSpace(event.boxPosition);
    int pointer = event.pointer;

    switch (event.type) {
      case 'pointerdown':
        if (_firstPointer == -1) {
          // Assign the first pointer
          _firstPointer = pointer;
          _firstPointerDownPos = pointerPos;
        }
        else if (_secondPointer == -1) {
          // Assign second pointer
          _secondPointer = pointer;
          controlFire();
        }
        else {
          // There is a pointer used for steering, let's fire instead
          controlFire();
        }
        break;
      case 'pointermove':
        if (pointer == _firstPointer) {
          // Handle turning control
          double joystickX = 0.0;
          double deltaX = pointerPos.x - _firstPointerDownPos.x;
          if (deltaX > _steeringThreshold || deltaX < -_steeringThreshold) {
            joystickX = (deltaX - _steeringThreshold)/(_steeringMax - _steeringThreshold);
            if (joystickX > 1.0) joystickX = 1.0;
            if (joystickX < -1.0) joystickX = -1.0;
          }

          double joystickY = 0.0;
          double deltaY = pointerPos.y - _firstPointerDownPos.y;
          if (deltaY > _steeringThreshold || deltaY < -_steeringThreshold) {
            joystickY = (deltaY - _steeringThreshold)/(_steeringMax - _steeringThreshold);
            if (joystickY > 1.0) joystickY = 1.0;
            if (joystickY < -1.0) joystickY = -1.0;
          }

          controlSteering(joystickX, joystickY);
        }
        break;
      case 'pointerup':
      case 'pointercancel':
        if (pointer == _firstPointer) {
          // Un-assign the first pointer
          _firstPointer = -1;
          _firstPointerDownPos = null;
          controlSteering(0.0, 0.0);
        }
        else if (pointer == _secondPointer) {
          _secondPointer = -1;
        }
        break;
      default:
        break;
    }
    return true;
  }
}

// Game objects

enum AsteroidSize {
  small,
  medium,
  large,
}

class Asteroid extends Sprite {
  Point _movementVector;
  AsteroidSize _asteroidSize;
  double _radius;

  double get radius {
    if (_radius != null) return _radius;
    if (_asteroidSize == AsteroidSize.small) _radius = _smlAsteroidRadius;
    else if (_asteroidSize == AsteroidSize.medium) _radius = _medAsteroidRadius;
    else if (_asteroidSize == AsteroidSize.large) _radius = _lrgAsteroidRadius;
    return _radius;
  }

  Asteroid(SpriteSheet spriteSheet, AsteroidSize this._asteroidSize) {
    size = new Size(radius * 2.0, radius * 2.0);
    position = new Point(_gameSizeWidth * _rand.nextDouble(), _gameSizeHeight * _rand.nextDouble());
    rotation = 360.0 * _rand.nextDouble();

    if (_asteroidSize == AsteroidSize.small) {
      texture = spriteSheet["asteroid_small_${_rand.nextInt(2)}.png"];
    } else {
      texture = spriteSheet["asteroid_big_${_rand.nextInt(2)}.png"];
    }

    _movementVector = new Point(_rand.nextDouble() * _maxAsteroidSpeed * 2 - _maxAsteroidSpeed,
                                _rand.nextDouble() * _maxAsteroidSpeed * 2 - _maxAsteroidSpeed);

    userInteractionEnabled = true;

    // Rotate forever
    double direction = (_rand.nextBool()) ? 360.0 : -360.0;
    ActionTween rot = new ActionTween( (a) => rotation = a, 0.0, direction, 2.0 * _rand.nextDouble() + 2.0);
    ActionRepeatForever repeat = new ActionRepeatForever(rot);
    actions.run(repeat);
  }

  bool handleEvent(SpriteBoxEvent event) {
    if (event.type == "pointerdown") {
      actions.stopWithTag("fade");
      colorOverlay = new Color(0x99ffffff);
    }
    else if (event.type == "pointerup") {
      // Fade out the color overlay
      Action fadeOut = new ActionTween((a) => this.colorOverlay = a, new Color(0x99ffffff), new Color(0x00ffffff), 1.0);
      Action fadeOutAndRemove = new ActionSequence([fadeOut, new ActionCallFunction(() => this.colorOverlay = null)]);
      actions.run(fadeOutAndRemove, "fade");
    }
    return false;
  }
}

class Ship extends Sprite {
  Vector2 _movementVector;
  double _rotationTarget;
  double radius = _shipRadius;

  Ship(Texture img) : super(img) {
    _movementVector = new Vector2.zero();
    rotation = _rotationTarget = 270.0;

    // Create sprite
    size = new Size(_shipRadius * 2.0, _shipRadius * 2.0);
    position = new Point(_gameSizeWidth/2.0, _gameSizeHeight/2.0);
  }

  void thrust(double x, double y) {
    _rotationTarget = convertRadians2Degrees(Math.atan2(y, x));
    Vector2 directionVector = new Vector2(x, y).normalize();
    _movementVector.addScaled(directionVector, 1.0);
  }

  void move() {
    position = new Point(position.x + _movementVector[0], position.y + _movementVector[1]);
    _movementVector.scale(0.9);

    rotation = dampenRotation(rotation, _rotationTarget, 0.1);
  }
}

class Laser extends Sprite {
  int _frameCount = 0;
  Point _movementVector;
  double radius = 20.0;

  Laser(Texture img, Ship ship) : super(img) {
    size = new Size(30.0, 30.0);
    position = ship.position;
    rotation = ship.rotation + 90.0;
    transferMode = sky.TransferMode.plus;
    double rotRadians = convertDegrees2Radians(rotation);
    _movementVector = pointMult(new Point(Math.sin(rotRadians), -Math.cos(rotRadians)), 10.0);
    _movementVector = new Point(_movementVector.x + ship._movementVector[0], _movementVector.y + ship._movementVector[1]);
  }

  void move() {
    position = pointAdd(position, _movementVector);
    _frameCount++;
  }
}

// Background starfield

class StarField extends Node {
  int _numStars;
  List<Point> _starPositions;
  List<double> _starScales;
  List<double> _opacity;
  List<Texture> _textures;

  StarField(SpriteSheet spriteSheet, this._numStars) {
    _starPositions = [];
    _starScales = [];
    _opacity = [];
    _textures = [];

    for (int i  = 0; i < _numStars; i++) {
      _starPositions.add(new Point(_rand.nextDouble() * _gameSizeWidth, _rand.nextDouble() * _gameSizeHeight));
      _starScales.add(_rand.nextDouble());
      _opacity.add(_rand.nextDouble() * 0.5 + 0.5);
      _textures.add(spriteSheet["star_${_rand.nextInt(2)}.png"]);
    }
  }

  void paint(PaintingCanvas canvas) {
    // Setup paint object for opacity and transfer mode
    Paint paint = new Paint();
    paint.setTransferMode(sky.TransferMode.plus);

    double baseScaleX = 64.0 / _textures[0].size.width;
    double baseScaleY = 64.0 / _textures[0].size.height;

    // Draw each star
    for (int i = 0; i < _numStars; i++) {
      Point pos = _starPositions[i];
      double scale = _starScales[i];
      paint.color = new Color.fromARGB((255.0*_opacity[i]).toInt(), 255, 255, 255);

      canvas.save();

      canvas.translate(pos.x, pos.y);
      canvas.scale(baseScaleX * scale, baseScaleY * scale);

      canvas.drawImageRect(_textures[i].image, _textures[i].frame, _textures[i].spriteSourceSize, paint);

      canvas.restore();
    }
  }

  void move(double dx, double dy) {
    for (int i  = 0; i < _numStars; i++) {
      double xPos = _starPositions[i].x;
      double yPos = _starPositions[i].y;
      double scale = _starScales[i];

      xPos += dx * scale;
      yPos += dy * scale;

      if (xPos >= _gameSizeWidth) xPos -= _gameSizeWidth;
      if (xPos < 0) xPos += _gameSizeWidth;
      if (yPos >= _gameSizeHeight) yPos -= _gameSizeHeight;
      if (yPos < 0) yPos += _gameSizeHeight;

      _starPositions[i] = new Point(xPos, yPos);
    }
  }
}

class Nebula extends Node {

  Nebula.withImage(sky.Image img) {
    for (int i = 0; i < 2; i++) {
      for (int j = 0; j < 2; j++) {
        Sprite sprt = new Sprite.fromImage(img);
        sprt.pivot = Point.origin;
        sprt.position = new Point(i * _gameSizeWidth - _gameSizeWidth, j * _gameSizeHeight - _gameSizeHeight);
        addChild(sprt);
      }
    }
  }
}

// Convenience methods

Point pointAdd(Point a, Point b) {
  return new Point(a.x+ b.x, a.y + b.y);
}

Point pointMult(Point a, double multiplier) {
  return new Point(a.x * multiplier, a.y * multiplier);
}

double dampenRotation(double src, double dst, double dampening) {
  double delta = dst - src;
  while (delta > 180.0) delta -= 360;
  while (delta < -180) delta += 360;
  delta *= dampening;

  return src + delta;
}

double pointQuickDist(Point a, Point b) {
  double dx = a.x - b.x;
  double dy = a.y - b.y;
  if (dx < 0.0) dx = -dx;
  if (dy < 0.0) dy = -dy;
  if (dx > dy) {
    return dx + dy/2.0;
  }
  else {
    return dy + dx/2.0;
  }
}
