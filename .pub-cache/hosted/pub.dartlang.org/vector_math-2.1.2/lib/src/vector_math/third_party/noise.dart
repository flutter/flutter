/*
  Copyright (C) 2013 Andrew Magill

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.

*/

part of vector_math;

/*
 * This is based on the implementation of Simplex Noise by Stefan Gustavson
 * found at: http://webstaff.itn.liu.se/~stegu/simplexnoise/SimplexNoise.java
 */

class SimplexNoise {
  static final List<List<double>> _grad3 = <List<double>>[
    <double>[1.0, 1.0, 0.0],
    <double>[-1.0, 1.0, 0.0],
    <double>[1.0, -1.0, 0.0],
    <double>[-1.0, -1.0, 0.0],
    <double>[1.0, 0.0, 1.0],
    <double>[-1.0, 0.0, 1.0],
    <double>[1.0, 0.0, -1.0],
    <double>[-1.0, 0.0, -1.0],
    <double>[0.0, 1.0, 1.0],
    <double>[0.0, -1.0, 1.0],
    <double>[0.0, 1.0, -1.0],
    <double>[0.0, -1.0, -1.0]
  ];

  static final List<List<double>> _grad4 = <List<double>>[
    <double>[0.0, 1.0, 1.0, 1.0],
    <double>[0.0, 1.0, 1.0, -1.0],
    <double>[0.0, 1.0, -1.0, 1.0],
    <double>[0.0, 1.0, -1.0, -1.0],
    <double>[0.0, -1.0, 1.0, 1.0],
    <double>[0.0, -1.0, 1.0, -1.0],
    <double>[0.0, -1.0, -1.0, 1.0],
    <double>[0.0, -1.0, -1.0, -1.0],
    <double>[1.0, 0.0, 1.0, 1.0],
    <double>[1.0, 0.0, 1.0, -1.0],
    <double>[1.0, 0.0, -1.0, 1.0],
    <double>[1.0, 0.0, -1.0, -1.0],
    <double>[-1.0, 0.0, 1.0, 1.0],
    <double>[-1.0, 0.0, 1.0, -1.0],
    <double>[-1.0, 0.0, -1.0, 1.0],
    <double>[-1.0, 0.0, -1.0, -1.0],
    <double>[1.0, 1.0, 0.0, 1.0],
    <double>[1.0, 1.0, 0.0, -1.0],
    <double>[1.0, -1.0, 0.0, 1.0],
    <double>[1.0, -1.0, 0.0, -1.0],
    <double>[-1.0, 1.0, 0.0, 1.0],
    <double>[-1.0, 1.0, 0.0, -1.0],
    <double>[-1.0, -1.0, 0.0, 1.0],
    <double>[-1.0, -1.0, 0.0, -1.0],
    <double>[1.0, 1.0, 1.0, 0.0],
    <double>[1.0, 1.0, -1.0, 0.0],
    <double>[1.0, -1.0, 1.0, 0.0],
    <double>[1.0, -1.0, -1.0, 0.0],
    <double>[-1.0, 1.0, 1.0, 0.0],
    <double>[-1.0, 1.0, -1.0, 0.0],
    <double>[-1.0, -1.0, 1.0, 0.0],
    <double>[-1.0, -1.0, -1.0, 0.0]
  ];

  // To remove the need for index wrapping, double the permutation table length
  late final List<int> _perm;
  late final List<int> _permMod12;

  // Skewing and unskewing factors for 2, 3, and 4 dimensions
  static final _F2 = 0.5 * (math.sqrt(3.0) - 1.0);
  static final _G2 = (3.0 - math.sqrt(3.0)) / 6.0;
  static const double _f3 = 1.0 / 3.0;
  static const double _g3 = 1.0 / 6.0;
  static final _F4 = (math.sqrt(5.0) - 1.0) / 4.0;
  static final _G4 = (5.0 - math.sqrt(5.0)) / 20.0;

  double _dot2(List<double> g, double x, double y) => g[0] * x + g[1] * y;

  double _dot3(List<double> g, double x, double y, double z) =>
      g[0] * x + g[1] * y + g[2] * z;

  double _dot4(List<double> g, double x, double y, double z, double w) =>
      g[0] * x + g[1] * y + g[2] * z + g[3] * w;

  SimplexNoise([math.Random? r]) {
    r ??= math.Random();
    final p = List<int>.generate(256, (_) => r!.nextInt(256), growable: false);
    _perm = List<int>.generate(p.length * 2, (int i) => p[i % p.length],
        growable: false);
    _permMod12 = List<int>.generate(_perm.length, (int i) => _perm[i] % 12,
        growable: false);
  }

  double noise2D(double xin, double yin) {
    double n0, n1, n2; // Noise contributions from the three corners
    // Skew the input space to determine which simplex cell we're in
    final s = (xin + yin) * _F2; // Hairy factor for 2D
    final i = (xin + s).floor();
    final j = (yin + s).floor();
    final t = (i + j) * _G2;
    final X0 = i - t; // Unskew the cell origin back to (x,y) space
    final Y0 = j - t;
    final x0 = xin - X0; // The x,y distances from the cell origin
    final y0 = yin - Y0;
    // For the 2D case, the simplex shape is an equilateral triangle.
    // Determine which simplex we are in.
    int i1, j1; // Offsets for second (middle) corner of simplex in (i,j) coords
    if (x0 > y0) {
      i1 = 1;
      j1 = 0;
    } // lower triangle, XY order: (0,0)->(1,0)->(1,1)
    else {
      i1 = 0;
      j1 = 1;
    } // upper triangle, YX order: (0,0)->(0,1)->(1,1)
    // A step of (1,0) in (i,j) means a step of (1-c,-c) in (x,y), and
    // a step of (0,1) in (i,j) means a step of (-c,1-c) in (x,y), where
    // c = (3-sqrt(3))/6
    final x1 =
        x0 - i1 + _G2; // Offsets for middle corner in (x,y) unskewed coords
    final y1 = y0 - j1 + _G2;
    final x2 = x0 -
        1.0 +
        2.0 * _G2; // Offsets for last corner in (x,y) unskewed coords
    final y2 = y0 - 1.0 + 2.0 * _G2;
    // Work out the hashed gradient indices of the three simplex corners
    final ii = i & 255;
    final jj = j & 255;
    final gi0 = _permMod12[ii + _perm[jj]];
    final gi1 = _permMod12[ii + i1 + _perm[jj + j1]];
    final gi2 = _permMod12[ii + 1 + _perm[jj + 1]];
    // Calculate the contribution from the three corners
    var t0 = 0.5 - x0 * x0 - y0 * y0;
    if (t0 < 0) {
      n0 = 0.0;
    } else {
      t0 *= t0;
      n0 = t0 *
          t0 *
          _dot2(_grad3[gi0], x0, y0); // (x,y) of grad3 used for 2D gradient
    }
    var t1 = 0.5 - x1 * x1 - y1 * y1;
    if (t1 < 0) {
      n1 = 0.0;
    } else {
      t1 *= t1;
      n1 = t1 * t1 * _dot2(_grad3[gi1], x1, y1);
    }
    var t2 = 0.5 - x2 * x2 - y2 * y2;
    if (t2 < 0) {
      n2 = 0.0;
    } else {
      t2 *= t2;
      n2 = t2 * t2 * _dot2(_grad3[gi2], x2, y2);
    }
    // Add contributions from each corner to get the final noise value.
    // The result is scaled to return values in the interval [-1,1].
    return 70.0 * (n0 + n1 + n2);
  }

  // 3D simplex noise
  double noise3D(double xin, double yin, double zin) {
    double n0, n1, n2, n3; // Noise contributions from the four corners
    // Skew the input space to determine which simplex cell we're in
    final s =
        (xin + yin + zin) * _f3; // Very nice and simple skew factor for 3D
    final i = (xin + s).floor();
    final j = (yin + s).floor();
    final k = (zin + s).floor();
    final t = (i + j + k) * _g3;
    final X0 = i - t; // Unskew the cell origin back to (x,y,z) space
    final Y0 = j - t;
    final Z0 = k - t;
    final x0 = xin - X0; // The x,y,z distances from the cell origin
    final y0 = yin - Y0;
    final z0 = zin - Z0;
    // For the 3D case, the simplex shape is a slightly irregular tetrahedron.
    // Determine which simplex we are in.
    int i1, j1, k1; // Offsets for second corner of simplex in (i,j,k) coords
    int i2, j2, k2; // Offsets for third corner of simplex in (i,j,k) coords
    if (x0 >= y0) {
      if (y0 >= z0) {
        i1 = 1;
        j1 = 0;
        k1 = 0;
        i2 = 1;
        j2 = 1;
        k2 = 0;
      } // X Y Z order
      else if (x0 >= z0) {
        i1 = 1;
        j1 = 0;
        k1 = 0;
        i2 = 1;
        j2 = 0;
        k2 = 1;
      } // X Z Y order
      else {
        i1 = 0;
        j1 = 0;
        k1 = 1;
        i2 = 1;
        j2 = 0;
        k2 = 1;
      } // Z X Y order
    } else {
      // x0<y0
      if (y0 < z0) {
        i1 = 0;
        j1 = 0;
        k1 = 1;
        i2 = 0;
        j2 = 1;
        k2 = 1;
      } // Z Y X order
      else if (x0 < z0) {
        i1 = 0;
        j1 = 1;
        k1 = 0;
        i2 = 0;
        j2 = 1;
        k2 = 1;
      } // Y Z X order
      else {
        i1 = 0;
        j1 = 1;
        k1 = 0;
        i2 = 1;
        j2 = 1;
        k2 = 0;
      } // Y X Z order
    }
    // A step of (1,0,0) in (i,j,k) means a step of (1-c,-c,-c) in (x,y,z),
    // a step of (0,1,0) in (i,j,k) means a step of (-c,1-c,-c) in (x,y,z), and
    // a step of (0,0,1) in (i,j,k) means a step of (-c,-c,1-c) in (x,y,z), where
    // c = 1/6.
    final x1 = x0 - i1 + _g3; // Offsets for second corner in (x,y,z) coords
    final y1 = y0 - j1 + _g3;
    final z1 = z0 - k1 + _g3;
    final x2 =
        x0 - i2 + 2.0 * _g3; // Offsets for third corner in (x,y,z) coords
    final y2 = y0 - j2 + 2.0 * _g3;
    final z2 = z0 - k2 + 2.0 * _g3;
    final x3 =
        x0 - 1.0 + 3.0 * _g3; // Offsets for last corner in (x,y,z) coords
    final y3 = y0 - 1.0 + 3.0 * _g3;
    final z3 = z0 - 1.0 + 3.0 * _g3;
    // Work out the hashed gradient indices of the four simplex corners
    final ii = i & 255;
    final jj = j & 255;
    final kk = k & 255;
    final gi0 = _permMod12[ii + _perm[jj + _perm[kk]]];
    final gi1 = _permMod12[ii + i1 + _perm[jj + j1 + _perm[kk + k1]]];
    final gi2 = _permMod12[ii + i2 + _perm[jj + j2 + _perm[kk + k2]]];
    final gi3 = _permMod12[ii + 1 + _perm[jj + 1 + _perm[kk + 1]]];
    // Calculate the contribution from the four corners
    var t0 = 0.6 - x0 * x0 - y0 * y0 - z0 * z0;
    if (t0 < 0) {
      n0 = 0.0;
    } else {
      t0 *= t0;
      n0 = t0 * t0 * _dot3(_grad3[gi0], x0, y0, z0);
    }
    var t1 = 0.6 - x1 * x1 - y1 * y1 - z1 * z1;
    if (t1 < 0) {
      n1 = 0.0;
    } else {
      t1 *= t1;
      n1 = t1 * t1 * _dot3(_grad3[gi1], x1, y1, z1);
    }
    var t2 = 0.6 - x2 * x2 - y2 * y2 - z2 * z2;
    if (t2 < 0) {
      n2 = 0.0;
    } else {
      t2 *= t2;
      n2 = t2 * t2 * _dot3(_grad3[gi2], x2, y2, z2);
    }
    var t3 = 0.6 - x3 * x3 - y3 * y3 - z3 * z3;
    if (t3 < 0) {
      n3 = 0.0;
    } else {
      t3 *= t3;
      n3 = t3 * t3 * _dot3(_grad3[gi3], x3, y3, z3);
    }
    // Add contributions from each corner to get the final noise value.
    // The result is scaled to stay just inside [-1,1]
    return 32.0 * (n0 + n1 + n2 + n3);
  }

  // 4D simplex noise, better simplex rank ordering method 2012-03-09
  double noise4D(double x, double y, double z, double w) {
    double n0, n1, n2, n3, n4; // Noise contributions from the five corners
    // Skew the (x,y,z,w) space to determine which cell of 24 simplices we're in
    final s = (x + y + z + w) * _F4; // Factor for 4D skewing
    final i = (x + s).floor();
    final j = (y + s).floor();
    final k = (z + s).floor();
    final l = (w + s).floor();
    final t = (i + j + k + l) * _G4; // Factor for 4D unskewing
    final X0 = i - t; // Unskew the cell origin back to (x,y,z,w) space
    final Y0 = j - t;
    final Z0 = k - t;
    final W0 = l - t;
    final x0 = x - X0; // The x,y,z,w distances from the cell origin
    final y0 = y - Y0;
    final z0 = z - Z0;
    final w0 = w - W0;
    // For the 4D case, the simplex is a 4D shape I won't even try to describe.
    // To find out which of the 24 possible simplices we're in, we need to
    // determine the magnitude ordering of x0, y0, z0 and w0.
    // Six pair-wise comparisons are performed between each possible pair
    // of the four coordinates, and the results are used to rank the numbers.
    var rankx = 0;
    var ranky = 0;
    var rankz = 0;
    var rankw = 0;
    if (x0 > y0) {
      rankx++;
    } else {
      ranky++;
    }
    if (x0 > z0) {
      rankx++;
    } else {
      rankz++;
    }
    if (x0 > w0) {
      rankx++;
    } else {
      rankw++;
    }
    if (y0 > z0) {
      ranky++;
    } else {
      rankz++;
    }
    if (y0 > w0) {
      ranky++;
    } else {
      rankw++;
    }
    if (z0 > w0) {
      rankz++;
    } else {
      rankw++;
    }
    int i1, j1, k1, l1; // The integer offsets for the second simplex corner
    int i2, j2, k2, l2; // The integer offsets for the third simplex corner
    int i3, j3, k3, l3; // The integer offsets for the fourth simplex corner
    // simplex[c] is a 4-vector with the numbers 0, 1, 2 and 3 in some order.
    // Many values of c will never occur, since e.g. x>y>z>w makes x<z, y<w and x<w
    // impossible. Only the 24 indices which have non-zero entries make any sense.
    // We use a thresholding to set the coordinates in turn from the largest magnitude.
    // Rank 3 denotes the largest coordinate.
    i1 = rankx >= 3 ? 1 : 0;
    j1 = ranky >= 3 ? 1 : 0;
    k1 = rankz >= 3 ? 1 : 0;
    l1 = rankw >= 3 ? 1 : 0;
    // Rank 2 denotes the second largest coordinate.
    i2 = rankx >= 2 ? 1 : 0;
    j2 = ranky >= 2 ? 1 : 0;
    k2 = rankz >= 2 ? 1 : 0;
    l2 = rankw >= 2 ? 1 : 0;
    // Rank 1 denotes the second smallest coordinate.
    i3 = rankx >= 1 ? 1 : 0;
    j3 = ranky >= 1 ? 1 : 0;
    k3 = rankz >= 1 ? 1 : 0;
    l3 = rankw >= 1 ? 1 : 0;
    // The fifth corner has all coordinate offsets = 1, so no need to compute that.
    final x1 = x0 - i1 + _G4; // Offsets for second corner in (x,y,z,w) coords
    final y1 = y0 - j1 + _G4;
    final z1 = z0 - k1 + _G4;
    final w1 = w0 - l1 + _G4;
    final x2 =
        x0 - i2 + 2.0 * _G4; // Offsets for third corner in (x,y,z,w) coords
    final y2 = y0 - j2 + 2.0 * _G4;
    final z2 = z0 - k2 + 2.0 * _G4;
    final w2 = w0 - l2 + 2.0 * _G4;
    final x3 =
        x0 - i3 + 3.0 * _G4; // Offsets for fourth corner in (x,y,z,w) coords
    final y3 = y0 - j3 + 3.0 * _G4;
    final z3 = z0 - k3 + 3.0 * _G4;
    final w3 = w0 - l3 + 3.0 * _G4;
    final x4 =
        x0 - 1.0 + 4.0 * _G4; // Offsets for last corner in (x,y,z,w) coords
    final y4 = y0 - 1.0 + 4.0 * _G4;
    final z4 = z0 - 1.0 + 4.0 * _G4;
    final w4 = w0 - 1.0 + 4.0 * _G4;
    // Work out the hashed gradient indices of the five simplex corners
    final ii = i & 255;
    final jj = j & 255;
    final kk = k & 255;
    final ll = l & 255;
    final gi0 = _perm[ii + _perm[jj + _perm[kk + _perm[ll]]]] % 32;
    final gi1 =
        _perm[ii + i1 + _perm[jj + j1 + _perm[kk + k1 + _perm[ll + l1]]]] % 32;
    final gi2 =
        _perm[ii + i2 + _perm[jj + j2 + _perm[kk + k2 + _perm[ll + l2]]]] % 32;
    final gi3 =
        _perm[ii + i3 + _perm[jj + j3 + _perm[kk + k3 + _perm[ll + l3]]]] % 32;
    final gi4 =
        _perm[ii + 1 + _perm[jj + 1 + _perm[kk + 1 + _perm[ll + 1]]]] % 32;
    // Calculate the contribution from the five corners
    var t0 = 0.6 - x0 * x0 - y0 * y0 - z0 * z0 - w0 * w0;
    if (t0 < 0) {
      n0 = 0.0;
    } else {
      t0 *= t0;
      n0 = t0 * t0 * _dot4(_grad4[gi0], x0, y0, z0, w0);
    }
    var t1 = 0.6 - x1 * x1 - y1 * y1 - z1 * z1 - w1 * w1;
    if (t1 < 0) {
      n1 = 0.0;
    } else {
      t1 *= t1;
      n1 = t1 * t1 * _dot4(_grad4[gi1], x1, y1, z1, w1);
    }
    var t2 = 0.6 - x2 * x2 - y2 * y2 - z2 * z2 - w2 * w2;
    if (t2 < 0) {
      n2 = 0.0;
    } else {
      t2 *= t2;
      n2 = t2 * t2 * _dot4(_grad4[gi2], x2, y2, z2, w2);
    }
    var t3 = 0.6 - x3 * x3 - y3 * y3 - z3 * z3 - w3 * w3;
    if (t3 < 0) {
      n3 = 0.0;
    } else {
      t3 *= t3;
      n3 = t3 * t3 * _dot4(_grad4[gi3], x3, y3, z3, w3);
    }
    var t4 = 0.6 - x4 * x4 - y4 * y4 - z4 * z4 - w4 * w4;
    if (t4 < 0) {
      n4 = 0.0;
    } else {
      t4 *= t4;
      n4 = t4 * t4 * _dot4(_grad4[gi4], x4, y4, z4, w4);
    }
    // Sum up and scale the result to cover the range [-1,1]
    return 27.0 * (n0 + n1 + n2 + n3 + n4);
  }
}
