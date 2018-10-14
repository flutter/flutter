import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PhysicalModel - creates a physical model layer when it needs compositing', (WidgetTester tester) async {
    debugDisableShadows = false;
    await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: PhysicalModel(
          shape: BoxShape.rectangle,
          color: Colors.grey,
          shadowColor: Colors.red,
          elevation: 1.0,
          child: Material(child: TextField(controller: TextEditingController())),
        ),
      ),
    );
    await tester.pump();

    final RenderPhysicalModel renderPhysicalModel = tester.allRenderObjects.firstWhere((RenderObject object) => object is RenderPhysicalModel);
    expect(renderPhysicalModel.needsCompositing, true);

    final PhysicalModelLayer physicalModelLayer = tester.layers.firstWhere((Layer layer) => layer is PhysicalModelLayer);
    expect(physicalModelLayer.shadowColor, Colors.red);
    expect(physicalModelLayer.color, Colors.grey);
    expect(physicalModelLayer.elevation, 1.0);
    debugDisableShadows = true;
  });
}
