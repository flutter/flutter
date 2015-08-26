part of game;

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
