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
  final List<Point> dataSet;
}

class Chart extends LeafRenderObjectWrapper {
  Chart({ Key key, this.data }) : super(key: key);

  final ChartData data;

  RenderChart createNode() => new RenderChart(data: data);
  RenderChart get root => super.root;

  void syncRenderObject(Widget old) {
    super.syncRenderObject(old);
    renderObject.textTheme = Theme.of(this).text;
    renderObject.data = data;
  }
}

class RenderChart extends RenderConstrainedBox {

  RenderChart({
    ChartData data
  }) : _painter = new ChartPainter(data),
       super(child: null, additionalConstraints: BoxConstraints.expand);

  final ChartPainter _painter;

  ChartData get data => _painter.data;
  void set data(ChartData value) {
    assert(value != null);
    if (value == _painter.data)
      return;
    _painter.data = value;
    markNeedsPaint();
  }

  TextTheme get textTheme => _painter.textTheme;
  void set textTheme(TextTheme value) {
    assert(value != null);
    if (value == _painter.textTheme)
      return;
    _painter.textTheme = value;
    markNeedsPaint();
  }

  void paint(PaintingContext context, Offset offset) {
    assert(size.width != null);
    assert(size.height != null);
    _painter.paint(context.canvas, offset & size);
    super.paint(context, offset);
  }
}

class ChartPainter {
  ChartPainter(this.data);

  ChartData data;

  TextTheme _textTheme;
  TextTheme get textTheme => _textTheme;
  void set textTheme(TextTheme value) {
    assert(value != null);
    if (_textTheme == value)
      return;
    _textTheme = value;
    labels = [
      new ParagraphPainter(new StyledTextSpan(_textTheme.body1, [new PlainTextSpan("${data.startY}")])),
      new ParagraphPainter(new StyledTextSpan(_textTheme.body1, [new PlainTextSpan("${data.endY}")])),
    ];
  }

  List<ParagraphPainter> labels;

  Point _convertPointToRectSpace(Point point, Rect rect) {
    double x = rect.left + ((point.x - data.startX) / (data.endX - data.startX)) * rect.width;
    double y = rect.bottom - ((point.y - data.startY) / (data.endY - data.startY)) * rect.height;
    return new Point(x, y);
  }

  void _paintChart(sky.Canvas canvas, Rect rect) {
    Paint paint = new Paint()
      ..strokeWidth = 2.0
      ..color = const Color(0xFF000000);
    List<Point> dataSet = data.dataSet;
    assert(dataSet != null);
    assert(dataSet.length > 0);
    Path path = new Path();
    Point start = _convertPointToRectSpace(data.dataSet[0], rect);
    path.moveTo(start.x, start.y);
    for(Point point in data.dataSet) {
      Point current = _convertPointToRectSpace(point, rect);
      canvas.drawCircle(current, 3.0, paint);
      path.lineTo(current.x, current.y);
    }
    paint.setStyle(sky.PaintingStyle.stroke);
    canvas.drawPath(path, paint);
  }

  void _paintScale(sky.Canvas canvas, Rect rect) {
    // TODO(jackson): Generalize this to draw the whole axis
    for(ParagraphPainter painter in labels) {
      painter.maxWidth = rect.width;
      painter.layout();
    }
    labels[0].paint(canvas, rect.bottomLeft.toOffset());
    labels[1].paint(canvas, rect.topLeft.toOffset());
  }

  void paint(sky.Canvas canvas, Rect rect) {
    _paintChart(canvas, rect);
    _paintScale(canvas, rect);
  }
}
