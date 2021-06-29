// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ui/ui.dart' as ui;

import '../offscreen_canvas.dart';
import '../../browser_detection.dart';
import '../../vector_math.dart';

/// Compiled and cached gl program.
class GlProgram {
  final Object program;
  GlProgram(this.program);
}

/// JS Interop helper for webgl apis.
class GlContext {
  final Object glContext;
  final bool isOffscreen;
  dynamic _kCompileStatus;
  dynamic _kArrayBuffer;
  dynamic _kElementArrayBuffer;
  dynamic _kStaticDraw;
  dynamic _kFloat;
  dynamic _kColorBufferBit;
  dynamic _kTexture2D;
  dynamic _kTextureWrapS;
  dynamic _kTextureWrapT;
  dynamic _kRepeat;
  dynamic _kClampToEdge;
  dynamic _kMirroredRepeat;
  dynamic _kTriangles;
  dynamic _kLinkStatus;
  dynamic _kUnsignedByte;
  dynamic _kUnsignedShort;
  dynamic _kRGBA;
  dynamic _kLinear;
  dynamic _kTextureMinFilter;
  int? _kTexture0;

  Object? _canvas;
  int? _widthInPixels;
  int? _heightInPixels;
  static late Map<String, GlProgram?> _programCache;

  factory GlContext(OffScreenCanvas offScreenCanvas) {
    return OffScreenCanvas.supported
        ? GlContext._fromOffscreenCanvas(offScreenCanvas.offScreenCanvas!)
        : GlContext._fromCanvasElement(
        offScreenCanvas.canvasElement!, webGLVersion == WebGLVersion.webgl1);
  }

  GlContext._fromOffscreenCanvas(html.OffscreenCanvas canvas)
      : glContext = canvas.getContext('webgl2', <String, dynamic>{'premultipliedAlpha': false})!,
        isOffscreen = true {
    _programCache = <String, GlProgram?>{};
    _canvas = canvas;
  }

  GlContext._fromCanvasElement(html.CanvasElement canvas, bool useWebGl1)
      : glContext = canvas.getContext(useWebGl1 ? 'webgl' : 'webgl2',
      <String, dynamic>{'premultipliedAlpha': false})!,
        isOffscreen = false {
    _programCache = <String, GlProgram?>{};
    _canvas = canvas;
  }

  void setViewportSize(int width, int height) {
    _widthInPixels = width;
    _heightInPixels = height;
  }

  /// Draws Gl context contents to canvas context.
  void drawImage(html.CanvasRenderingContext2D context,
      double left, double top) {
    // Actual size of canvas may be larger than viewport size. Use
    // source/destination to draw part of the image data.
    js_util.callMethod(context, 'drawImage',
        <dynamic>[_canvas, 0, 0, _widthInPixels, _heightInPixels,
          left, top, _widthInPixels, _heightInPixels]);
  }

  GlProgram cacheProgram(
      String vertexShaderSource, String fragmentShaderSource) {
    String cacheKey = '$vertexShaderSource||$fragmentShaderSource';
    GlProgram? cachedProgram = _programCache[cacheKey];
    if (cachedProgram == null) {
      // Create and compile shaders.
      Object vertexShader = compileShader('VERTEX_SHADER', vertexShaderSource);
      Object fragmentShader =
      compileShader('FRAGMENT_SHADER', fragmentShaderSource);
      // Create a gl program and link shaders.
      Object program = createProgram();
      attachShader(program, vertexShader);
      attachShader(program, fragmentShader);
      linkProgram(program);
      cachedProgram = GlProgram(program);
      _programCache[cacheKey] = cachedProgram;
    }
    return cachedProgram;
  }

  Object compileShader(String shaderType, String source) {
    Object? shader = _createShader(shaderType);
    if (shader == null) {
      throw Exception(error);
    }
    js_util.callMethod(glContext, 'shaderSource', <dynamic>[shader, source]);
    js_util.callMethod(glContext, 'compileShader', <dynamic>[shader]);
    bool shaderStatus = js_util
        .callMethod(glContext, 'getShaderParameter', <dynamic>[shader, compileStatus]);
    if (!shaderStatus) {
      throw Exception('Shader compilation failed: ${getShaderInfoLog(shader)}');
    }
    return shader;
  }

  Object createProgram() =>
      js_util.callMethod(glContext, 'createProgram', const <dynamic>[])!;

  void attachShader(Object? program, Object shader) {
    js_util.callMethod(glContext, 'attachShader', <dynamic>[program, shader]);
  }

  void linkProgram(Object program) {
    js_util.callMethod(glContext, 'linkProgram', <dynamic>[program]);
    if (!js_util
        .callMethod(glContext, 'getProgramParameter', <dynamic>[program, kLinkStatus])) {
      throw Exception(getProgramInfoLog(program));
    }
  }

  void useProgram(GlProgram program) {
    js_util.callMethod(glContext, 'useProgram', <dynamic>[program.program]);
  }

  Object? createBuffer() =>
      js_util.callMethod(glContext, 'createBuffer', const <dynamic>[]);

  void bindArrayBuffer(Object? buffer) {
    js_util.callMethod(glContext, 'bindBuffer', <dynamic>[kArrayBuffer, buffer]);
  }

  Object? createVertexArray() =>
      js_util.callMethod(glContext, 'createVertexArray', const <dynamic>[]);

  void bindVertexArray(Object vertexObjectArray) {
    js_util.callMethod(glContext, 'bindVertexArray',
        <dynamic>[vertexObjectArray]);
  }

  void unbindVertexArray() {
    js_util.callMethod(glContext, 'bindVertexArray',
        <dynamic>[null]);
  }

  void bindElementArrayBuffer(Object? buffer) {
    js_util.callMethod(glContext, 'bindBuffer', <dynamic>[kElementArrayBuffer, buffer]);
  }

  Object? createTexture() =>
      js_util.callMethod(glContext, 'createTexture', const <dynamic>[]);

  void generateMipmap(dynamic target) =>
      js_util.callMethod(glContext, 'generateMipmap', <dynamic>[target]);

  void bindTexture(dynamic target, Object? buffer) {
    js_util.callMethod(glContext, 'bindTexture', <dynamic>[target, buffer]);
  }

  void activeTexture(int textureUnit) {
    js_util.callMethod(glContext, 'activeTexture', <dynamic>[textureUnit]);
  }

  void texImage2D(dynamic target, int level, dynamic internalFormat,
      dynamic format, dynamic dataType,
      dynamic pixels, {int? width, int? height, int border = 0}) {
    if (width == null) {
      js_util.callMethod(glContext, 'texImage2D', <dynamic>[
        target, level, internalFormat, format, dataType, pixels]);
    } else {
      js_util.callMethod(glContext, 'texImage2D', <dynamic>[
        target, level, internalFormat, width, height, border, format, dataType,
        pixels]);
    }
  }

  void texParameteri(dynamic target, dynamic parameterName, dynamic value) {
    js_util.callMethod(glContext, 'texParameteri', <dynamic>[
      target, parameterName, value]);
  }

  void deleteBuffer(Object buffer) {
    js_util.callMethod(glContext, 'deleteBuffer', <dynamic>[buffer]);
  }

  void bufferData(TypedData? data, dynamic type) {
    js_util.callMethod(glContext, 'bufferData', <dynamic>[kArrayBuffer, data, type]);
  }

  void bufferElementData(TypedData? data, dynamic type) {
    js_util.callMethod(glContext, 'bufferData', <dynamic>[kElementArrayBuffer, data, type]);
  }

  void enableVertexAttribArray(dynamic index) {
    js_util.callMethod(glContext, 'enableVertexAttribArray', <dynamic>[index]);
  }

  /// Clear background.
  void clear() {
    js_util.callMethod(glContext, 'clear', <dynamic>[kColorBufferBit]);
  }

  /// Destroys gl context.
  void dispose() {
    js_util.callMethod(_getExtension('WEBGL_lose_context'), 'loseContext', const <dynamic>[]);
  }

  void deleteProgram(Object program) {
    js_util.callMethod(glContext, 'deleteProgram', <dynamic>[program]);
  }

  void deleteShader(Object shader) {
    js_util.callMethod(glContext, 'deleteShader', <dynamic>[shader]);
  }

  dynamic _getExtension(String extensionName) =>
      js_util.callMethod(glContext, 'getExtension', <dynamic>[extensionName]);

  void drawTriangles(int triangleCount, ui.VertexMode vertexMode) {
    dynamic mode = _triangleTypeFromMode(vertexMode);
    js_util.callMethod(glContext, 'drawArrays', <dynamic>[mode, 0, triangleCount]);
  }

  void drawElements(dynamic type, int indexCount, dynamic indexType) {
    js_util.callMethod(glContext, 'drawElements', <dynamic>[type, indexCount, indexType, 0]);
  }

  /// Sets affine transformation from normalized device coordinates
  /// to window coordinates
  void viewport(double x, double y, double width, double height) {
    js_util.callMethod(glContext, 'viewport', <dynamic>[x, y, width, height]);
  }

  dynamic _triangleTypeFromMode(ui.VertexMode mode) {
    switch (mode) {
      case ui.VertexMode.triangles:
        return kTriangles;
      case ui.VertexMode.triangleFan:
        return kTriangleFan;
      case ui.VertexMode.triangleStrip:
        return kTriangleStrip;
    }
  }

  Object? _createShader(String shaderType) => js_util.callMethod(
      glContext, 'createShader', <dynamic>[js_util.getProperty(glContext, shaderType)]);

  /// Error state of gl context.
  dynamic get error => js_util.callMethod(glContext, 'getError', const <dynamic>[]);

  /// Shader compiler error, if this returns [kFalse], to get details use
  /// [getShaderInfoLog].
  dynamic get compileStatus =>
      _kCompileStatus ??= js_util.getProperty(glContext, 'COMPILE_STATUS');

  dynamic get kArrayBuffer =>
      _kArrayBuffer ??= js_util.getProperty(glContext, 'ARRAY_BUFFER');

  dynamic get kElementArrayBuffer =>
      _kElementArrayBuffer ??= js_util.getProperty(glContext,
          'ELEMENT_ARRAY_BUFFER');

  dynamic get kLinkStatus =>
      _kLinkStatus ??= js_util.getProperty(glContext, 'LINK_STATUS');

  dynamic get kFloat => _kFloat ??= js_util.getProperty(glContext, 'FLOAT');

  dynamic get kRGBA => _kRGBA ??= js_util.getProperty(glContext, 'RGBA');

  dynamic get kUnsignedByte =>
      _kUnsignedByte ??= js_util.getProperty(glContext, 'UNSIGNED_BYTE');

  dynamic get kUnsignedShort =>
      _kUnsignedShort ??= js_util.getProperty(glContext, 'UNSIGNED_SHORT');

  dynamic get kStaticDraw =>
      _kStaticDraw ??= js_util.getProperty(glContext, 'STATIC_DRAW');

  dynamic get kTriangles =>
      _kTriangles ??= js_util.getProperty(glContext, 'TRIANGLES');

  dynamic get kTriangleFan =>
      _kTriangles ??= js_util.getProperty(glContext, 'TRIANGLE_FAN');

  dynamic get kTriangleStrip =>
      _kTriangles ??= js_util.getProperty(glContext, 'TRIANGLE_STRIP');

  dynamic get kColorBufferBit =>
      _kColorBufferBit ??= js_util.getProperty(glContext, 'COLOR_BUFFER_BIT');

  dynamic get kTexture2D =>
      _kTexture2D ??= js_util.getProperty(glContext, 'TEXTURE_2D');

  int get kTexture0 =>
      _kTexture0 ??= js_util.getProperty(glContext, 'TEXTURE0') as int;

  dynamic get kTextureWrapS =>
      _kTextureWrapS ??= js_util.getProperty(glContext, 'TEXTURE_WRAP_S');

  dynamic get kTextureWrapT =>
      _kTextureWrapT ??= js_util.getProperty(glContext, 'TEXTURE_WRAP_T');

  dynamic get kRepeat =>
      _kRepeat ??= js_util.getProperty(glContext, 'REPEAT');

  dynamic get kClampToEdge =>
      _kClampToEdge ??= js_util.getProperty(glContext, 'CLAMP_TO_EDGE');

  dynamic get kMirroredRepeat =>
      _kMirroredRepeat ??= js_util.getProperty(glContext, 'MIRRORED_REPEAT');

  dynamic get kLinear =>
      _kLinear ??= js_util.getProperty(glContext, 'LINEAR');

  dynamic get kTextureMinFilter =>
      _kTextureMinFilter ??= js_util.getProperty(glContext,
          'TEXTURE_MIN_FILTER');

  /// Returns reference to uniform in program.
  Object getUniformLocation(Object program, String uniformName) {
    Object? res = js_util
        .callMethod(glContext, 'getUniformLocation', <dynamic>[program, uniformName]);
    if (res == null) {
      throw Exception('$uniformName not found');
    } else {
      return res;
    }
  }

  /// Returns true if uniform exists.
  bool containsUniform(Object program, String uniformName) {
    Object? res = js_util
        .callMethod(glContext, 'getUniformLocation', <dynamic>[program, uniformName]);
    return res != null;
  }

  /// Returns reference to uniform in program.
  Object getAttributeLocation(Object program, String attribName) {
    Object? res = js_util
        .callMethod(glContext, 'getAttribLocation', <dynamic>[program, attribName]);
    if (res == null) {
      throw Exception('$attribName not found');
    } else {
      return res;
    }
  }

  /// Sets float uniform value.
  void setUniform1f(Object uniform, double value) {
    js_util.callMethod(glContext, 'uniform1f', <dynamic>[uniform, value]);
  }

  /// Sets vec2 uniform values.
  void setUniform2f(Object uniform, double value1, double value2) {
    js_util.callMethod(glContext, 'uniform2f', <dynamic>[uniform, value1, value2]);
  }

  /// Sets vec4 uniform values.
  void setUniform4f(Object uniform, double value1, double value2, double value3,
      double value4) {
    js_util.callMethod(
        glContext, 'uniform4f', <dynamic>[uniform, value1, value2, value3, value4]);
  }

  /// Sets mat4 uniform values.
  void setUniformMatrix4fv(Object uniform, bool transpose, Float32List value) {
    js_util.callMethod(
        glContext, 'uniformMatrix4fv', <dynamic>[uniform, transpose, value]);
  }

  /// Shader compile error log.
  dynamic getShaderInfoLog(Object glShader) {
    return js_util.callMethod(glContext, 'getShaderInfoLog', <dynamic>[glShader]);
  }

  ///  Errors that occurred during failed linking or validation of program
  ///  objects. Typically called after [linkProgram].
  String? getProgramInfoLog(Object glProgram) {
    return js_util.callMethod(glContext, 'getProgramInfoLog', <dynamic>[glProgram]);
  }

  int? get drawingBufferWidth =>
      js_util.getProperty(glContext, 'drawingBufferWidth');
  int? get drawingBufferHeight =>
      js_util.getProperty(glContext, 'drawingBufferWidth');

  /// Reads gl contents as image data.
  ///
  /// Warning: data is read bottom up (flipped).
  html.ImageData readImageData() {
    const int kBytesPerPixel = 4;
    final int bufferWidth = _widthInPixels!;
    final int bufferHeight = _heightInPixels!;
    if (browserEngine == BrowserEngine.webkit ||
        browserEngine == BrowserEngine.firefox) {
      final Uint8List pixels =
      Uint8List(bufferWidth * bufferHeight * kBytesPerPixel);
      js_util.callMethod(glContext, 'readPixels',
          <dynamic>[0, 0, bufferWidth, bufferHeight, kRGBA, kUnsignedByte, pixels]);
      return html.ImageData(
          Uint8ClampedList.fromList(pixels), bufferWidth, bufferHeight);
    } else {
      final Uint8ClampedList pixels =
      Uint8ClampedList(bufferWidth * bufferHeight * kBytesPerPixel);
      js_util.callMethod(glContext, 'readPixels',
          <dynamic>[0, 0, bufferWidth, bufferHeight, kRGBA, kUnsignedByte, pixels]);
      return html.ImageData(pixels, bufferWidth, bufferHeight);
    }
  }

  /// Returns image data in a form that can be used to create Canvas
  /// context patterns.
  Object? readPatternData() {
    // When using OffscreenCanvas and transferToImageBitmap is supported by
    // browser create ImageBitmap otherwise use more expensive canvas
    // allocation.
    if (_canvas != null &&
        js_util.hasProperty(_canvas!, 'transferToImageBitmap')) {
      js_util.callMethod(_canvas!, 'getContext', <dynamic>['webgl2']);
      Object?imageBitmap = js_util.callMethod(_canvas!, 'transferToImageBitmap',
          <dynamic>[]);
      return imageBitmap;
    } else {
      html.CanvasElement canvas = html.CanvasElement(width: _widthInPixels, height: _heightInPixels);
      final html.CanvasRenderingContext2D ctx = canvas.context2D;
      drawImage(ctx, 0, 0);
      return canvas;
    }
  }

  /// Returns image data in data url format.
  String toImageUrl() {
    html.CanvasElement canvas = html.CanvasElement(width: _widthInPixels, height: _heightInPixels);
    final html.CanvasRenderingContext2D ctx = canvas.context2D;
    drawImage(ctx, 0, 0);
    final String dataUrl = canvas.toDataUrl();
    canvas.width = 0;
    canvas.height = 0;
    return dataUrl;
  }
}

/// Creates gl context from cached OffscreenCanvas for webgl rendering to image.
class GlContextCache {
  static int _maxPixelWidth = 0;
  static int _maxPixelHeight = 0;
  static GlContext? _cachedContext;
  static OffScreenCanvas? _offScreenCanvas;

  static void dispose() {
    _maxPixelWidth = 0;
    _maxPixelHeight = 0;
    _cachedContext = null;
    _offScreenCanvas?.dispose();
  }

  static GlContext? createGlContext(int widthInPixels, int heightInPixels) {
    if (widthInPixels > _maxPixelWidth || heightInPixels > _maxPixelHeight) {
      _cachedContext?.dispose();
      _cachedContext = null;
      _offScreenCanvas = null;
      _maxPixelWidth = math.max(_maxPixelWidth, widthInPixels);
      _maxPixelHeight = math.max(_maxPixelHeight, widthInPixels);
    }
    _offScreenCanvas ??= OffScreenCanvas(widthInPixels, heightInPixels);
    _cachedContext ??= GlContext(_offScreenCanvas!);
    _cachedContext!.setViewportSize(widthInPixels, heightInPixels);
    return _cachedContext;
  }
}

void setupVertexTransforms(
    GlContext gl,
    GlProgram glProgram,
    double offsetX,
    double offsetY,
    double widthInPixels,
    double heightInPixels,
    Matrix4 transform) {
  Object transformUniform =
      gl.getUniformLocation(glProgram.program, 'u_ctransform');
  Matrix4 transformAtOffset = transform.clone()
    ..translate(-offsetX, -offsetY);
  gl.setUniformMatrix4fv(transformUniform, false, transformAtOffset.storage);

  // Set uniform to scale 0..width/height pixels coordinates to -1..1
  // clipspace range and flip the Y axis.
  Object resolution = gl.getUniformLocation(glProgram.program, 'u_scale');
  gl.setUniform4f(resolution, 2.0 / widthInPixels.toDouble(),
      -2.0 / heightInPixels.toDouble(), 1, 1);
  Object shift = gl.getUniformLocation(glProgram.program, 'u_shift');
  gl.setUniform4f(shift, -1, 1, 0, 0);
}

void setupTextureTransform(
    GlContext gl, GlProgram glProgram, double offsetx, double offsety, double sx, double sy) {
  Object scalar = gl.getUniformLocation(glProgram.program, 'u_textransform');
  gl.setUniform4f(scalar, sx, sy, offsetx, offsety);
}

void bufferVertexData(GlContext gl, Float32List positions,
    double devicePixelRatio) {
  if (devicePixelRatio == 1.0) {
    gl.bufferData(positions, gl.kStaticDraw);
  } else {
    final int length = positions.length;
    Float32List scaledList = Float32List(length);
    for (int i = 0; i < length; i++) {
      scaledList[i] = positions[i] * devicePixelRatio;
    }
    gl.bufferData(scaledList, gl.kStaticDraw);
  }
}

dynamic tileModeToGlWrapping(GlContext gl, ui.TileMode tileMode) {
  switch (tileMode) {
    case ui.TileMode.clamp:
    return gl.kClampToEdge;
    case ui.TileMode.decal:
    return gl.kClampToEdge;
    case ui.TileMode.mirror:
    return gl.kMirroredRepeat;
    case ui.TileMode.repeated:
    return gl.kRepeat;
  }
}