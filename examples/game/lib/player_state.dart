part of game;

class PlayerState extends Node {
  PlayerState(this._sheetUI, this._sheetGame) {
    // Score display
    _sprtBgScore = new Sprite(_sheetUI["scoreboard.png"]);
    _sprtBgScore.pivot = new Point(1.0, 0.0);
    _sprtBgScore.scale = 0.35;
    _sprtBgScore.position = new Point(240.0, 10.0);
    addChild(_sprtBgScore);

    _scoreDisplay = new ScoreDisplay(_sheetUI);
    _scoreDisplay.position = new Point(-13.0, 49.0);
    _sprtBgScore.addChild(_scoreDisplay);

    // Coin display
    _sprtBgCoins = new Sprite(_sheetUI["coinboard.png"]);
    _sprtBgCoins.pivot = new Point(1.0, 0.0);
    _sprtBgCoins.scale = 0.35;
    _sprtBgCoins.position = new Point(105.0, 10.0);
    addChild(_sprtBgCoins);

    _coinDisplay = new ScoreDisplay(_sheetUI);
    _coinDisplay.position = new Point(-13.0, 49.0);
    _sprtBgCoins.addChild(_coinDisplay);
  }

  final SpriteSheet _sheetUI;
  final SpriteSheet _sheetGame;

  Sprite _sprtBgScore;
  ScoreDisplay _scoreDisplay;
  Sprite _sprtBgCoins;
  ScoreDisplay _coinDisplay;

  int get score => _scoreDisplay.score;

  set score(int score) {
    _scoreDisplay.score = score;
    flashBgSprite(_sprtBgScore);
  }

  int get coins => _coinDisplay.score;

  void addCoin(Coin c) {
    // Animate coin to the top of the screen
    Point startPos = convertPointFromNode(Point.origin, c);
    Point finalPos = new Point(30.0, 30.0);
    Point middlePos = new Point((startPos.x + finalPos.x) / 2.0 + 50.0,
      (startPos.y + finalPos.y) / 2.0);

    List<Point> path = [startPos, middlePos, finalPos];

    Sprite sprt = new Sprite(_sheetGame["coin.png"]);
    sprt.scale = 0.7;

    ActionSpline spline = new ActionSpline((a) => sprt.position = a, path, 0.5);
    spline.tension = 0.25;
    ActionTween rotate = new ActionTween((a) => sprt.rotation = a, 0.0, 360.0, 0.5);
    ActionTween scale = new ActionTween((a) => sprt.scale = a, 0.7, 1.2, 0.5);
    ActionGroup group = new ActionGroup([spline, rotate, scale]);
    sprt.actions.run(new ActionSequence([
      group,
      new ActionRemoveNode(sprt),
      new ActionCallFunction(() {
        _coinDisplay.score += 1;
        flashBgSprite(_sprtBgCoins);
      })
    ]));

    addChild(sprt);
  }

  void activatePowerUp(PowerUpType type) {
    if (type == PowerUpType.shield) {
      _shieldFrames += 300;
    } else if (type == PowerUpType.sideLaser) {
      _sideLaserFrames += 300;
    } else if (type == PowerUpType.speedLaser) {
      _speedLaserFrames += 300;
    }
  }

  int _shieldFrames = 0;
  bool get shieldActive => _shieldFrames > 0;
  bool get shieldDeactivating => _shieldFrames > 0 && _shieldFrames < 60;

  int _sideLaserFrames = 0;
  bool get sideLaserActive => _sideLaserFrames > 0;

  int _speedLaserFrames = 0;
  bool get speedLaserActive => _speedLaserFrames > 0;

  void flashBgSprite(Sprite sprt) {
    sprt.actions.stopAll();
    ActionTween flash = new ActionTween(
      (a) => sprt.colorOverlay = a,
      new Color(0x66ccfff0),
      new Color(0x00ccfff0),
      0.3);
    sprt.actions.run(flash);
  }

  void update(double dt) {
    if (_shieldFrames > 0) _shieldFrames--;
    if (_sideLaserFrames > 0) _sideLaserFrames--;
    if (_speedLaserFrames > 0) _speedLaserFrames--;
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
        Sprite numSprt = new Sprite(_sheetUI["number_$numStr.png"]);
        numSprt.position = new Point(xPos, 0.0);
        addChild(numSprt);
        xPos -= 37.0;
      }
      _dirtyScore = false;
    }
  }
}
