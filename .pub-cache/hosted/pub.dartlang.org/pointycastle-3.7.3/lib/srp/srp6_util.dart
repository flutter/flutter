library src.srp_util;

import 'dart:typed_data';
import 'package:pointycastle/pointycastle.dart';
import 'dart:math' as math;

class SRP6Util {
  static final _byteMask = BigInt.from(0xff);

  static BigInt calculateK(Digest digest, BigInt N, BigInt g) {
    return hashPaddedPair(digest, N, N, g);
  }

  static BigInt calculateU(Digest digest, BigInt N, BigInt? A, BigInt? B) {
    return hashPaddedPair(digest, N, A, B);
  }

  static BigInt calculateX(Digest digest, BigInt N, Uint8List salt,
      Uint8List identity, Uint8List password) {
    var output = Uint8List(digest.digestSize);

    digest.update(identity, 0, identity.length);
    digest.updateByte(':'.codeUnitAt(0));
    digest.update(password, 0, password.length);
    digest.doFinal(output, 0);

    digest.update(salt, 0, salt.length);
    digest.update(output, 0, output.length);
    digest.doFinal(output, 0);

    return decodeBigInt(output);
  }

  /// Decode a BigInt from bytes in big-endian encoding.
  static BigInt decodeBigInt(List<int> bytes) {
    var result = BigInt.from(0);
    for (var i = 0; i < bytes.length; i++) {
      result += BigInt.from(bytes[bytes.length - i - 1]) << (8 * i);
    }
    return result;
  }

  /// Encode a BigInt into bytes using big-endian encoding.
  static Uint8List encodeBigInt(BigInt number) {
    // Not handling negative numbers. Decide how you want to do that.
    var size = (number.bitLength + 7) >> 3;
    var result = Uint8List(size);
    for (var i = 0; i < size; i++) {
      result[size - i - 1] = (number & _byteMask).toInt();
      number = number >> 8;
    }
    return result;
  }

  static BigInt? generatePrivateValue(
      Digest digest, BigInt N, BigInt g, SecureRandom random) {
    var minBits = math.min(256, N.bitLength ~/ 2);
    var min = BigInt.one << (minBits - 1);
    var max = N - BigInt.one;

    var result;
    do {
      result = random.nextBigInteger(minBits);
    } while (result > max || result < min);
    return result;
  }

  static BigInt validatePublicValue(BigInt N, BigInt val) {
    val = val % N;

    // Check that val % N != 0
    if (val == BigInt.zero) {
      throw Exception('Invalid public value: 0');
    }

    return val;
  }

  /// Computes the client evidence message (M1) according to the standard routine:
  /// M1 = H( A | B | S )
  /// [digest] The Digest used as the hashing function H
  /// [N] Modulus used to get the pad length
  /// [A] The public client value
  /// [B] The public server value
  /// [S] The secret calculated by both sides
  /// [M1] The calculated client evidence message
  static BigInt calculateM1(
      Digest digest, BigInt N, BigInt? A, BigInt? B, BigInt? S) {
    return hashPaddedTriplet(digest, N, A, B, S);
  }

  /// Computes the server evidence message (M2) according to the standard routine:
  /// M2 = H( A | M1 | S )
  /// [digest] The Digest used as the hashing function H
  /// [N] Modulus used to get the pad length
  /// [A] The public client value
  /// [M1] The client evidence message
  /// [S] The secret calculated by both sides
  /// @return M2 The calculated server evidence message
  static BigInt calculateM2(
      Digest digest, BigInt N, BigInt? A, BigInt? M1, BigInt? S) {
    return hashPaddedTriplet(digest, N, A, M1, S);
  }

  /// Computes the final Key according to the standard routine: Key = H(S)
  /// [digest] The Digest used as the hashing function H
  /// [N] Modulus used to get the pad length
  /// [S] The secret calculated by both sides
  /// @return the final Key value.
  static BigInt calculateKey(Digest digest, BigInt N, BigInt? S) {
    var padLength = (N.bitLength + 7) ~/ 8;
    var _S = getPadded(S!, padLength);
    digest.update(_S, 0, _S.length);

    var output = Uint8List(digest.digestSize);
    digest.doFinal(output, 0);
    return decodeBigInt(output);
  }

  static BigInt hashPaddedTriplet(
      Digest digest, BigInt N, BigInt? n1, BigInt? n2, BigInt? n3) {
    var padLength = (N.bitLength + 7) ~/ 8;

    var n1Bytes = getPadded(n1!, padLength);
    var n2Bytes = getPadded(n2!, padLength);
    var n3Bytes = getPadded(n3!, padLength);

    digest.update(n1Bytes, 0, n1Bytes.length);
    digest.update(n2Bytes, 0, n2Bytes.length);
    digest.update(n3Bytes, 0, n3Bytes.length);

    var output = Uint8List(digest.digestSize);
    digest.doFinal(output, 0);

    return decodeBigInt(output);
  }

  static Uint8List getPadded(BigInt n, int length) {
    var bs = encodeBigInt(n);
    if (bs.length < length) {
      var tmp = Uint8List(length);
      var start = (length - bs.length);
      for (var i = 0; start < length; i++, start++) {
        tmp[start] = bs[i];
      }
      bs = tmp;
    }
    return bs;
  }

  static BigInt hashPaddedPair(
      Digest digest, BigInt N, BigInt? n1, BigInt? n2) {
    var padLength = (N.bitLength + 7) ~/ 8;

    var n1Bytes = getPadded(n1!, padLength);
    var n2Bytes = getPadded(n2!, padLength);

    digest.update(n1Bytes, 0, n1Bytes.length);
    digest.update(n2Bytes, 0, n2Bytes.length);

    var output = Uint8List(digest.digestSize);
    digest.doFinal(output, 0);

    return decodeBigInt(output);
  }
}
