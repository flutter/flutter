import 'dart:typed_data';

import '../color.dart';
import '../image.dart';

typedef _TestPixel = bool Function(int y, int x);
typedef _MarkPixel = void Function(int y, int x);

/// Fill the 4-connected shape containing [x],[y] in the image [src] with the
/// given [color].
Image fillFlood(Image src, int x, int y, int color,
    {num threshold = 0.0, bool compareAlpha = false}) {
  final visited = Uint8List(src.width * src.height);

  var srcColor = src.getPixel(x, y);
  if (!compareAlpha) {
    srcColor = setAlpha(srcColor, 0);
  }

  _TestPixel array;
  if (threshold > 0) {
    final lab =
        rgbToLab(getRed(srcColor), getGreen(srcColor), getBlue(srcColor));
    if (compareAlpha) {
      lab.add(getAlpha(srcColor).toDouble());
    }

    array = (int y, int x) =>
        visited[y * src.width + x] == 0 &&
        _testPixelLabColorDistance(src, x, y, lab, threshold);
  } else if (!compareAlpha) {
    array = (int y, int x) =>
        visited[y * src.width + x] == 0 &&
        setAlpha(src.getPixel(x, y), 0) != srcColor;
  } else {
    array = (int y, int x) =>
        visited[y * src.width + x] == 0 && src.getPixel(x, y) != srcColor;
  }

  void mark(int y, int x) {
    src.setPixel(x, y, color);
    visited[y * src.width + x] = 1;
  }

  _fill4(src, x, y, array, mark, visited);
  return src;
}

/// Create a mask describing the 4-connected shape containing [x],[y] in the
/// image [src].
Uint8List maskFlood(Image src, int x, int y,
    {num threshold = 0.0, bool compareAlpha = false, int fillValue = 255}) {
  final visited = Uint8List(src.width * src.height);

  var srcColor = src.getPixel(x, y);
  if (!compareAlpha) {
    srcColor = setAlpha(srcColor, 0);
  }

  final ret = Uint8List(src.width * src.height);

  _TestPixel array;
  if (threshold > 0) {
    final lab =
        rgbToLab(getRed(srcColor), getGreen(srcColor), getBlue(srcColor));

    if (compareAlpha) {
      lab.add(getAlpha(srcColor).toDouble());
    }

    array = (int y, int x) =>
        visited[y * src.width + x] == 0 &&
        (ret[y * src.width + x] != 0 ||
            _testPixelLabColorDistance(src, x, y, lab, threshold));
  } else if (!compareAlpha) {
    array = (int y, int x) =>
        visited[y * src.width + x] == 0 &&
        (ret[y * src.width + x] != 0 ||
            setAlpha(src.getPixel(x, y), 0) != srcColor);
  } else {
    array = (int y, int x) =>
        visited[y * src.width + x] == 0 &&
        (ret[y * src.width + x] != 0 || src.getPixel(x, y) != srcColor);
  }

  void mark(int y, int x) {
    ret[y * src.width + x] = fillValue;
    visited[y * src.width + x] = 1;
  }

  _fill4(src, x, y, array, mark, visited);
  return ret;
}

bool _testPixelLabColorDistance(
    Image src, int x, int y, List<num> refColor, num threshold) {
  final pixel = src.getPixel(x, y);
  final compareAlpha = refColor.length > 3;
  final pixelColor = rgbToLab(getRed(pixel), getGreen(pixel), getBlue(pixel));
  if (compareAlpha) {
    pixelColor.add(getAlpha(pixel).toDouble());
  }

  return Color.distance(pixelColor, refColor, compareAlpha) > threshold;
}

// Adam Milazzo (2015). A More Efficient Flood Fill.
// http://www.adammil.net/blog/v126_A_More_Efficient_Flood_Fill.html
void _fill4(Image src, int x, int y, _TestPixel array, _MarkPixel mark,
    Uint8List visited) {
  if (visited[y * src.width + x] == 1) {
    return;
  }

  // at this point, we know array(y,x) is clear, and we want to move as far as
  // possible to the upper-left. moving up is much more important than moving
  // left, so we could try to make this smarter by sometimes moving to the
  // right if doing so would allow us to move further up, but it doesn't seem
  // worth the complexity
  while (true) {
    final ox = x;
    final oy = y;
    while (y != 0 && !array(y - 1, x)) {
      y--;
    }
    while (x != 0 && !array(y, x - 1)) {
      x--;
    }
    if (x == ox && y == oy) {
      break;
    }
  }
  _fill4Core(src, x, y, array, mark, visited);
}

void _fill4Core(Image src, int x, int y, _TestPixel array, _MarkPixel mark,
    Uint8List visited) {
  if (visited[y * src.width + x] == 1) {
    return;
  }
  // at this point, we know that array(y,x) is clear, and array(y-1,x) and
  // array(y,x-1) are set. We'll begin scanning down and to the right,
  // attempting to fill an entire rectangular block

  // the number of cells that were clear in the last row we scanned
  var lastRowLength = 0;

  do {
    var rowLength = 0;
    var sx = x;
    // keep track of how long this row is. sx is the starting x for the main
    // scan below now we want to handle a case like |***|, where we fill 3
    // cells in the first row and then after we move to the second row we find
    // the first  | **| cell is filled, ending our rectangular scan. rather
    // than handling this via the recursion below, we'll increase the starting
    // value of 'x' and reduce the last row length to match. then we'll continue
    // trying to set the narrower rectangular block
    if (lastRowLength != 0 && array(y, x)) {
      // if this is not the first row and the leftmost cell is filled...
      do {
        if (--lastRowLength == 0) {
          return; // shorten the row. if it's full, we're done
        }
        // otherwise, update the starting point of the main scan to match
      } while (array(y, ++x));
      sx = x;
    } else {
      // we also want to handle the opposite case, | **|, where we begin
      // scanning a 2-wide rectangular block and then find on the next row that
      // it has |***| gotten wider on the left. again, we could handle this
      // with recursion but we'd prefer to adjust x and lastRowLength instead
      for (; x != 0 && !array(y, x - 1); rowLength++, lastRowLength++) {
        mark(y, --x);
        // to avoid scanning the cells twice, we'll fill them and update
        // rowLength here if there's something above the new starting point,
        // handle that recursively. this deals with cases like |* **| when we
        // begin filling from (2,0), move down to (2,1), and then move left to
        // (0,1). The  |****| main scan assumes the portion of the previous row
        // from x to x+lastRowLength has already been filled. adjusting x and
        // lastRowLength breaks that assumption in this case, so we must fix it
        if (y != 0 && !array(y - 1, x)) {
          // use _Fill since there may be more up and left
          _fill4(src, x, y - 1, array, mark, visited);
        }
      }
    }

    // now at this point we can begin to scan the current row in the rectangular
    // block. the span of the previous row from x (inclusive) to x+lastRowLength
    // (exclusive) has already been filled, so we don't need to
    // check it. so scan across to the right in the current row
    for (; sx < src.width && !array(y, sx); rowLength++, sx++) {
      mark(y, sx);
    }
    // now we've scanned this row. if the block is rectangular, then the
    // previous row has already been scanned, so we don't need to look upwards
    // and we're going to scan the next row in the next iteration so we don't
    // need to look downwards. however, if the block is not rectangular, we may
    // need to look upwards or rightwards for some portion of the row. if this
    // row was shorter than the last row, we may need to look rightwards near
    // the end, as in the case of |*****|, where the first row is 5 cells long
    // and the second row is 3 cells long. We must look to the right  |*** *|
    // of the single cell at the end of the second row, i.e. at (4,1)
    if (rowLength < lastRowLength) {
      // 'end' is the end of the previous row, so scan the current row to
      for (final end = x + lastRowLength; ++sx < end;) {
        // there. any clear cells would have been connected to the previous
        if (!array(y, sx)) {
          // row. the cells up and left must be set so use FillCore
          _fill4Core(src, sx, y, array, mark, visited);
        }
      }
    }
    // alternately, if this row is longer than the previous row, as in the case
    // |*** *| then we must look above the end of the row, i.e at (4,0)
    // |*****|
    else if (rowLength > lastRowLength && y != 0) {
      // if this row is longer and we're not already at the top...
      for (var ux = x + lastRowLength; ++ux < sx;) {
        // sx is the end of the current row
        if (!array(y - 1, ux)) {
          // since there may be clear cells up and left, use _Fill
          _fill4(src, ux, y - 1, array, mark, visited);
        }
      }
    }
    lastRowLength = rowLength; // record the new row length
    // if we get to a full row or to the bottom, we're done
  } while (lastRowLength != 0 && ++y < src.height);
}
