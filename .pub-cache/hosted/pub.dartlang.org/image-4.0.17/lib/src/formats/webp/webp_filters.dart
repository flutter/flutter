import 'dart:typed_data';

import '../../util/_internal.dart';
import '../../util/input_buffer.dart';

@internal
class WebPFilters {
  // Filters.
  static const filterNone = 0;
  static const filterHorizontal = 1;
  static const filterVertical = 2;
  static const fitlerGradient = 3;
  static const fitlerLast = fitlerGradient + 1; // end marker
  static const fitlerBest = 5;
  static const filterFast = 6;

  static const filters = [
    null, // WEBP_FILTER_NONE
    horizontalFilter, // WEBP_FILTER_HORIZONTAL
    verticalFilter, // WEBP_FILTER_VERTICAL
    gradientFilter // WEBP_FILTER_GRADIENT
  ];

  static const unfilters = [
    null, // WEBP_FILTER_NONE
    horizontalUnfilter, // WEBP_FILTER_HORIZONTAL
    verticalUnfilter, // WEBP_FILTER_VERTICAL
    gradientUnfilter // WEBP_FILTER_GRADIENT
  ];

  static void horizontalFilter(Uint8List data, int width, int height,
      int stride, Uint8List filteredData) {
    _doHorizontalFilter(
        data, width, height, stride, 0, height, false, filteredData);
  }

  static void horizontalUnfilter(
      int width, int height, int stride, int row, int numRows, Uint8List data) {
    _doHorizontalFilter(data, width, height, stride, row, numRows, true, data);
  }

  static void verticalFilter(Uint8List data, int width, int height, int stride,
      Uint8List filteredData) {
    _doVerticalFilter(
        data, width, height, stride, 0, height, false, filteredData);
  }

  static void verticalUnfilter(
      int width, int height, int stride, int row, int numRows, Uint8List data) {
    _doVerticalFilter(data, width, height, stride, row, numRows, true, data);
  }

  static void gradientFilter(Uint8List data, int width, int height, int stride,
      Uint8List filteredData) {
    _doGradientFilter(
        data, width, height, stride, 0, height, false, filteredData);
  }

  static void gradientUnfilter(
      int width, int height, int stride, int row, int numRows, Uint8List data) {
    _doGradientFilter(data, width, height, stride, row, numRows, true, data);
  }

  static void _predictLine(InputBuffer src, InputBuffer pred, InputBuffer dst,
      int length, bool inverse) {
    if (inverse) {
      for (var i = 0; i < length; ++i) {
        dst[i] = src[i] + pred[i];
      }
    } else {
      for (var i = 0; i < length; ++i) {
        dst[i] = src[i] - pred[i];
      }
    }
  }

  static void _doHorizontalFilter(Uint8List src, int width, int height,
      int stride, int row, int numRows, bool inverse, Uint8List out) {
    final startOffset = row * stride;
    final lastRow = row + numRows;
    final s = InputBuffer(src, offset: startOffset);
    final o = InputBuffer(src, offset: startOffset);
    final preds = InputBuffer.from(inverse ? o : s);

    if (row == 0) {
      // Leftmost pixel is the same as input for topmost scanline.
      o[0] = s[0];
      _predictLine(InputBuffer.from(s, offset: 1), preds,
          InputBuffer.from(o, offset: 1), width - 1, inverse);
      row = 1;
      preds.offset += stride;
      s.offset += stride;
      o.offset += stride;
    }

    // Filter line-by-line.
    while (row < lastRow) {
      // Leftmost pixel is predicted from above.
      _predictLine(s, InputBuffer.from(preds, offset: -stride), o, 1, inverse);
      _predictLine(InputBuffer.from(s, offset: 1), preds,
          InputBuffer.from(o, offset: 1), width - 1, inverse);
      ++row;
      preds.offset += stride;
      s.offset += stride;
      o.offset += stride;
    }
  }

  static void _doVerticalFilter(Uint8List src, int width, int height,
      int stride, int row, int numRows, bool inverse, Uint8List out) {
    final startOffset = row * stride;
    final lastRow = row + numRows;
    final s = InputBuffer(src, offset: startOffset);
    final o = InputBuffer(out, offset: startOffset);
    final preds = InputBuffer.from(inverse ? o : s);

    if (row == 0) {
      // Very first top-left pixel is copied.
      o[0] = s[0];
      // Rest of top scan-line is left-predicted.
      _predictLine(InputBuffer.from(s, offset: 1), preds,
          InputBuffer.from(o, offset: 1), width - 1, inverse);
      row = 1;
      s.offset += stride;
      o.offset += stride;
    } else {
      // We are starting from in-between. Make sure 'preds' points to prev row.
      preds.offset -= stride;
    }

    // Filter line-by-line.
    while (row < lastRow) {
      _predictLine(s, preds, o, width, inverse);
      ++row;
      preds.offset += stride;
      s.offset += stride;
      o.offset += stride;
    }
  }

  static int _gradientPredictor(int a, int b, int c) {
    final g = a + b - c;
    return ((g & ~0xff) == 0)
        ? g
        : (g < 0)
            ? 0
            : 255; // clip to 8bit
  }

  static void _doGradientFilter(Uint8List src, int width, int height,
      int stride, int row, int numRows, bool inverse, Uint8List out) {
    final startOffset = row * stride;
    final lastRow = row + numRows;
    final s = InputBuffer(src, offset: startOffset);
    final o = InputBuffer(out, offset: startOffset);
    final preds = InputBuffer.from(inverse ? o : s);

    // left prediction for top scan-line
    if (row == 0) {
      o[0] = s[0];
      _predictLine(InputBuffer.from(s, offset: 1), preds,
          InputBuffer.from(o, offset: 1), width - 1, inverse);
      row = 1;
      preds.offset += stride;
      s.offset += stride;
      o.offset += stride;
    }

    // Filter line-by-line.
    while (row < lastRow) {
      // leftmost pixel: predict from above.
      _predictLine(s, InputBuffer.from(preds, offset: -stride), o, 1, inverse);
      for (var w = 1; w < width; ++w) {
        final pred = _gradientPredictor(
            preds[w - 1], preds[w - stride], preds[w - stride - 1]);
        o[w] = s[w] + (inverse ? pred : -pred);
      }
      ++row;
      preds.offset += stride;
      s.offset += stride;
      o.offset += stride;
    }
  }

  // DartAnalyzer doesn't like classes with only static members now, so
  // I added this member for now to avoid the warnings.
  var fixWarnings = 0;
}
