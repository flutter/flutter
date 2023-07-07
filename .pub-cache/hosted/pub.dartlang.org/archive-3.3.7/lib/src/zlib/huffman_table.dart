import 'dart:typed_data';

/// Build huffman table from length list.
class HuffmanTable {
  late Uint32List table;
  int maxCodeLength = 0;
  int minCodeLength = 0x7fffffff;

  HuffmanTable(List<int> lengths) {
    final listSize = lengths.length;

    for (var i = 0; i < listSize; ++i) {
      if (lengths[i] > maxCodeLength) {
        maxCodeLength = lengths[i];
      }
      if (lengths[i] < minCodeLength) {
        minCodeLength = lengths[i];
      }
    }

    final size = 1 << maxCodeLength;
    table = Uint32List(size);

    for (var bitLength = 1, code = 0, skip = 2; bitLength <= maxCodeLength;) {
      for (var i = 0; i < listSize; ++i) {
        if (lengths[i] == bitLength) {
          var reversed = 0;
          var rtemp = code;
          for (var j = 0; j < bitLength; ++j) {
            reversed = (reversed << 1) | (rtemp & 1);
            rtemp >>= 1;
          }

          for (var j = reversed; j < size; j += skip) {
            table[j] = (bitLength << 16) | i;
          }

          ++code;
        }
      }

      ++bitLength;
      code <<= 1;
      skip <<= 1;
    }
  }
}
