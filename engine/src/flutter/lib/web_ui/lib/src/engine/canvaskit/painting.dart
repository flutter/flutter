// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:ui/ui.dart' as ui;

import '../color_filter.dart';
import '../shader_data.dart';
import '../vector_math.dart';
import 'canvaskit_api.dart';
import 'color_filter.dart';
import 'image_filter.dart';
import 'mask_filter.dart';
import 'native_memory.dart';
import 'shader.dart';

/// The implementation of [ui.Paint] used by the CanvasKit backend.
///
/// This class is backed by a Skia object that must be explicitly
/// deleted to avoid a memory leak. This is done by extending [SkiaObject].
class CkPaint implements ui.Paint {
  CkPaint() : skiaObject = SkPaint() {
    skiaObject.setAntiAlias(_isAntiAlias);
    skiaObject.setColorInt(_defaultPaintColor.toDouble());
    _ref = UniqueRef<SkPaint>(this, skiaObject, 'Paint');
  }

  final SkPaint skiaObject;
  late final UniqueRef<SkPaint> _ref;
  CkManagedSkImageFilterConvertible? _imageFilter;

  static const int _defaultPaintColor = 0xFF000000;

  /// Returns the native reference to the underlying [SkPaint] object.
  ///
  /// This should only be used in tests.
  @visibleForTesting
  UniqueRef<SkPaint> get debugRef => _ref;

  @override
  ui.BlendMode get blendMode => _blendMode;
  @override
  set blendMode(ui.BlendMode value) {
    if (_blendMode == value) {
      return;
    }
    _blendMode = value;
    skiaObject.setBlendMode(toSkBlendMode(value));
  }

  ui.BlendMode _blendMode = ui.BlendMode.srcOver;

  @override
  ui.PaintingStyle get style => _style;

  @override
  set style(ui.PaintingStyle value) {
    if (_style == value) {
      return;
    }
    _style = value;
    skiaObject.setStyle(toSkPaintStyle(value));
  }

  ui.PaintingStyle _style = ui.PaintingStyle.fill;

  @override
  double get strokeWidth => _strokeWidth;
  @override
  set strokeWidth(double value) {
    if (_strokeWidth == value) {
      return;
    }
    _strokeWidth = value;
    skiaObject.setStrokeWidth(value);
  }

  double _strokeWidth = 0.0;

  @override
  ui.StrokeCap get strokeCap => _strokeCap;
  @override
  set strokeCap(ui.StrokeCap value) {
    if (_strokeCap == value) {
      return;
    }
    _strokeCap = value;
    skiaObject.setStrokeCap(toSkStrokeCap(value));
  }

  ui.StrokeCap _strokeCap = ui.StrokeCap.butt;

  @override
  ui.StrokeJoin get strokeJoin => _strokeJoin;
  @override
  set strokeJoin(ui.StrokeJoin value) {
    if (_strokeJoin == value) {
      return;
    }
    _strokeJoin = value;
    skiaObject.setStrokeJoin(toSkStrokeJoin(value));
  }

  ui.StrokeJoin _strokeJoin = ui.StrokeJoin.miter;

  @override
  bool get isAntiAlias => _isAntiAlias;
  @override
  set isAntiAlias(bool value) {
    if (_isAntiAlias == value) {
      return;
    }
    _isAntiAlias = value;
    skiaObject.setAntiAlias(value);
  }

  bool _isAntiAlias = true;

  @override
  ui.Color get color => ui.Color(_color);
  @override
  set color(ui.Color value) {
    if (_color == value.value) {
      return;
    }
    _color = value.value;
    skiaObject.setColorInt(value.value.toDouble());
  }

  int _color = _defaultPaintColor;

  @override
  bool get invertColors => _invertColors;
  @override
  set invertColors(bool value) {
    if (value == _invertColors) {
      return;
    }
    if (!value) {
      _effectiveColorFilter = _originalColorFilter;
      _originalColorFilter = null;
    } else {
      _originalColorFilter = _effectiveColorFilter;
      if (_effectiveColorFilter == null) {
        _effectiveColorFilter = _invertColorFilter;
      } else {
        _effectiveColorFilter = ManagedSkColorFilter(
          CkComposeColorFilter(_invertColorFilter, _effectiveColorFilter!)
        );
      }
    }
    skiaObject.setColorFilter(_effectiveColorFilter?.skiaObject);
    _invertColors = value;
  }

  bool _invertColors = false;
  // The original color filter before we inverted colors. If we set
  // `invertColors` back to `false`, then restore this filter rather than
  // invert the color filter again.
  ManagedSkColorFilter? _originalColorFilter;

  @override
  ui.Shader? get shader => _shader;
  @override
  set shader(ui.Shader? value) {
    if (_shader == value) {
      return;
    }
    _shader = value as CkShader?;
    skiaObject.setShader(_shader?.getSkShader(_filterQuality));
  }

  CkShader? _shader;

  @override
  ui.MaskFilter? get maskFilter => _maskFilter;
  @override
  set maskFilter(ui.MaskFilter? value) {
    if (value == _maskFilter) {
      return;
    }
    _maskFilter = value;
    if (value != null) {
      // CanvasKit returns `null` if the sigma is `0` or infinite.
      if (!(value.webOnlySigma.isFinite && value.webOnlySigma > 0)) {
        // Don't create a [CkMaskFilter].
        _ckMaskFilter = null;
      } else {
        _ckMaskFilter = CkMaskFilter.blur(
          value.webOnlyBlurStyle,
          value.webOnlySigma,
        );
      }
    } else {
      _ckMaskFilter = null;
    }
    skiaObject.setMaskFilter(_ckMaskFilter?.skiaObject);
  }

  ui.MaskFilter? _maskFilter;
  CkMaskFilter? _ckMaskFilter;

  @override
  ui.FilterQuality get filterQuality => _filterQuality;
  @override
  set filterQuality(ui.FilterQuality value) {
    if (_filterQuality == value) {
      return;
    }
    _filterQuality = value;
    skiaObject.setShader(_shader?.getSkShader(value));
  }

  ui.FilterQuality _filterQuality = ui.FilterQuality.none;
  EngineColorFilter? _engineColorFilter;

  @override
  ui.ColorFilter? get colorFilter => _engineColorFilter;

  @override
  set colorFilter(ui.ColorFilter? value) {
    if (_engineColorFilter == value) {
      return;
    }
    _engineColorFilter = value as EngineColorFilter?;
    _originalColorFilter = null;
    if (value == null) {
      _effectiveColorFilter = null;
    } else {
      final CkColorFilter ckColorFilter = createCkColorFilter(value)!;
      _effectiveColorFilter = ManagedSkColorFilter(ckColorFilter);
    }

    if (invertColors) {
      _originalColorFilter = _effectiveColorFilter;
      if (_effectiveColorFilter == null) {
        _effectiveColorFilter = _invertColorFilter;
      } else {
        _effectiveColorFilter = ManagedSkColorFilter(
          CkComposeColorFilter(_invertColorFilter, _effectiveColorFilter!)
        );
      }
    }

    skiaObject.setColorFilter(_effectiveColorFilter?.skiaObject);
  }

  /// The effective color filter.
  ///
  /// This is a combination of the `colorFilter` and `invertColors` properties.
  ManagedSkColorFilter? _effectiveColorFilter;

  @override
  double get strokeMiterLimit => _strokeMiterLimit;
  @override
  set strokeMiterLimit(double value) {
    if (_strokeMiterLimit == value) {
      return;
    }
    _strokeMiterLimit = value;
    skiaObject.setStrokeMiter(value);
  }

  double _strokeMiterLimit = 0.0;

  @override
  ui.ImageFilter? get imageFilter => _imageFilter;
  @override
  set imageFilter(ui.ImageFilter? value) {
    if (_imageFilter == value) {
      return;
    }
    final CkManagedSkImageFilterConvertible? filter;
    if (value is ui.ColorFilter) {
      filter = createCkColorFilter(value as EngineColorFilter);
    }
    else {
      filter = value as CkManagedSkImageFilterConvertible?;
    }

    if (filter != null) {
      filter.imageFilter((SkImageFilter skImageFilter) {
        skiaObject.setImageFilter(skImageFilter);
      });
    }

    _imageFilter = filter;
  }

  /// Disposes of this paint object.
  ///
  /// This object cannot be used again after calling this method.
  void dispose() {
    _ref.dispose();
  }
}

final Float32List _invertColorMatrix = Float32List.fromList(const <double>[
  -1.0, 0, 0, 1.0, 0, // row
  0, -1.0, 0, 1.0, 0, // row
  0, 0, -1.0, 1.0, 0, // row
  1.0, 1.0, 1.0, 1.0, 0
]);

final ManagedSkColorFilter _invertColorFilter = ManagedSkColorFilter(CkMatrixColorFilter(_invertColorMatrix));

class CkFragmentProgram implements ui.FragmentProgram {
  CkFragmentProgram(this.name, this.effect, this.uniforms, this.floatCount,
      this.textureCount);

  factory CkFragmentProgram.fromBytes(String name, Uint8List data) {
    final ShaderData shaderData = ShaderData.fromBytes(data);
    final SkRuntimeEffect? effect = MakeRuntimeEffect(shaderData.source);
    if (effect == null) {
      throw const FormatException('Invalid Shader Source');
    }

    return CkFragmentProgram(
      name,
      effect,
      shaderData.uniforms,
      shaderData.floatCount,
      shaderData.textureCount,
    );
  }

  final String name;
  final SkRuntimeEffect effect;
  final List<UniformData> uniforms;
  final int floatCount;
  final int textureCount;

  @override
  ui.FragmentShader fragmentShader() {
    return CkFragmentShader(name, effect, floatCount, textureCount);
  }
}

class CkFragmentShader implements ui.FragmentShader, CkShader {
  CkFragmentShader(this.name, this.effect, int floatCount, int textureCount)
      : floats = List<double>.filled(floatCount + textureCount * 2, 0),
        samplers = List<SkShader?>.filled(textureCount, null),
        lastFloatIndex = floatCount;

  final String name;
  final SkRuntimeEffect effect;
  final int lastFloatIndex;
  final List<double> floats;
  final List<SkShader?> samplers;

  @visibleForTesting
  UniqueRef<SkShader>? ref;

  @override
  SkShader getSkShader(ui.FilterQuality contextualQuality) {
    assert(!_debugDisposed, 'FragmentShader has been disposed of.');
    ref?.dispose();

    final SkShader? result = samplers.isEmpty
        ? effect.makeShader(floats)
        : effect.makeShaderWithChildren(floats, samplers);
    if (result == null) {
      throw Exception('Invalid uniform data for shader $name:'
          '  floatUniforms: $floats \n'
          '  samplerUniforms: $samplers \n');
    }

    ref = UniqueRef<SkShader>(this, result, 'FragmentShader');
    return result;
  }

  @override
  void setFloat(int index, double value) {
    assert(!_debugDisposed, 'FragmentShader has been disposed of.');
    floats[index] = value;
  }

  @override
  void setImageSampler(int index, ui.Image image) {
    assert(!_debugDisposed, 'FragmentShader has been disposed of.');
    final ui.ImageShader sampler = ui.ImageShader(image, ui.TileMode.clamp,
        ui.TileMode.clamp, toMatrix64(Matrix4.identity().storage));
    samplers[index] = (sampler as CkShader).getSkShader(ui.FilterQuality.none);
    setFloat(lastFloatIndex + 2 * index, (sampler as CkImageShader).imageWidth.toDouble());
    setFloat(lastFloatIndex + 2 * index + 1, sampler.imageHeight.toDouble());
  }

  @override
  void dispose() {
    assert(!_debugDisposed, 'Cannot dispose FragmentShader more than once.');
    assert(() {
      _debugDisposed = true;
      return true;
    }());
    ref?.dispose();
    ref = null;
  }

  bool _debugDisposed = false;

  @override
  bool get debugDisposed => _debugDisposed;
}
