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
// TODO(154281): try to unify with SkwasmPaint
class CkPaint implements ui.Paint {
  CkPaint();

  /// Creates a new [SkPaint] object and returns it.
  ///
  /// The caller is responsible for deleting the returned object when it's no
  /// longer needed.
  SkPaint toSkPaint({ui.TileMode defaultBlurTileMode = ui.TileMode.decal}) {
    final skPaint = SkPaint();
    skPaint.setAntiAlias(isAntiAlias);
    skPaint.setBlendMode(toSkBlendMode(blendMode));
    skPaint.setStyle(toSkPaintStyle(style));
    skPaint.setStrokeWidth(strokeWidth);
    skPaint.setStrokeCap(toSkStrokeCap(strokeCap));
    skPaint.setStrokeJoin(toSkStrokeJoin(strokeJoin));
    skPaint.setColorInt(_colorValue);
    skPaint.setStrokeMiter(strokeMiterLimit);

    final ManagedSkColorFilter? effectiveColorFilter = _effectiveColorFilter;
    if (effectiveColorFilter != null) {
      skPaint.setColorFilter(effectiveColorFilter.skiaObject);
    }

    final CkShader? shader = _shader;
    if (shader != null) {
      skPaint.setShader(shader.getSkShader(filterQuality));
      if (shader.isGradient) {
        skPaint.setDither(true);
      }
    }

    final ui.MaskFilter? localMaskFilter = maskFilter;
    if (localMaskFilter != null) {
      // CanvasKit returns `null` if the sigma is `0` or infinite.
      if (localMaskFilter.webOnlySigma.isFinite && localMaskFilter.webOnlySigma > 0) {
        skPaint.setMaskFilter(
          createBlurSkMaskFilter(localMaskFilter.webOnlyBlurStyle, localMaskFilter.webOnlySigma),
        );
      }
    }

    final CkManagedSkImageFilterConvertible? localImageFilter = _imageFilter;
    if (localImageFilter != null) {
      localImageFilter.withSkImageFilter((skImageFilter) {
        skPaint.setImageFilter(skImageFilter);
      }, defaultBlurTileMode: defaultBlurTileMode);
    }

    return skPaint;
  }

  @override
  ui.BlendMode blendMode = ui.BlendMode.srcOver;

  @override
  ui.PaintingStyle style = ui.PaintingStyle.fill;

  @override
  double strokeWidth = 0.0;

  @override
  ui.StrokeCap strokeCap = ui.StrokeCap.butt;

  @override
  ui.StrokeJoin strokeJoin = ui.StrokeJoin.miter;

  @override
  bool isAntiAlias = true;

  @override
  ui.Color get color => ui.Color(_colorValue);
  @override
  set color(ui.Color value) {
    _colorValue = value.value;
  }

  static const int _defaultPaintColorValue = 0xFF000000;
  int _colorValue = _defaultPaintColorValue;

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
          CkComposeColorFilter(_invertColorFilter, _effectiveColorFilter!),
        );
      }
    }
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
  }

  CkShader? _shader;

  @override
  ui.MaskFilter? maskFilter;

  @override
  ui.FilterQuality filterQuality = ui.FilterQuality.none;

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
          CkComposeColorFilter(_invertColorFilter, _effectiveColorFilter!),
        );
      }
    }
  }

  /// The original color filter objects passed by the framework.
  EngineColorFilter? _engineColorFilter;

  /// The effective color filter.
  ///
  /// This is a combination of the `colorFilter` and `invertColors` properties.
  ManagedSkColorFilter? _effectiveColorFilter;

  @override
  double strokeMiterLimit = 4.0;

  @override
  ui.ImageFilter? get imageFilter => _imageFilter;
  @override
  set imageFilter(ui.ImageFilter? value) {
    if (_imageFilter == value) {
      return;
    }

    if (value is ui.ColorFilter) {
      _imageFilter = createCkColorFilter(value as EngineColorFilter);
    } else {
      _imageFilter = value as CkManagedSkImageFilterConvertible?;
    }
  }

  CkManagedSkImageFilterConvertible? _imageFilter;

  // Must be kept in sync with the default in paint.cc.
  static const double _kStrokeMiterLimitDefault = 4.0;

  // Must be kept in sync with the default in paint.cc.
  static const int _kColorDefault = 0xFF000000;

  // Must be kept in sync with the default in paint.cc.
  static final int _kBlendModeDefault = ui.BlendMode.srcOver.index;

  @override
  String toString() {
    var resultString = 'Paint()';

    assert(() {
      final result = StringBuffer();
      var semicolon = '';
      result.write('Paint(');
      if (style == ui.PaintingStyle.stroke) {
        result.write('$style');
        if (strokeWidth != 0.0) {
          result.write(' ${strokeWidth.toStringAsFixed(1)}');
        } else {
          result.write(' hairline');
        }
        if (strokeCap != ui.StrokeCap.butt) {
          result.write(' $strokeCap');
        }
        if (strokeJoin == ui.StrokeJoin.miter) {
          if (strokeMiterLimit != _kStrokeMiterLimitDefault) {
            result.write(' $strokeJoin up to ${strokeMiterLimit.toStringAsFixed(1)}');
          }
        } else {
          result.write(' $strokeJoin');
        }
        semicolon = '; ';
      }
      if (!isAntiAlias) {
        result.write('${semicolon}antialias off');
        semicolon = '; ';
      }
      if (color != const ui.Color(_kColorDefault)) {
        result.write('$semicolon$color');
        semicolon = '; ';
      }
      if (blendMode.index != _kBlendModeDefault) {
        result.write('$semicolon$blendMode');
        semicolon = '; ';
      }
      if (colorFilter != null) {
        result.write('${semicolon}colorFilter: $colorFilter');
        semicolon = '; ';
      }
      if (maskFilter != null) {
        result.write('${semicolon}maskFilter: $maskFilter');
        semicolon = '; ';
      }
      if (filterQuality != ui.FilterQuality.none) {
        result.write('${semicolon}filterQuality: $filterQuality');
        semicolon = '; ';
      }
      if (shader != null) {
        result.write('${semicolon}shader: $shader');
        semicolon = '; ';
      }
      if (imageFilter != null) {
        result.write('${semicolon}imageFilter: $imageFilter');
        semicolon = '; ';
      }
      if (invertColors) {
        result.write('${semicolon}invert: $invertColors');
      }
      result.write(')');
      resultString = result.toString();
      return true;
    }());

    return resultString;
  }
}

final Float32List _invertColorMatrix = Float32List.fromList(const <double>[
  -1.0, 0, 0, 1.0, 0, // row
  0, -1.0, 0, 1.0, 0, // row
  0, 0, -1.0, 1.0, 0, // row
  1.0, 1.0, 1.0, 1.0, 0,
]);

final ManagedSkColorFilter _invertColorFilter = ManagedSkColorFilter(
  CkMatrixColorFilter(_invertColorMatrix),
);

class CkFragmentProgram implements ui.FragmentProgram {
  CkFragmentProgram(this.name, this.effect, this.uniforms, this.floatCount, this.textureCount);

  factory CkFragmentProgram.fromBytes(String name, Uint8List data) {
    final shaderData = ShaderData.fromBytes(data);
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
    return CkFragmentShader(name, effect, this);
  }

  UniformData _getUniformFloatInfo(String name) {
    for (final UniformData uniform in uniforms) {
      if (uniform.name == name) {
        return uniform;
      }
    }
    throw ArgumentError('No uniform named "$name".');
  }
}

class CkFragmentShader implements ui.FragmentShader, CkShader {
  CkFragmentShader(this.name, this.effect, this._program)
    : floats = mallocFloat32List(_program.floatCount + _program.textureCount * 2),
      samplers = List<SkShader?>.filled(_program.textureCount, null),
      lastFloatIndex = _program.floatCount;

  final String name;
  final SkRuntimeEffect effect;
  final int lastFloatIndex;
  final SkFloat32List floats;
  final List<SkShader?> samplers;
  final CkFragmentProgram _program;

  @visibleForTesting
  UniqueRef<SkShader>? ref;

  @override
  bool get isGradient => false;

  @override
  SkShader getSkShader(ui.FilterQuality contextualQuality) {
    assert(!_debugDisposed, 'FragmentShader has been disposed of.');
    ref?.dispose();

    final SkShader? result = samplers.isEmpty
        ? effect.makeShader(floats)
        : effect.makeShaderWithChildren(floats, samplers);
    if (result == null) {
      throw Exception(
        'Invalid uniform data for shader $name:'
        '  floatUniforms: $floats \n'
        '  samplerUniforms: $samplers \n',
      );
    }

    ref = UniqueRef<SkShader>(this, result, 'FragmentShader');
    return result;
  }

  @override
  void setFloat(int index, double value) {
    assert(!_debugDisposed, 'FragmentShader has been disposed of.');
    floats.toTypedArray()[index] = value;
  }

  @override
  void setImageSampler(
    int index,
    ui.Image image, {
    ui.FilterQuality filterQuality = ui.FilterQuality.none,
  }) {
    assert(!_debugDisposed, 'FragmentShader has been disposed of.');
    final sampler = ui.ImageShader(
      image,
      ui.TileMode.clamp,
      ui.TileMode.clamp,
      toMatrix64(Matrix4.identity().storage),
    );
    samplers[index] = (sampler as CkShader).getSkShader(filterQuality);
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
    free(floats);
  }

  bool _debugDisposed = false;

  @override
  bool get debugDisposed => _debugDisposed;

  @override
  ui.UniformFloatSlot getUniformFloat(String name, [int? index]) {
    index ??= 0;
    final UniformData info = _program._getUniformFloatInfo(name);

    IndexError.check(index, info.floatCount, message: 'Index `$index` out of bounds for `$name`.');

    return CkUniformFloatSlot._(this, index, name, info.floatOffset + index);
  }

  @override
  ui.UniformVec2Slot getUniformVec2(String name) {
    final List<CkUniformFloatSlot> slots = _getUniformFloatSlots(name, 2);
    return _CkUniformVec2Slot._(slots[0], slots[1]);
  }

  @override
  ui.UniformVec3Slot getUniformVec3(String name) {
    final List<CkUniformFloatSlot> slots = _getUniformFloatSlots(name, 3);
    return _CkUniformVec3Slot._(slots[0], slots[1], slots[2]);
  }

  @override
  ui.UniformVec4Slot getUniformVec4(String name) {
    final List<CkUniformFloatSlot> slots = _getUniformFloatSlots(name, 4);
    return _CkUniformVec4Slot._(slots[0], slots[1], slots[2], slots[3]);
  }

  ui.UniformArray<T> _getUniformArray<T extends ui.UniformType>(
    String name,
    int elementSize,
    T Function(List<CkUniformFloatSlot> slots) elementFactory,
  ) {
    final UniformData info = _program._getUniformFloatInfo(name);

    if (info.floatCount % elementSize != 0) {
      throw ArgumentError(
        'Uniform size (${info.floatCount}) for "$name" is not a multiple of $elementSize.',
      );
    }
    final int numElements = info.floatCount ~/ elementSize;

    final elements = List<T>.generate(numElements, (i) {
      final slots = List<CkUniformFloatSlot>.generate(
        info.floatCount,
        (j) => CkUniformFloatSlot._(this, j, name, info.floatOffset + i * elementSize + j),
      );
      return elementFactory(slots);
    });

    return _CkUniformFloatArray<T>._(elements);
  }

  @override
  ui.UniformArray<ui.UniformFloatSlot> getUniformFloatArray(String name) {
    return _getUniformArray(name, 1, (components) => components.first);
  }

  @override
  ui.UniformArray<ui.UniformVec2Slot> getUniformVec2Array(String name) {
    return _getUniformArray<_CkUniformVec2Slot>(
      name,
      2, // 2 floats per element
      (components) => _CkUniformVec2Slot._(
        components[0],
        components[1],
      ), // Create Vec2 from two UniformFloat components
    );
  }

  @override
  ui.UniformArray<ui.UniformVec3Slot> getUniformVec3Array(String name) {
    return _getUniformArray<_CkUniformVec3Slot>(
      name,
      3, // 3 floats per element
      (components) =>
          _CkUniformVec3Slot._(components[0], components[1], components[2]), // Create Vec3
    );
  }

  @override
  ui.UniformArray<ui.UniformVec4Slot> getUniformVec4Array(String name) {
    return _getUniformArray<_CkUniformVec4Slot>(
      name,
      4, // 4 floats per element
      (components) => _CkUniformVec4Slot._(
        components[0],
        components[1],
        components[2],
        components[3],
      ), // Create Vec4
    );
  }

  @override
  ui.UniformMat2Slot getUniformMat2(String name) {
    throw UnsupportedError('getUniformMat2 is not supported on the web.');
  }

  @override
  ui.UniformMat3Slot getUniformMat3(String name) {
    throw UnsupportedError('getUniformMat3 is not supported on the web.');
  }

  @override
  ui.UniformMat4Slot getUniformMat4(String name) {
    throw UnsupportedError('getUniformMat4 is not supported on the web.');
  }

  @override
  ui.UniformArray<ui.UniformMat2Slot> getUniformMat2Array(String name) {
    throw UnsupportedError('getUniformMat2Array is not supported on the web.');
  }

  @override
  ui.UniformArray<ui.UniformMat3Slot> getUniformMat3Array(String name) {
    throw UnsupportedError('getUniformMat3Array is not supported on the web.');
  }

  @override
  ui.UniformArray<ui.UniformMat4Slot> getUniformMat4Array(String name) {
    throw UnsupportedError('getUniformMat4Array is not supported on the web.');
  }

  @override
  ui.ImageSamplerSlot getImageSampler(String name) {
    throw UnsupportedError('getImageSampler is not supported on the web.');
  }

  List<CkUniformFloatSlot> _getUniformFloatSlots(String name, int size) {
    final UniformData info = _program._getUniformFloatInfo(name);

    if (info.floatCount != size) {
      throw ArgumentError('Uniform `$name` has size ${info.floatCount}, not size $size.');
    }

    return List<CkUniformFloatSlot>.generate(
      size,
      (i) => CkUniformFloatSlot._(this, i, name, info.floatOffset + i),
    );
  }
}

class CkUniformFloatSlot implements ui.UniformFloatSlot {
  CkUniformFloatSlot._(this._shader, this.index, this.name, this.shaderIndex);

  final CkFragmentShader _shader;

  @override
  final int index;

  @override
  final String name;

  @override
  void set(double val) {
    _shader.setFloat(shaderIndex, val);
  }

  @override
  final int shaderIndex;
}

class _CkUniformVec2Slot implements ui.UniformVec2Slot {
  _CkUniformVec2Slot._(this._xSlot, this._ySlot);

  @override
  void set(double x, double y) {
    _xSlot.set(x);
    _ySlot.set(y);
  }

  final CkUniformFloatSlot _xSlot, _ySlot;
}

class _CkUniformVec3Slot implements ui.UniformVec3Slot {
  _CkUniformVec3Slot._(this._xSlot, this._ySlot, this._zSlot);

  @override
  void set(double x, double y, double z) {
    _xSlot.set(x);
    _ySlot.set(y);
    _zSlot.set(z);
  }

  final CkUniformFloatSlot _xSlot, _ySlot, _zSlot;
}

class _CkUniformVec4Slot implements ui.UniformVec4Slot {
  _CkUniformVec4Slot._(this._xSlot, this._ySlot, this._zSlot, this._wSlot);

  @override
  void set(double x, double y, double z, double w) {
    _xSlot.set(x);
    _ySlot.set(y);
    _zSlot.set(z);
    _wSlot.set(w);
  }

  final CkUniformFloatSlot _xSlot, _ySlot, _zSlot, _wSlot;
}

class _CkUniformFloatArray<T extends ui.UniformType> implements ui.UniformArray<T> {
  _CkUniformFloatArray._(this._elements);

  @override
  T operator [](int index) {
    return _elements[index];
  }

  @override
  int get length => _elements.length;

  final List<T> _elements;
}
