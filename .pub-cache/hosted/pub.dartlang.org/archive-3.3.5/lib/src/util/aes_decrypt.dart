import 'dart:typed_data';

// From https://github.com/kokke/tiny-AES-c

class AesDecrypt {
  static const aes128 = 0;
  static const aes192 = 1;
  static const aes256 = 2;

  int mode;
  Uint8List key;

  final Uint8List _roundKey;
  final _iv = Uint8List(16);
  Uint8List? iv;

  AesDecrypt(this.key, { this.mode = aes256 })
    : _roundKey = Uint8List(_expSize[mode]) {
    _keyExpansion(_roundKey, key);
  }

  // Symmetrical operation: same function for encrypting as for decrypting.
  // Note any IV/nonce should never be reused with the same key
  void decryptCrt(Uint8List buffer) {
    final length = buffer.length;
    _iv.fillRange(0, _iv.length, 0);

    for (int i = 0, bi = _aesBlockLen; i < length; ++i, ++bi) {
      // we need to regen xor compliment in buffer
      if (bi == _aesBlockLen) {
        _buffer.setAll(0, _iv);
        _cipher(_buffer, _roundKey);

        for (bi = _aesBlockLen - 1; bi >= 0; --bi) {
          if (_iv[bi] == 255) {
            _iv[bi] = 0;
            continue;
          }
          _iv[bi]++;
          break;
        }
        bi = 0;
      }

      buffer[i] = (buffer[i] ^ _buffer[bi]);
    }
  }

  void _cipher(Uint8List state, Uint8List roundKey) {
    _addRoundKey(0, state, roundKey);
    for (int round = 1; ; ++round) {
      _subBytes(state);
      _shiftRows(state);
      if (round == _nR[mode]) {
        break;
      }
      _mixColumns(state);
      _addRoundKey(round, state, roundKey);
    }
    _addRoundKey(_nR[mode], state, roundKey);
  }

  void _mixColumns(Uint8List state) {
    for (int i = 0, k = 0; i < 4; ++i, k += 4) {
      final t = state[k];
      var tmp = state[k] ^ state[k + 1] ^ state[k + 2] ^ state[k + 3];
      var tm  = state[k] ^ state[k + 1];
      tm = _xtime(tm);
      state[k] ^= tm ^ tmp;
      tm = state[k + 1] ^ state[k + 2];
      tm = _xtime(tm);
      state[k + 1] ^= tm ^ tmp;
      tm = state[k + 2] ^ state[k + 3];
      tm = _xtime(tm);
      state[k + 2] ^= tm ^ tmp;
      tm = state[k + 3] ^ t;
      tm = _xtime(tm);
      state[k + 3] ^= tm ^ tmp;
    }
  }

  int _xtime(int x) {
    return ((x << 1) ^ (((x >> 7) & 1) * 0x1b));
  }

  void _subBytes(Uint8List state) {
    for (int i = 0; i < 16; ++i) {
      state[i] = _sbox[state[i]];
    }
  }

  void _shiftRows(Uint8List state) {
    var temp = state[1];
    state[1] = state[4+1];
    state[4+1] = state[8+1];
    state[8+1] = state[12+1];
    state[12+1] = temp;

    // Rotate second row 2 columns to left  
    temp = state[2];
    state[2] = state[8+2];
    state[8+2] = temp;

    temp = state[4+2];
    state[4+2] = state[12+2];
    state[12+2] = temp;

    // Rotate third row 3 columns to left
    temp = state[3];
    state[3] = state[12+3];
    state[12+3] = state[8+3];
    state[8+3] = state[4+3];
    state[4+3] = temp;
  }

  void _addRoundKey(int round, Uint8List state, Uint8List roundKey) {
    for (int i = 0, k = 0; i < 4; ++i) {
      for (int j = 0; j < 4; ++j, ++k) {
        state[k] ^= roundKey[(round * _nB * 4) + (i * _nB) + j];
      }
    }
  }

  // This function produces Nb(Nr+1) round keys. The round keys are used in
  // each round to decrypt the states.
  void _keyExpansion(Uint8List roundKey, Uint8List key) {
    final tempA = [0, 0, 0, 0];
    for (int i = 0; i < _nK[mode]; ++i) {
      roundKey[(i * 4) + 0] = key[(i * 4) + 0];
      roundKey[(i * 4) + 1] = key[(i * 4) + 1];
      roundKey[(i * 4) + 2] = key[(i * 4) + 2];
      roundKey[(i * 4) + 3] = key[(i * 4) + 3];
    }

    // All other round keys are found from the previous round keys.
    for (int i = _nK[mode]; i < _nB * (_nR[mode] + 1); ++i) {
      {
        int k = (i - 1) * 4;
        tempA[0] = roundKey[k + 0];
        tempA[1] = roundKey[k + 1];
        tempA[2] = roundKey[k + 2];
        tempA[3] = roundKey[k + 3];
      }

      if (i % _nK[mode] == 0) {
        // This function shifts the 4 bytes in a word to the left once.
        // [a0,a1,a2,a3] becomes [a1,a2,a3,a0]

        // Function RotWord()
        {
          final u8tmp = tempA[0];
          tempA[0] = tempA[1];
          tempA[1] = tempA[2];
          tempA[2] = tempA[3];
          tempA[3] = u8tmp;
        }

        // SubWord() is a function that takes a four-byte input word and
        // applies the S-box to each of the four bytes to produce an output word.

        // Function Subword()
        {
          tempA[0] = _sbox[tempA[0]];
          tempA[1] = _sbox[tempA[1]];
          tempA[2] = _sbox[tempA[2]];
          tempA[3] = _sbox[tempA[3]];
        }

        tempA[0] = tempA[0] ^ _rcon[i ~/ _nK[mode]];
      }
      if (mode == aes256) {
        if (i % _nK[mode] == 4) {
          // Function Subword()
          {
            tempA[0] = _sbox[tempA[0]];
            tempA[1] = _sbox[tempA[1]];
            tempA[2] = _sbox[tempA[2]];
            tempA[3] = _sbox[tempA[3]];
          }
        }
      }
      final j = i * 4;
      final k = (i - _nK[mode]) * 4;
      roundKey[j + 0] = roundKey[k + 0] ^ tempA[0];
      roundKey[j + 1] = roundKey[k + 1] ^ tempA[1];
      roundKey[j + 2] = roundKey[k + 2] ^ tempA[2];
      roundKey[j + 3] = roundKey[k + 3] ^ tempA[3];
    }
  }

  static const _aesBlockLen = 16;
  final _buffer = Uint8List(_aesBlockLen);

  //static const _keyLen = [ 16, 24, 32 ];
  static const _expSize = [ 176, 208, 240 ];

  static const _nB = 4;
  static const _nK = [ 4, 6, 8 ];
  static const _nR = [ 10, 12, 14 ];

  static const _sbox = [
  //0     1    2      3     4    5     6     7      8    9     A      B    C     D     E     F
  0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
  0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0,
  0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
  0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75,
  0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0, 0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84,
  0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
  0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8,
  0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2,
  0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
  0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb,
  0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c, 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79,
  0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
  0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a,
  0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e, 0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e,
  0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
  0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16 ];

  static const _rcon = [
  0x8d, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 0x36 ];
}
