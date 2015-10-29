// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of playfair;

class ChartData {
  const ChartData({
    this.startX,
    this.endX,
    this.startY,
    this.endY,
    this.dataSet,
    this.numHorizontalGridlines,
    this.roundToPlaces,
    this.indicatorLine,
    this.indicatorText
  });
  final double startX;
  final double endX;
  final double startY;
  final double endY;
  final int numHorizontalGridlines;
  final int roundToPlaces;
  final double indicatorLine;
  final String indicatorText;
  final List<Point> dataSet;
}

// TODO(jackson): Make these configurable
const double kGridStrokeWidth = 1.0;
const Color kGridColor = const Color(0xFFCCCCCC);
const Color kMarkerColor = const Color(0xFF000000);
const double kMarkerStrokeWidth = 2.0;
const double kMarkerRadius = 2.0;
const double kScaleMargin = 10.0;
const double kIndicatorStrokeWidth = 2.0;
const Color kIndicatorColor = const Color(0xFFFF4081);
const double kIndicatorMargin = 2.0;

class Chart extends StatelessComponent {
  Chart({ Key key, this.data }) : super(key: key);

  final ChartData data;

  Widget build(BuildContext context) {
    return new _ChartWrapper(textTheme: Theme.of(context).text, data: data);
  }
}

class _ChartWrapper extends LeafRenderObjectWidget {
  _ChartWrapper({ Key key, this.textTheme, this.data }) : super(key: key);

  final TextTheme textTheme;
  final ChartData data;

  RenderChart createRenderObject() => new RenderChart(textTheme: textTheme, data: data);

  void updateRenderObject(RenderChart renderObject, _ChartWrapper oldWidget) {
    renderObject.textTheme = textTheme;
    renderObject.data = data;
  }
}

class RenderChart extends RenderConstrainedBox {

  RenderChart({
    TextTheme textTheme,
    ChartData data
  }) : _painter = new ChartPainter(textTheme: textTheme, data: data),
       super(child: null, additionalConstraints: const BoxConstraints.expand());

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

class Gridline {
  double value;
  TextPainter labelPainter;
  Point labelPosition;
  Point start;
  Point end;
}

class Indicator {
  Point start;
  Point end;
  TextPainter labelPainter;
  Point labelPosition;
}

class ChartPainter {
  ChartPainter({ TextTheme textTheme, ChartData data }) : _data = data, _textTheme = textTheme;

  ChartData _data;
  ChartData get data => _data;
  void set data(ChartData value) {
    assert(data != null);
    if (_data == value)
      return;
    _data = value;
    _needsLayout = true;
  }

  TextTheme _textTheme;
  TextTheme get textTheme => _textTheme;
  void set textTheme(TextTheme value) {
    assert(value != null);
    if (_textTheme == value)
      return;
    _textTheme = value;
    _needsLayout = true;
  }

  static double _roundToPlaces(double value, int places) {
    int multiplier = math.pow(10, places);
    return (value * multiplier).roundToDouble() / multiplier;
  }

  // If this is set to true we will _layout() the next time we paint()
  bool _needsLayout = true;

  // The last rectangle that we were drawn into. If it changes we will _layout()
  Rect _rect;

  // These are updated by _layout()
  List<Gridline> _horizontalGridlines;
  List<Point> _markers;
  Indicator _indicator;

  void _layout() {
    // Create the scale labels
    double yScaleWidth = 0.0;
    _horizontalGridlines = new List<Gridline>();
    assert(data.numHorizontalGridlines > 1);
    double stepSize = (data.endY - data.startY) / (data.numHorizontalGridlines - 1);
    for(int i = 0; i < data.numHorizontalGridlines; i++) {
      Gridline gridline = new Gridline()
        ..value = _roundToPlaces(data.startY + stepSize * i, data.roundToPlaces);
      if (gridline.value < data.startY || gridline.value > data.endY)
        continue;  // TODO(jackson): Align things so this doesn't ever happen
      TextSpan text = new StyledTextSpan(
        _textTheme.body1,
        [new PlainTextSpan("${gridline.value}")]
      );
      gridline.labelPainter = new TextPainter(text)
        ..maxWidth = _rect.width
        ..layout();
      _horizontalGridlines.add(gridline);
      yScaleWidth = math.max(yScaleWidth, gridline.labelPainter.maxIntrinsicWidth);
    }

    yScaleWidth += kScaleMargin;

    // Leave room for the scale on the right side
    Rect markerRect = new Rect.fromLTWH(
      _rect.left,
      _rect.top,
      _rect.width - yScaleWidth,
      _rect.height
    );

    // Left align and vertically center the labels on the right side
    for(Gridline gridline in _horizontalGridlines) {
      gridline.start = _convertPointToRectSpace(new Point(data.startX, gridline.value), markerRect);
      gridline.end = _convertPointToRectSpace(new Point(data.endX, gridline.value), markerRect);
      gridline.labelPosition = new Point(
        gridline.end.x + kScaleMargin,
        gridline.end.y - gridline.labelPainter.size.height / 2.0
      );
    }

    // Place the markers
    List<Point> dataSet = data.dataSet;
    assert(dataSet != null);
    assert(dataSet.length > 0);
    _markers = new List<Point>();
    for(int i = 0; i < dataSet.length; i++)
      _markers.add(_convertPointToRectSpace(dataSet[i], markerRect));

    // Place the indicator line
    if (data.indicatorLine != null &&
        data.indicatorLine >= data.startY &&
        data.indicatorLine <= data.endY) {
      _indicator = new Indicator()
        ..start = _convertPointToRectSpace(new Point(data.startX, data.indicatorLine), markerRect)
        ..end = _convertPointToRectSpace(new Point(data.endX, data.indicatorLine), markerRect);
      if (data.indicatorText != null) {
        TextSpan text = new StyledTextSpan(
          _textTheme.body1,
          [new PlainTextSpan("${data.indicatorText}")]
        );
        _indicator.labelPainter = new TextPainter(text)
          ..maxWidth = markerRect.width
          ..layout();
        _indicator.labelPosition = new Point(
          ((_indicator.start.x + _indicator.end.x) / 2.0) - _indicator.labelPainter.maxIntrinsicWidth / 2.0,
          _indicator.start.y - _indicator.labelPainter.size.height - kIndicatorMargin
        );
      }
    } else {
      _indicator = null;
    }

    // we don't need to compute layout again unless something changes
    _needsLayout = false;
  }

  Point _convertPointToRectSpace(Point point, Rect rect) {
    double x = rect.left + ((point.x - data.startX) / (data.endX - data.startX)) * rect.width;
    double y = rect.bottom - ((point.y - data.startY) / (data.endY - data.startY)) * rect.height;
    return new Point(x, y);
  }

  void _paintGrid(ui.Canvas canvas) {
    Paint paint = new Paint()
      ..strokeWidth = kGridStrokeWidth
      ..color = kGridColor;
    for(Gridline gridline in _horizontalGridlines) {
      gridline.labelPainter.paint(canvas, gridline.labelPosition.toOffset());
      canvas.drawLine(gridline.start, gridline.end, paint);
    }
  }

  void _paintChart(ui.Canvas canvas) {
    Paint paint = new Paint()
      ..strokeWidth = kMarkerStrokeWidth
      ..color = kMarkerColor;
    Path path = new Path();
    path.moveTo(_markers[0].x, _markers[0].y);
    for (Point marker in _markers) {
      canvas.drawCircle(marker, kMarkerRadius, paint);
      path.lineTo(marker.x, marker.y);
    }
    paint.style = ui.PaintingStyle.stroke;
    canvas.drawPath(path, paint);
  }

  void _paintIndicator(ui.Canvas canvas) {
    if (_indicator == null)
      return;
    Paint paint = new Paint()
      ..strokeWidth = kIndicatorStrokeWidth
      ..color = kIndicatorColor;
    canvas.drawLine(_indicator.start, _indicator.end, paint);
    if (_indicator.labelPainter != null)
      _indicator.labelPainter.paint(canvas, _indicator.labelPosition.toOffset());
  }

  void paint(ui.Canvas canvas, Rect rect) {
    if (rect != _rect)
      _needsLayout = true;
    _rect = rect;
    if (_needsLayout)
      _layout();
    _paintGrid(canvas);
    _paintChart(canvas);
    _paintIndicator(canvas);
  }
}
