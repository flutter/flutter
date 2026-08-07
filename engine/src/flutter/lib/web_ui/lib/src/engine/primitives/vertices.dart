// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:ui/ui.dart' as ui;

import '../backend/vertices.dart';
import '../native_memory.dart';
import '../renderer.dart';

/// The engine-side implementation of [ui.Vertices].
///
/// This class acts as a shared frontend for all backends, handling the conversion
/// from standard lists to typed arrays and managing the native memory lifecycle
/// of the [BackendVertices] delegate.
class EngineVertices implements ui.Vertices {
  /// Creates a new [EngineVertices] from generic lists.
  factory EngineVertices(
    ui.VertexMode mode,
    List<ui.Offset> positions, {
    List<ui.Offset>? textureCoordinates,
    List<ui.Color>? colors,
    List<int>? indices,
  }) {
    if (textureCoordinates != null && textureCoordinates.length != positions.length) {
      throw ArgumentError('"positions" and "textureCoordinates" lengths must match.');
    }
    if (colors != null && colors.length != positions.length) {
      throw ArgumentError('"positions" and "colors" lengths must match.');
    }
    if (indices != null && indices.any((int i) => i < 0 || i >= positions.length)) {
      throw ArgumentError('"indices" values must be valid indices in the positions list.');
    }

    final int len = positions.length;
    final flatPositions = Float32List(len * 2);
    for (var i = 0; i < len; i++) {
      flatPositions[2 * i] = positions[i].dx;
      flatPositions[2 * i + 1] = positions[i].dy;
    }

    Float32List? flatTextureCoordinates;
    if (textureCoordinates != null) {
      flatTextureCoordinates = Float32List(len * 2);
      for (var i = 0; i < len; i++) {
        flatTextureCoordinates[2 * i] = textureCoordinates[i].dx;
        flatTextureCoordinates[2 * i + 1] = textureCoordinates[i].dy;
      }
    }

    Int32List? flatColors;
    if (colors != null) {
      flatColors = Int32List(len);
      for (var i = 0; i < len; i++) {
        flatColors[i] = colors[i].value;
      }
    }

    final Uint16List? flatIndices = indices != null ? Uint16List.fromList(indices) : null;

    return EngineVertices.raw(
      mode,
      flatPositions,
      textureCoordinates: flatTextureCoordinates,
      colors: flatColors,
      indices: flatIndices,
    );
  }

  /// Creates a new [EngineVertices] from typed arrays.
  factory EngineVertices.raw(
    ui.VertexMode mode,
    Float32List positions, {
    Float32List? textureCoordinates,
    Int32List? colors,
    Uint16List? indices,
  }) {
    if (positions.length % 2 != 0) {
      throw ArgumentError('"positions" length must be even.');
    }
    if (textureCoordinates != null && textureCoordinates.length != positions.length) {
      throw ArgumentError('"positions" and "textureCoordinates" lengths must match.');
    }
    if (colors != null && colors.length * 2 != positions.length) {
      throw ArgumentError('"positions" and "colors" lengths must match.');
    }
    if (indices != null && indices.any((int i) => i < 0 || i >= positions.length ~/ 2)) {
      throw ArgumentError('"indices" values must be valid indices in the positions list.');
    }

    BackendVertices? delegate;
    if (positions.isNotEmpty) {
      delegate = renderer.createVertices(
        mode,
        positions,
        textureCoordinates: textureCoordinates,
        colors: colors,
        indices: indices,
      );
    }

    return EngineVertices._(delegate);
  }

  EngineVertices._(this._delegate) {
    if (_delegate != null) {
      _ref = UniqueRef<BackendVertices>(
        this,
        _delegate,
        'Vertices',
        onDispose: (BackendVertices v) => v.dispose(),
      );
    } else {
      _ref = null;
    }
  }

  /// The backend delegate that manages the native resources.
  ///
  /// This will be null if the `positions` list provided during construction was empty.
  BackendVertices? get delegate {
    assert(!_isDisposed, 'Attempted to use a disposed Vertices.');
    return _delegate;
  }

  final BackendVertices? _delegate;

  late final UniqueRef<BackendVertices>? _ref;
  bool _isDisposed = false;

  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }
    _ref?.dispose();
    _isDisposed = true;
  }

  @override
  bool get debugDisposed => _isDisposed;
}
