import 'dart:math';
import 'dart:typed_data';
import '../color.dart';
import '../image.dart';
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
  late Uint8List colorMap;

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

  /// How many colors are in the [colorMap]?
  int get numColors => netSize;

  /// Get a color from the [colorMap].
  int color(int index) => getColor(
      colorMap[index * 3], colorMap[index * 3 + 1], colorMap[index * 3 + 2]);

  /// Find the index of the closest color to [c] in the [colorMap].
  int lookup(int c) {
    final r = getRed(c);
    final g = getGreen(c);
    final b = getBlue(c);
    return _inxSearch(b, g, r);
  }

  /// Find the index of the closest color to [r],[g],[b] in the [colorMap].
  int lookupRGB(int r, int g, int b) => _inxSearch(b, g, r);

  /// Find the color closest to [c] in the [colorMap].
  @override
  int getQuantizedColor(int c) {
    final r = getRed(c);
    final g = getGreen(c);
    final b = getBlue(c);
    final a = getAlpha(c);
    final i = _inxSearch(b, g, r) * 3;
    return getColor(colorMap[i], colorMap[i + 1], colorMap[i + 2], a);
  }

  /// Convert the [image] to an index map, mapping to this [colorMap].
  Uint8List getIndexMap(Image image) {
    final map = Uint8List(image.width * image.height);
    for (var i = 0, len = image.length; i < len; ++i) {
      map[i] = lookup(image[i]);
    }
    return map;
  }

  void _initialize(int numberOfColors) {
    netSize = max(numberOfColors, 4); // number of colours used
    cutNetSize = netSize - specials;
    maxNetPos = netSize - 1;
    initRadius = netSize ~/ 8; // for 256 cols, radius starts at 32
    initBiasRadius = initRadius * radiusBias;
    _colorMap = Int32List(netSize * 4);
    colorMap = Uint8List(netSize * 3);
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
    for (var i = 0, p = 0, q = 0; i < netSize; ++i) {
      colorMap[p++] = _colorMap[q + 2].abs() & 0xff;
      colorMap[p++] = _colorMap[q + 1].abs() & 0xff;
      colorMap[p++] = _colorMap[q].abs() & 0xff;
      q += 4;
    }
  }

  int _inxSearch(int b, int g, int r) {
    // Search for BGR values 0..255 and return colour index
    var bestd = 1000; // biggest possible dist is 256*3
    var best = -1;
    var i = _netIndex[g]; // index on g
    var j = i - 1; // start at netindex[g] and work outwards

    while ((i < netSize) || (j >= 0)) {
      if (i < netSize) {
        final p = i * 4;
        var dist = _colorMap[p + 1] - g; // inx key
        if (dist >= bestd) {
          i = netSize; // stop iter
        } else {
          if (dist < 0) {
            dist = -dist;
          }
          var a = _colorMap[p] - b;
          if (a < 0) {
            a = -a;
          }
          dist += a;
          if (dist < bestd) {
            a = _colorMap[p + 2] - r;
            if (a < 0) {
              a = -a;
            }
            dist += a;
            if (dist < bestd) {
              bestd = dist;
              best = i;
            }
          }
          i++;
        }
      }

      if (j >= 0) {
        final p = j * 4;
        var dist = g - _colorMap[p + 1]; // inx key - reverse dif
        if (dist >= bestd) {
          j = -1; // stop iter
        } else {
          if (dist < 0) {
            dist = -dist;
          }
          var a = _colorMap[p] - b;
          if (a < 0) {
            a = -a;
          }
          dist += a;
          if (dist < bestd) {
            a = _colorMap[p + 2] - r;
            if (a < 0) {
              a = -a;
            }
            dist += a;
            if (dist < bestd) {
              bestd = dist;
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
    for (var i = 0, p = 0, q = 0; i < netSize; i++, q += 4) {
      for (var j = 0; j < 3; ++j, ++p) {
        var x = (0.5 + _network[p]).toInt();
        if (x < 0) {
          x = 0;
        }
        if (x > 255) {
          x = 255;
        }
        _colorMap[q + j] = x;
      }
      _colorMap[q + 3] = i;
    }
  }

  /// Insertion sort of network and building of netindex[0..255]
  void _inxBuild() {
    var previousColor = 0;
    var startPos = 0;

    for (var i = 0, p = 0; i < netSize; i++, p += 4) {
      var smallpos = i;
      var smallval = _colorMap[p + 1]; // index on g

      // find smallest in i..netsize-1
      for (var j = i + 1, q = p + 4; j < netSize; j++, q += 4) {
        if (_colorMap[q + 1] < smallval) {
          // index on g
          smallpos = j;
          smallval = _colorMap[q + 1]; // index on g
        }
      }

      final q = smallpos * 4;

      // swap p (i) and q (smallpos) entries
      if (i != smallpos) {
        var j = _colorMap[q];
        _colorMap[q] = _colorMap[p];
        _colorMap[p] = j;

        j = _colorMap[q + 1];
        _colorMap[q + 1] = _colorMap[p + 1];
        _colorMap[p + 1] = j;

        j = _colorMap[q + 2];
        _colorMap[q + 2] = _colorMap[p + 2];
        _colorMap[p + 2] = j;

        j = _colorMap[q + 3];
        _colorMap[q + 3] = _colorMap[p + 3];
        _colorMap[p + 3] = j;
      }

      // smallVal entry is now in position i
      if (smallval != previousColor) {
        _netIndex[previousColor] = (startPos + i) >> 1;
        for (var j = previousColor + 1; j < smallval; j++) {
          _netIndex[j] = i;
        }
        previousColor = smallval;
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
    final lengthCount = image.length;
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

    var i = 0;
    while (i < samplePixels) {
      final p = image[pos];
      final red = getRed(p);
      final green = getGreen(p);
      final blue = getBlue(p);

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
      while (pos >= lengthCount) {
        pos -= lengthCount;
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
    _network[p] -= (alpha * (_network[p] - b));
    _network[p + 1] -= (alpha * (_network[p + 1] - g));
    _network[p + 2] -= (alpha * (_network[p + 2] - r));
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
    // bias[i] = gamma*((1/netsize)-freq[i])

    var bestd = 1.0e30;
    var bestBiasDist = bestd;
    var bestpos = -1;
    var bestbiaspos = bestpos;

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
      if (dist < bestd) {
        bestd = dist;
        bestpos = i;
      }

      final biasDist = dist - _bias[i];
      if (biasDist < bestBiasDist) {
        bestBiasDist = biasDist;
        bestbiaspos = i;
      }
      _freq[i] -= beta * _freq[i];
      _bias[i] += betaGamma * _freq[i];
    }
    _freq[bestpos] += beta;
    _bias[bestpos] -= betaGamma;
    return bestbiaspos;
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
  static const alphaRadiusBias = (1 << alphaRadiusBiasShift);
  late int initBiasRadius;
  static const radiusDec = 30; // factor of 1/30 each cycle
  late Int32List _radiusPower;

  static const double gamma = 1024.0;
  static const double beta = 1.0 / 1024.0;
  static const double betaGamma = beta * gamma;

  /// the network itself
  late List<double> _network;
  late Int32List _colorMap;
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
