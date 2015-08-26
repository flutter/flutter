part of game;

class PlayerState extends Node {
  PlayerState(this._sheetUI, this._sheetGame) {
    // Score display
    Sprite sprtBgScore = new Sprite(_sheetUI["scoreboard.png"]);
    sprtBgScore.pivot = new Point(1.0, 0.0);
    sprtBgScore.scale = 0.35;
    sprtBgScore.position = new Point(310.0, 10.0);
    addChild(sprtBgScore);

    _scoreDisplay = new ScoreDisplay(_sheetUI);
    _scoreDisplay.position = new Point(-13.0, 49.0);
    sprtBgScore.addChild(_scoreDisplay);

    // Coin display
    Sprite sprtBgCoins = new Sprite(_sheetUI["scoreboard.png"]);
    sprtBgCoins.pivot = new Point(1.0, 0.0);
    sprtBgCoins.scale = 0.35;
    sprtBgCoins.position = new Point(170.0, 10.0);
    addChild(sprtBgCoins);

    _coinDisplay = new ScoreDisplay(_sheetUI);
    _coinDisplay.position = new Point(-13.0, 49.0);
    sprtBgCoins.addChild(_coinDisplay);
  }

  final SpriteSheet _sheetUI;
  final SpriteSheet _sheetGame;

  ScoreDisplay _scoreDisplay;
  ScoreDisplay _coinDisplay;

  int get score => _scoreDisplay.score;

  set score(int score) {
    _scoreDisplay.score = score;
  }

  int get coins => _coinDisplay.score;

  void addCoin(Coin c) {
    // Animate coin to the top of the screen
    Point startPos = convertPointFromNode(Point.origin, c);
    Point finalPos = new Point(10.0, 10.0);
    Point middlePos = new Point((startPos.x + finalPos.x) / 2.0 + 50.0,
      (startPos.y + finalPos.y) / 2.0);

    List<Point> path = [startPos, middlePos, finalPos];

    Sprite sprt = new Sprite(_sheetGame["shield.png"]);
    sprt.size = new Size(15.0, 15.0);
    sprt.transferMode = sky.TransferMode.plus;
    sprt.colorOverlay = new Color(0xffffff00);
    ActionSpline spline = new ActionSpline((a) => sprt.position = a, path, 0.5);
    spline.tension = 0.25;
    sprt.actions.run(new ActionSequence([
      spline,
      new ActionRemoveNode(sprt),
      new ActionCallFunction(() { _coinDisplay.score += 1; })
    ]));

    addChild(sprt);
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
