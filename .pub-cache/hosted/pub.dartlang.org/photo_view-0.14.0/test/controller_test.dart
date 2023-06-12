import 'dart:ui';

import 'package:photo_view/src/controller/photo_view_controller.dart';
import 'package:test/test.dart';

void main() {
  late PhotoViewController controller;
  setUp(() {
    controller = PhotoViewController();
  });

  test('controller constructor', () {
    const double initialRotation = 0.0;
    const Offset initialPosition = Offset(40.0, 40.0);
    controller = PhotoViewController(
      initialRotation: initialRotation,
      initialPosition: initialPosition,
    );

    const PhotoViewControllerValue testValue = const PhotoViewControllerValue(
      position: initialPosition,
      scale: null,
      rotation: initialRotation,
      rotationFocusPoint: null,
    );

    expect(controller.value, testValue);
  });
  test('controller change values', () {
    controller.scale = 0.1;
    expect(controller.scale, 0.1);

    controller.position = Offset.zero;
    expect(controller.position, Offset.zero);

    controller.rotation = 0.1;
    expect(controller.rotation, 0.1);

    controller.rotationFocusPoint = Offset.zero;
    expect(controller.rotationFocusPoint, Offset.zero);

    controller.updateMultiple(position: const Offset(1, 1));
    expect(controller.scale, 0.1);
    expect(controller.position, const Offset(1, 1));
    expect(controller.rotation, 0.1);
    expect(controller.rotationFocusPoint, Offset.zero);

    controller.setScaleInvisibly(2.0);
    expect(controller.scale, 2.0);
  });
  test('controller reset', () {
    controller.updateMultiple(position: const Offset(1, 1), rotation: 40);
    controller.reset();
    expect(controller.position, Offset.zero);
    expect(controller.rotation, 0.0);
  });
  test('controller stream mutation', () {
    const PhotoViewControllerValue value1 = const PhotoViewControllerValue(
      position: Offset.zero,
      scale: null,
      rotation: 1.0,
      rotationFocusPoint: null,
    );

    const PhotoViewControllerValue value2 = const PhotoViewControllerValue(
      position: Offset.zero,
      scale: 3.0,
      rotation: 1.0,
      rotationFocusPoint: null,
    );

    const PhotoViewControllerValue value3 = const PhotoViewControllerValue(
      position: const Offset(1, 1),
      scale: 3.0,
      rotation: 45.0,
      rotationFocusPoint: null,
    );

    const PhotoViewControllerValue value4 = const PhotoViewControllerValue(
      position: const Offset(1, 1),
      scale: 5.0,
      rotation: 45.0,
      rotationFocusPoint: null,
    );

    expect(
      controller.outputStateStream,
      emitsInOrder([
        value1,
        value2,
        value3,
        value4,
      ]),
    );

    controller.rotation = 1.0;
    controller.scale = 3.0;

    controller.updateMultiple(position: const Offset(1, 1), rotation: 45.0);

    controller.setScaleInvisibly(5.0);
  });
}
