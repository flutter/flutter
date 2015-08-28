part of game;

abstract class GameObject extends Node {
  GameObject(this.f);

  double radius = 0.0;
  double removeLimit = 1280.0;
  bool canDamageShip = true;
  bool canBeDamaged = true;
  bool canBeCollected = false;
  double maxDamage = 3.0;
  double damage = 0.0;

  final GameObjectFactory f;

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

      Collectable powerUp = createPowerUp();
      if (powerUp != null) {
        powerUp.position = position;
        powerUp.setupActions();
        parent.addChild(powerUp);
      }

      removeFromParent();
    }
  }

  void collect() {
    removeFromParent();
  }

  void addDamage(double d) {
    if (!canBeDamaged) return;

    damage += d;
    if (damage >= maxDamage) {
      destroy();
      f.playerState.score += (maxDamage * 10).ceil();
    }
  }

  Explosion createExplosion() {
    return null;
  }

  Collectable createPowerUp() {
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
  Ship(GameObjectFactory f) : super(f) {
    // Add main ship sprite
    _sprt = new Sprite(f.sheet["ship.png"]);
    _sprt.scale = 0.3;
    _sprt.rotation = -90.0;
    addChild(_sprt);

    _sprtShield = new Sprite(f.sheet["shield.png"]);
    _sprtShield.scale = 0.35;
    _sprtShield.transferMode = sky.TransferMode.plus;
    addChild(_sprtShield);

    radius = 20.0;
    canBeDamaged = false;
    canDamageShip = false;

    // Set start position
    position = new Point(0.0, 50.0);
  }

  Sprite _sprt;
  Sprite _sprtShield;

  void applyThrust(Point joystickValue, double scroll) {
    Point oldPos = position;
    Point target = new Point(joystickValue.x * 160.0, joystickValue.y * 220.0 - 250.0 - scroll);
    double filterFactor = 0.2;

    position = new Point(
      GameMath.filter(oldPos.x, target.x, filterFactor),
      GameMath.filter(oldPos.y, target.y, filterFactor));
  }

  void setupActions() {
    ActionTween rotate = new ActionTween((a) => _sprtShield.rotation = a, 0.0, 360.0, 1.0);
    _sprtShield.actions.run(new ActionRepeatForever(rotate));
  }

  void update(double dt) {
    // Update shield
    if (f.playerState.shieldActive) {
      if (f.playerState.shieldDeactivating)
        _sprtShield.visible = !_sprtShield.visible;
      else
        _sprtShield.visible = true;
    } else {
      _sprtShield.visible = false;
    }
  }
}

class Laser extends GameObject {
  double impact = 1.0;

  Laser(GameObjectFactory f, double r) : super(f) {
    // Add sprite
    _sprt = new Sprite(f.sheet["explosion_particle.png"]);
    _sprt.scale = 0.5;
    _sprt.colorOverlay = new Color(0xff95f4fb);
    _sprt.transferMode = sky.TransferMode.plus;
    _sprt.rotation = r + 90.0;
    addChild(_sprt);
    radius = 10.0;
    removeLimit = 640.0;


    canDamageShip = false;
    canBeDamaged = false;

    _offset = new Offset(math.cos(radians(r)) * 10.0, math.sin(radians(r)) * 10.0);
  }

  Sprite _sprt;
  Offset _offset;

  void move() {
    position += _offset;
  }
}

Color colorForDamage(double damage, double maxDamage) {
  int alpha = ((200.0 * damage) ~/ maxDamage).clamp(0, 200);
  return new Color.fromARGB(alpha, 255, 3, 86);
}

abstract class Obstacle extends GameObject {

  Obstacle(GameObjectFactory f) : super(f);

  double explosionScale = 1.0;

  Explosion createExplosion() {
    SoundEffectPlayer.sharedInstance().play(f.sounds["explosion"]);
    Explosion explo = new ExplosionBig(f.sheet);
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
    if (randomBool()) direction = -1;
    ActionTween rotate = new ActionTween(
      (a) => _sprt.rotation = a,
      0.0, 360.0 * direction, 5.0 + 5.0 * randomDouble());
    _sprt.actions.run(new ActionRepeatForever(rotate));
  }

  set damage(double d) {
    super.damage = d;
    _sprt.colorOverlay = colorForDamage(d, maxDamage);
  }

  Collectable createPowerUp() {
    return new Coin(f);
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

class AsteroidPowerUp extends AsteroidBig {
  AsteroidPowerUp(GameObjectFactory f) : super(f);

  Collectable createPowerUp() {
    return new PowerUp(f, nextPowerUpType());
  }
}

class EnemyScout extends Obstacle {
  EnemyScout(GameObjectFactory f) : super(f) {
    _sprt = new Sprite(f.sheet["enemy_scout_0.png"]);
    _sprt.scale = 0.32;
    radius = 12.0;
    maxDamage = 1.0;
    addChild(_sprt);

    constraints = [new ConstraintRotationToMovement(dampening: 0.5)];
  }

  final double _swirlSpacing = 80.0;

  _addRandomSquare(List<Offset> offsets, double x, double y) {
    double xMove = (randomBool()) ? _swirlSpacing : -_swirlSpacing;
    double yMove = (randomBool()) ? _swirlSpacing : -_swirlSpacing;

    if (randomBool()) {
      offsets.addAll([
        new Offset(x, y),
        new Offset(xMove + x, y),
        new Offset(xMove + x, yMove + y),
        new Offset(x, yMove + y),
        new Offset(x, y)
      ]);
    } else {
      offsets.addAll([
        new Offset(x, y),
        new Offset(x, y + yMove),
        new Offset(xMove + x, yMove + y),
        new Offset(xMove + x, y),
        new Offset(x, y)
      ]);
    }
  }

  void setupActions() {

    List<Offset> offsets = [];
    _addRandomSquare(offsets, -_swirlSpacing, 0.0);
    _addRandomSquare(offsets, _swirlSpacing, 0.0);
    offsets.add(new Offset(-_swirlSpacing, 0.0));

    List<Point> points = [];
    for (Offset offset in offsets) {
      points.add(position + offset);
    }

    ActionSpline spline = new ActionSpline((a) => position = a, points, 6.0);
    spline.tension = 0.7;
    actions.run(new ActionRepeatForever(spline));
  }

  Collectable createPowerUp() {
    return new Coin(f);
  }

  Sprite _sprt;
}

class EnemyDestroyer extends Obstacle {
  EnemyDestroyer(GameObjectFactory f) : super(f) {
    _sprt = new Sprite(f.sheet["enemy_destroyer_1.png"]);
    _sprt.scale = 0.32;
    radius = 24.0;
    maxDamage = 4.0;
    addChild(_sprt);

    constraints = [new ConstraintRotationToNode(f.level.ship, dampening: 0.05)];
  }

  int _countDown = randomInt(120) + 240;

  void setupActions() {
    ActionCircularMove circle = new ActionCircularMove(
      (a) => position = a,
      position, 40.0,
      360.0 * randomDouble(),
      randomBool(),
      3.0);
    actions.run(new ActionRepeatForever(circle));
  }

  Collectable createPowerUp() {
    return new Coin(f);
  }

  void update(double dt) {
    _countDown -= 1;
    if (_countDown <= 0) {
      print("SHOOT!!");

      // Shoot at player
      EnemyLaser laser = new EnemyLaser(f, rotation, 5.0, new Color(0xffffe38e));
      laser.position = position;
      f.level.addChild(laser);

      _countDown = 60 + randomInt(120);
    }
  }

  set damage(double d) {
    super.damage = d;
    _sprt.colorOverlay = colorForDamage(d, maxDamage);
  }

  Sprite _sprt;
}

class EnemyLaser extends Obstacle {
  EnemyLaser(GameObjectFactory f, double rotation, double speed, Color color) : super(f) {
    _sprt = new Sprite(f.sheet["explosion_particle.png"]);
    _sprt.scale = 0.5;
    _sprt.rotation = rotation + 90;
    _sprt.colorOverlay = color;
    addChild(_sprt);

    canDamageShip = true;
    canBeDamaged = false;

    double rad = radians(rotation);
    _movement = new Offset(math.cos(rad) * speed, math.sin(rad) * speed);

    print("LASER!!");
  }

  Sprite _sprt;
  Offset _movement;

  void move() {
    position += _movement;
  }
}

class Collectable extends GameObject {
  Collectable(GameObjectFactory f) : super(f) {
    canDamageShip = false;
    canBeDamaged = false;
    canBeCollected = true;

    zPosition = 20.0;
  }
}

class Coin extends Collectable {
  Coin(GameObjectFactory f) : super(f) {
    _sprt = new Sprite(f.sheet["coin.png"]);
    _sprt.scale = 0.7;
    addChild(_sprt);

    radius = 7.5;
  }

  void setupActions() {
    // Rotate
    ActionTween rotate = new ActionTween((a) => _sprt.rotation = a, 0.0, 360.0, 1.0);
    actions.run(new ActionRepeatForever(rotate));

    // Fade in
    ActionTween fadeIn = new ActionTween((a) => _sprt.opacity = a, 0.0, 1.0, 0.6);
    actions.run(fadeIn);
  }

  Sprite _sprt;

  void collect() {
    f.playerState.addCoin(this);
    super.collect();
  }
}

enum PowerUpType {
  shield,
  speedLaser,
  sideLaser,
}

List<PowerUpType> _powerUpTypes = new List.from(PowerUpType.values);
int _lastPowerUp = _powerUpTypes.length;

PowerUpType nextPowerUpType() {
  if (_lastPowerUp >= _powerUpTypes.length) {
     _powerUpTypes.shuffle();
     _lastPowerUp = 0;
  }

  PowerUpType type = _powerUpTypes[_lastPowerUp];
  _lastPowerUp++;

  return type;
}

class PowerUp extends Collectable {
  PowerUp(GameObjectFactory f, this.type) : super(f) {
    _sprt = new Sprite(f.sheet["coin.png"]);
    _sprt.scale = 1.2;
    addChild(_sprt);

    radius = 10.0;
  }

  Sprite _sprt;
  PowerUpType type;

  void setupActions() {
    ActionTween rotate = new ActionTween((a) => _sprt.rotation = a, 0.0, 360.0, 1.0);
    actions.run(new ActionRepeatForever(rotate));

    // Fade in
    ActionTween fadeIn = new ActionTween((a) => _sprt.opacity = a, 0.0, 1.0, 0.6);
    actions.run(fadeIn);
  }

  void collect() {
    f.playerState.activatePowerUp(type);
    super.collect();
  }
}
