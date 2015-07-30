import 'dart:math' as math;
import 'dart:sky' as sky;

import 'package:sky/rendering/box.dart';
import 'package:sky/rendering/stack.dart';
import 'package:sky/rendering/object.dart';

import '../resources/display_list.dart';

void main() {
  RenderBox size = new RenderConstrainedBox(
    additionalConstraints: new BoxConstraints.tight(const Size(100.0, 100.0)));

  RenderBox red = new RenderDecoratedBox(
    decoration: new BoxDecoration(
      backgroundColor: const sky.Color(0xFFFF0000)
    ),
    child: size);

  RenderBox green = new RenderDecoratedBox(
    decoration: new BoxDecoration(
      backgroundColor: const sky.Color(0xFFFF0000)
    ));

  RenderBox stack = new RenderStack(children: [red, green]);
  (green.parentData as StackParentData)
    ..left = 0.0
    ..right = 0.0
    ..bottom = 0.0
    ..top = 0.0;

  RenderBox center = new RenderPositionedBox(child: stack);
  new TestRenderView(center).endTest();
}
