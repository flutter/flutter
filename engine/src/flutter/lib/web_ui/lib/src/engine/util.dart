// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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

/// Returns `true` is the [matrix] describes an identity transformation.
bool isIdentityFloat64ListTransform(Float64List matrix) {
  assert(matrix.length == 16);
  final Float64List m = matrix;
  return m[0] == 1.0 &&
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
      m[12] == 0.0 &&
      m[13] == 0.0 &&
      m[14] == 0.0 &&
      m[15] == 1.0;
}

/// Converts [matrix] to CSS transform value.
String float64ListToCssTransform(Float64List matrix) {
  assert(matrix.length == 16);
  final Float64List m = matrix;
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
    return 'translate(${tx}px, ${ty}px)';
  } else {
    return 'matrix3d(${m[0]},${m[1]},${m[2]},${m[3]},${m[4]},${m[5]},${m[6]},${m[7]},${m[8]},${m[9]},${m[10]},${m[11]},${m[12]},${m[13]},${m[14]},${m[15]})';
  }
}

bool get assertionsEnabled {
  bool k = false;
  assert(k = true);
  return k;
}

/// Transforms a [ui.Rect] given the effective [transform].
///
/// The resulting rect is aligned to the pixel grid, i.e. two of
/// its sides are vertical and two are horizontal. In the presence of rotations
/// the rectangle is inflated such that it fits the rotated rectangle.
ui.Rect transformRect(Matrix4 transform, ui.Rect rect) {
  return transformLTRB(transform, rect.left, rect.top, rect.right, rect.bottom);
}

/// Transforms a rectangle given the effective [transform].
///
/// This is the same as [transformRect], except that the rect is specified
/// in terms of left, top, right, and bottom edge offsets.
ui.Rect transformLTRB(
    Matrix4 transform, double left, double top, double right, double bottom) {
  assert(left != null);
  assert(top != null);
  assert(right != null);
  assert(bottom != null);

  // Construct a matrix where each row represents a vector pointing at
  // one of the four corners of the (left, top, right, bottom) rectangle.
  // Using the row-major order allows us to multiply the matrix in-place
  // by the transposed current transformation matrix. The vector_math
  // library has a convenience function `multiplyTranspose` that performs
  // the multiplication without copying. This way we compute the positions
  // of all four points in a single matrix-by-matrix multiplication at the
  // cost of one `Matrix4` instance and one `Float64List` instance.
  //
  // The rejected alternative was to use `Vector3` for each point and
  // multiply by the current transform. However, that would cost us four
  // `Vector3` instances, four `Float64List` instances, and four
  // matrix-by-vector multiplications.
  //
  // `Float64List` initializes the array with zeros, so we do not have to
  // fill in every single element.
  final Float64List pointData = Float64List(16);

  // Row 0: top-left
  pointData[0] = left;
  pointData[4] = top;
  pointData[12] = 1;

  // Row 1: top-right
  pointData[1] = right;
  pointData[5] = top;
  pointData[13] = 1;

  // Row 2: bottom-left
  pointData[2] = left;
  pointData[6] = bottom;
  pointData[14] = 1;

  // Row 3: bottom-right
  pointData[3] = right;
  pointData[7] = bottom;
  pointData[15] = 1;

  final Matrix4 pointMatrix = Matrix4.fromFloat64List(pointData);
  pointMatrix.multiplyTranspose(transform);

  return ui.Rect.fromLTRB(
    math.min(math.min(math.min(pointData[0], pointData[1]), pointData[2]),
        pointData[3]),
    math.min(math.min(math.min(pointData[4], pointData[5]), pointData[6]),
        pointData[7]),
    math.max(math.max(math.max(pointData[0], pointData[1]), pointData[2]),
        pointData[3]),
    math.max(math.max(math.max(pointData[4], pointData[5]), pointData[6]),
        pointData[7]),
  );
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
    {double offsetX = 0, double offsetY = 0}) {
  _clipIdCounter += 1;
  final ui.Rect bounds = path.getBounds();
  final StringBuffer sb = StringBuffer();
  sb.write('<svg width="${bounds.right}" height="${bounds.bottom}" '
      'style="position:absolute">');
  sb.write('<defs>');

  final String clipId = 'svgClip$_clipIdCounter';
  sb.write('<clipPath id=$clipId>');

  sb.write('<path fill="#FFFFFF" d="');
  pathToSvg(path, sb, offsetX: offsetX, offsetY: offsetY);
  sb.write('"></path></clipPath></defs></svg');
  return sb.toString();
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
