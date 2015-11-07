part of game;

class RepeatedImage extends Node {
  Sprite _sprite0;
  Sprite _sprite1;

  RepeatedImage(ui.Image image, [ui.TransferMode mode = null]) {
    _sprite0 = new Sprite.fromImage(image);
    _sprite0.size = new Size(1024.0, 1024.0);
    _sprite0.pivot = Point.origin;
    _sprite1 = new Sprite.fromImage(image);
    _sprite1.size = new Size(1024.0, 1024.0);
    _sprite1.pivot = Point.origin;
    _sprite1.position = new Point(0.0, -1024.0);

    if (mode != null) {
      _sprite0.transferMode = mode;
      _sprite1.transferMode = mode;
    }

    addChild(_sprite0);
    addChild(_sprite1);
  }

  void move(double dy) {
    double yPos = (position.y + dy) % 1024.0;
    position = new Point(0.0, yPos);
  }
}
