part of game;

class PowerBar extends NodeWithSize {
  PowerBar(Size size, [this.power = 1.0]) : super(size);

  double power;

  Paint _paintFill = new Paint()
    ..color = new Color(0xffffffff);
  Paint _paintOutline = new Paint()
    ..color = new Color(0xffffffff)
    ..strokeWidth = 1.0
    ..style = ui.PaintingStyle.stroke;

  void paint(PaintingCanvas canvas) {
    applyTransformForPivot(canvas);

    canvas.drawRect(new Rect.fromLTRB(0.0, 0.0, size.width - 0.0, size.height - 0.0), _paintOutline);
    canvas.drawRect(new Rect.fromLTRB(2.0, 2.0, (size.width - 2.0) * power, size.height - 2.0), _paintFill);
  }
}
