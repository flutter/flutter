// See file LICENSE for more information.

library src.utils;

import 'dart:typed_data';

///
/// Constant time XOR, use to replace if (condition) { xor(x,y);}
/// CT_xor, x <- x ^ y when b is true
/// asserts x length and y length are equal
///
void CT_xor(Uint8List x, Uint8List y, bool b) {
  assert(x.length == y.length, 'x length and y length must be same');
  var mask = b ? 0xFF : 0; //  (-b) & 0xFF;
  for (var i = 0; i < x.length; i++) {
    x[i] = x[i] ^ (y[i] & mask);
  }
}
