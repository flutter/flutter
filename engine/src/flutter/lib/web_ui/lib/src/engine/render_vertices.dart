// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
part of engine;

_GlRenderer _glRenderer;

void initWebGl() {
  _glRenderer ??= _WebGlRenderer();
}

void disposeWebGl() {
  _OffscreenCanvas.dispose();
  _glRenderer = null;
}

abstract class _GlRenderer {
  void drawVertices(
      html.CanvasRenderingContext2D context,
      int canvasWidthInPixels,
      int canvasHeightInPixels,
      Matrix4 transform,
      ui.Vertices vertices,
      ui.BlendMode blendMode,
      SurfacePaintData paint);

  void drawHairline(html.CanvasRenderingContext2D _ctx, Float32List positions);
}

/// Treeshakeable backend for rendering webgl on canvas.
///
/// This class gets instantiated on demand by Vertices constructor. For apps
/// that don't use Vertices WebGlRenderer will be removed from release binary.
class _WebGlRenderer implements _GlRenderer {
  // Vertex shader transforms pixel space [Vertices.positions] to
  // final clipSpace -1..1 coordinates with inverted Y Axis.
  static const _vertexShaderTriangle = '''
      #version 300 es
      layout (location=0) in vec4 position;
      layout (location=1) in vec4 color;
      uniform mat4 u_ctransform;
      uniform vec4 u_scale;
      uniform vec4 u_shift;
      out vec4 vColor;
      void main() {
        gl_Position = ((u_ctransform * position) * u_scale) + u_shift;
        vColor = color.zyxw;
      }''';
  // This fragment shader enables Int32List of colors to be passed directly
  // to gl context buffer for rendering by decoding RGBA8888.
  static const _fragmentShaderTriangle = '''
      #version 300 es
      precision highp float;
      in vec4 vColor;
      out vec4 fragColor;
      void main() {
        fragColor = vColor;
      }''';

  // WebGL 1 version of shaders above for compatibility with Safari.
  static const _vertexShaderTriangleEs1 = '''
      attribute vec4 position;
      attribute vec4 color;
      uniform mat4 u_ctransform;
      uniform vec4 u_scale;
      uniform vec4 u_shift;
      varying vec4 vColor;
      void main() {
        gl_Position = ((u_ctransform * position) * u_scale) + u_shift;
        vColor = color.zyxw;
      }''';
  // WebGL 1 version of shaders above for compatibility with Safari.
  static const _fragmentShaderTriangleEs1 = '''
      precision highp float;
      varying vec4 vColor;
      void main() {
        gl_FragColor = vColor;
      }''';

  @override
  void drawVertices(
      html.CanvasRenderingContext2D context,
      int canvasWidthInPixels,
      int canvasHeightInPixels,
      Matrix4 transform,
      ui.Vertices vertices,
      ui.BlendMode blendMode,
      SurfacePaintData paint) {
    // Compute bounds of vertices.
    final Float32List positions = vertices.positions;
    ui.Rect bounds = _computeVerticesBounds(positions, transform);
    double minValueX = bounds.left;
    double minValueY = bounds.top;
    double maxValueX = bounds.right;
    double maxValueY = bounds.bottom;
    double offsetX = 0;
    double offsetY = 0;
    int widthInPixels = canvasWidthInPixels;
    int heightInPixels = canvasHeightInPixels;
    // If vertices fall outside the bitmap area, cull.
    if (maxValueX < 0 || maxValueY < 0) {
      return;
    }
    if (minValueX > widthInPixels || minValueY > heightInPixels) {
      return;
    }
    // If Vertices are is smaller than hosting canvas, allocate minimal
    // offscreen canvas to reduce readPixels data size.
    if ((maxValueX - minValueX) < widthInPixels &&
        (maxValueY - minValueY) < heightInPixels) {
      widthInPixels = maxValueX.ceil() - minValueX.floor();
      heightInPixels = maxValueY.ceil() - minValueY.floor();
      offsetX = minValueX.floor().toDouble();
      offsetY = minValueY.floor().toDouble();
    }
    if (widthInPixels == 0 || heightInPixels == 0) {
      return;
    }
    _GlContext gl =
        _OffscreenCanvas.createGlContext(widthInPixels, heightInPixels);
    final bool isWebKit = (browserEngine == BrowserEngine.webkit);
    _GlProgram glProgram = isWebKit
        ? gl.useAndCacheProgram(
            _vertexShaderTriangleEs1, _fragmentShaderTriangleEs1)
        : gl.useAndCacheProgram(
            _vertexShaderTriangle, _fragmentShaderTriangle);

    Object transformUniform = gl.getUniformLocation(glProgram.program, 'u_ctransform');
    Matrix4 transformAtOffset = transform.clone()..translate(-offsetX, -offsetY);
    gl.setUniformMatrix4fv(transformUniform, false, transformAtOffset.storage);

    // Set uniform to scale 0..width/height pixels coordinates to -1..1
    // clipspace range and flip the Y axis.
    Object resolution = gl.getUniformLocation(glProgram.program, 'u_scale');
    gl.setUniform4f(resolution, 2.0 / widthInPixels.toDouble(),
        -2.0 / heightInPixels.toDouble(), 1, 1);
    Object shift = gl.getUniformLocation(glProgram.program, 'u_shift');
    gl.setUniform4f(shift, -1, 1, 0, 0);

    // Setup geometry.
    Object positionsBuffer = gl.createBuffer();
    assert(positionsBuffer != null);
    gl.bindArrayBuffer(positionsBuffer);
    gl.bufferData(positions, gl.kStaticDraw);
    js_util.callMethod(
        gl.glContext, 'vertexAttribPointer', <dynamic>[0, 2, gl.kFloat, false, 0, 0]);
    gl.enableVertexAttribArray(0);

    // Setup color buffer.
    Object colorsBuffer = gl.createBuffer();
    gl.bindArrayBuffer(colorsBuffer);
    // Buffer kBGRA_8888.
    gl.bufferData(vertices.colors, gl.kStaticDraw);

    js_util.callMethod(gl.glContext, 'vertexAttribPointer',
        <dynamic>[1, 4, gl.kUnsignedByte, true, 0, 0]);
    gl.enableVertexAttribArray(1);
    gl.clear();
    final int vertexCount = positions.length ~/ 2;
    gl.drawTriangles(vertexCount, vertices.mode);

    context.save();
    context.resetTransform();
    gl.drawImage(context, offsetX, offsetY);
    context.restore();
  }

  @override
  void drawHairline(html.CanvasRenderingContext2D _ctx, Float32List positions) {
    assert(positions != null);
    final int pointCount = positions.length ~/ 2;
    _ctx.lineWidth = 1.0;
    _ctx.beginPath();
    for (int i = 0, len = pointCount * 2; i < len;) {
      for (int triangleVertexIndex = 0;
          triangleVertexIndex < 3;
          triangleVertexIndex++, i += 2) {
        final double dx = positions[i];
        final double dy = positions[i + 1];
        switch (triangleVertexIndex) {
          case 0:
            _ctx.moveTo(dx, dy);
            break;
          case 1:
            _ctx.lineTo(dx, dy);
            break;
          case 2:
            _ctx.lineTo(dx, dy);
            _ctx.closePath();
            _ctx.stroke();
        }
      }
    }
  }
}

ui.Rect _computeVerticesBounds(Float32List positions, Matrix4 transform) {
  double minValueX, maxValueX, minValueY, maxValueY;
  minValueX = maxValueX = positions[0];
  minValueY = maxValueY = positions[1];
  for (int i = 2, len = positions.length; i < len; i += 2) {
    final double x = positions[i];
    final double y = positions[i + 1];
    if (x.isNaN || y.isNaN) {
      // Follows skia implementation that sets bounds to empty
      // and aborts.
      return ui.Rect.zero;
    }
    minValueX = math.min(minValueX, x);
    maxValueX = math.max(maxValueX, x);
    minValueY = math.min(minValueY, y);
    maxValueY = math.max(maxValueY, y);
  }
  return _transformBounds(
      transform, minValueX, minValueY, maxValueX, maxValueY);
}

ui.Rect _transformBounds(
    Matrix4 transform, double left, double top, double right, double bottom) {
  final Float32List storage = transform.storage;
  final double m0 = storage[0];
  final double m1 = storage[1];
  final double m4 = storage[4];
  final double m5 = storage[5];
  final double m12 = storage[12];
  final double m13 = storage[13];
  final double x0 = (m0 * left) + (m4 * top) + m12;
  final double y0 = (m1 * left) + (m5 * top) + m13;
  final double x1 = (m0 * right) + (m4 * top) + m12;
  final double y1 = (m1 * right) + (m5 * top) + m13;
  final double x2 = (m0 * right) + (m4 * bottom) + m12;
  final double y2 = (m1 * right) + (m5 * bottom) + m13;
  final double x3 = (m0 * left) + (m4 * bottom) + m12;
  final double y3 = (m1 * left) + (m5 * bottom) + m13;
  return ui.Rect.fromLTRB(
      math.min(x0, math.min(x1, math.min(x2, x3))),
      math.min(y0, math.min(y1, math.min(y2, y3))),
      math.max(x0, math.max(x1, math.max(x2, x3))),
      math.max(y0, math.max(y1, math.max(y2, y3))));
}

// Converts from [VertexMode] triangleFan and triangleStrip to triangles.
Float32List _convertVertexPositions(ui.VertexMode mode, Float32List positions) {
  assert(mode != ui.VertexMode.triangles);
  if (mode == ui.VertexMode.triangleFan) {
    final int coordinateCount = positions.length ~/ 2;
    final int triangleCount = coordinateCount - 2;
    final Float32List triangleList = Float32List(triangleCount * 3 * 2);
    double centerX = positions[0];
    double centerY = positions[1];
    int destIndex = 0;
    int positionIndex = 2;
    for (int triangleIndex = 0;
        triangleIndex < triangleCount;
        triangleIndex++, positionIndex += 2) {
      triangleList[destIndex++] = centerX;
      triangleList[destIndex++] = centerY;
      triangleList[destIndex++] = positions[positionIndex];
      triangleList[destIndex++] = positions[positionIndex + 1];
      triangleList[destIndex++] = positions[positionIndex + 2];
      triangleList[destIndex++] = positions[positionIndex + 3];
    }
    return triangleList;
  } else {
    assert(mode == ui.VertexMode.triangleStrip);
    // Set of connected triangles. Each triangle shares 2 last vertices.
    final int vertexCount = positions.length ~/ 2;
    int triangleCount = vertexCount - 2;
    double x0 = positions[0];
    double y0 = positions[1];
    double x1 = positions[2];
    double y1 = positions[3];
    final Float32List triangleList = Float32List(triangleCount * 3 * 2);
    int destIndex = 0;
    for (int i = 0, positionIndex = 4; i < triangleCount; i++) {
      final double x2 = positions[positionIndex++];
      final double y2 = positions[positionIndex++];
      triangleList[destIndex++] = x0;
      triangleList[destIndex++] = y0;
      triangleList[destIndex++] = x1;
      triangleList[destIndex++] = y1;
      triangleList[destIndex++] = x2;
      triangleList[destIndex++] = y2;
      x0 = x1;
      y0 = y1;
      x1 = x2;
      y1 = y2;
    }
    return triangleList;
  }
}

/// Compiled and cached gl program.
class _GlProgram {
  final Object program;
  _GlProgram(this.program);
}

/// JS Interop helper for webgl apis.
class _GlContext {
  final Object glContext;
  final bool isOffscreen;
  dynamic _kCompileStatus;
  dynamic _kArrayBuffer;
  dynamic _kStaticDraw;
  dynamic _kFloat;
  dynamic _kColorBufferBit;
  dynamic _kTriangles;
  dynamic _kLinkStatus;
  dynamic _kUnsignedByte;
  dynamic _kRGBA;
  Object _canvas;
  int _widthInPixels;
  int _heightInPixels;
  static Map<String, _GlProgram> _programCache;

  _GlContext.fromOffscreenCanvas(html.OffscreenCanvas canvas)
      : glContext = canvas.getContext('webgl2', <String, dynamic>{'premultipliedAlpha': false}),
        isOffscreen = true {
    _programCache = <String, _GlProgram>{};
    _canvas = canvas;
  }

  _GlContext.fromCanvas(html.CanvasElement canvas, bool useWebGl1)
      : glContext = canvas.getContext(useWebGl1 ? 'webgl' : 'webgl2',
          <String, dynamic>{'premultipliedAlpha': false}),
        isOffscreen = false {
    _programCache = <String, _GlProgram>{};
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

  _GlProgram useAndCacheProgram(
      String vertexShaderSource, String fragmentShaderSource) {
    String cacheKey = '$vertexShaderSource||$fragmentShaderSource';
    _GlProgram cachedProgram = _programCache[cacheKey];
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
      cachedProgram = _GlProgram(program);
      _programCache[cacheKey] = cachedProgram;
      useProgram(program);
    }
    return cachedProgram;
  }

  Object compileShader(String shaderType, String source) {
    Object shader = _createShader(shaderType);
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
      js_util.callMethod(glContext, 'createProgram', const <dynamic>[]);

  void attachShader(Object program, Object shader) {
    js_util.callMethod(glContext, 'attachShader', <dynamic>[program, shader]);
  }

  void linkProgram(Object program) {
    js_util.callMethod(glContext, 'linkProgram', <dynamic>[program]);
    if (!js_util
        .callMethod(glContext, 'getProgramParameter', <dynamic>[program, kLinkStatus])) {
      throw Exception(getProgramInfoLog(program));
    }
  }

  void useProgram(Object program) {
    js_util.callMethod(glContext, 'useProgram', <dynamic>[program]);
  }

  Object createBuffer() =>
      js_util.callMethod(glContext, 'createBuffer', const <dynamic>[]);

  void bindArrayBuffer(Object buffer) {
    js_util.callMethod(glContext, 'bindBuffer', <dynamic>[kArrayBuffer, buffer]);
  }

  void deleteBuffer(Object buffer) {
    js_util.callMethod(glContext, 'deleteBuffer', <dynamic>[buffer]);
  }

  void bufferData(TypedData data, dynamic type) {
    js_util.callMethod(glContext, 'bufferData', <dynamic>[kArrayBuffer, data, type]);
  }

  void enableVertexAttribArray(int index) {
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

  /// Sets affine transformation from normalized device coordinates
  /// to window coordinates
  void viewport(double x, double y, double width, double height) {
    js_util.callMethod(glContext, 'viewport', <dynamic>[x, y, width, height]);
  }

  dynamic _triangleTypeFromMode(ui.VertexMode mode) {
    switch (mode) {
      case ui.VertexMode.triangles:
        return kTriangles;
        break;
      case ui.VertexMode.triangleFan:
        return kTriangleFan;
        break;
      case ui.VertexMode.triangleStrip:
        return kTriangleStrip;
        break;
    }
  }

  Object _createShader(String shaderType) => js_util.callMethod(
      glContext, 'createShader', <dynamic>[js_util.getProperty(glContext, shaderType)]);

  /// Error state of gl context.
  dynamic get error => js_util.callMethod(glContext, 'getError', const <dynamic>[]);

  /// Shader compiler error, if this returns [kFalse], to get details use
  /// [getShaderInfoLog].
  dynamic get compileStatus =>
      _kCompileStatus ??= js_util.getProperty(glContext, 'COMPILE_STATUS');

  dynamic get kArrayBuffer =>
      _kArrayBuffer ??= js_util.getProperty(glContext, 'ARRAY_BUFFER');

  dynamic get kLinkStatus =>
      _kLinkStatus ??= js_util.getProperty(glContext, 'LINK_STATUS');

  dynamic get kFloat => _kFloat ??= js_util.getProperty(glContext, 'FLOAT');

  dynamic get kRGBA => _kRGBA ??= js_util.getProperty(glContext, 'RGBA');

  dynamic get kUnsignedByte =>
      _kUnsignedByte ??= js_util.getProperty(glContext, 'UNSIGNED_BYTE');

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

  /// Returns reference to uniform in program.
  Object getUniformLocation(Object program, String uniformName) {
    return js_util
        .callMethod(glContext, 'getUniformLocation', <dynamic>[program, uniformName]);
  }

  /// Sets vec2 uniform values.
  void setUniform2f(Object uniform, double value1, double value2) {
    return js_util
        .callMethod(glContext, 'uniform2f', <dynamic>[uniform, value1, value2]);
  }

  /// Sets vec4 uniform values.
  void setUniform4f(Object uniform, double value1, double value2, double value3,
      double value4) {
    return js_util.callMethod(
        glContext, 'uniform4f', <dynamic>[uniform, value1, value2, value3, value4]);
  }

  /// Sets mat4 uniform values.
  void setUniformMatrix4fv(Object uniform, bool transpose, Float32List value) {
    return js_util.callMethod(
        glContext, 'uniformMatrix4fv', <dynamic>[uniform, transpose, value]);
  }

  /// Shader compile error log.
  dynamic getShaderInfoLog(Object glShader) {
    return js_util.callMethod(glContext, 'getShaderInfoLog', <dynamic>[glShader]);
  }

  ///  Errors that occurred during failed linking or validation of program
  ///  objects. Typically called after [linkProgram].
  String getProgramInfoLog(Object glProgram) {
    return js_util.callMethod(glContext, 'getProgramInfoLog', <dynamic>[glProgram]);
  }

  int get drawingBufferWidth =>
      js_util.getProperty(glContext, 'drawingBufferWidth');
  int get drawingBufferHeight =>
      js_util.getProperty(glContext, 'drawingBufferWidth');

  html.ImageData readImageData() {
    if (browserEngine == BrowserEngine.webkit ||
        browserEngine == BrowserEngine.firefox) {
      const int kBytesPerPixel = 4;
      final int bufferWidth = _widthInPixels;
      final int bufferHeight = _heightInPixels;
      final Uint8List pixels =
          Uint8List(bufferWidth * bufferHeight * kBytesPerPixel);
      js_util.callMethod(glContext, 'readPixels',
          <dynamic>[0, 0, bufferWidth, bufferHeight, kRGBA, kUnsignedByte, pixels]);
      return html.ImageData(
          Uint8ClampedList.fromList(pixels), bufferWidth, bufferHeight);
    } else {
      const int kBytesPerPixel = 4;
      final int bufferWidth = _widthInPixels;
      final int bufferHeight = _heightInPixels;
      final Uint8ClampedList pixels =
          Uint8ClampedList(bufferWidth * bufferHeight * kBytesPerPixel);
      js_util.callMethod(glContext, 'readPixels',
          <dynamic>[0, 0, bufferWidth, bufferHeight, kRGBA, kUnsignedByte, pixels]);
      return html.ImageData(pixels, bufferWidth, bufferHeight);
    }
  }
}

/// Shared Cached OffscreenCanvas for webgl rendering to image.
class _OffscreenCanvas {
  static html.OffscreenCanvas _canvas;
  static int _maxPixelWidth = 0;
  static int _maxPixelHeight = 0;
  static html.CanvasElement _glCanvas;
  static _GlContext _cachedContext;

  _OffscreenCanvas(int width, int height) {
    assert(width > 0 && height > 0);
    if (width > _maxPixelWidth || height > _maxPixelHeight) {
      // Allocate bigger offscreen canvas.
      _canvas = html.OffscreenCanvas(width, height);
      _maxPixelWidth = width;
      _maxPixelHeight = height;
      _cachedContext?.dispose();
      _cachedContext = null;
    }
  }

  static void dispose() {
    _canvas = null;
    _maxPixelWidth = 0;
    _maxPixelHeight = 0;
    _glCanvas = null;
    _cachedContext = null;
  }

  html.OffscreenCanvas get canvas => _canvas;

  static _GlContext createGlContext(int widthInPixels, int heightInPixels) {
    final bool isWebKit = (browserEngine == BrowserEngine.webkit);

    if (_OffscreenCanvas.supported) {
      final _OffscreenCanvas offScreenCanvas =
          _OffscreenCanvas(widthInPixels, heightInPixels);
      _cachedContext ??= _GlContext.fromOffscreenCanvas(offScreenCanvas.canvas);
      _cachedContext.setViewportSize(widthInPixels, heightInPixels);
      return _cachedContext;
    } else {
      // Allocate new canvas element is size is larger.
      if (widthInPixels > _maxPixelWidth || heightInPixels > _maxPixelHeight) {
        _glCanvas = html.CanvasElement(
          width: widthInPixels,
          height: heightInPixels,
        );
        _glCanvas.className = 'gl-canvas';
        final double cssWidth = widthInPixels / EngineWindow.browserDevicePixelRatio;
        final double cssHeight = heightInPixels / EngineWindow.browserDevicePixelRatio;
        _glCanvas.style
          ..position = 'absolute'
          ..width = '${cssWidth}px'
          ..height = '${cssHeight}px';
        _maxPixelWidth = widthInPixels;
        _maxPixelHeight = heightInPixels;
        _cachedContext?.dispose();
        _cachedContext = null;
      }
      _cachedContext ??= _GlContext.fromCanvas(_glCanvas, isWebKit);
      _cachedContext.setViewportSize(widthInPixels, heightInPixels);
      return _cachedContext;
    }
  }

  /// Feature detects OffscreenCanvas.
  static bool get supported =>
      js_util.hasProperty(html.window, 'OffscreenCanvas');
}
