// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

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

  test('OffsetLayer.findAll respects offset (positive)', () {
    // The target position would have fallen outside of child if not for the
    // offset.
    const Offset position = Offset(-5, 5);

    final Layer root = _appendAnnotationIfNotOpaque(1000,
      _Layers(
        OffsetLayer(offset: const Offset(-10, 0)),
        children: <Object>[
          _TestAnnotatedLayer(1, opaque: true, size: const Size(10, 10)),
        ]
      ).build(),
    );

    final List<int> result = root.findAll<int>(position);
    expect(result, <int>[1]);
  });

  test('OffsetLayer.findAll respects offset (negative)', () {
    // The target position would have fallen inside of child if not for the
    // offset.
    const Offset position = Offset(5, 5);

    final Layer root = _appendAnnotationIfNotOpaque(1000,
      _Layers(
        OffsetLayer(offset: const Offset(-10, 0)),
        children: <Object>[
          _TestAnnotatedLayer(1, opaque: true, size: const Size(10, 10)),
        ]
      ).build(),
    );

    final List<int> result = root.findAll<int>(position);
    expect(result, <int>[1000]);
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
          _TestAnnotatedLayer(2, opaque: false, size: const Size(110, 110)),
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

/// Append `value` to the result of [Layer.findAll] of `layer` if and only if
/// it returns true.
///
/// It is a utility function that helps checking the opacity returned by [layer].
/// Technically it is a [ContainerLayer] that contains `layer` followed by another
/// layer annotated with `value`.
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
  bool findAnnotations<S>(List<S> result, Offset regionOffset, {bool onlyFirst}) {
    if (S != int)
      return false;
    if (size != null && !(offset & size).contains(regionOffset))
      return false;
    final Object untypedValue = value;
    final S typedValue = untypedValue;
    result.add(typedValue);
    return opaque;
  }
}
