
import 'dart:async';
import 'dart:sky' as sky;
import "dart:sky.internals" as internals;
import 'dart:typed_data';

import 'package:sky/widgets/basic.dart';
import 'package:sky/rendering/box.dart';
import 'package:sky/rendering/object.dart';

typedef void Logger (String s);

class TestRenderCanvas extends RenderCanvas {
  TestRenderCanvas(sky.PictureRecorder recorder, Size size, this.logger, { this.indent: '' })
    : size = size,
      super(recorder, size) {
    log("TestRenderCanvas() constructor: ${size.width} x ${size.height}");
  }

  final String indent;
  final Size size;

  Logger logger;
  void log(String s) {
    logger("${indent} ${s}");
  }

  void save() {
    log("save");
  }

  void saveLayer(Rect bounds, Paint paint) {
    log("saveLayer($bounds, $paint)");
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

  void concat(Float32List matrix4) {
    log("concat($matrix4)");
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

  void drawLine(Point p1, Point p2, Paint paint) {
    log("drawLine($p1, $p2, $paint)");
  }

  void drawPicture(sky.Picture picture) {
    log("drawPicture($picture)");
  }

  void drawPaint(Paint paint) {
    log("drawPaint($paint)");
  }

  void drawRect(Rect rect, Paint paint) {
    log("drawRect($rect, $paint)");
  }

  void drawRRect(sky.RRect rrect, Paint paint) {
    log("drawRRect($rrect, $paint)");
  }

  void drawOval(Rect rect, Paint paint) {
    log("drawOval($rect, $paint)");
  }

  void drawCircle(Point c, double radius, Paint paint) {
    log("drawCircle($c, $radius, $paint)");
  }

  void drawPath(Path path, Paint paint) {
    log("drawPath($path, $paint)");
  }

  void drawImage(sky.Image image, Point p, Paint paint) {
    log("drawImage($image, $p, $paint)");
  }

  void drawImageRect(sky.Image image, sky.Rect src, sky.Rect dst, Paint paint) {
    log("drawImageRect($image, $src, $dst, paint)");
  }

  void paintChild(RenderObject child, Point position) {
    log("paintChild ${child.runtimeType} at $position");
    child.paint(new TestRenderCanvas(new sky.PictureRecorder(), size, logger, indent: "$indent  |"), position.toOffset());
  }
}

class TestRenderView extends RenderView {

  TestRenderView([ RenderBox child = null ]) : super(child: child) {
    print("TestRenderView enabled");
    attach();
    rootConstraints = new ViewConstraints(size: new Size(800.0, 600.0)); // arbitrary figures
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
    var recorder = new sky.PictureRecorder();
    var canvas = new TestRenderCanvas(recorder, rootConstraints.size, log, indent: "${frame} |");
    paint(canvas, Offset.zero);
    recorder.endRecording();
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
