// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of playfair;

class ChartData {
  const ChartData({ this.startX, this.endX, this.startY, this.endY, this.dataSet });
  final double startX;
  final double endX;
  final double startY;
  final double endY;
  final List<sky.Point> dataSet;
}

class Chart extends LeafRenderObjectWrapper {
  Chart({ Key key, this.data }) : super(key: key);

  final ChartData data;

  RenderChart createNode() => new RenderChart(data: data);
  RenderChart get root => super.root;

  void syncRenderObject(Widget old) {
    super.syncRenderObject(old);
    root.data = data;
  }
}

class RenderChart extends RenderConstrainedBox {

  RenderChart({
    ChartData data
  }) : _painter = new ChartPainter(data),
       super(child: null, additionalConstraints: BoxConstraints.expand);

  final ChartPainter _painter;

  ChartData get data => _painter.data;
  void set data (ChartData value) {
    assert(value != null);
    if (value == _painter.data)
      return;
    _painter.data = value;
    markNeedsPaint();
  }

  void paint(PaintingCanvas canvas, Offset offset) {
    assert(size.width != null);
    assert(size.height != null);
    _painter.paint(canvas, offset & size);
    super.paint(canvas, offset);
  }
}

class ChartPainter {
  ChartPainter(this.data);

  ChartData data;

  Point _convertPointToRectSpace(sky.Point point, Rect rect) {
    double x = rect.left + ((point.x - data.startX) / (data.endX - data.startX)) * rect.width;
    double y = rect.bottom - ((point.y - data.startY) / (data.endY - data.startY)) * rect.height;
    return new Point(x, y);
  }

  void _paintChart(sky.Canvas canvas, Rect rect) {
    Paint paint = new Paint()
      ..strokeWidth = 2.0
      ..color = const Color(0xFF000000);
    List<sky.Point> dataSet = data.dataSet;
    assert(dataSet != null);
    assert(dataSet.length > 0);
    Path path = new Path();
    Point start = _convertPointToRectSpace(data.dataSet[0], rect);
    path.moveTo(start.x, start.y);
    for(sky.Point point in data.dataSet) {
      Point current = _convertPointToRectSpace(point, rect);
      canvas.drawCircle(current, 3.0, paint);
      path.lineTo(current.x, current.y);
    }
    paint.setStyle(sky.PaintingStyle.stroke);
    canvas.drawPath(path, paint);
  }

  void _paintScale(sky.Canvas canvas, Rect rect) {
    Paint paint = new Paint()..color = const Color(0xFF000000);
    canvas.drawText("${data.startY}", rect.bottomRight, paint);
    canvas.drawText("${data.endY}", rect.topRight, paint);
  }

  void paint(sky.Canvas canvas, Rect rect) {
    _paintChart(canvas, rect);
    _paintScale(canvas, rect);
  }
}
