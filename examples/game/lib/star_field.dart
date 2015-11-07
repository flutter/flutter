part of game;

class StarField extends NodeWithSize {
  ui.Image _image;
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
    ..filterQuality = ui.FilterQuality.low
    ..isAntiAlias = false
    ..transferMode = ui.TransferMode.plus;

  StarField(this._spriteSheet, this._numStars, [this._autoScroll = false]) : super(Size.zero) {
    _image = _spriteSheet.image;
  }

  void addStars() {
    _starPositions = <Point>[];
    _starScales = <double>[];
    _colors = <Color>[];
    _rects = <Rect>[];

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
    List<ui.RSTransform> transforms = <ui.RSTransform>[];
    for (int i = 0; i < _numStars; i++) {
      ui.RSTransform transform = new ui.RSTransform(
        _starScales[i],
        0.0,
        _starPositions[i].x - _padding,
        _starPositions[i].y - _padding);

      transforms.add(transform);
    }

    // Draw the stars
    canvas.drawAtlas(_image, transforms, _rects, _colors, ui.TransferMode.modulate, null, _paint);
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
