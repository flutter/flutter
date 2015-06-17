import 'dart:math' as math;
import 'dart:sky' as sky;

import 'package:sky/app/view.dart';
import 'package:sky/rendering/block.dart';
import 'package:sky/rendering/box.dart';
import 'package:sky/rendering/object.dart';

import '../resources/display_list.dart';

void main() {
  var size = new RenderConstrainedBox(additionalConstraints: new BoxConstraints().applyHeight(100.0));
  var inner = new RenderDecoratedBox(decoration: new BoxDecoration(backgroundColor: const sky.Color(0xFF00FF00)), child: size);
  var padding = new RenderPadding(padding: new EdgeDims.all(50.0), child: inner);
  var block = new RenderBlock(children: [padding]);
  var outer = new RenderDecoratedBox(decoration: new BoxDecoration(backgroundColor: const sky.Color(0xFF0000FF)), child: block);
  new TestRenderView(outer).endTest();
}
