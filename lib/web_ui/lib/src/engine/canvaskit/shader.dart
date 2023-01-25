// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ui/ui.dart' as ui;

import '../util.dart';
import '../validators.dart';
import 'canvaskit_api.dart';
import 'image.dart';
import 'skia_object_cache.dart';

abstract class CkShader extends ManagedSkiaObject<SkShader>
    implements ui.Shader {
  SkShader withQuality(ui.FilterQuality contextualQuality) => skiaObject;

  @override
  void delete() {
    rawSkiaObject?.delete();
  }

  bool _disposed = false;

  @override
  bool get debugDisposed {
    late bool disposed;
    assert(() {
      disposed = _disposed;
      return true;
    }());
    return disposed;
  }

  @override
  void dispose() {
    assert(() {
      _disposed = true;
      return true;
    }());
  }
}

class CkGradientSweep extends CkShader implements ui.Gradient {
  CkGradientSweep(this.center, this.colors, this.colorStops, this.tileMode,
      this.startAngle, this.endAngle, this.matrix4)
      : assert(offsetIsValid(center)),
        assert(startAngle < endAngle),
        assert(matrix4 == null || matrix4IsValid(matrix4)) {
    validateColorStops(colors, colorStops);
  }

  final ui.Offset center;
  final List<ui.Color> colors;
  final List<double>? colorStops;
  final ui.TileMode tileMode;
  final double startAngle;
  final double endAngle;
  final Float32List? matrix4;

  @override
  SkShader createDefault() {
    const double toDegrees = 180.0 / math.pi;
    return canvasKit.Shader.MakeSweepGradient(
      center.dx,
      center.dy,
      toFlatColors(colors),
      toSkColorStops(colorStops),
      toSkTileMode(tileMode),
      matrix4 != null ? toSkMatrixFromFloat32(matrix4!) : null,
      0,
      toDegrees * startAngle,
      toDegrees * endAngle,
    );
  }

  @override
  SkShader resurrect() {
    return createDefault();
  }
}

class CkGradientLinear extends CkShader implements ui.Gradient {
  CkGradientLinear(
    this.from,
    this.to,
    this.colors,
    this.colorStops,
    this.tileMode,
    Float32List? matrix,
  )   : assert(offsetIsValid(from)),
        assert(offsetIsValid(to)),
        matrix4 = matrix {
    if (assertionsEnabled) {
      assert(matrix4 == null || matrix4IsValid(matrix4!));
      validateColorStops(colors, colorStops);
    }
  }

  final ui.Offset from;
  final ui.Offset to;
  final List<ui.Color> colors;
  final List<double>? colorStops;
  final ui.TileMode tileMode;
  final Float32List? matrix4;

  @override
  SkShader createDefault() {
    return canvasKit.Shader.MakeLinearGradient(
      toSkPoint(from),
      toSkPoint(to),
      toFlatColors(colors),
      toSkColorStops(colorStops),
      toSkTileMode(tileMode),
      matrix4 != null ? toSkMatrixFromFloat32(matrix4!) : null,
    );
  }

  @override
  SkShader resurrect() => createDefault();
}

class CkGradientRadial extends CkShader implements ui.Gradient {
  CkGradientRadial(this.center, this.radius, this.colors, this.colorStops,
      this.tileMode, this.matrix4);

  final ui.Offset center;
  final double radius;
  final List<ui.Color> colors;
  final List<double>? colorStops;
  final ui.TileMode tileMode;
  final Float32List? matrix4;

  @override
  SkShader createDefault() {
    return canvasKit.Shader.MakeRadialGradient(
      toSkPoint(center),
      radius,
      toFlatColors(colors),
      toSkColorStops(colorStops),
      toSkTileMode(tileMode),
      matrix4 != null ? toSkMatrixFromFloat32(matrix4!) : null,
      0,
    );
  }

  @override
  SkShader resurrect() => createDefault();
}

class CkGradientConical extends CkShader implements ui.Gradient {
  CkGradientConical(this.focal, this.focalRadius, this.center, this.radius,
      this.colors, this.colorStops, this.tileMode, this.matrix4);

  final ui.Offset focal;
  final double focalRadius;
  final ui.Offset center;
  final double radius;
  final List<ui.Color> colors;
  final List<double>? colorStops;
  final ui.TileMode tileMode;
  final Float32List? matrix4;

  @override
  SkShader createDefault() {
    return canvasKit.Shader.MakeTwoPointConicalGradient(
      toSkPoint(focal),
      focalRadius,
      toSkPoint(center),
      radius,
      toFlatColors(colors),
      toSkColorStops(colorStops),
      toSkTileMode(tileMode),
      matrix4 != null ? toSkMatrixFromFloat32(matrix4!) : null,
      0,
    );
  }

  @override
  SkShader resurrect() => createDefault();
}

class CkImageShader extends CkShader implements ui.ImageShader {
  CkImageShader(ui.Image image, this.tileModeX, this.tileModeY, this.matrix4,
      this.filterQuality)
      : _image = image as CkImage;

  final ui.TileMode tileModeX;
  final ui.TileMode tileModeY;
  final Float64List matrix4;
  final ui.FilterQuality? filterQuality;
  final CkImage _image;

  int get imageWidth => _image.width;

  int get imageHeight => _image.height;

  ui.FilterQuality? _cachedQuality;
  @override
  SkShader withQuality(ui.FilterQuality contextualQuality) {
    final ui.FilterQuality quality = filterQuality ?? contextualQuality;
    SkShader? shader = rawSkiaObject;
    if (_cachedQuality != quality || shader == null) {
      if (quality == ui.FilterQuality.high) {
        shader = _image.skImage.makeShaderCubic(
          toSkTileMode(tileModeX),
          toSkTileMode(tileModeY),
          1.0 / 3.0,
          1.0 / 3.0,
          toSkMatrixFromFloat64(matrix4),
        );
      } else {
        shader = _image.skImage.makeShaderOptions(
          toSkTileMode(tileModeX),
          toSkTileMode(tileModeY),
          toSkFilterMode(quality),
          toSkMipmapMode(quality),
          toSkMatrixFromFloat64(matrix4),
        );
      }
      _cachedQuality = quality;
      rawSkiaObject = shader;
    }
    return shader;
  }

  @override
  SkShader createDefault() => withQuality(ui.FilterQuality.none);

  @override
  SkShader resurrect() => withQuality(_cachedQuality ?? ui.FilterQuality.none);

  @override
  void delete() {
    rawSkiaObject?.delete();
  }

  @override
  void dispose() {
    super.dispose();
    _image.dispose();
  }
}
