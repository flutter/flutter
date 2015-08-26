part of game;

class PlayerState extends Node {
  SpriteSheet sheet;
  Sprite sprtBgScore;

  bool _dirtyScore = true;
  int _score = 0;

  int get score => _score;

  set score(int score) {
    _score = score;
    _dirtyScore = true;
  }

  PlayerState(this.sheet) {
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
