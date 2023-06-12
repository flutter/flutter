import 'dart:typed_data';

import '../../util/_internal.dart';
import '../../util/image_exception.dart';
import '../../util/input_buffer.dart';

@internal
class ExrHuffman {
  static void uncompress(
      InputBuffer compressed, int nCompressed, Uint16List? raw, int nRaw) {
    if (nCompressed == 0) {
      if (nRaw != 0) {
        throw ImageException('Incomplete huffman data');
      }

      return;
    }

    final start = compressed.offset;

    final im = compressed.readUint32();
    final iM = compressed.readUint32();
    compressed.skip(4); // tableLength
    final nBits = compressed.readUint32();

    if (im < 0 ||
        im >= _huffmanEncodingSize ||
        iM < 0 ||
        iM >= _huffmanEncodingSize) {
      throw ImageException('Invalid huffman table size');
    }

    compressed.skip(4);

    final freq = List<int>.filled(_huffmanEncodingSize, 0);
    final hdec = List<ExrHufDec>.generate(
        _huffmanDecodingSize, (_) => ExrHufDec(),
        growable: false);

    unpackEncTable(compressed, nCompressed - 20, im, iM, freq);

    if (nBits > 8 * (nCompressed - (compressed.offset - start))) {
      throw ImageException('Error in header for Huffman-encoded data '
          '(invalid number of bits).');
    }

    buildDecTable(freq, im, iM, hdec);
    decode(freq, hdec, compressed, nBits, iM, nRaw, raw);
  }

  static void decode(List<int> hcode, List<ExrHufDec> hdecod, InputBuffer input,
      int ni, int rlc, int no, Uint16List? out) {
    final cLc = [0, 0];
    final ie = input.offset + (ni + 7) ~/ 8; // input byte size
    var oi = 0;

    // Loop on input bytes

    while (input.offset < ie) {
      getChar(cLc, input);

      // Access decoding table
      while (cLc[1] >= _huffmanDecodingBits) {
        final pl = hdecod[
            (cLc[0] >> (cLc[1] - _huffmanDecodingBits)) & _huffmanDecodingMask];

        if (pl.len != 0) {
          // Get short code
          cLc[1] -= pl.len;
          oi = getCode(pl.lit, rlc, cLc, input, out, oi, no);
        } else {
          if (pl.p == null) {
            throw ImageException('Error in Huffman-encoded data '
                '(invalid code).');
          }

          // Search long code
          int j;
          for (j = 0; j < pl.lit; j++) {
            final l = hufLength(hcode[pl.p![j]]);

            while (cLc[1] < l && input.offset < ie) {
              // get more bits
              getChar(cLc, input);
            }

            if (cLc[1] >= l) {
              if (hufCode(hcode[pl.p![j]]) ==
                  ((cLc[0] >> (cLc[1] - l)) & ((1 << l) - 1))) {
                // Found : get long code
                cLc[1] -= l;
                oi = getCode(pl.p![j], rlc, cLc, input, out, oi, no);
                break;
              }
            }
          }

          if (j == pl.lit) {
            throw ImageException('Error in Huffman-encoded data '
                '(invalid code).');
          }
        }
      }
    }

    // Get remaining (short) codes
    final i = (8 - ni) & 7;
    cLc[0] >>= i;
    cLc[1] -= i;

    while (cLc[1] > 0) {
      final pl = hdecod[
          (cLc[0] << (_huffmanDecodingBits - cLc[1])) & _huffmanDecodingMask];

      if (pl.len != 0) {
        cLc[1] -= pl.len;
        oi = getCode(pl.lit, rlc, cLc, input, out, oi, no);
      } else {
        throw ImageException('Error in Huffman-encoded data '
            '(invalid code).');
      }
    }

    if (oi != no) {
      throw ImageException('Error in Huffman-encoded data '
          '(decoded data are shorter than expected).');
    }
  }

  static int getCode(int po, int rlc, List<int> cLc, InputBuffer input,
      Uint16List? out, int oi, int oe) {
    if (po == rlc) {
      if (cLc[1] < 8) {
        getChar(cLc, input);
      }

      cLc[1] -= 8;

      var cs = (cLc[0] >> cLc[1]) & 0xff;

      if (oi + cs > oe) {
        throw ImageException('Error in Huffman-encoded data '
            '(decoded data are longer than expected).');
      }

      final s = out![oi - 1];

      while (cs-- > 0) {
        out[oi++] = s;
      }
    } else if (oi < oe) {
      out![oi++] = po;
    } else {
      throw ImageException('Error in Huffman-encoded data '
          '(decoded data are longer than expected).');
    }
    return oi;
  }

  static void buildDecTable(
      List<int> hcode, int im, int iM, List<ExrHufDec> hdecod) {
    // Init hashtable & loop on all codes.
    // Assumes that hufClearDecTable(hdecod) has already been called.
    for (; im <= iM; im++) {
      final c = hufCode(hcode[im]);
      final l = hufLength(hcode[im]);

      if (c >> l != 0) {
        // Error: c is supposed to be an l-bit code,
        // but c contains a value that is greater
        // than the largest l-bit number.
        throw ImageException('Error in Huffman-encoded data '
            '(invalid code table entry).');
      }

      if (l > _huffmanDecodingBits) {
        // Long code: add a secondary entry
        final pl = hdecod[(c >> (l - _huffmanDecodingBits))];

        if (pl.len != 0) {
          // Error: a short code has already
          // been stored in table entry *pl.
          throw ImageException('Error in Huffman-encoded data '
              '(invalid code table entry).');
        }

        pl.lit++;

        if (pl.p != null) {
          final p = pl.p;
          pl.p = List<int>.filled(pl.lit, 0);

          for (var i = 0; i < pl.lit - 1; ++i) {
            pl.p![i] = p![i];
          }
        } else {
          pl.p = [0];
        }

        pl.p![pl.lit - 1] = im;
      } else if (l != 0) {
        // Short code: init all primary entries
        var pi = c << (_huffmanDecodingBits - l);
        var pl = hdecod[pi];

        for (var i = 1 << (_huffmanDecodingBits - l); i > 0; i--, pi++) {
          pl = hdecod[pi];
          if (pl.len != 0 || pl.p != null) {
            // Error: a short code or a long code has
            // already been stored in table entry *pl.
            throw ImageException('Error in Huffman-encoded data '
                '(invalid code table entry).');
          }

          pl
            ..len = l
            ..lit = im;
        }
      }
    }
  }

  static void unpackEncTable(
      InputBuffer p, int ni, int im, int iM, List<int> hcode) {
    final pcode = p.offset;
    final cLc = [0, 0];

    for (; im <= iM; im++) {
      if (p.offset - pcode > ni) {
        throw ImageException('Error in Huffman-encoded data '
            '(unexpected end of code table data).');
      }

      final l = hcode[im] = getBits(6, cLc, p); // code length

      if (l == _longZeroCodeRun) {
        if (p.offset - pcode > ni) {
          throw ImageException('Error in Huffman-encoded data '
              '(unexpected end of code table data).');
        }

        var zerun = getBits(8, cLc, p) + _shortestLongRun;

        if (im + zerun > iM + 1) {
          throw ImageException('Error in Huffman-encoded data '
              '(code table is longer than expected).');
        }

        while (zerun-- != 0) {
          hcode[im++] = 0;
        }

        im--;
      } else if (l >= _shortZeroCodeRun) {
        var zerun = l - _shortZeroCodeRun + 2;

        if (im + zerun > iM + 1) {
          throw ImageException('Error in Huffman-encoded data '
              '(code table is longer than expected).');
        }

        while (zerun-- != 0) {
          hcode[im++] = 0;
        }

        im--;
      }
    }

    canonicalCodeTable(hcode);
  }

  static int hufLength(int code) => code & 63;

  static int hufCode(int code) => code >> 6;

  static void canonicalCodeTable(List<int> hcode) {
    final n = List<int>.filled(59, 0);

    // For each i from 0 through 58, count the
    // number of different codes of length i, and
    // store the count in n[i].

    for (var i = 0; i < _huffmanEncodingSize; ++i) {
      n[hcode[i]] += 1;
    }

    // For each i from 58 through 1, compute the
    // numerically lowest code with length i, and
    // store that code in n[i].

    var c = 0;

    for (var i = 58; i > 0; --i) {
      final nc = (c + n[i]) >> 1;
      n[i] = c;
      c = nc;
    }

    // hcode[i] contains the length, l, of the
    // code for symbol i. Assign the next available
    // code of length l to the symbol and store both
    // l and the code in hcode[i].

    for (var i = 0; i < _huffmanEncodingSize; ++i) {
      final l = hcode[i];
      if (l > 0) {
        hcode[i] = l | (n[l]++ << 6);
      }
    }
  }

  static void getChar(List<int> cLc, InputBuffer input) {
    cLc[0] = ((cLc[0] << 8) | input.readByte()) & _mask64;
    cLc[1] = (cLc[1] + 8) & _mask32;
  }

  static int getBits(int nBits, List<int> cLc, InputBuffer input) {
    while (cLc[1] < nBits) {
      cLc[0] = ((cLc[0] << 8) | input.readByte()) & _mask64;
      cLc[1] = (cLc[1] + 8) & _mask32;
    }

    cLc[1] -= nBits;

    return (cLc[0] >> cLc[1]) & ((1 << nBits) - 1);
  }

  static const _mask32 = (1 << 32) - 1;
  static const _mask64 = (1 << 64) - 1;
  static const _huffmanEncodingBits = 16; // literal (value) bit length
  static const _huffmanDecodingBits = 14; // decoding bit size (>= 8)

  static const _huffmanEncodingSize = (1 << _huffmanEncodingBits) + 1;
  static const _huffmanDecodingSize = 1 << _huffmanDecodingBits;
  static const _huffmanDecodingMask = _huffmanDecodingSize - 1;

  static const _shortZeroCodeRun = 59;
  static const _longZeroCodeRun = 63;
  static const _shortestLongRun = 2 + _longZeroCodeRun - _shortZeroCodeRun;
  //static const _longestLongRun = 255 + _shortestLongRun;

  // DartAnalyzer doesn't like classes with only static members now, so
  // I added this member for now to avoid the warnings.
  var fixWarnings = 0;
}

class ExrHufDec {
  int len = 0;
  int lit = 0;
  List<int>? p;
}
