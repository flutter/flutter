/// Clip a line to a rectangle using the Cohen–Sutherland clipping algorithm.
/// [line] is a list of 4 ints <x1, y1, x2, y2>.
/// [rect] is a list of 4 ints <x1, y1, x2, y2>.
/// Results are stored in [line].
/// If [line] falls completely outside of [rect], false is returned, otherwise
/// true is returned.

bool clipLine(List<int> line, List<int> rect) {
  var x0 = line[0];
  var y0 = line[1];
  var x1 = line[2];
  var y1 = line[3];
  final xmin = rect[0];
  final ymin = rect[1];
  final xmax = rect[2];
  final ymax = rect[3];

  const INSIDE = 0; // 0000
  const LEFT = 1; // 0001
  const RIGHT = 2; // 0010
  const BOTTOM = 4; // 0100
  const TOP = 8; // 1000

  // Compute the bit code for a point (x, y) using the clip rectangle
  // bounded diagonally by (xmin, ymin), and (xmax, ymax)
  int _computeOutCode(int x, int y) {
    var code = INSIDE; // initialised as being inside of clip window
    if (x < xmin) {
      // to the left of clip window
      code |= LEFT;
    } else if (x > xmax) {
      // to the right of clip window
      code |= RIGHT;
    }

    if (y < ymin) {
      // below the clip window
      code |= BOTTOM;
    } else if (y > ymax) {
      // above the clip window
      code |= TOP;
    }

    return code;
  }

  // compute outcodes for P0, P1, and whatever point lies outside the clip
  // rectangle
  var outcode0 = _computeOutCode(x0, y0);
  var outcode1 = _computeOutCode(x1, y1);
  var accept = false;

  while (true) {
    if ((outcode0 | outcode1) == 0) {
      // Bitwise OR is 0. Trivially accept and get out of loop
      accept = true;
      break;
    } else if ((outcode0 & outcode1) != 0) {
      // Bitwise AND is not 0. Trivially reject and get out of loop
      break;
    } else {
      // failed both tests, so calculate the line segment to clip
      // from an outside point to an intersection with clip edge

      // At least one endpoint is outside the clip rectangle; pick it.
      final outcodeOut = outcode0 != 0 ? outcode0 : outcode1;

      int? x, y;
      // Now find the intersection point;
      // use formulas y = y0 + slope * (x - x0), x = x0 + (1 / slope) * (y - y0)
      if ((outcodeOut & TOP) != 0) {
        // point is above the clip rectangle
        x = x0 + (x1 - x0) * (ymax - y0) ~/ (y1 - y0);
        y = ymax;
      } else if ((outcodeOut & BOTTOM) != 0) {
        // point is below the clip rectangle
        x = x0 + (x1 - x0) * (ymin - y0) ~/ (y1 - y0);
        y = ymin;
      } else if ((outcodeOut & RIGHT) != 0) {
        // point is to the right of clip rectangle
        y = y0 + (y1 - y0) * (xmax - x0) ~/ (x1 - x0);
        x = xmax;
      } else if ((outcodeOut & LEFT) != 0) {
        // point is to the left of clip rectangle
        y = y0 + (y1 - y0) * (xmin - x0) ~/ (x1 - x0);
        x = xmin;
      }

      // Now we move outside point to intersection point to clip
      // and get ready for next pass.
      if (outcodeOut == outcode0) {
        x0 = x!;
        y0 = y!;
        outcode0 = _computeOutCode(x0, y0);
      } else {
        x1 = x!;
        y1 = y!;
        outcode1 = _computeOutCode(x1, y1);
      }
    }
  }

  line[0] = x0;
  line[1] = y0;
  line[2] = x1;
  line[3] = y1;

  return accept;
}
