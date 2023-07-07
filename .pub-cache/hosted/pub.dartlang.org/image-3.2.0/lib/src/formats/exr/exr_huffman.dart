import 'dart:typed_data';

import '../../image_exception.dart';
import '../../util/input_buffer.dart';

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

    if (im < 0 || im >= HUF_ENCSIZE || iM < 0 || iM >= HUF_ENCSIZE) {
      throw ImageException('Invalid huffman table size');
    }

    compressed.skip(4);

    final freq = List<int>.filled(HUF_ENCSIZE, 0);
    final hdec = List<ExrHufDec>.generate(HUF_DECSIZE, (_) => ExrHufDec(),
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
    final c_lc = [0, 0];
    final ie = input.offset + (ni + 7) ~/ 8; // input byte size
    var oi = 0;

    // Loop on input bytes

    while (input.offset < ie) {
      getChar(c_lc, input);

      // Access decoding table
      while (c_lc[1] >= HUF_DECBITS) {
        final pl = hdecod[(c_lc[0] >> (c_lc[1] - HUF_DECBITS)) & HUF_DECMASK];

        if (pl.len != 0) {
          // Get short code
          c_lc[1] -= pl.len;
          oi = getCode(pl.lit, rlc, c_lc, input, out, oi, no);
        } else {
          if (pl.p == null) {
            throw ImageException('Error in Huffman-encoded data '
                '(invalid code).');
          }

          // Search long code
          int j;
          for (j = 0; j < pl.lit; j++) {
            final l = hufLength(hcode[pl.p![j]]);

            while (c_lc[1] < l && input.offset < ie) {
              // get more bits
              getChar(c_lc, input);
            }

            if (c_lc[1] >= l) {
              if (hufCode(hcode[pl.p![j]]) ==
                  ((c_lc[0] >> (c_lc[1] - l)) & ((1 << l) - 1))) {
                // Found : get long code
                c_lc[1] -= l;
                oi = getCode(pl.p![j], rlc, c_lc, input, out, oi, no);
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
    c_lc[0] >>= i;
    c_lc[1] -= i;

    while (c_lc[1] > 0) {
      final pl = hdecod[(c_lc[0] << (HUF_DECBITS - c_lc[1])) & HUF_DECMASK];

      if (pl.len != 0) {
        c_lc[1] -= pl.len;
        oi = getCode(pl.lit, rlc, c_lc, input, out, oi, no);
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

  static int getCode(int po, int rlc, List<int> c_lc, InputBuffer input,
      Uint16List? out, int oi, int oe) {
    if (po == rlc) {
      if (c_lc[1] < 8) {
        getChar(c_lc, input);
      }

      c_lc[1] -= 8;

      var cs = (c_lc[0] >> c_lc[1]) & 0xff;

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

      if (l > HUF_DECBITS) {
        // Long code: add a secondary entry
        final pl = hdecod[(c >> (l - HUF_DECBITS))];

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
        var pi = (c << (HUF_DECBITS - l));
        var pl = hdecod[pi];

        for (var i = 1 << (HUF_DECBITS - l); i > 0; i--, pi++) {
          pl = hdecod[pi];
          if (pl.len != 0 || pl.p != null) {
            // Error: a short code or a long code has
            // already been stored in table entry *pl.
            throw ImageException('Error in Huffman-encoded data '
                '(invalid code table entry).');
          }

          pl.len = l;
          pl.lit = im;
        }
      }
    }
  }

  static void unpackEncTable(
      InputBuffer p, int ni, int im, int iM, List<int> hcode) {
    final pcode = p.offset;
    final c_lc = [0, 0];

    for (; im <= iM; im++) {
      if (p.offset - pcode > ni) {
        throw ImageException('Error in Huffman-encoded data '
            '(unexpected end of code table data).');
      }

      final l = hcode[im] = getBits(6, c_lc, p); // code length

      if (l == LONG_ZEROCODE_RUN) {
        if (p.offset - pcode > ni) {
          throw ImageException('Error in Huffman-encoded data '
              '(unexpected end of code table data).');
        }

        var zerun = getBits(8, c_lc, p) + SHORTEST_LONG_RUN;

        if (im + zerun > iM + 1) {
          throw ImageException('Error in Huffman-encoded data '
              '(code table is longer than expected).');
        }

        while (zerun-- != 0) {
          hcode[im++] = 0;
        }

        im--;
      } else if (l >= SHORT_ZEROCODE_RUN) {
        var zerun = l - SHORT_ZEROCODE_RUN + 2;

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

    for (var i = 0; i < HUF_ENCSIZE; ++i) {
      n[hcode[i]] += 1;
    }

    // For each i from 58 through 1, compute the
    // numerically lowest code with length i, and
    // store that code in n[i].

    var c = 0;

    for (var i = 58; i > 0; --i) {
      final nc = ((c + n[i]) >> 1);
      n[i] = c;
      c = nc;
    }

    // hcode[i] contains the length, l, of the
    // code for symbol i. Assign the next available
    // code of length l to the symbol and store both
    // l and the code in hcode[i].

    for (var i = 0; i < HUF_ENCSIZE; ++i) {
      final l = hcode[i];
      if (l > 0) {
        hcode[i] = l | (n[l]++ << 6);
      }
    }
  }

  static void getChar(List<int> c_lc, InputBuffer input) {
    c_lc[0] = ((c_lc[0] << 8) | input.readByte()) & MASK_64;
    c_lc[1] = (c_lc[1] + 8) & MASK_32;
  }

  static int getBits(int nBits, List<int> c_lc, InputBuffer input) {
    while (c_lc[1] < nBits) {
      c_lc[0] = ((c_lc[0] << 8) | input.readByte()) & MASK_64;
      c_lc[1] = (c_lc[1] + 8) & MASK_32;
    }

    c_lc[1] -= nBits;

    return (c_lc[0] >> c_lc[1]) & ((1 << nBits) - 1);
  }

  static const MASK_32 = (1 << 32) - 1;
  static const MASK_64 = (1 << 64) - 1;
  static const HUF_ENCBITS = 16; // literal (value) bit length
  static const HUF_DECBITS = 14; // decoding bit size (>= 8)

  static const HUF_ENCSIZE = (1 << HUF_ENCBITS) + 1; // encoding table size
  static const HUF_DECSIZE = 1 << HUF_DECBITS; // decoding table size
  static const HUF_DECMASK = HUF_DECSIZE - 1;

  static const SHORT_ZEROCODE_RUN = 59;
  static const LONG_ZEROCODE_RUN = 63;
  static const SHORTEST_LONG_RUN = 2 + LONG_ZEROCODE_RUN - SHORT_ZEROCODE_RUN;
  static const LONGEST_LONG_RUN = 255 + SHORTEST_LONG_RUN;

  // DartAnalyzer doesn't like classes with only static members now, so
  // I added this member for now to avoid the warnings.
  var fixWarnings = 0;
}

class ExrHufDec {
  int len = 0;
  int lit = 0;
  List<int>? p;
}
