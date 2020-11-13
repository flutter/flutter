// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
part of engine;

abstract class EngineGradient implements ui.Gradient {
  /// Hidden constructor to prevent subclassing.
  EngineGradient._();

  /// Creates a fill style to be used in painting.
  Object createPaintStyle(html.CanvasRenderingContext2D? ctx,
      ui.Rect? shaderBounds, double density);
}

class GradientSweep extends EngineGradient {
  GradientSweep(this.center, this.colors, this.colorStops, this.tileMode,
      this.startAngle, this.endAngle, this.matrix4)
      : assert(_offsetIsValid(center)),
        assert(colors != null), // ignore: unnecessary_null_comparison
        assert(tileMode != null), // ignore: unnecessary_null_comparison
        assert(startAngle != null), // ignore: unnecessary_null_comparison
        assert(endAngle != null), // ignore: unnecessary_null_comparison
        assert(startAngle < endAngle),
        super._() {
    _validateColorStops(colors, colorStops);
  }

  @override
  Object createPaintStyle(html.CanvasRenderingContext2D? ctx,
      ui.Rect? shaderBounds, double density) {
    assert(shaderBounds != null);
    int widthInPixels = shaderBounds!.width.ceil();
    int heightInPixels = shaderBounds.height.ceil();
    assert(widthInPixels > 0 && heightInPixels > 0);

    initWebGl();
    // Render gradient into a bitmap and create a canvas pattern.
    _OffScreenCanvas offScreenCanvas =
        _OffScreenCanvas(widthInPixels, heightInPixels);
    _GlContext gl = _OffScreenCanvas.supported
        ? _GlContext.fromOffscreenCanvas(offScreenCanvas._canvas!)
        : _GlContext.fromCanvas(offScreenCanvas._glCanvas!,
            webGLVersion == WebGLVersion.webgl1);
    gl.setViewportSize(widthInPixels, heightInPixels);

    NormalizedGradient normalizedGradient = NormalizedGradient(
        colors, stops: colorStops);

    _GlProgram glProgram = gl.useAndCacheProgram(
        _WebGlRenderer.writeBaseVertexShader(),
        _createSweepFragmentShader(normalizedGradient, tileMode))!;

    Object tileOffset = gl.getUniformLocation(glProgram.program, 'u_tile_offset');
    double centerX = (center.dx - shaderBounds.left) / (shaderBounds.width);
    double centerY = (center.dy - shaderBounds.top) / (shaderBounds.height);
    gl.setUniform2f(tileOffset,
        2 * (shaderBounds.width * (centerX - 0.5)),
        2 * (shaderBounds.height * (centerY - 0.5)));
    Object angleRange = gl.getUniformLocation(glProgram.program, 'angle_range');
    gl.setUniform2f(angleRange, startAngle, endAngle);
    normalizedGradient.setupUniforms(gl, glProgram);
    if (matrix4 != null) {
      Object gradientMatrix = gl.getUniformLocation(
          glProgram.program, 'm_gradient');
      gl.setUniformMatrix4fv(gradientMatrix, false, matrix4!);
    }

    Object? imageBitmap = _glRenderer!.drawRect(ui.Rect.fromLTWH(0, 0, shaderBounds.width, shaderBounds.height),
        gl, glProgram, normalizedGradient, widthInPixels, heightInPixels);

    return ctx!.createPattern(imageBitmap!, 'no-repeat')!;
  }

  String _createSweepFragmentShader(NormalizedGradient gradient,
      ui.TileMode tileMode) {
    ShaderBuilder builder = ShaderBuilder.fragment(webGLVersion);
    builder.floatPrecision = ShaderPrecision.kMedium;
    builder.addIn(ShaderType.kVec4, name: 'v_color');
    builder.addUniform(ShaderType.kVec2, name: 'u_resolution');
    builder.addUniform(ShaderType.kVec2, name: 'u_tile_offset');
    builder.addUniform(ShaderType.kVec2, name: 'angle_range');
    builder.addUniform(ShaderType.kMat4, name: 'm_gradient');
    ShaderDeclaration fragColor = builder.fragmentColor;
    ShaderMethod method = builder.addMethod('main');
    // Sweep gradient
    method.addStatement(
        'vec2 center = 0.5 * (u_resolution + u_tile_offset);');
    method.addStatement(
        'vec4 localCoord = vec4(gl_FragCoord.x - center.x, center.y - gl_FragCoord.y, 0, 1) * m_gradient;');
    method.addStatement(
        'float angle = atan(-localCoord.y, -localCoord.x) + ${math.pi};');
    method.addStatement(
        'float sweep = angle_range.y - angle_range.x;');
    method.addStatement(
        'angle = (angle - angle_range.x) / sweep;');
    method.addStatement(''
        'float st = angle;');

    method.addStatement('vec4 bias;');
    method.addStatement('vec4 scale;');
    // Write uniforms for each threshold, bias and scale.
    for (int i = 0; i < (gradient.thresholdCount - 1) ~/ 4 + 1; i++) {
      builder.addUniform(ShaderType.kVec4, name: 'threshold_${i}');
    }
    for (int i = 0; i < gradient.thresholdCount; i++) {
      builder.addUniform(ShaderType.kVec4, name: 'bias_$i');
      builder.addUniform(ShaderType.kVec4, name: 'scale_$i');
    }
    String probeName = 'st';
    switch (tileMode) {
      case ui.TileMode.clamp:
        break;
      case ui.TileMode.repeated:
        method.addStatement('float tiled_st = fract(st);');
        probeName = 'tiled_st';
        break;
      case ui.TileMode.mirror:
        method.addStatement('float t_1 = (st - 1.0);');
        method.addStatement('float tiled_st = abs((t_1 - 2.0 * floor(t_1 * 0.5)) - 1.0);');
        probeName = 'tiled_st';
        break;
    }
    _writeUnrolledBinarySearch(method, 0, gradient.thresholdCount - 1,
      probe: probeName, sourcePrefix: 'threshold',
      biasName: 'bias', scaleName: 'scale');
    method.addStatement('${fragColor.name} = ${probeName} * scale + bias;');
    String shader = builder.build();
    return shader;
  }

  final ui.Offset center;
  final List<ui.Color> colors;
  final List<double>? colorStops;
  final ui.TileMode tileMode;
  final double startAngle;
  final double endAngle;
  final Float32List? matrix4;
}

class GradientLinear extends EngineGradient {
  GradientLinear(
    this.from,
    this.to,
    this.colors,
    this.colorStops,
    this.tileMode,
    Float64List? matrix,
  )   : assert(_offsetIsValid(from)),
        assert(_offsetIsValid(to)),
        assert(colors != null), // ignore: unnecessary_null_comparison
        assert(tileMode != null), // ignore: unnecessary_null_comparison
        this.matrix4 = matrix == null ? null : _FastMatrix64(matrix),
        super._() {
    if (assertionsEnabled) {
      _validateColorStops(colors, colorStops);
    }
  }

  final ui.Offset from;
  final ui.Offset to;
  final List<ui.Color> colors;
  final List<double>? colorStops;
  final ui.TileMode tileMode;
  final _FastMatrix64? matrix4;

  @override
  html.CanvasGradient createPaintStyle(html.CanvasRenderingContext2D? ctx,
      ui.Rect? shaderBounds, double density) {
    _FastMatrix64? matrix4 = this.matrix4;
    html.CanvasGradient gradient;
    final double offsetX = shaderBounds!.left;
    final double offsetY = shaderBounds.top;
    if (matrix4 != null) {
      final centerX = (from.dx + to.dx) / 2.0;
      final centerY = (from.dy + to.dy) / 2.0;
      matrix4.transform(from.dx - centerX, from.dy - centerY);
      final double fromX = matrix4.transformedX + centerX;
      final double fromY = matrix4.transformedY + centerY;
      matrix4.transform(to.dx - centerX, to.dy - centerY);
      gradient = ctx!.createLinearGradient(fromX - offsetX, fromY - offsetY,
          matrix4.transformedX + centerX - offsetX, matrix4.transformedY - offsetY + centerY);
    } else {
      gradient = ctx!.createLinearGradient(from.dx - offsetX, from.dy - offsetY, to.dx - offsetX, to.dy - offsetY);
    }

    final List<double>? colorStops = this.colorStops;
    if (colorStops == null) {
      assert(colors.length == 2);
      gradient.addColorStop(0, colorToCssString(colors[0])!);
      gradient.addColorStop(1, colorToCssString(colors[1])!);
      return gradient;
    }
    for (int i = 0; i < colors.length; i++) {
      gradient.addColorStop(colorStops[i], colorToCssString(colors[i])!);
    }
    return gradient;
  }
}

// TODO(flutter_web): For transforms and tile modes implement as webgl
// For now only GradientRotation is supported in flutter which is implemented
// for linear gradient.
// See https://github.com/flutter/flutter/issues/32819
class GradientRadial extends EngineGradient {
  GradientRadial(this.center, this.radius, this.colors, this.colorStops,
      this.tileMode, this.matrix4)
      : super._();

  final ui.Offset center;
  final double radius;
  final List<ui.Color> colors;
  final List<double>? colorStops;
  final ui.TileMode tileMode;
  final Float32List? matrix4;

  @override
  Object createPaintStyle(html.CanvasRenderingContext2D? ctx,
      ui.Rect? shaderBounds, double density) {
    if (!useCanvasKit) {
      if (tileMode != ui.TileMode.clamp) {
        throw UnimplementedError(
            'TileMode not supported in GradientRadial shader');
      }
    }
    final double offsetX = shaderBounds!.left;
    final double offsetY = shaderBounds.top;
    final html.CanvasGradient gradient = ctx!.createRadialGradient(
        center.dx - offsetX, center.dy - offsetY, 0,
        center.dx - offsetX, center.dy - offsetY, radius);
    final List<double>? colorStops = this.colorStops;
    if (colorStops == null) {
      assert(colors.length == 2);
      gradient.addColorStop(0, colorToCssString(colors[0])!);
      gradient.addColorStop(1, colorToCssString(colors[1])!);
      return gradient;
    } else {
      for (int i = 0; i < colors.length; i++) {
        gradient.addColorStop(colorStops[i], colorToCssString(colors[i])!);
      }
    }
    return gradient;
  }
}

class GradientConical extends EngineGradient {
  GradientConical(this.focal, this.focalRadius, this.center, this.radius,
      this.colors, this.colorStops, this.tileMode, this.matrix4)
      : super._();

  final ui.Offset focal;
  final double focalRadius;
  final ui.Offset center;
  final double radius;
  final List<ui.Color> colors;
  final List<double>? colorStops;
  final ui.TileMode tileMode;
  final Float32List? matrix4;

  @override
  Object createPaintStyle(html.CanvasRenderingContext2D? ctx,
      ui.Rect? shaderBounds, double density) {
    throw UnimplementedError();
  }
}

/// Backend implementation of [ui.ImageFilter].
///
/// Currently only `blur` is supported.
class EngineImageFilter implements ui.ImageFilter {
  EngineImageFilter.blur({this.sigmaX = 0.0, this.sigmaY = 0.0});

  final double sigmaX;
  final double sigmaY;

  @override
  bool operator ==(Object other) {
    return other is EngineImageFilter
        && other.sigmaX == sigmaX
        && other.sigmaY == sigmaY;
  }

  @override
  int get hashCode => ui.hashValues(sigmaX, sigmaY);

  @override
  String toString() {
    return 'ImageFilter.blur($sigmaX, $sigmaY)';
  }
}
