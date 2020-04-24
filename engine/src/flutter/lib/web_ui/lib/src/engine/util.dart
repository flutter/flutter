// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
part of engine;

/// Generic callback signature, used by [_futurize].
typedef Callback<T> = void Function(T result);

/// Signature for a method that receives a [_Callback].
///
/// Return value should be null on success, and a string error message on
/// failure.
typedef Callbacker<T> = String Function(Callback<T> callback);

/// Converts a method that receives a value-returning callback to a method that
/// returns a Future.
///
/// Return a [String] to cause an [Exception] to be synchronously thrown with
/// that string as a message.
///
/// If the callback is called with null, the future completes with an error.
///
/// Example usage:
///
/// ```dart
/// typedef IntCallback = void Function(int result);
///
/// String _doSomethingAndCallback(IntCallback callback) {
///   new Timer(new Duration(seconds: 1), () { callback(1); });
/// }
///
/// Future<int> doSomething() {
///   return _futurize(_doSomethingAndCallback);
/// }
/// ```
Future<T> futurize<T>(Callbacker<T> callbacker) {
  final Completer<T> completer = Completer<T>.sync();
  final String error = callbacker((T t) {
    if (t == null) {
      completer.completeError(Exception('operation failed'));
    } else {
      completer.complete(t);
    }
  });
  if (error != null) {
    throw Exception(error);
  }
  return completer.future;
}

/// Converts [matrix] to CSS transform value.
String matrix4ToCssTransform(Matrix4 matrix) {
  return float64ListToCssTransform(matrix.storage);
}

/// Applies a transform to the [element].
///
/// See [float64ListToCssTransform] for details on how the CSS value is chosen.
void setElementTransform(html.Element element, Float32List matrix4) {
  element.style
    ..transformOrigin = '0 0 0'
    ..transform = float64ListToCssTransform(matrix4);
}

/// Converts [matrix] to CSS transform value.
///
/// To avoid blurry text on some screens this function uses a 2D CSS transform
/// if it detects that [matrix] is a 2D transform. Otherwise, it uses a 3D CSS
/// transform.
///
/// See also:
///  * https://github.com/flutter/flutter/issues/32274
///  * https://bugs.chromium.org/p/chromium/issues/detail?id=1040222
String float64ListToCssTransform(Float32List matrix) {
  assert(matrix.length == 16);
  final TransformKind transformKind = transformKindOf(matrix);
  if (transformKind == TransformKind.transform2d) {
    return float64ListToCssTransform2d(matrix);
  } else if (transformKind == TransformKind.complex) {
    return float64ListToCssTransform3d(matrix);
  } else {
    assert(transformKind == TransformKind.identity);
    return null;
  }
}

/// The kind of effect a transform matrix performs.
enum TransformKind {
  /// No effect.
  ///
  /// We do not want to set any CSS properties in this case.
  identity,

  /// A transform that contains only 2d scale, rotation, and translation.
  ///
  /// We prefer to use "matrix" instead of "matrix3d" in this case.
  transform2d,

  /// All other kinds of transforms.
  ///
  /// In this case we will use "matrix3d".
  complex,
}

/// Detects the kind of transform the [matrix] performs.
TransformKind transformKindOf(Float32List matrix) {
  assert(matrix.length == 16);
  final Float32List m = matrix;

  // If matrix contains scaling, rotation, z translation or
  // perspective transform, it is not considered simple.
  final bool isSimple2dTransform =
      m[15] == 1.0 &&  // start reading from the last element to eliminate range checks in subsequent reads.
      m[14] == 0.0 && // z translation is NOT simple
      // m[13] - y translation is simple
      // m[12] - x translation is simple
      m[11] == 0.0 &&
      m[10] == 1.0 &&
      m[9] == 0.0 &&
      m[8] == 0.0 &&
      m[7] == 0.0 &&
      m[6] == 0.0 &&
      // m[5] - scale y is simple
      // m[4] - 2D rotation is simple
      m[3] == 0.0 &&
      m[2] == 0.0;
      // m[1] - 2D rotation is simple
      // m[0] - scale x is simple

  if (!isSimple2dTransform) {
    return TransformKind.complex;
  }

  // From this point on we're sure the transform is 2D, but we don't know if
  // it's identity or not. To check, we need to look at the remaining elements
  // that were not checked above.
  final bool isIdentityTransform =
      m[0] == 1.0 &&
      m[1] == 0.0 &&
      m[4] == 0.0 &&
      m[5] == 1.0 &&
      m[12] == 0.0 &&
      m[13] == 0.0;

  if (isIdentityTransform) {
    return TransformKind.identity;
  } else {
    return TransformKind.transform2d;
  }
}

/// Returns `true` is the [matrix] describes an identity transformation.
bool isIdentityFloat32ListTransform(Float32List matrix) {
  assert(matrix.length == 16);
  return transformKindOf(matrix) == TransformKind.identity;
}

/// Converts [matrix] to CSS transform 2D matrix value.
///
/// The [matrix] must not be a [TransformKind.complex] transform, because CSS
/// `matrix` can only express 2D transforms. [TransformKind.identity] is
/// permitted. However, it is inefficient to construct a matrix for an identity
/// transform. Consider removing the CSS `transform` property from elements
/// that apply identity transform.
String float64ListToCssTransform2d(Float32List matrix) {
  assert (transformKindOf(matrix) != TransformKind.complex);
  return 'matrix(${matrix[0]},${matrix[1]},${matrix[4]},${matrix[5]},${matrix[12]},${matrix[13]})';
}

/// Converts [matrix] to a 3D CSS transform value.
String float64ListToCssTransform3d(Float32List matrix) {
  assert(matrix.length == 16);
  final Float32List m = matrix;
  if (m[0] == 1.0 &&
      m[1] == 0.0 &&
      m[2] == 0.0 &&
      m[3] == 0.0 &&
      m[4] == 0.0 &&
      m[5] == 1.0 &&
      m[6] == 0.0 &&
      m[7] == 0.0 &&
      m[8] == 0.0 &&
      m[9] == 0.0 &&
      m[10] == 1.0 &&
      m[11] == 0.0 &&
      // 12 can be anything
      // 13 can be anything
      m[14] == 0.0 &&
      m[15] == 1.0) {
    final double tx = m[12];
    final double ty = m[13];
    return 'translate3d(${tx}px, ${ty}px, 0px)';
  } else {
    return 'matrix3d(${m[0]},${m[1]},${m[2]},${m[3]},${m[4]},${m[5]},${m[6]},${m[7]},${m[8]},${m[9]},${m[10]},${m[11]},${m[12]},${m[13]},${m[14]},${m[15]})';
  }
}

bool get assertionsEnabled {
  bool k = false;
  assert(k = true);
  return k;
}

final Float32List _tempRectData = Float32List(4);

/// Transforms a [ui.Rect] given the effective [transform].
///
/// The resulting rect is aligned to the pixel grid, i.e. two of
/// its sides are vertical and two are horizontal. In the presence of rotations
/// the rectangle is inflated such that it fits the rotated rectangle.
ui.Rect transformRect(Matrix4 transform, ui.Rect rect) {
  _tempRectData[0] = rect.left;
  _tempRectData[1] = rect.top;
  _tempRectData[2] = rect.right;
  _tempRectData[3] = rect.bottom;
  transformLTRB(transform, _tempRectData);
  return ui.Rect.fromLTRB(
    _tempRectData[0],
    _tempRectData[1],
    _tempRectData[2],
    _tempRectData[3],
  );
}

/// Temporary storage for intermediate data used by [transformLTRB].
///
/// WARNING: do not use this outside [transformLTRB]. Sharing this variable in
/// other contexts will lead to bugs.
final Float32List _tempPointData = Float32List(16);
final Matrix4 _tempPointMatrix = Matrix4.fromFloat32List(_tempPointData);

/// Transforms a rectangle given the effective [transform].
///
/// This is the same as [transformRect], except that the rect is specified
/// in terms of left, top, right, and bottom edge offsets.
void transformLTRB(Matrix4 transform, Float32List ltrb) {
  // Construct a matrix where each row represents a vector pointing at
  // one of the four corners of the (left, top, right, bottom) rectangle.
  // Using the row-major order allows us to multiply the matrix in-place
  // by the transposed current transformation matrix. The vector_math
  // library has a convenience function `multiplyTranspose` that performs
  // the multiplication without copying. This way we compute the positions
  // of all four points in a single matrix-by-matrix multiplication at the
  // cost of one `Matrix4` instance and one `Float32List` instance.
  //
  // The rejected alternative was to use `Vector3` for each point and
  // multiply by the current transform. However, that would cost us four
  // `Vector3` instances, four `Float32List` instances, and four
  // matrix-by-vector multiplications.
  //
  // `Float32List` initializes the array with zeros, so we do not have to
  // fill in every single element.

  // Row 0: top-left
  _tempPointData[0] = ltrb[0];
  _tempPointData[4] = ltrb[1];
  _tempPointData[8] = 0;
  _tempPointData[12] = 1;

  // Row 1: top-right
  _tempPointData[1] = ltrb[2];
  _tempPointData[5] = ltrb[1];
  _tempPointData[9] = 0;
  _tempPointData[13] = 1;

  // Row 2: bottom-left
  _tempPointData[2] = ltrb[0];
  _tempPointData[6] = ltrb[3];
  _tempPointData[10] = 0;
  _tempPointData[14] = 1;

  // Row 3: bottom-right
  _tempPointData[3] = ltrb[2];
  _tempPointData[7] = ltrb[3];
  _tempPointData[11] = 0;
  _tempPointData[15] = 1;

  _tempPointMatrix.multiplyTranspose(transform);

  ltrb[0] = math.min(math.min(math.min(_tempPointData[0], _tempPointData[1]), _tempPointData[2]), _tempPointData[3]);
  ltrb[1] = math.min(math.min(math.min(_tempPointData[4], _tempPointData[5]), _tempPointData[6]), _tempPointData[7]);
  ltrb[2] = math.max(math.max(math.max(_tempPointData[0], _tempPointData[1]), _tempPointData[2]), _tempPointData[3]);
  ltrb[3] = math.max(math.max(math.max(_tempPointData[4], _tempPointData[5]), _tempPointData[6]), _tempPointData[7]);
}

/// Returns true if [rect] contains every point that is also contained by the
/// [other] rect.
///
/// Points on the edges of both rectangles are also considered. For example,
/// this returns true when the two rects are equal to each other.
bool rectContainsOther(ui.Rect rect, ui.Rect other) {
  return rect.left <= other.left &&
      rect.top <= other.top &&
      rect.right >= other.right &&
      rect.bottom >= other.bottom;
}

/// Counter used for generating clip path id inside an svg <defs> tag.
int _clipIdCounter = 0;

/// Converts Path to svg element that contains a clip-path definition.
///
/// Calling this method updates [_clipIdCounter]. The HTML id of the generated
/// clip is set to "svgClip${_clipIdCounter}", e.g. "svgClip123".
String _pathToSvgClipPath(ui.Path path,
    {double offsetX = 0,
    double offsetY = 0,
    double scaleX = 1.0,
    double scaleY = 1.0}) {
  _clipIdCounter += 1;
  final StringBuffer sb = StringBuffer();
  sb.write('<svg width="0" height="0" '
      'style="position:absolute">');
  sb.write('<defs>');

  final String clipId = 'svgClip$_clipIdCounter';
  sb.write('<clipPath id=$clipId clipPathUnits="objectBoundingBox">');

  sb.write('<path transform="scale($scaleX, $scaleY)" fill="#FFFFFF" d="');
  pathToSvg(path, sb, offsetX: offsetX, offsetY: offsetY);
  sb.write('"></path></clipPath></defs></svg');
  return sb.toString();
}

/// Converts color to a css compatible attribute value.
String colorToCssString(ui.Color color) {
  if (color == null) {
    return null;
  }
  final int value = color.value;
  if ((0xff000000 & value) == 0xff000000) {
    final String hexValue = (value & 0xFFFFFF).toRadixString(16);
    final int hexValueLength = hexValue.length;
    switch (hexValueLength) {
      case 1:
        return '#00000$hexValue';
      case 2:
        return '#0000$hexValue';
      case 3:
        return '#000$hexValue';
      case 4:
        return '#00$hexValue';
      case 5:
        return '#0$hexValue';
      default:
        return '#$hexValue';
    }
  } else {
    final double alpha = ((value >> 24) & 0xFF) / 255.0;
    final StringBuffer sb = StringBuffer();
    sb.write('rgba(');
    sb.write(((value >> 16) & 0xFF).toString());
    sb.write(',');
    sb.write(((value >> 8) & 0xFF).toString());
    sb.write(',');
    sb.write((value & 0xFF).toString());
    sb.write(',');
    sb.write(alpha.toString());
    sb.write(')');
    return sb.toString();
  }
}

/// Converts color components to a CSS compatible attribute value.
String colorComponentsToCssString(int r, int g, int b, int a) {
  if (a == 255) {
    return 'rgb($r,$g,$b)';
  } else {
    final double alphaRatio = a / 255;
    return 'rgba($r,$g,$b,${alphaRatio.toStringAsFixed(2)})';
  }
}

/// Determines if the (dynamic) exception passed in is a NS_ERROR_FAILURE
/// (from Firefox).
///
/// NS_ERROR_FAILURE (0x80004005) is the most general of all the (Firefox)
/// errors and occurs for all errors for which a more specific error code does
/// not apply. (https://developer.mozilla.org/en-US/docs/Mozilla/Errors)
///
/// Other browsers do not throw this exception.
///
/// In Flutter, this exception happens when we try to perform some operations on
/// a Canvas when the application is rendered in a display:none iframe.
///
/// We need this in [BitmapCanvas] and [RecordingCanvas] to swallow this
/// Firefox exception without interfering with others (potentially useful
/// for the programmer).
bool _isNsErrorFailureException(dynamic e) {
  return js_util.getProperty(e, 'name') == 'NS_ERROR_FAILURE';
}

/// From: https://developer.mozilla.org/en-US/docs/Web/CSS/font-family#Syntax
///
/// Generic font families are a fallback mechanism, a means of preserving some
/// of the style sheet author's intent when none of the specified fonts are
/// available. Generic family names are keywords and must not be quoted. A
/// generic font family should be the last item in the list of font family
/// names.
const Set<String> _genericFontFamilies = <String>{
  'serif',
  'sans-serif',
  'monospace',
  'cursive',
  'fantasy',
  'system-ui',
  'math',
  'emoji',
  'fangsong',
};

/// A default fallback font family in case an unloaded font has been requested.
///
/// For iOS, default to Helvetica, where it should be available, otherwise
/// default to Arial.
final String _fallbackFontFamily =
    operatingSystem == OperatingSystem.iOs ? 'Helvetica' : 'Arial';

/// Create a font-family string appropriate for CSS.
///
/// If the given [fontFamily] is a generic font-family, then just return it.
/// Otherwise, wrap the family name in quotes and add a fallback font family.
String canonicalizeFontFamily(String fontFamily) {
  if (_genericFontFamilies.contains(fontFamily)) {
    return fontFamily;
  }
  return '"$fontFamily", $_fallbackFontFamily, sans-serif';
}

/// Converts a list of [Offset] to a typed array of floats.
Float32List offsetListToFloat32List(List<ui.Offset> offsetList) {
  if (offsetList == null) {
    return null;
  }
  final int length = offsetList.length;
  final floatList = Float32List(length * 2);
  for (int i = 0, destIndex = 0; i < length; i++, destIndex += 2) {
    floatList[destIndex] = offsetList[i].dx;
    floatList[destIndex + 1] = offsetList[i].dy;
  }
  return floatList;
}

/// Apply this function to container elements in the HTML render tree (this is
/// not relevant to semantics tree).
///
/// On WebKit browsers this will apply `z-order: 0` to ensure that clips are
/// applied correctly. Otherwise, the browser will refuse to clip its contents.
///
/// Other possible fixes that were rejected:
///
/// * Use 3D transform instead of 2D: this does not work because it causes text
///   blurriness: https://github.com/flutter/flutter/issues/32274
void applyWebkitClipFix(html.Element containerElement) {
  if (browserEngine == BrowserEngine.webkit) {
    containerElement.style.zIndex = '0';
  }
}

final ByteData _fontChangeMessage = JSONMessageCodec().encodeMessage(<String, dynamic>{'type': 'fontsChange'});

// Font load callbacks will typically arrive in sequence, we want to prevent
// sendFontChangeMessage of causing multiple synchronous rebuilds.
// This flag ensures we properly schedule a single call to framework.
bool _fontChangeScheduled = false;

FutureOr<void> sendFontChangeMessage() async {
  if (window._onPlatformMessage != null)
    if (!_fontChangeScheduled) {
      _fontChangeScheduled = true;
      // Batch updates into next animationframe.
      html.window.requestAnimationFrame((num _) {
        _fontChangeScheduled = false;
        window.invokeOnPlatformMessage(
          'flutter/system',
          _fontChangeMessage,
              (_) {},
        );
      });
    }
}
