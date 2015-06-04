import '../resources/third_party/unittest/unittest.dart';
import '../resources/unit.dart';
import '../resources/display_list.dart';
import 'dart:math' as math;
import 'dart:sky' as sky;
import 'package:sky/framework/app.dart';
import 'package:sky/framework/rendering/box.dart';
import 'package:sky/framework/rendering/block.dart';
import 'package:sky/framework/rendering/object.dart';

TestApp app;

void main() {
  initUnit();

  test("padding", () {
    var size = new RenderSizedBox(desiredSize: new sky.Size(double.INFINITY, 100.0));
    var inner = new RenderDecoratedBox(decoration: new BoxDecoration(backgroundColor: const sky.Color(0xFF00FF00)), child: size);
    var padding = new RenderPadding(padding: new EdgeDims.all(50.0), child: inner);
    var block = new RenderBlock(children: [padding]);
    var outer = new RenderDecoratedBox(decoration: new BoxDecoration(backgroundColor: const sky.Color(0xFF0000FF)), child: block);
    app = new TestApp(outer);
  });
}
