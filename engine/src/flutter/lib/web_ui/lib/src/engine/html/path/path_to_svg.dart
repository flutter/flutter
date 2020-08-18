// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.10
part of engine;

/// Converts [path] to SVG path syntax to be used as "d" attribute in path
/// element.
void pathToSvg(SurfacePath path, StringBuffer sb,
    {double offsetX = 0, double offsetY = 0}) {
  final PathRefIterator iter = PathRefIterator(path.pathRef);
  int verb = 0;
  final Float32List outPts = Float32List(PathRefIterator.kMaxBufferSize);
  while ((verb = iter.next(outPts)) != SPath.kDoneVerb) {
    switch (verb) {
      case SPath.kMoveVerb:
        sb.write('M ${outPts[0] + offsetX} ${outPts[1] + offsetY}');
        break;
      case SPath.kLineVerb:
        sb.write('L ${outPts[2] + offsetX} ${outPts[3] + offsetY}');
        break;
      case SPath.kCubicVerb:
        sb.write('C ${outPts[2] + offsetX} ${outPts[3] + offsetY} '
            '${outPts[4] + offsetX} ${outPts[5] + offsetY} ${outPts[6] + offsetX} ${outPts[7] + offsetY}');
        break;
      case SPath.kQuadVerb:
        sb.write('Q ${outPts[2] + offsetX} ${outPts[3] + offsetY} '
            '${outPts[4] + offsetX} ${outPts[5] + offsetY}');
        break;
      case SPath.kConicVerb:
        final double w = iter.conicWeight;
        Conic conic = Conic(outPts[0], outPts[1], outPts[2], outPts[3],
            outPts[4], outPts[5], w);
        List<ui.Offset> points = conic.toQuads();
        final int len = points.length;
        for (int i = 1; i < len; i += 2) {
          final double p1x = points[i].dx;
          final double p1y = points[i].dy;
          final double p2x = points[i + 1].dx;
          final double p2y = points[i + 1].dy;
          sb.write('Q ${p1x + offsetX} ${p1y + offsetY} '
              '${p2x + offsetX} ${p2y + offsetY}');
        }
        break;
      case SPath.kCloseVerb:
        sb.write('Z');
        break;
      default:
        throw UnimplementedError('Unknown path verb $verb');
    }
  }
}
