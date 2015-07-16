import 'dart:math' as math;
import 'dart:sky' as sky;

import 'package:sky/rendering/box.dart';
import 'package:sky/rendering/flex.dart';
import 'package:sky/rendering/object.dart';

import '../resources/display_list.dart';

void main() {
  RenderBox size = new RenderConstrainedBox(additionalConstraints: new BoxConstraints().applyHeight(100.0));
  RenderBox inner = new RenderDecoratedBox(decoration: new BoxDecoration(backgroundColor: const sky.Color(0xFF00FF00)), child: size);
  RenderBox padding = new RenderPadding(padding: new EdgeDims.all(50.0), child: inner);
  RenderBox flex = new RenderFlex(children: [padding], direction: FlexDirection.vertical, alignItems: FlexAlignItems.stretch);
  RenderBox outer = new RenderDecoratedBox(decoration: new BoxDecoration(backgroundColor: const sky.Color(0xFF0000FF)), child: flex);
  new TestRenderView(outer).endTest();
}
