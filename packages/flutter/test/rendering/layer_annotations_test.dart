// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  test('ContainerLayer.findAll returns all results from its children', () {
    final Layer root = _Layers(
      ContainerLayer(),
      children: <Object>[
        _TestAnnotatedLayer(1, opaque: false),
        _TestAnnotatedLayer(2, opaque: false),
        _TestAnnotatedLayer(3, opaque: false),
      ]
    ).build();

    final List<int> result = root.findAll<int>(Offset.zero);
    expect(result, <int>[3, 2, 1]);
  });

  test('ContainerLayer.find returns the first result from its children', () {
    final Layer root = _Layers(
      ContainerLayer(),
      children: <Object>[
        _TestAnnotatedLayer(1, opaque: false),
        _TestAnnotatedLayer(2, opaque: false),
        _TestAnnotatedLayer(3, opaque: false),
      ]
    ).build();

    final int result = root.find<int>(Offset.zero);
    expect(result, 3);
  });

  test('ContainerLayer.findAll returns empty array when finding nothing', () {
    final Layer root = _Layers(
      ContainerLayer(),
      children: <Object>[
        _TestAnnotatedLayer(1, opaque: false),
        _TestAnnotatedLayer(2, opaque: false),
        _TestAnnotatedLayer(3, opaque: false),
      ]
    ).build();

    final List<double> result = root.findAll<double>(Offset.zero);
    expect(result, <int>[]);
  });

  test('ContainerLayer.find returns null when finding nothing', () {
    final Layer root = _Layers(
      ContainerLayer(),
      children: <Object>[
        _TestAnnotatedLayer(1, opaque: false),
        _TestAnnotatedLayer(2, opaque: false),
        _TestAnnotatedLayer(3, opaque: false),
      ]
    ).build();

    final double result = root.find<double>(Offset.zero);
    expect(result, isNull);
  });

  test('ContainerLayer.findAll stops at the first opaque child', () {
    final Layer root = _Layers(
      ContainerLayer(),
      children: <Object>[
        _TestAnnotatedLayer(1, opaque: false),
        _TestAnnotatedLayer(2, opaque: true),
        _TestAnnotatedLayer(3, opaque: false),
      ]
    ).build();

    final List<int> result = root.findAll<int>(Offset.zero);
    expect(result, <int>[3, 2]);
  });

  test('ContainerLayer.findAll returns children\'s opacity (true)', () {
    final Layer root = _appendAnnotationIfNotOpaque(1000,
      _Layers(
        ContainerLayer(),
        children: <Object>[
          _TestAnnotatedLayer(2, opaque: true),
        ]
      ).build(),
    );

    final List<int> result = root.findAll<int>(Offset.zero);
    expect(result, <int>[2]);
  });

  test('ContainerLayer.findAll returns children\'s opacity (false)', () {
    final Layer root = _appendAnnotationIfNotOpaque(1000,
      _Layers(
        ContainerLayer(),
        children: <Object>[
          _TestAnnotatedLayer(2, opaque: false),
        ],
      ).build(),
    );

    final List<int> result = root.findAll<int>(Offset.zero);
    expect(result, <int>[2, 1000]);
  });

  test('ContainerLayer.findAll returns false as opacity when finding nothing', () {
    final Layer root = _appendAnnotationIfNotOpaque(1000,
      _Layers(
        ContainerLayer(),
        children: <Object>[
          _TestAnnotatedLayer(2, opaque: false, size: Size.zero),
        ],
      ).build(),
    );

    final List<int> result = root.findAll<int>(Offset.zero);
    expect(result, <int>[1000]);
  });

  test('OffsetLayer.findAll respects offset', () {
    const Offset insidePosition = Offset(-5, 5);
    const Offset outsidePosition = Offset(5, 5);

    final Layer root = _appendAnnotationIfNotOpaque(1000,
      _Layers(
        OffsetLayer(offset: const Offset(-10, 0)),
        children: <Object>[
          _TestAnnotatedLayer(1, opaque: true, size: const Size(10, 10)),
        ]
      ).build(),
    );

    expect(root.findAll<int>(insidePosition), <int>[1]);
    expect(root.findAll<int>(outsidePosition), <int>[1000]);
  });

  test('ClipRectLayer.findAll respects clipRect', () {
    const Offset insidePosition = Offset(11, 11);
    const Offset outsidePosition = Offset(19, 19);

    final Layer root = _appendAnnotationIfNotOpaque(1000,
      _Layers(
        ClipRectLayer(clipRect: const Offset(10, 10) & const Size(5, 5)),
        children: <Object>[
          _TestAnnotatedLayer(
            1,
            opaque: true,
            size: const Size(10, 10),
            offset: const Offset(10, 10),
          ),
        ]
      ).build(),
    );

    expect(root.findAll<int>(insidePosition), <int>[1]);
    expect(root.findAll<int>(outsidePosition), <int>[1000]);
  });

  test('ClipRRectLayer.findAll respects clipRRect', () {
    // For a curve of radius 4 centered at (4, 4),
    // location (1, 1) is outside, while (2, 2) is inside.
    // Here we shift this RRect by (10, 10).
    final RRect rrect = RRect.fromRectAndRadius(
      const Offset(10, 10) & const Size(10, 10),
      const Radius.circular(4),
    );
    const Offset insidePosition = Offset(12, 12);
    const Offset outsidePosition = Offset(11, 11);

    final Layer root = _appendAnnotationIfNotOpaque(1000,
      _Layers(
        ClipRRectLayer(clipRRect: rrect),
        children: <Object>[
          _TestAnnotatedLayer(
            1,
            opaque: true,
            size: const Size(10, 10),
            offset: const Offset(10, 10),
          ),
        ]
      ).build(),
    );

    expect(root.findAll<int>(insidePosition), <int>[1]);
    expect(root.findAll<int>(outsidePosition), <int>[1000]);
  });

  test('ClipPathLayer.findAll respects clipPath', () {
    // For this triangle, location (1, 1) is inside, while (2, 2) is outside.
    //         2
    //    —————
    //    |  /
    //    | /
    // 2  |/
    final Path originalPath = Path();
    originalPath.lineTo(2, 0);
    originalPath.lineTo(0, 2);
    originalPath.close();
    // Shift this clip path by (10, 10).
    final Path path = originalPath.shift(const Offset(10, 10));
    const Offset insidePosition = Offset(11, 11);
    const Offset outsidePosition = Offset(12, 12);

    final Layer root = _appendAnnotationIfNotOpaque(1000,
      _Layers(
        ClipPathLayer(clipPath: path),
        children: <Object>[
          _TestAnnotatedLayer(
            1,
            opaque: true,
            size: const Size(10, 10),
            offset: const Offset(10, 10),
          ),
        ]
      ).build(),
    );

    expect(root.findAll<int>(insidePosition), <int>[1]);
    expect(root.findAll<int>(outsidePosition), <int>[1000]);
  });

  test('TransformLayer.findAll respects transform', () {
    // Matrix `transform` enlarges the target by 2x, then shift it by
    // (10, 10).
    final Matrix4 transform = Matrix4.diagonal3Values(2, 2, 1)
      ..setTranslation(Vector3(10, 10, 0));
    // The original region is Offset(10, 10) & Size(10, 10)
    // The transformed region is Offset(30, 30) & Size(20, 20)
    const Offset insidePosition = Offset(40, 40);
    const Offset outsidePosition = Offset(15, 15);

    final Layer root = _appendAnnotationIfNotOpaque(1000,
      _Layers(
        TransformLayer(transform: transform),
        children: <Object>[
          _TestAnnotatedLayer(
            1,
            opaque: true,
            size: const Size(10, 10),
            offset: const Offset(10, 10),
          ),
        ]
      ).build(),
    );

    expect(root.findAll<int>(insidePosition), <int>[1]);
    expect(root.findAll<int>(outsidePosition), <int>[1000]);
  });

  test('TransformLayer.findAll skips when transform is irreversible', () {
    final Matrix4 transform = Matrix4.diagonal3Values(1, 0, 1);

    final Layer root = _appendAnnotationIfNotOpaque(1000,
      _Layers(
        TransformLayer(transform: transform),
        children: <Object>[
          _TestAnnotatedLayer(1, opaque: true),
        ]
      ).build(),
    );

    expect(root.findAll<int>(Offset.zero), <int>[1000]);
  });

  test('PhysicalModelLayer.findAll respects clipPath', () {
    // For this triangle, location (1, 1) is inside, while (2, 2) is outside.
    //         2
    //    —————
    //    |  /
    //    | /
    // 2  |/
    final Path originalPath = Path();
    originalPath.lineTo(2, 0);
    originalPath.lineTo(0, 2);
    originalPath.close();
    // Shift this clip path by (10, 10).
    final Path path = originalPath.shift(const Offset(10, 10));
    const Offset insidePosition = Offset(11, 11);
    const Offset outsidePosition = Offset(12, 12);

    final Layer root = _appendAnnotationIfNotOpaque(1000,
      _Layers(
        PhysicalModelLayer(
          clipPath: path,
          elevation: 10,
          color: const Color.fromARGB(0, 0, 0, 0),
          shadowColor: const Color.fromARGB(0, 0, 0, 0),
        ),
        children: <Object>[
          _TestAnnotatedLayer(
            1,
            opaque: true,
            size: const Size(10, 10),
            offset: const Offset(10, 10),
          ),
        ]
      ).build(),
    );

    expect(root.findAll<int>(insidePosition), <int>[1]);
    expect(root.findAll<int>(outsidePosition), <int>[1000]);
  });


  test('LeaderLayer.findAll respects offset', () {
    const Offset insidePosition = Offset(-5, 5);
    const Offset outsidePosition = Offset(5, 5);

    final Layer root = _appendAnnotationIfNotOpaque(1000,
      _Layers(
        LeaderLayer(
          link: LayerLink(),
          offset: const Offset(-10, 0),
        ),
        children: <Object>[
          _TestAnnotatedLayer(1, opaque: true, size: const Size(10, 10)),
        ]
      ).build(),
    );

    expect(root.findAll<int>(insidePosition), <int>[1]);
    expect(root.findAll<int>(outsidePosition), <int>[1000]);
  });

  test('AnnotatedRegionLayer.findAll should append to the list '
    'and return the given opacity (false) during a successful hit', () {
    const Offset position = Offset(5, 5);

    final Layer root = _appendAnnotationIfNotOpaque(1000,
      _Layers(
        AnnotatedRegionLayer<int>(1, opaque: false),
        children: <Object>[
          _TestAnnotatedLayer(2, opaque: false),
        ]
      ).build(),
    );

    final List<int> result = root.findAll<int>(position);
    expect(result, <int>[2, 1, 1000]);
  });

  test('AnnotatedRegionLayer.findAll should append to the list '
    'and return the given opacity (true) during a successful hit', () {
    const Offset position = Offset(5, 5);

    final Layer root = _appendAnnotationIfNotOpaque(1000,
      _Layers(
        AnnotatedRegionLayer<int>(1, opaque: true),
        children: <Object>[
          _TestAnnotatedLayer(2, opaque: false),
        ]
      ).build(),
    );

    final List<int> result = root.findAll<int>(position);
    expect(result, <int>[2, 1]);
  });

  test('AnnotatedRegionLayer.findAll has default opacity as false', () {
    const Offset position = Offset(5, 5);

    final Layer root = _appendAnnotationIfNotOpaque(1000,
      _Layers(
        AnnotatedRegionLayer<int>(1),
        children: <Object>[
          _TestAnnotatedLayer(2, opaque: false),
        ]
      ).build(),
    );

    final List<int> result = root.findAll<int>(position);
    expect(result, <int>[2, 1, 1000]);
  });

  test('AnnotatedRegionLayer.findAll should still check children and return'
    'children\'s opacity (false) during a failed hit', () {
    const Offset position = Offset(5, 5);

    final Layer root = _appendAnnotationIfNotOpaque(1000,
      _Layers(
        AnnotatedRegionLayer<int>(1, opaque: true, size: Size.zero),
        children: <Object>[
          _TestAnnotatedLayer(2, opaque: false),
        ]
      ).build(),
    );

    final List<int> result = root.findAll<int>(position);
    expect(result, <int>[2, 1000]);
  });

  test('AnnotatedRegionLayer.findAll should still check children and return'
    'children\'s opacity (true) during a failed hit', () {
    const Offset position = Offset(5, 5);

    final Layer root = _appendAnnotationIfNotOpaque(1000,
      _Layers(
        AnnotatedRegionLayer<int>(1, opaque: false, size: Size.zero),
        children: <Object>[
          _TestAnnotatedLayer(2, opaque: true),
        ]
      ).build()
    );

    final List<int> result = root.findAll<int>(position);
    expect(result, <int>[2]);
  });

  test('AnnotatedRegionLayer.findAll should still check children and return'
    'children\'s opacity (false) during a failed hit', () {
    const Offset position = Offset(5, 5);

    final Layer root = _appendAnnotationIfNotOpaque(1000,
      _Layers(
        AnnotatedRegionLayer<int>(1, opaque: false, size: Size.zero),
        children: <Object>[
          _TestAnnotatedLayer(2, opaque: false),
        ]
      ).build()
    );

    final List<int> result = root.findAll<int>(position);
    expect(result, <int>[2, 1000]);
  });

  test('AnnotatedRegionLayer.findAll should clip its annotation '
    'using size and offset (positive)', () {
    // The target position would have fallen outside if not for the offset.
    const Offset position = Offset(100, 100);

    final Layer root = _appendAnnotationIfNotOpaque(1000,
      _Layers(
        AnnotatedRegionLayer<int>(
          1,
          size: const Size(20, 20),
          offset: const Offset(90, 90),
        ),
        children: <Object>[
          _TestAnnotatedLayer(
            2,
            opaque: false,
            // Use this offset to make sure AnnotatedRegionLayer's offset
            // does not affect its children.
            offset: const Offset(20, 20),
            size: const Size(110, 110),
          ),
        ]
      ).build()
    );

    final List<int> result = root.findAll<int>(position);
    expect(result, <int>[2, 1, 1000]);
  });

  test('AnnotatedRegionLayer.findAll should clip its annotation '
    'using size and offset (negative)', () {
    // The target position would have fallen inside if not for the offset.
    const Offset position = Offset(10, 10);

    final Layer root = _appendAnnotationIfNotOpaque(1000,
      _Layers(
        AnnotatedRegionLayer<int>(
          1,
          size: const Size(20, 20),
          offset: const Offset(90, 90),
        ),
        children: <Object>[
          _TestAnnotatedLayer(2, opaque: false, size: const Size(110, 110)),
        ]
      ).build()
    );

    final List<int> result = root.findAll<int>(position);
    expect(result, <int>[2, 1000]);
  });
}

/// Append `value` to the result of the annotations test of `layer` if and only
/// if it is opaque at the given location.
///
/// It is a utility function that helps checking the opacity returned by
/// [Layer.findAnnotations].
/// Technically it is a [ContainerLayer] that contains `layer` followed by
/// another layer annotated with `value`.
Layer _appendAnnotationIfNotOpaque(int value, Layer layer) {
  return _Layers(
    ContainerLayer(),
    children: <Object>[
      _TestAnnotatedLayer(value, opaque: false),
      layer,
    ],
  ).build();
}

// A utility class that helps building a layer tree.
class _Layers {
  _Layers(this.root, {this.children});

  final ContainerLayer root;
  // Each element must be instance of Layer or _Layers.
  final List<Object> children;
  bool _assigned = false;

  // Build the layer tree by calling each child's `build`, then append children
  // to [root]. Returns the root.
  Layer build() {
    assert(!_assigned);
    _assigned = true;
    if (children != null) {
      for (Object child in children) {
        Layer layer;
        if (child is Layer) {
          layer = child;
        } else if (child is _Layers) {
          layer = child.build();
        } else {
          assert(false, 'Element of _Layers.children must be instance of Layer or _Layers');
        }
        root.append(layer);
      }
    }
    return root;
  }
}

// This layer's [findAnnotation] can be controlled by the given arguments.
class _TestAnnotatedLayer extends Layer {
  _TestAnnotatedLayer(this.value, {
    @required this.opaque,
    this.offset = Offset.zero,
    this.size,
  });

  // The value added to result in [findAnnotations] during a successful hit.
  final int value;

  // The return value of [findAnnotations] during a successful hit.
  final bool opaque;

  /// The [offset] is optionally used to translate the clip region for the
  /// hit-testing of [find] by [offset].
  ///
  /// If not provided, offset defaults to [Offset.zero].
  ///
  /// Ignored if [size] is not set.
  final Offset offset;

  /// The [size] is optionally used to clip the hit-testing of [find].
  ///
  /// If not provided, all offsets are considered to be contained within this
  /// layer, unless an ancestor layer applies a clip.
  ///
  /// If [offset] is set, then the offset is applied to the size region before
  /// hit testing in [find].
  final Size size;

  @override
  EngineLayer addToScene(SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    return null;
  }

  // This implementation is hit when the type is `int` and position is within
  // [offset] & [size]. If it is hit, it adds [value] to result and returns
  // [opaque]; otherwise it directly returns false.
  @override
  bool findAnnotations<S>(
    List<AnnotationEntry<S>> result,
    Offset regionOffset, {
    bool onlyFirst,
  }) {
    if (S != int)
      return false;
    if (size != null && !(offset & size).contains(regionOffset))
      return false;
    final Object untypedValue = value;
    final S typedValue = untypedValue;
    result.add(AnnotationEntry<S>(annotation: typedValue, localPosition: Offset.zero));
    return opaque;
  }
}
