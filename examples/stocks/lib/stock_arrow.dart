// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of stocks;

class StockArrowPainter extends CustomPainter {
  StockArrowPainter({ this.color, this.percentChange });

  final Color color;
  final double percentChange;

  void paint(Canvas canvas, Size size) {
    Paint paint = new Paint()..color = color;
    paint.strokeWidth = 1.0;
    const double padding = 2.0;
    assert(padding > paint.strokeWidth / 2.0); // make sure the circle remains inside the box
    double r = (size.shortestSide - padding) / 2.0; // radius of the circle
    double centerX = padding + r;
    double centerY = padding + r;

    // Draw the arrow.
    double w = 8.0;
    double h = 5.0;
    double arrowY;
    if (percentChange < 0.0) {
      h = -h;
      arrowY = centerX + 1.0;
    } else {
      arrowY = centerX - 1.0;
    }
    Path path = new Path();
    path.moveTo(centerX, arrowY - h); // top of the arrow
    path.lineTo(centerX + w, arrowY + h);
    path.lineTo(centerX - w, arrowY + h);
    path.close();
    paint.style = ui.PaintingStyle.fill;
    canvas.drawPath(path, paint);

    // Draw a circle that circumscribes the arrow.
    paint.style = ui.PaintingStyle.stroke;
    canvas.drawCircle(new Point(centerX, centerY), r, paint);
  }

  bool shouldRepaint(StockArrowPainter oldPainter) {
    return oldPainter.color != color
        || oldPainter.percentChange != percentChange;
  }
}

class StockArrow extends StatelessComponent {
  StockArrow({ Key key, this.percentChange }) : super(key: key);

  final double percentChange;

  int _colorIndexForPercentChange(double percentChange) {
    double maxPercent = 10.0;
    double normalizedPercentChange = math.min(percentChange.abs(), maxPercent) / maxPercent;
    return 100 + (normalizedPercentChange * 8.0).floor() * 100;
  }

  Color _colorForPercentChange(double percentChange) {
    if (percentChange > 0)
      return Colors.green[_colorIndexForPercentChange(percentChange)];
    return Colors.red[_colorIndexForPercentChange(percentChange)];
  }

  Widget build(BuildContext context) {
    return new Container(
      width: 40.0,
      height: 40.0,
      margin: const EdgeDims.symmetric(horizontal: 5.0),
      child: new CustomPaint(
        painter: new StockArrowPainter(
          // TODO(jackson): This should change colors with the theme
          color: _colorForPercentChange(percentChange),
          percentChange: percentChange
        )
      )
    );
  }
}
