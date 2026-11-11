// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';

import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui.dart' as ui;

/// The Skwasm implementation of [BackendPaint].
///
/// Owns a C++ paint object built from an [EnginePaint] for a single draw call.
/// The C++ object must be explicitly freed by calling [dispose].
class SkwasmPaint implements BackendPaint {
  SkwasmPaint(EnginePaint paint, {required ui.TileMode defaultBlurTileMode})
    : handle = paintCreate(
        paint.isAntiAlias,
        paint.blendMode.index,
        paint.colorValue,
        paint.style.index,
        paint.strokeWidth,
        paint.strokeCap.index,
        paint.strokeJoin.index,
        paint.strokeMiterLimit,
        paint.invertColors,
      ) {
    final EngineColorFilter? colorFilter = paint.colorFilter;
    if (colorFilter != null) {
      final backendFilter = colorFilter.backendFilter as SkwasmColorFilter;
      paintSetColorFilter(handle, backendFilter.handle);
    }

    final ShaderHandle? shaderHandle =
        (paint.shader?.getBackendShader(paint.filterQuality) as SkwasmShader?)?.handle;
    if (shaderHandle != null) {
      paintSetShader(handle, shaderHandle);
    }

    final EngineMaskFilter? maskFilter = paint.effectiveMaskFilter;
    if (maskFilter != null) {
      final backendFilter = maskFilter.backendFilter as SkwasmMaskFilter;
      paintSetMaskFilter(handle, backendFilter.handle);
    }

    final EngineImageFilter? imageFilter = paint.effectiveImageFilter;
    if (imageFilter != null) {
      final backendFilter = imageFilter.getBackendFilter(
        defaultBlurTileMode: defaultBlurTileMode,
      ) as SkwasmImageFilter;
      final ImageFilterHandle nativeHandle = backendFilter.nativeFilter;
      if (nativeHandle != nullptr) {
        paintSetImageFilter(handle, nativeHandle);
      }
    }
  }

  /// The native C++ paint object.
  final PaintHandle handle;

  bool _isDisposed = false;

  @override
  void dispose() {
    if (!_isDisposed) {
      _isDisposed = true;
      paintDispose(handle);
    }
  }
}
