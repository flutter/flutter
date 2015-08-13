
import 'dart:async';
import 'dart:sky' as sky;
import 'dart:typed_data';

import 'package:sky/widgets/basic.dart';
import 'package:sky/rendering/box.dart';
import 'package:sky/rendering/object.dart';

import 'harness.dart';

typedef void Logger (String s);

class TestPaintingCanvas extends PaintingCanvas {
  TestPaintingCanvas(sky.PictureRecorder recorder, Size size, this.logger, { this.indent: '' })
    : size = size,
      super(recorder, Point.origin & size) {
    log("TestPaintingCanvas() constructor: ${size.width} x ${size.height}");
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

  void drawDRRect(sky.RRect outer, sky.RRect inner, Paint paint) {
    log("drawDRRect($outer, $inner, $paint)");
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
}

class TestPaintingContext extends PaintingContext {
  TestPaintingContext(TestPaintingCanvas canvas) : super.forTesting(canvas);

  TestPaintingCanvas get canvas => super.canvas;

  void paintChild(RenderObject child, Point position) {
    canvas.log("paintChild ${child.runtimeType} at $position");
    TestPaintingCanvas childCanvas = new TestPaintingCanvas(new sky.PictureRecorder(), canvas.size, canvas.logger, indent: "${canvas.indent}  |");
    child.paint(new TestPaintingContext(childCanvas), position.toOffset());
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
    sky.PictureRecorder recorder = new sky.PictureRecorder();
    TestPaintingCanvas canvas = new TestPaintingCanvas(recorder, rootConstraints.size, log, indent: "${frame} |");
    TestPaintingContext context = new TestPaintingContext(canvas);

    paint(context, Offset.zero);
    recorder.endRecording();
    log("------------------------------------------------------------------------");
    RenderObject.debugDoingPaint = false;
  }

  void compositeFrame() {
  }

  // TEST API:

  void syncCheckFrame() {
    Component.flushBuild();
    RenderObject.flushLayout();
    paintFrame();
    print(lastPaint); // TODO(ianh): figure out how to make this fit the unit testing framework better
  }

  Future checkFrame() {
    return new Future.microtask(syncCheckFrame);
  }

  void endTest() {
    notifyTestComplete("PAINTED $frame FRAMES");
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

  Future test(Function builder, { int frameCount: 1 }) async {
    runApp(new TestApp(builder: builder), renderViewOverride: renderView);
    while (--frameCount != 0)
      await renderView.checkFrame();
    return await renderView.checkFrame();
  }

  void endTest() {
    renderView.endTest();
  }
}
