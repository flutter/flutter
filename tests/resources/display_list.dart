
import 'dart:async';
import 'dart:sky' as sky;
import "dart:sky.internals" as internals;
import 'dart:typed_data';

import 'package:sky/widgets/basic.dart';
import 'package:sky/rendering/box.dart';
import 'package:sky/rendering/object.dart';

typedef void Logger (String s);

class TestRenderCanvas extends RenderCanvas {
  TestRenderCanvas(sky.PictureRecorder recorder, double width, double height, this.logger, { this.indent: '' })
    : width = width,
      height = height,
      super(recorder, width, height) {
    log("TestRenderCanvas() constructor: $width x $height");
  }

  final String indent;
  final double width;
  final double height;

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

  void drawLine(double x0, double y0, double x1, double y1, Paint paint) {
    log("drawLine($x0, $y0, $x1, $y1, $paint)");
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

  void drawCircle(double x, double y, double radius, Paint paint) {
    log("drawCircle($x, $y, $radius, $paint)");
  }

  void drawPath(Path path, Paint paint) {
    log("drawPath($path, $paint)");
  }

  void drawImage(sky.Image image, double x, double y, Paint paint) {
    log("drawImage($image, $x, $y, $paint)");
  }

  void drawImageRect(sky.Image image, sky.Rect src, sky.Rect dst, Paint paint) {
    log("drawImageRect($image, $src, $dst, paint)");
  }

  void paintChild(RenderObject child, Point position) {
    log("paintChild ${child.runtimeType} at $position");
    child.paint(new TestRenderCanvas(new sky.PictureRecorder(), width, height, logger, indent: "$indent  |"));
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
    var recorder = new sky.PictureRecorder();
    var canvas = new TestRenderCanvas(recorder, rootConstraints.width, rootConstraints.height, log, indent: "${frame} |");
    paint(canvas);
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
