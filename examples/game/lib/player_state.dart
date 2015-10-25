part of game;

class PlayerState extends Node {
  PlayerState(this._sheetUI, this._sheetGame) {
    // Score display
    _spriteBackgroundScore = new Sprite(_sheetUI["scoreboard.png"]);
    _spriteBackgroundScore.pivot = new Point(1.0, 0.0);
    _spriteBackgroundScore.scale = 0.35;
    _spriteBackgroundScore.position = new Point(240.0, 10.0);
    addChild(_spriteBackgroundScore);

    _scoreDisplay = new ScoreDisplay(_sheetUI);
    _scoreDisplay.position = new Point(-13.0, 49.0);
    _spriteBackgroundScore.addChild(_scoreDisplay);

    // Coin display
    _spriteBackgroundCoins = new Sprite(_sheetUI["coinboard.png"]);
    _spriteBackgroundCoins.pivot = new Point(1.0, 0.0);
    _spriteBackgroundCoins.scale = 0.35;
    _spriteBackgroundCoins.position = new Point(105.0, 10.0);
    addChild(_spriteBackgroundCoins);

    _coinDisplay = new ScoreDisplay(_sheetUI);
    _coinDisplay.position = new Point(-13.0, 49.0);
    _spriteBackgroundCoins.addChild(_coinDisplay);
  }

  final SpriteSheet _sheetUI;
  final SpriteSheet _sheetGame;

  int laserLevel = 0;

  static const double normalScrollSpeed = 2.0;

  double scrollSpeed = normalScrollSpeed;

  double _scrollSpeedTarget = normalScrollSpeed;

  EnemyBoss boss;

  Sprite _spriteBackgroundScore;
  ScoreDisplay _scoreDisplay;
  Sprite _spriteBackgroundCoins;
  ScoreDisplay _coinDisplay;

  int get score => _scoreDisplay.score;

  set score(int score) {
    _scoreDisplay.score = score;
    flashBackgroundSprite(_spriteBackgroundScore);
  }

  int get coins => _coinDisplay.score;

  void addCoin(Coin c) {
    // Animate coin to the top of the screen
    Point startPos = convertPointFromNode(Point.origin, c);
    Point finalPos = new Point(30.0, 30.0);
    Point middlePos = new Point((startPos.x + finalPos.x) / 2.0 + 50.0,
      (startPos.y + finalPos.y) / 2.0);

    List<Point> path = <Point>[startPos, middlePos, finalPos];

    Sprite sprite = new Sprite(_sheetGame["coin.png"]);
    sprite.scale = 0.7;

    ActionSpline spline = new ActionSpline((Point a) { sprite.position = a; }, path, 0.5);
    spline.tension = 0.25;
    ActionTween rotate = new ActionTween((double a) { sprite.rotation = a; }, 0.0, 360.0, 0.5);
    ActionTween scale = new ActionTween((double a) { sprite.scale = a; }, 0.7, 1.2, 0.5);
    ActionGroup group = new ActionGroup(<Action>[spline, rotate, scale]);
    sprite.actions.run(new ActionSequence(<Action>[
      group,
      new ActionRemoveNode(sprite),
      new ActionCallFunction(() {
        _coinDisplay.score += 1;
        flashBackgroundSprite(_spriteBackgroundCoins);
      })
    ]));

    addChild(sprite);
  }

  void activatePowerUp(PowerUpType type) {
    if (type == PowerUpType.shield) {
      _shieldFrames += 300;
    } else if (type == PowerUpType.sideLaser) {
      _sideLaserFrames += 300;
    } else if (type == PowerUpType.speedLaser) {
      _speedLaserFrames += 300;
    } else if (type == PowerUpType.speedBoost) {
      _speedBoostFrames += 150;
    }
  }

  int _shieldFrames = 0;
  bool get shieldActive => _shieldFrames > 0 || _speedBoostFrames > 0;
  bool get shieldDeactivating =>
    math.max(_shieldFrames, _speedBoostFrames) > 0 && math.max(_shieldFrames, _speedBoostFrames) < 60;

  int _sideLaserFrames = 0;
  bool get sideLaserActive => _sideLaserFrames > 0;

  int _speedLaserFrames = 0;
  bool get speedLaserActive => _speedLaserFrames > 0;

  int _speedBoostFrames = 0;
  bool get speedBoostActive => _speedBoostFrames > 0;

  void flashBackgroundSprite(Sprite sprite) {
    sprite.actions.stopAll();
    ActionTween flash = new ActionTween(
      (Color a) { sprite.colorOverlay = a; },
      new Color(0x66ccfff0),
      new Color(0x00ccfff0),
      0.3);
    sprite.actions.run(flash);
  }

  void update(double dt) {
    if (_shieldFrames > 0)
      _shieldFrames--;
    if (_sideLaserFrames > 0)
      _sideLaserFrames--;
    if (_speedLaserFrames > 0)
      _speedLaserFrames--;
    if (_speedBoostFrames > 0)
      _speedBoostFrames--;

    // Update speed
    if (boss != null) {
      Point globalBossPos = boss.convertPointToBoxSpace(Point.origin);
      if (globalBossPos.y > (_gameSizeHeight - 400.0))
        _scrollSpeedTarget = 0.0;
      else
        _scrollSpeedTarget = normalScrollSpeed;
    } else {
      if (speedBoostActive)
        _scrollSpeedTarget = normalScrollSpeed * 6.0;
      else
        _scrollSpeedTarget = normalScrollSpeed;
    }

    scrollSpeed = GameMath.filter(scrollSpeed, _scrollSpeedTarget, 0.1);
  }
}

class ScoreDisplay extends Node {
  ScoreDisplay(this._sheetUI);

  int _score = 0;

  int get score => _score;

  set score(int score) {
    _score = score;
    _dirtyScore = true;
  }

  SpriteSheet _sheetUI;

  bool _dirtyScore = true;

  void update(double dt) {
    if (_dirtyScore) {
      removeAllChildren();

      String scoreStr = _score.toString();
      double xPos = -37.0;
      for (int i = scoreStr.length - 1; i >= 0; i--) {
        String numStr = scoreStr.substring(i, i + 1);
        Sprite numSprite = new Sprite(_sheetUI["number_$numStr.png"]);
        numSprite.position = new Point(xPos, 0.0);
        addChild(numSprite);
        xPos -= 37.0;
      }
      _dirtyScore = false;
    }
  }
}
