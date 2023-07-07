library impl.digest.utils;

import 'dart:typed_data';

class XofUtils {
  static Uint8List leftEncode(int strLen) {
    var n = 1;
    var v = strLen;
    while ((v >>= 8) != 0) {
      n++;
    }
    var b = Uint8List(n + 1);
    b[0] = n;
    for (var i = 1; i <= n; i++) {
      b[i] = strLen >> (8 * (n - i));
    }
    return b;
  }

  static Uint8List rightEncode(int strLen) {
    var n = 1;
    var v = strLen;
    while ((v >>= 8) != 0) {
      n++;
    }

    var b = Uint8List(n + 1);

    b[n] = n;

    for (var i = 0; i < n; i++) {
      b[i] = (strLen >> (8 * (n - i - 1)));
    }

    return b;
  }
}
