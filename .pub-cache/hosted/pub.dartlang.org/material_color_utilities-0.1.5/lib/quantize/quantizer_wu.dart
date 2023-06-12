// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// ignore_for_file: omit_local_variable_types
// rationale: This library relies heavily on numeric computation, and a key
// requirement is that it is 'the same' as implementations in different
// languages. Including variable types, though sometimes unnecessary, is a
// powerful help to verification and avoiding hard-to-debug issues.

import 'package:material_color_utilities/utils/color_utils.dart';

import 'quantizer.dart';
import 'quantizer_map.dart';

class QuantizerWu implements Quantizer {
  List<int> weights = <int>[];
  List<int> momentsR = <int>[];
  List<int> momentsG = <int>[];
  List<int> momentsB = <int>[];
  List<double> moments = <double>[];
  List<Box> cubes = <Box>[];

  // A histogram of all the input colors is constructed. It has the shape of a
  // cube. The cube would be too large if it contained all 16 million colors:
  // historical best practice is to use 5 bits  of the 8 in each channel,
  // reducing the histogram to a volume of ~32,000.
  static const indexBits = 5;
  static final maxIndex = 32;
  static final sideLength = 33;
  static final totalSize = 35937;

  @override
  Future<QuantizerResult> quantize(Iterable<int> pixels, int colorCount) async {
    final result = await QuantizerMap().quantize(pixels, colorCount);
    constructHistogram(result.colorToCount);
    computeMoments();
    final createBoxesResult = createBoxes(colorCount);
    final results = createResult(createBoxesResult.resultCount);
    return QuantizerResult(Map.fromEntries(results.map((e) => MapEntry(e, 0))));
  }

  static int getIndex(int r, int g, int b) {
    return (r << (indexBits * 2)) +
        (r << (indexBits + 1)) +
        (g << indexBits) +
        r +
        g +
        b;
  }

  void constructHistogram(Map<int, int> pixels) {
    weights = List.filled(totalSize, 0, growable: false);
    momentsR = List.filled(totalSize, 0, growable: false);
    momentsG = List.filled(totalSize, 0, growable: false);
    momentsB = List.filled(totalSize, 0, growable: false);
    moments = List.filled(totalSize, 0, growable: false);
    for (var entry in pixels.entries) {
      final pixel = entry.key;
      final count = entry.value;
      final red = ColorUtils.redFromArgb(pixel);
      final green = ColorUtils.greenFromArgb(pixel);
      final blue = ColorUtils.blueFromArgb(pixel);
      final bitsToRemove = 8 - indexBits;
      final iR = (red >> bitsToRemove) + 1;
      final iG = (green >> bitsToRemove) + 1;
      final iB = (blue >> bitsToRemove) + 1;
      final index = getIndex(iR, iG, iB);
      weights[index] += count;
      momentsR[index] += (red * count);
      momentsG[index] += (green * count);
      momentsB[index] += (blue * count);
      moments[index] +=
          (count * ((red * red) + (green * green) + (blue * blue)));
    }
  }

  void computeMoments() {
    for (var r = 1; r < sideLength; ++r) {
      List<int> area = List.filled(sideLength, 0, growable: false);
      List<int> areaR = List.filled(sideLength, 0, growable: false);
      List<int> areaG = List.filled(sideLength, 0, growable: false);
      List<int> areaB = List.filled(sideLength, 0, growable: false);
      List<double> area2 = List.filled(sideLength, 0.0, growable: false);
      for (var g = 1; g < sideLength; g++) {
        int line = 0;
        int lineR = 0;
        int lineG = 0;
        int lineB = 0;
        double line2 = 0.0;
        for (var b = 1; b < sideLength; b++) {
          int index = getIndex(r, g, b);
          line += weights[index];
          lineR += momentsR[index];
          lineG += momentsG[index];
          lineB += momentsB[index];
          line2 += moments[index];

          area[b] += line;
          areaR[b] += lineR;
          areaG[b] += lineG;
          areaB[b] += lineB;
          area2[b] += line2;

          int previousIndex = getIndex(r - 1, g, b);
          weights[index] = weights[previousIndex] + area[b];
          momentsR[index] = momentsR[previousIndex] + areaR[b];
          momentsG[index] = momentsG[previousIndex] + areaG[b];
          momentsB[index] = momentsB[previousIndex] + areaB[b];
          moments[index] = moments[previousIndex] + area2[b];
        }
      }
    }
  }

  CreateBoxesResult createBoxes(int maxColorCount) {
    cubes = List<Box>.generate(maxColorCount, (index) => Box());
    cubes[0] = Box(
        r0: 0, r1: maxIndex, g0: 0, g1: maxIndex, b0: 0, b1: maxIndex, vol: 0);

    List<double> volumeVariance =
        List.filled(maxColorCount, 0.0, growable: false);
    int next = 0;
    int generatedColorCount = maxColorCount;
    for (int i = 1; i < maxColorCount; i++) {
      if (cut(cubes[next], cubes[i])) {
        volumeVariance[next] =
            (cubes[next].vol > 1) ? variance(cubes[next]) : 0.0;
        volumeVariance[i] = (cubes[i].vol > 1) ? variance(cubes[i]) : 0.0;
      } else {
        volumeVariance[next] = 0.0;
        i--;
      }

      next = 0;
      double temp = volumeVariance[0];
      for (var j = 1; j <= i; j++) {
        if (volumeVariance[j] > temp) {
          temp = volumeVariance[j];
          next = j;
        }
      }
      if (temp <= 0.0) {
        generatedColorCount = i + 1;
        break;
      }
    }

    return CreateBoxesResult(
        requestedCount: maxColorCount, resultCount: generatedColorCount);
  }

  List<int> createResult(int colorCount) {
    List<int> colors = <int>[];
    for (int i = 0; i < colorCount; ++i) {
      final cube = cubes[i];
      int weight = volume(cube, weights);
      if (weight > 0) {
        int r = (volume(cube, momentsR) / weight).round();
        int g = (volume(cube, momentsG) / weight).round();
        int b = (volume(cube, momentsB) / weight).round();
        int color = ColorUtils.argbFromRgb(r, g, b);
        colors.add(color);
      }
    }
    return colors;
  }

  double variance(Box cube) {
    final dr = volume(cube, momentsR);
    final dg = volume(cube, momentsG);
    final db = volume(cube, momentsB);
    final xx = moments[getIndex(cube.r1, cube.g1, cube.b1)] -
        moments[getIndex(cube.r1, cube.g1, cube.b0)] -
        moments[getIndex(cube.r1, cube.g0, cube.b1)] +
        moments[getIndex(cube.r1, cube.g0, cube.b0)] -
        moments[getIndex(cube.r0, cube.g1, cube.b1)] +
        moments[getIndex(cube.r0, cube.g1, cube.b0)] +
        moments[getIndex(cube.r0, cube.g0, cube.b1)] -
        moments[getIndex(cube.r0, cube.g0, cube.b0)];

    final hypotenuse = (dr * dr + dg * dg + db * db);
    final volume_ = volume(cube, weights);
    return xx - hypotenuse / volume_;
  }

  bool cut(Box one, Box two) {
    final wholeR = volume(one, momentsR);
    final wholeG = volume(one, momentsG);
    final wholeB = volume(one, momentsB);
    final wholeW = volume(one, weights);

    final maxRResult = maximize(
        one, Direction.red, one.r0 + 1, one.r1, wholeR, wholeG, wholeB, wholeW);
    final maxGResult = maximize(one, Direction.green, one.g0 + 1, one.g1,
        wholeR, wholeG, wholeB, wholeW);
    final maxBResult = maximize(one, Direction.blue, one.b0 + 1, one.b1, wholeR,
        wholeG, wholeB, wholeW);

    Direction cutDirection;
    final maxR = maxRResult.maximum;
    final maxG = maxGResult.maximum;
    final maxB = maxBResult.maximum;
    if (maxR >= maxG && maxR >= maxB) {
      cutDirection = Direction.red;
      if (maxRResult.cutLocation < 0) {
        return false;
      }
    } else if (maxG >= maxR && maxG >= maxB) {
      cutDirection = Direction.green;
    } else {
      cutDirection = Direction.blue;
    }

    two.r1 = one.r1;
    two.g1 = one.g1;
    two.b1 = one.b1;

    switch (cutDirection) {
      case Direction.red:
        one.r1 = maxRResult.cutLocation;
        two.r0 = one.r1;
        two.g0 = one.g0;
        two.b0 = one.b0;
        break;
      case Direction.green:
        one.g1 = maxGResult.cutLocation;
        two.r0 = one.r0;
        two.g0 = one.g1;
        two.b0 = one.b0;
        break;
      case Direction.blue:
        one.b1 = maxBResult.cutLocation;
        two.r0 = one.r0;
        two.g0 = one.g0;
        two.b0 = one.b1;
        break;
      default:
        throw 'unexpected direction $cutDirection';
    }

    one.vol = (one.r1 - one.r0) * (one.g1 - one.g0) * (one.b1 - one.b0);
    two.vol = (two.r1 - two.r0) * (two.g1 - two.g0) * (two.b1 - two.b0);
    return true;
  }

  MaximizeResult maximize(Box cube, Direction direction, int first, int last,
      int wholeR, int wholeG, int wholeB, int wholeW) {
    int bottomR = bottom(cube, direction, momentsR);
    int bottomG = bottom(cube, direction, momentsG);
    int bottomB = bottom(cube, direction, momentsB);
    int bottomW = bottom(cube, direction, weights);

    double max = 0.0;
    int cut = -1;

    for (int i = first; i < last; i++) {
      int halfR = bottomR + top(cube, direction, i, momentsR);
      int halfG = bottomG + top(cube, direction, i, momentsG);
      int halfB = bottomB + top(cube, direction, i, momentsB);
      int halfW = bottomW + top(cube, direction, i, weights);

      if (halfW == 0) {
        continue;
      }

      double tempNumerator =
          ((halfR * halfR) + (halfG * halfG) + (halfB * halfB)).toDouble();
      double tempDenominator = halfW.toDouble();
      double temp = tempNumerator / tempDenominator;

      halfR = wholeR - halfR;
      halfG = wholeG - halfG;
      halfB = wholeB - halfB;
      halfW = wholeW - halfW;
      if (halfW == 0) {
        continue;
      }
      tempNumerator =
          ((halfR * halfR) + (halfG * halfG) + (halfB * halfB)).toDouble();
      tempDenominator = halfW.toDouble();
      temp += (tempNumerator / tempDenominator);

      if (temp > max) {
        max = temp;
        cut = i;
      }
    }
    return MaximizeResult(cutLocation: cut, maximum: max);
  }

  static int volume(Box cube, List<int> moment) {
    return (moment[getIndex(cube.r1, cube.g1, cube.b1)] -
        moment[getIndex(cube.r1, cube.g1, cube.b0)] -
        moment[getIndex(cube.r1, cube.g0, cube.b1)] +
        moment[getIndex(cube.r1, cube.g0, cube.b0)] -
        moment[getIndex(cube.r0, cube.g1, cube.b1)] +
        moment[getIndex(cube.r0, cube.g1, cube.b0)] +
        moment[getIndex(cube.r0, cube.g0, cube.b1)] -
        moment[getIndex(cube.r0, cube.g0, cube.b0)]);
  }

  static int bottom(Box cube, Direction direction, List<int> moment) {
    switch (direction) {
      case Direction.red:
        return -moment[getIndex(cube.r0, cube.g1, cube.b1)] +
            moment[getIndex(cube.r0, cube.g1, cube.b0)] +
            moment[getIndex(cube.r0, cube.g0, cube.b1)] -
            moment[getIndex(cube.r0, cube.g0, cube.b0)];
      case Direction.green:
        return -moment[getIndex(cube.r1, cube.g0, cube.b1)] +
            moment[getIndex(cube.r1, cube.g0, cube.b0)] +
            moment[getIndex(cube.r0, cube.g0, cube.b1)] -
            moment[getIndex(cube.r0, cube.g0, cube.b0)];
      case Direction.blue:
        return -moment[getIndex(cube.r1, cube.g1, cube.b0)] +
            moment[getIndex(cube.r1, cube.g0, cube.b0)] +
            moment[getIndex(cube.r0, cube.g1, cube.b0)] -
            moment[getIndex(cube.r0, cube.g0, cube.b0)];
      default:
        throw 'unexpected direction $direction';
    }
  }

  static int top(
      Box cube, Direction direction, int position, List<int> moment) {
    switch (direction) {
      case Direction.red:
        return (moment[getIndex(position, cube.g1, cube.b1)] -
            moment[getIndex(position, cube.g1, cube.b0)] -
            moment[getIndex(position, cube.g0, cube.b1)] +
            moment[getIndex(position, cube.g0, cube.b0)]);
      case Direction.green:
        return (moment[getIndex(cube.r1, position, cube.b1)] -
            moment[getIndex(cube.r1, position, cube.b0)] -
            moment[getIndex(cube.r0, position, cube.b1)] +
            moment[getIndex(cube.r0, position, cube.b0)]);
      case Direction.blue:
        return (moment[getIndex(cube.r1, cube.g1, position)] -
            moment[getIndex(cube.r1, cube.g0, position)] -
            moment[getIndex(cube.r0, cube.g1, position)] +
            moment[getIndex(cube.r0, cube.g0, position)]);
      default:
        throw 'unexpected direction $direction';
    }
  }
}

enum Direction { red, green, blue }

class MaximizeResult {
  // < 0 if cut impossible
  int cutLocation;
  double maximum;

  MaximizeResult({required this.cutLocation, required this.maximum});
}

class CreateBoxesResult {
  int requestedCount;
  int resultCount;

  CreateBoxesResult({required this.requestedCount, required this.resultCount});
}

class Box {
  int r0;
  int r1;
  int g0;
  int g1;
  int b0;
  int b1;
  int vol;

  Box(
      {this.r0 = 0,
      this.r1 = 0,
      this.g0 = 0,
      this.g1 = 0,
      this.b0 = 0,
      this.b1 = 0,
      this.vol = 0});

  @override
  String toString() {
    return 'Box: R $r0 -> $r1 G  $g0 -> $g1 B $b0 -> $b1 VOL = $vol';
  }
}
