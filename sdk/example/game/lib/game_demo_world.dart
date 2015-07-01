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

class GameDemoWorld extends NodeWithSize {

  // Images
  Image _imgNebula;

  SpriteSheet _spriteSheet;

  // Inputs
  double _joystickX = 0.0;
  double _joystickY = 0.0;
  bool _fire;

  Node _gameLayer;

  Ship _ship;
  List<Asteroid> _asteroids = [];
  List<Laser> _lasers = [];
  StarField _starField;
  Nebula _nebula;
  
  GameDemoWorld(ImageMap images, this._spriteSheet) : super(new Size(_gameSizeWidth, _gameSizeHeight)) {

    // Fetch images
    _imgNebula = images["res/nebula.png"];

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

    // Add starfield
    _starField = new StarField(_spriteSheet["star.png"], _numStarsInStarField);
    _starField.zPosition = -2.0;
    addChild(_starField);

    // Add nebula
    addNebula();

    userInteractionEnabled = true;
    handleMultiplePointers = true;
  }

  // Methods for adding game objects
  
  void addAsteroid(AsteroidSize size, [Point pos]) {
    Asteroid asteroid = new Asteroid(_spriteSheet["asteroid_big_1.png"], size);
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
    // Add particles
    ParticleSystem particles = new ParticleSystem(_spriteSheet["laser.png"], rotateToMovement: true,
    startRotation:90.0, startRotationVar: 0.0, endRotation: 90.0, startSize: 0.2, startSizeVar: 0.1, endSize: 0.2, endSizeVar: 0.1,
    numParticlesToEmit: 25, emissionRate:1000.0, blueVar: 127);
    particles.zPosition = 1010.0;
    particles.position = position;
    _gameLayer.addChild(particles);
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

    // Move objects to center camera and warp objects around the edges
    centerCamera();
    warpObjects();
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

  // Handling controls

  void controlSteering(double x, double y) {
    _joystickX = x;
    _joystickY = y;
  }

  void controlFire() {
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

  Asteroid(Texture img, AsteroidSize this._asteroidSize) : super(img) {
    size = new Size(radius * 2.0, radius * 2.0);
    position = new Point(_gameSizeWidth * _rand.nextDouble(), _gameSizeHeight * _rand.nextDouble());
    rotation = 360.0 * _rand.nextDouble();

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
      colorOverlay = new Color(0x99ff0000);
    }
    else if (event.type == "pointerup") {
      colorOverlay = null;
    }
    return false;
  }
}

class Ship extends Sprite {
  Vector2 _movementVector;
  double _rotationTarget;

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
    transferMode = TransferMode.plus;
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
  Texture _img;
  int _numStars;
  List<Point> _starPositions;
  List<double> _starScales;
  List<double> _opacity;

  StarField(this._img, this._numStars) {
    _starPositions = [];
    _starScales = [];
    _opacity = [];

    for (int i  = 0; i < _numStars; i++) {
      _starPositions.add(new Point(_rand.nextDouble() * _gameSizeWidth, _rand.nextDouble() * _gameSizeHeight));
      _starScales.add(_rand.nextDouble());
      _opacity.add(_rand.nextDouble() * 0.5 + 0.5);
    }
  }

  void paint(PaintingCanvas canvas) {
    // Setup paint object for opacity and transfer mode
    Paint paint = new Paint();
    paint.setTransferMode(TransferMode.plus);

    double baseScaleX = 32.0 / _img.size.width;
    double baseScaleY = 32.0 / _img.size.height;

    // Draw each star
    for (int i = 0; i < _numStars; i++) {
      Point pos = _starPositions[i];
      double scale = _starScales[i];
      paint.color = new Color.fromARGB((255.0*_opacity[i]).toInt(), 255, 255, 255);

      canvas.save();

      canvas.translate(pos.x, pos.y);
      canvas.scale(baseScaleX * scale, baseScaleY * scale);

      canvas.drawImageRect(_img.image, _img.frame, _img.spriteSourceSize, paint);

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

  Nebula.withImage(Image img) {
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
