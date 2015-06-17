
import 'dart:async';
import 'dart:sky' as sky;
import "dart:sky.internals" as internals;

import 'package:sky/widgets/basic.dart';
import 'package:sky/rendering/box.dart';
import 'package:sky/rendering/object.dart';

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

  String explainPaint(Paint paint) {
    assert(paint.toString() == "Instance of 'Paint'"); // if this assertion fails, remove all calls to explainPaint with just inlining $paint
    return "Paint(${paint.color})";
  }

  void save() {
    log("save");
  }

  void saveLayer(Rect bounds, Paint paint) {
    log("saveLayer($bounds, ${explainPaint(paint)})");
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

  void clipRect(Rect rect) {
    log("clipRect($rect)");
  }

  void clipRRect(sky.RRect rrect) {
    log("clipRRect()");
  }

  void clipPath(Path path) {
    log("clipPath($path)");
  }

  void drawLine(double x0, double y0, double x1, double y1, Paint paint) {
    log("drawLine($x0, $y0, $x1, $y1, ${explainPaint(paint)})");
  }

  void drawPicture(sky.Picture picture) {
    log("drawPicture($picture)");
  }

  void drawPaint(Paint paint) {
    log("drawPaint(${explainPaint(paint)})");
  }

  void drawRect(Rect rect, Paint paint) {
    log("drawRect($rect, ${explainPaint(paint)})");
  }

  void drawRRect(sky.RRect rrect, Paint paint) {
    log("drawRRect($rrect, ${explainPaint(paint)})");
  }

  void drawOval(Rect rect, Paint paint) {
    log("drawOval($rect, ${explainPaint(paint)})");
  }

  void drawCircle(double x, double y, double radius, Paint paint) {
    log("drawCircle($x, $y, $radius, ${explainPaint(paint)})");
  }

  void drawPath(Path path, Paint paint) {
    log("drawPath($path, ${explainPaint(paint)})");
  }

  void drawImage(sky.Image image, double x, double y, Paint paint) {
    log("drawImage($image, $x, $y, ${explainPaint(paint)})");
  }

  void paintChild(RenderObject child, Point position) {
    log("paintChild ${child.runtimeType} at $position");
    child.paint(new TestDisplayList(width, height, logger, indent: "$indent  |"));
  }
}

class TestRenderView extends RenderView {

  TestRenderView([ RenderBox child = null ]) : super(child: child) {
    print("TestRenderView enabled");
    attach();
    rootConstraints = new ViewConstraints(width: 800.0, height: 600.0); // arbitrary figures
    scheduleInitialLayout();
    syncCheckFrame();
  }

  int frame = 0;

  String lastPaint = '';
  void log(String s) {
    lastPaint += "\n$s";
  }

  void paintFrame() {
    RenderObject.debugDoingPaint = true;
    frame += 1;
    lastPaint = '';
    log("PAINT FOR FRAME #${frame} ----------------------------------------------");
    var canvas = new TestDisplayList(rootConstraints.width, rootConstraints.height, log, indent: "${frame} |");
    paint(canvas);
    log("------------------------------------------------------------------------");
    RenderObject.debugDoingPaint = false;
  }

  // TEST API:

  void syncCheckFrame() {
    RenderObject.flushLayout();
    paintFrame();
    print(lastPaint); // TODO(ianh): figure out how to make this fit the unit testing framework better
  }

  Future checkFrame() {
    return new Future.microtask(syncCheckFrame);
  }

  void endTest() {
    internals.notifyTestComplete("PAINTED $frame FRAMES");
  }

}

class TestApp extends App {
  TestApp({ this.builder });

  Function builder;

  Widget build() {
    return builder();
  }
}

class WidgetTester {
  TestRenderView renderView = new TestRenderView();

  Future test(Function builder) {
    runApp(new TestApp(builder: builder), renderViewOverride: renderView);
    return renderView.checkFrame();
  }

  void endTest() {
    renderView.endTest();
  }
}
