
import 'package:sky/framework/rendering/object.dart';
import 'package:sky/framework/rendering/box.dart';
import 'dart:sky' as sky;

typedef void Logger (String s);

class TestDisplayList extends RenderObjectDisplayList {
  TestDisplayList(double width, double height, this.logger, { this.indent: '' }) :
    this.width = width,
    this.height = height,
    super(width, height) {
    log("TestDisplayList() constructor: $width x $height");
  }

  final String indent;
  final double width;
  final double height;

  Logger logger;
  void log(String s) {
    logger("${indent} ${s}");
  }

  String explainPaint(sky.Paint paint) {
    return "Paint(${paint.color})";
  }

  void save() {
    log("save");
  }

  void saveLayer(sky.Rect bounds, sky.Paint paint) {
    log("saveLayer(${bounds.top}:${bounds.left}:${bounds.bottom}:${bounds.right}, ${explainPaint(paint)})");
  }

  void restore() {
    log("restore");
  }

  void translate(double dx, double dy) {
    log("translate($dx, $dy)");
  }

  void scale(double sx, double sy) {
    log("scale($sx, $sy)");
  }

  void rotate(double radians) {
    log("rotate($radians)");
  }

  void skew(double sx, double sy) {
    log("skew($sx, $sy)");
  }

  void concat(List<double> matrix9) {
    log("concat($matrix9)");
  }

  void clipRect(sky.Rect rect) {
    log("clipRect(${rect.top}:${rect.left}:${rect.bottom}:${rect.right})");
  }

  void drawPicture(sky.Picture picture) {
    log("drawPicture()");
  }

  void drawPaint(sky.Paint paint) {
    log("drawPaint(${explainPaint(paint)})");
  }

  void drawRect(sky.Rect rect, sky.Paint paint) {
    log("drawRect(${rect.top}:${rect.left}:${rect.bottom}:${rect.right}, ${explainPaint(paint)})");
  }

  void drawOval(sky.Rect rect, sky.Paint paint) {
    log("drawOval(${rect.top}:${rect.left}:${rect.bottom}:${rect.right}, ${explainPaint(paint)})");
  }

  void drawCircle(double x, double y, double radius, sky.Paint paint) {
    log("drawCircle($x, $y, $radius, ${explainPaint(paint)})");
  }

  void drawPath(sky.Path path, sky.Paint paint) {
    log("drawPath(Path, ${explainPaint(paint)})");
  }

  void paintChild(RenderObject child, sky.Point position) {
    log("paintChild at ${position.x},${position.y}");
    child.paint(new TestDisplayList(width, height, logger, indent: "$indent  |"));
  }
}

class TestView extends RenderView {

  TestView({
    RenderBox child,
    Duration timeForRotation
  }) : super(child: child, timeForRotation: timeForRotation) {
    print("TestView enabled");
  }

  int frame = 0;

  String lastPaint = '';
  void log(String s) {
    lastPaint += "\n$s";
  }

  void paintFrame() {
    RenderObject.debugDoingPaint = true;
    frame += 1;
    log("PAINT FOR FRAME #${frame} ----------------------------------------------");
    var canvas = new TestDisplayList(sky.view.width, sky.view.height, log, indent: "${frame} |");
    paint(canvas);
    log("------------------------------------------------------------------------");
    RenderObject.debugDoingPaint = false;
  }

}

class TestApp {

  TestApp(RenderBox root) {
    _renderView = new TestView(child: root);
    _renderView.attach();
    _renderView.rootConstraints = new ViewConstraints(width: sky.view.width, height: sky.view.height);
    _renderView.scheduleInitialLayout();
    RenderObject.flushLayout();
    _renderView.paintFrame();
    print(_renderView.lastPaint); // TODO(ianh): figure out how to make this fit the unit testing framework better
  }

  RenderView _renderView;

  RenderBox get root => _renderView.child;
  void set root(RenderBox value) {
    _renderView.child = value;
  }
  void _beginFrame(double timeStamp) {
    RenderObject.flushLayout();
    _renderView.paintFrame();
    print(_renderView.lastPaint); // TODO(ianh): figure out how to make this fit the unit testing framework better
  }

}
