// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data' show Float64List;
import 'dart:ui';

import 'package:test/test.dart';

void main() {
  test('pushTransform validates the matrix', () {
    final SceneBuilder builder = SceneBuilder();
    final Float64List matrix4 = Float64List.fromList(<double>[
      1, 0, 0, 0,
      0, 1, 0, 0,
      0, 0, 1, 0,
      0, 0, 0, 1,
    ]);
    expect(builder.pushTransform(matrix4), isNotNull);

    final Float64List matrix4WrongLength = Float64List.fromList(<double>[
      1, 0, 0, 0,
      0, 1, 0,
      0, 0, 1, 0,
      0, 0, 0,
    ]);
    assert(() {
      expect(
        () => builder.pushTransform(matrix4WrongLength),
        throwsA(const TypeMatcher<AssertionError>()),
      );
      return true;
    }());

    final Float64List matrix4NaN = Float64List.fromList(<double>[
      1, 0, 0, 0,
      0, 1, 0, 0,
      0, 0, 1, 0,
      0, 0, 0, double.nan,
    ]);
    assert(() {
      expect(
        () => builder.pushTransform(matrix4NaN),
        throwsA(const TypeMatcher<AssertionError>()),
      );
      return true;
    }());

    final Float64List matrix4Infinity = Float64List.fromList(<double>[
      1, 0, 0, 0,
      0, 1, 0, 0,
      0, 0, 1, 0,
      0, 0, 0, double.infinity,
    ]);
    assert(() {
      expect(
        () => builder.pushTransform(matrix4Infinity),
        throwsA(const TypeMatcher<AssertionError>()),
      );
      return true;
    }());
  });

  test('SceneBuilder accepts typed layers', () {
    final SceneBuilder builder1 = SceneBuilder();
    final OpacityEngineLayer opacity1 = builder1.pushOpacity(100);
    expect(opacity1, isNotNull);
    builder1.pop();
    builder1.build();

    final SceneBuilder builder2 = SceneBuilder();
    final OpacityEngineLayer opacity2 = builder2.pushOpacity(200, oldLayer: opacity1);
    expect(opacity2, isNotNull);
    builder2.pop();
    builder2.build();
  });

  // Attempts to use the same layer first as `oldLayer` then in `addRetained`.
  void testPushThenIllegalRetain(_TestNoSharingFunction pushFunction) {
    final SceneBuilder builder1 = SceneBuilder();
    final EngineLayer layer = pushFunction(builder1, null);
    builder1.pop();
    builder1.build();

    final SceneBuilder builder2 = SceneBuilder();
    pushFunction(builder2, layer);
    builder2.pop();
    assert(() {
      try {
        builder2.addRetained(layer);
        fail('Expected addRetained to throw AssertionError but it returned successully');
      } on AssertionError catch (error) {
        expect(error.toString(), contains('The layer is already being used'));
      }
      return true;
    }());
    builder2.build();
  }

  // Attempts to use the same layer first in `addRetained` then as `oldLayer`.
  void testAddRetainedThenIllegalPush(_TestNoSharingFunction pushFunction) {
    final SceneBuilder builder1 = SceneBuilder();
    final EngineLayer layer = pushFunction(builder1, null);
    builder1.pop();
    builder1.build();

    final SceneBuilder builder2 = SceneBuilder();
    builder2.addRetained(layer);
    assert(() {
      try {
        pushFunction(builder2, layer);
        fail('Expected push to throw AssertionError but it returned successully');
      } on AssertionError catch (error) {
        expect(error.toString(), contains('The layer is already being used'));
      }
      return true;
    }());
    builder2.build();
  }

  // Attempts to retain the same layer twice in the same scene.
  void testDoubleAddRetained(_TestNoSharingFunction pushFunction) {
    final SceneBuilder builder1 = SceneBuilder();
    final EngineLayer layer = pushFunction(builder1, null);
    builder1.pop();
    builder1.build();

    final SceneBuilder builder2 = SceneBuilder();
    builder2.addRetained(layer);
    assert(() {
      try {
        builder2.addRetained(layer);
        fail('Expected second addRetained to throw AssertionError but it returned successully');
      } on AssertionError catch (error) {
        expect(error.toString(), contains('The layer is already being used'));
      }
      return true;
    }());
    builder2.build();
  }

  // Attempts to use the same layer as `oldLayer` twice in the same scene.
  void testPushOldLayerTwice(_TestNoSharingFunction pushFunction) {
    final SceneBuilder builder1 = SceneBuilder();
    final EngineLayer layer = pushFunction(builder1, null);
    builder1.pop();
    builder1.build();

    final SceneBuilder builder2 = SceneBuilder();
    pushFunction(builder2, layer);
    assert(() {
      try {
        pushFunction(builder2, layer);
        fail('Expected push to throw AssertionError but it returned successully');
      } on AssertionError catch (error) {
        expect(error.toString(), contains('was previously used as oldLayer'));
      }
      return true;
    }());
    builder2.build();
  }

  // Attempts to use a child of a retained layer as an `oldLayer`.
  void testPushChildLayerOfRetainedLayer(_TestNoSharingFunction pushFunction) {
    final SceneBuilder builder1 = SceneBuilder();
    final EngineLayer layer = pushFunction(builder1, null);
    final EngineLayer childLayer = builder1.pushOpacity(123);
    builder1.pop();
    builder1.pop();
    builder1.build();

    final SceneBuilder builder2 = SceneBuilder();
    builder2.addRetained(layer);
    assert(() {
      try {
        builder2.pushOpacity(321, oldLayer: childLayer);
        fail('Expected pushOpacity to throw AssertionError but it returned successully');
      } on AssertionError catch (error) {
        expect(error.toString(), contains('The layer is already being used'));
      }
      return true;
    }());
    builder2.build();
  }

  // Attempts to retain a layer whose child is already used as `oldLayer` elsewhere in the scene.
  void testRetainParentLayerOfPushedChild(_TestNoSharingFunction pushFunction) {
    final SceneBuilder builder1 = SceneBuilder();
    final EngineLayer layer = pushFunction(builder1, null);
    final EngineLayer childLayer = builder1.pushOpacity(123);
    builder1.pop();
    builder1.pop();
    builder1.build();

    final SceneBuilder builder2 = SceneBuilder();
    builder2.pushOpacity(234, oldLayer: childLayer);
    builder2.pop();
    assert(() {
      try {
        builder2.addRetained(layer);
        fail('Expected addRetained to throw AssertionError but it returned successully');
      } on AssertionError catch (error) {
        expect(error.toString(), contains('The layer is already being used'));
      }
      return true;
    }());
    builder2.build();
  }

  // Attempts to retain a layer that has been used as `oldLayer` in a previous frame.
  void testRetainOldLayer(_TestNoSharingFunction pushFunction) {
    final SceneBuilder builder1 = SceneBuilder();
    final EngineLayer layer = pushFunction(builder1, null);
    builder1.pop();
    builder1.build();

    final SceneBuilder builder2 = SceneBuilder();
    pushFunction(builder2, layer);
    builder2.pop();
    assert(() {
      try {
        final SceneBuilder builder3 = SceneBuilder();
        builder3.addRetained(layer);
        fail('Expected addRetained to throw AssertionError but it returned successully');
      } on AssertionError catch (error) {
        expect(error.toString(), contains('was previously used as oldLayer'));
      }
      return true;
    }());
    builder2.build();
  }

  // Attempts to pass layer as `oldLayer` that has been used as `oldLayer` in a previous frame.
  void testPushOldLayer(_TestNoSharingFunction pushFunction) {
    final SceneBuilder builder1 = SceneBuilder();
    final EngineLayer layer = pushFunction(builder1, null);
    builder1.pop();
    builder1.build();

    final SceneBuilder builder2 = SceneBuilder();
    pushFunction(builder2, layer);
    builder2.pop();
    assert(() {
      try {
        final SceneBuilder builder3 = SceneBuilder();
        pushFunction(builder3, layer);
        fail('Expected addRetained to throw AssertionError but it returned successully');
      } on AssertionError catch (error) {
        expect(error.toString(), contains('was previously used as oldLayer'));
      }
      return true;
    }());
    builder2.build();
  }

  // Attempts to retain a parent of a layer used as `oldLayer` in a previous frame.
  void testRetainsParentOfOldLayer(_TestNoSharingFunction pushFunction) {
    final SceneBuilder builder1 = SceneBuilder();
    final EngineLayer parentLayer = pushFunction(builder1, null);
    final OpacityEngineLayer childLayer = builder1.pushOpacity(123);
    builder1.pop();
    builder1.pop();
    builder1.build();

    final SceneBuilder builder2 = SceneBuilder();
    builder2.pushOpacity(321, oldLayer: childLayer);
    builder2.pop();
    assert(() {
      try {
        final SceneBuilder builder3 = SceneBuilder();
        builder3.addRetained(parentLayer);
        fail('Expected addRetained to throw AssertionError but it returned successully');
      } on AssertionError catch (error) {
        expect(error.toString(), contains('was previously used as oldLayer'));
      }
      return true;
    }());
    builder2.build();
  }

  void testNoSharing(_TestNoSharingFunction pushFunction) {
    testPushThenIllegalRetain(pushFunction);
    testAddRetainedThenIllegalPush(pushFunction);
    testDoubleAddRetained(pushFunction);
    testPushOldLayerTwice(pushFunction);
    testPushChildLayerOfRetainedLayer(pushFunction);
    testRetainParentLayerOfPushedChild(pushFunction);
    testRetainOldLayer(pushFunction);
    testPushOldLayer(pushFunction);
    testRetainsParentOfOldLayer(pushFunction);
  }

  test('SceneBuilder does not share a layer between addRetained and push*', () {
    testNoSharing((SceneBuilder builder, EngineLayer oldLayer) {
      return builder.pushOffset(0, 0, oldLayer: oldLayer);
    });
    testNoSharing((SceneBuilder builder, EngineLayer oldLayer) {
      return builder.pushTransform(Float64List(16), oldLayer: oldLayer);
    });
    testNoSharing((SceneBuilder builder, EngineLayer oldLayer) {
      return builder.pushClipRect(Rect.zero, oldLayer: oldLayer);
    });
    testNoSharing((SceneBuilder builder, EngineLayer oldLayer) {
      return builder.pushClipRRect(RRect.zero, oldLayer: oldLayer);
    });
    testNoSharing((SceneBuilder builder, EngineLayer oldLayer) {
      return builder.pushClipPath(Path(), oldLayer: oldLayer);
    });
    testNoSharing((SceneBuilder builder, EngineLayer oldLayer) {
      return builder.pushOpacity(100, oldLayer: oldLayer);
    });
    testNoSharing((SceneBuilder builder, EngineLayer oldLayer) {
      return builder.pushBackdropFilter(ImageFilter.blur(), oldLayer: oldLayer);
    });
    testNoSharing((SceneBuilder builder, EngineLayer oldLayer) {
      return builder.pushShaderMask(
        Gradient.radial(
          const Offset(0, 0),
          10,
          const <Color>[Color.fromARGB(0, 0, 0, 0), Color.fromARGB(0, 255, 255, 255)],
        ),
        Rect.zero,
        BlendMode.color,
        oldLayer: oldLayer,
      );
    });
    testNoSharing((SceneBuilder builder, EngineLayer oldLayer) {
      return builder.pushPhysicalShape(path: Path(), color: const Color.fromARGB(0, 0, 0, 0), oldLayer: oldLayer);
    });
    testNoSharing((SceneBuilder builder, EngineLayer oldLayer) {
      return builder.pushColorFilter(
        const ColorFilter.mode(
          Color.fromARGB(0, 0, 0, 0),
          BlendMode.color,
        ),
        oldLayer: oldLayer,
      );
    });
    testNoSharing((SceneBuilder builder, EngineLayer oldLayer) {
      return builder.pushColorFilter(
        const ColorFilter.matrix(<double>[
          1, 0, 0, 0, 0,
          0, 1, 0, 0, 0,
          0, 0, 1, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        oldLayer: oldLayer,
      );
    });
    testNoSharing((SceneBuilder builder, EngineLayer oldLayer) {
      return builder.pushColorFilter(
        const ColorFilter.linearToSrgbGamma(),
        oldLayer: oldLayer,
      );
    });
    testNoSharing((SceneBuilder builder, EngineLayer oldLayer) {
      return builder.pushColorFilter(
        const ColorFilter.srgbToLinearGamma(),
        oldLayer: oldLayer,
      );
    });
  });
}

typedef _TestNoSharingFunction = EngineLayer Function(SceneBuilder builder, EngineLayer oldLayer);
