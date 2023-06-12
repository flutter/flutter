import 'dart:math';
import 'dart:typed_data';

import '../color/color.dart';
import '../color/color_uint8.dart';
import '../image/image.dart';
import '../image/palette_uint32.dart';
import '../image/palette_uint8.dart';
import 'quantizer.dart';

/* NeuQuant Neural-Net Quantization Algorithm
 * ------------------------------------------
 *
 * Copyright (c) 1994 Anthony Dekker
 *
 * NEUQUANT Neural-Net quantization algorithm by Anthony Dekker, 1994.
 * See "Kohonen neural networks for optimal colour quantization"
 * in "Network: Computation in Neural Systems" Vol. 5 (1994) pp 351-367.
 * for a discussion of the algorithm.
 * See also  http://members.ozemail.com.au/~dekker/NEUQUANT.HTML
 *
 * Any party obtaining a copy of these files from the author, directly or
 * indirectly, is granted, free of charge, a full and unrestricted irrevocable,
 * world-wide, paid up, royalty-free, nonexclusive right and license to deal
 * in this software and documentation files (the "Software"), including without
 * limitation the rights to use, copy, modify, merge, publish, distribute,
 * sublicense,
 * and/or sell copies of the Software, and to permit persons who receive
 * copies from any such party to do so, with the only requirement being
 * that this copyright notice remain intact.
 *
 * Dart port by Brendan Duncan.
 */

/// Compute a color map with a given number of colors that best represents
/// the given image.
class NeuralQuantizer extends Quantizer {
  @override
  late PaletteUint8 palette;

  int samplingFactor;

  /// 10 is a reasonable [samplingFactor] according to
  /// https://scientificgems.wordpress.com/stuff/neuquant-fast-high-quality-image-quantization/.
  NeuralQuantizer(Image image,
      {int numberOfColors = 256, this.samplingFactor = 10}) {
    _initialize(numberOfColors);
    addImage(image);
  }

  /// Add an image to the quantized color table.
  void addImage(Image image) {
    _learn(image);
    _fix();
    _inxBuild();
    _copyColorMap();
  }

  /// How many colors are in the colorMap?
  int get numColors => netSize;

  /// Find the index of the closest color to [c] in the colorMap.
  @override
  int getColorIndex(Color c) {
    final r = c.r.toInt();
    final g = c.g.toInt();
    final b = c.b.toInt();
    return _inxSearch(b, g, r);
  }

  /// Find the index of the closest color to [r],[g],[b] in the colorMap.
  @override
  int getColorIndexRgb(int r, int g, int b) => _inxSearch(b, g, r);

  /// Find the color closest to [c] in the colorMap.
  @override
  Color getQuantizedColor(Color c) {
    final i = getColorIndex(c);
    final out = c.length == 4 ? ColorRgba8(0, 0, 0, 255) : ColorRgb8(0, 0, 0)
      ..r = palette.get(i, 0)
      ..g = palette.get(i, 1)
      ..b = palette.get(i, 2);
    if (c.length == 4) {
      out.a = c.a;
    }
    return out;
  }

  void _initialize(int numberOfColors) {
    netSize = max(numberOfColors, 4); // number of colours used
    cutNetSize = netSize - specials;
    maxNetPos = netSize - 1;
    initRadius = netSize ~/ 8; // for 256 cols, radius starts at 32
    initBiasRadius = initRadius * radiusBias;
    _palette = PaletteUint32(256, 4);
    palette = PaletteUint8(256, 3);
    specials = 3; // number of reserved colours used
    bgColor = specials - 1;
    _radiusPower = Int32List(netSize >> 3);

    _network = List<double>.filled(netSize * 3, 0);
    _bias = List<double>.filled(netSize, 0);
    _freq = List<double>.filled(netSize, 0);

    _network[0] = 0.0; // black
    _network[1] = 0.0;
    _network[2] = 0.0;

    _network[3] = 255.0; // white
    _network[4] = 255.0;
    _network[5] = 255.0;

    // RESERVED bgColour  // background
    final f = 1.0 / netSize;
    for (var i = 0; i < specials; ++i) {
      _freq[i] = f;
      _bias[i] = 0.0;
    }

    for (var i = specials, p = specials * 3; i < netSize; ++i) {
      _network[p++] = (255.0 * (i - specials)) / cutNetSize;
      _network[p++] = (255.0 * (i - specials)) / cutNetSize;
      _network[p++] = (255.0 * (i - specials)) / cutNetSize;

      _freq[i] = f;
      _bias[i] = 0.0;
    }
  }

  void _copyColorMap() {
    for (var i = 0; i < netSize; ++i) {
      palette.setRgb(i, _palette.get(i, 2).abs(), _palette.get(i, 1).abs(),
          _palette.get(i, 0).abs());
    }
  }

  int _inxSearch(int b, int g, int r) {
    // Search for BGR values 0..255 and return colour index
    var bestD = 1000; // biggest possible dist is 256*3
    var best = -1;
    var i = _netIndex[g]; // index on g
    var j = i - 1; // start at netIndex[g] and work outwards

    while ((i < netSize) || (j >= 0)) {
      if (i < netSize) {
        var dist = _palette.get(i, 1) - g; // inx key
        if (dist >= bestD) {
          i = netSize; // stop iter
        } else {
          if (dist < 0) {
            dist = -dist;
          }
          var a = _palette.get(i, 0) - b;
          if (a < 0) {
            a = -a;
          }
          dist += a;
          if (dist < bestD) {
            a = _palette.get(i, 2) - r;
            if (a < 0) {
              a = -a;
            }
            dist += a;
            if (dist < bestD) {
              bestD = dist as int;
              best = i;
            }
          }
          i++;
        }
      }

      if (j >= 0) {
        var dist = g - _palette.get(j, 1); // inx key - reverse dif
        if (dist >= bestD) {
          j = -1; // stop iter
        } else {
          if (dist < 0) {
            dist = -dist;
          }
          var a = _palette.get(j, 0) - b;
          if (a < 0) {
            a = -a;
          }
          dist += a;
          if (dist < bestD) {
            a = _palette.get(j, 2) - r;
            if (a < 0) {
              a = -a;
            }
            dist += a;
            if (dist < bestD) {
              bestD = dist as int;
              best = j;
            }
          }
          j--;
        }
      }
    }

    return best;
  }

  void _fix() {
    for (var i = 0, p = 0; i < netSize; i++) {
      for (var j = 0; j < 3; ++j, ++p) {
        final x = (0.5 + _network[p]).toInt().clamp(0, 255);
        _palette.set(i, j, x);
      }
      _palette.set(i, 3, i);
    }
  }

  /// Insertion sort of network and building of netIndex[0..255]
  void _inxBuild() {
    var previousColor = 0;
    var startPos = 0;

    for (var i = 0; i < netSize; i++) {
      var smallPos = i;
      var smallVal = _palette.get(i, 1); // index on g

      // find smallest in i..netSize-1
      for (var j = i + 1; j < netSize; j++) {
        if (_palette.get(j, 1) < smallVal) {
          // index on g
          smallPos = j;
          smallVal = _palette.get(j, 1); // index on g
        }
      }

      final p = i;
      final q = smallPos;

      // swap p (i) and q (smallPos) entries
      if (i != smallPos) {
        var j = _palette.get(q, 0);
        _palette
          ..set(q, 0, _palette.get(p, 0))
          ..set(p, 0, j);

        j = _palette.get(q, 1);
        _palette
          ..set(q, 1, _palette.get(p, 1))
          ..set(p, 1, j);

        j = _palette.get(q, 2);
        _palette
          ..set(q, 2, _palette.get(p, 2))
          ..set(p, 2, j);

        j = _palette.get(q, 3);
        _palette
          ..set(q, 3, _palette.get(p, 3))
          ..set(p, 3, j);
      }

      // smallVal entry is now in position i
      if (smallVal != previousColor) {
        _netIndex[previousColor] = (startPos + i) >> 1;
        for (var j = previousColor + 1; j < smallVal; j++) {
          _netIndex[j] = i;
        }
        previousColor = smallVal as int;
        startPos = i;
      }
    }

    _netIndex[previousColor] = (startPos + maxNetPos!) >> 1;
    for (var j = previousColor + 1; j < 256; j++) {
      _netIndex[j] = maxNetPos!; // really 256
    }
  }

  void _updateRadiusPower(int rad, int alpha) {
    for (var i = 0; i < rad; i++) {
      _radiusPower[i] =
          (alpha * (((rad * rad - i * i) * radiusBias) / (rad * rad))).toInt();
    }
  }

  void _learn(Image image) {
    var biasRadius = initBiasRadius;
    final alphaDec = 30 + ((samplingFactor - 1) ~/ 3);
    final lengthCount = image.width * image.height;
    final samplePixels = lengthCount ~/ samplingFactor;
    var delta = max(samplePixels ~/ numCycles, 1);
    var alpha = initAlpha;

    if (delta == 0) {
      delta = 1;
    }

    var rad = biasRadius >> radiusBiasShift;
    if (rad <= 1) {
      rad = 0;
    }
    _updateRadiusPower(rad, alpha);

    var step = 0;
    var pos = 0;
    if (lengthCount < smallImageBytes) {
      samplingFactor = 1;
      step = 1;
    } else if ((lengthCount % prime1) != 0) {
      step = prime1;
    } else {
      if ((lengthCount % prime2) != 0) {
        step = prime2;
      } else {
        if ((lengthCount % prime3) != 0) {
          step = prime3;
        } else {
          step = prime4;
        }
      }
    }

    final w = image.width;
    final h = image.height;

    var x = 0;
    var y = 0;
    var i = 0;
    while (i < samplePixels) {
      final p = image.getPixel(x, y);

      final red = p.r;
      final green = p.g;
      final blue = p.b;

      final b = blue.toDouble();
      final g = green.toDouble();
      final r = red.toDouble();

      if (i == 0) {
        // remember background colour
        _network[bgColor * 3] = b;
        _network[bgColor * 3 + 1] = g;
        _network[bgColor * 3 + 2] = r;
      }

      var j = _specialFind(b, g, r);
      j = j < 0 ? _contest(b, g, r) : j;

      if (j >= specials) {
        // don't learn for specials
        final a = (1.0 * alpha) / initAlpha;
        _alterSingle(a, j, b, g, r);
        if (rad > 0) {
          _alterNeighbors(a, rad, j, b, g, r); // alter neighbours
        }
      }

      pos += step;
      x += step;
      while (x > w) {
        x -= w;
        y++;
      }
      while (pos >= lengthCount) {
        pos -= lengthCount;
        y -= h;
      }

      i++;
      if (i % delta == 0) {
        alpha -= alpha ~/ alphaDec;
        biasRadius -= biasRadius ~/ radiusDec;
        rad = biasRadius >> radiusBiasShift;
        if (rad <= 1) {
          rad = 0;
        }
        _updateRadiusPower(rad, alpha);
      }
    }
  }

  void _alterSingle(double alpha, int i, double b, double g, double r) {
    // Move neuron i towards biased (b,g,r) by factor alpha
    final p = i * 3;
    _network[p] -= alpha * (_network[p] - b);
    _network[p + 1] -= alpha * (_network[p + 1] - g);
    _network[p + 2] -= alpha * (_network[p + 2] - r);
  }

  void _alterNeighbors(
      double alpha, int rad, int i, double b, double g, double r) {
    var lo = i - rad;
    if (lo < specials - 1) {
      lo = specials - 1;
    }

    var hi = i + rad;
    if (hi > netSize) {
      hi = netSize;
    }

    var j = i + 1;
    var k = i - 1;
    var m = 1;
    while ((j < hi) || (k > lo)) {
      final a = _radiusPower[m++];
      if (j < hi) {
        final p = j * 3;
        _network[p] -= (a * (_network[p] - b)) / alphaRadiusBias;
        _network[p + 1] -= (a * (_network[p + 1] - g)) / alphaRadiusBias;
        _network[p + 2] -= (a * (_network[p + 2] - r)) / alphaRadiusBias;
        j++;
      }
      if (k > lo) {
        final p = k * 3;
        _network[p] -= (a * (_network[p] - b)) / alphaRadiusBias;
        _network[p + 1] -= (a * (_network[p + 1] - g)) / alphaRadiusBias;
        _network[p + 2] -= (a * (_network[p + 2] - r)) / alphaRadiusBias;
        k--;
      }
    }
  }

  // Search for biased BGR values
  int _contest(double b, double g, double r) {
    // finds closest neuron (min dist) and updates freq
    // finds best neuron (min dist-bias) and returns position
    // for frequently chosen neurons, freq[i] is high and bias[i] is negative
    // bias[i] = gamma*((1/netSize)-freq[i])

    var bestD = 1.0e30;
    var bestBiasDist = bestD;
    var bestPos = -1;
    var bestBiasPos = bestPos;

    for (var i = specials, p = specials * 3; i < netSize; i++) {
      var dist = _network[p++] - b;
      if (dist < 0) {
        dist = -dist;
      }
      var a = _network[p++] - g;
      if (a < 0) {
        a = -a;
      }
      dist += a;
      a = _network[p++] - r;
      if (a < 0) {
        a = -a;
      }
      dist += a;
      if (dist < bestD) {
        bestD = dist;
        bestPos = i;
      }

      final biasDist = dist - _bias[i];
      if (biasDist < bestBiasDist) {
        bestBiasDist = biasDist;
        bestBiasPos = i;
      }
      _freq[i] -= beta * _freq[i];
      _bias[i] += betaGamma * _freq[i];
    }
    _freq[bestPos] += beta;
    _bias[bestPos] -= betaGamma;
    return bestBiasPos;
  }

  int _specialFind(double b, double g, double r) {
    for (var i = 0, p = 0; i < specials; i++) {
      if (_network[p++] == b && _network[p++] == g && _network[p++] == r) {
        return i;
      }
    }
    return -1;
  }

  static const numCycles = 100; // no. of learning cycles

  int netSize = 16; // number of colours used
  int specials = 3; // number of reserved colours used
  late int bgColor; // reserved background colour
  late int cutNetSize;
  int? maxNetPos;

  static const alphaBiasShift = 10; // alpha starts at 1
  static const initAlpha = 1 << alphaBiasShift; // biased by 10 bits

  late int initRadius; // for 256 cols, radius starts at 32
  static const radiusBiasShift = 8;
  static const radiusBias = 1 << radiusBiasShift;
  static const alphaRadiusBiasShift = alphaBiasShift + radiusBiasShift;
  static const alphaRadiusBias = 1 << alphaRadiusBiasShift;
  late int initBiasRadius;
  static const radiusDec = 30; // factor of 1/30 each cycle
  late Int32List _radiusPower;

  static const double gamma = 1024.0;
  static const double beta = 1.0 / 1024.0;
  static const double betaGamma = beta * gamma;

  /// the network itself
  late List<double> _network;
  late PaletteUint32 _palette;
  final _netIndex = Int32List(256);
  // bias and freq arrays for learning
  late List<double> _bias;
  late List<double> _freq;

  // four primes near 500 - assume no image has a length so large
  // that it is divisible by all four primes

  static const prime1 = 499;
  static const prime2 = 491;
  static const prime3 = 487;
  static const prime4 = 503;
  static const maxPrime = prime4;
  static const smallImageBytes = 3 * prime4;
}
