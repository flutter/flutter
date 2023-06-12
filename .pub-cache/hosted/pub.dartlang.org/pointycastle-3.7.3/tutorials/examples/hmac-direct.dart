/// HMAC
///
/// Calculates a HMACs from a key and data provided on the command line.
///
/// For example:
///
///     dart hmac-sha1.dart "mykey" "Hello world!"
///
/// Note: this example use Pointy Castle WITHOUT the registry.

import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

// BEGIN EXAMPLE in "../hmac.md"

Uint8List hmacSha256(Uint8List hmacKey, Uint8List data) {
  final hmac = HMac(SHA256Digest(), 64) // HMAC SHA-256: block must be 64 bytes
    ..init(KeyParameter(hmacKey));

  return hmac.process(data);
}

// END EXAMPLE

void hmacWithOtherDigestAlgorithms(Uint8List hmacKey, Uint8List data) {
  final hmacSha256 = HMac(SHA256Digest(), 64);
  final hmacSha512 = HMac(SHA512Digest(), 128);
  final hmacMd2 = HMac(MD2Digest(), 16);
  final hmacMd5 = HMac(MD5Digest(), 64);

  for (final hmac in [hmacSha256, hmacSha512, hmacMd2, hmacMd5]) {
    hmac.init(KeyParameter(hmacKey));
    final value = hmac.process(data);

    print('${hmac.algorithmName}: ${bin2hex(value)}');
  }
}

void main(List<String> args) {
  if (args.length != 2) {
    print('Usage: hmac-direct key data');
    return;
  }

  final key = utf8.encode(args[0]); // first argument is the key
  final data = utf8.encode(args[1]); // second argument is the data

  print('Data: "${args[1]}"');
  final hmacValue =
      hmacSha256(Uint8List.fromList(key), Uint8List.fromList(data));
  //print('HMAC SHA-1: $hmacValue');
  print('HMAC SHA-1: ${bin2hex(hmacValue)}');

  hmacWithOtherDigestAlgorithms(
      Uint8List.fromList(key), Uint8List.fromList(data));
}

//----------------------------------------------------------------
/// Represent bytes in hexadecimal
///
/// If a [separator] is provided, it is placed the hexadecimal characters
/// representing each byte. Otherwise, all the hexadecimal characters are
/// simply concatenated together.

String bin2hex(Uint8List bytes, {String? separator, int? wrap}) {
  var len = 0;
  final buf = StringBuffer();
  for (final b in bytes) {
    final s = b.toRadixString(16);
    if (buf.isNotEmpty && separator != null) {
      buf.write(separator);
      len += separator.length;
    }

    if (wrap != null && wrap < len + 2) {
      buf.write('\n');
      len = 0;
    }

    buf.write('${(s.length == 1) ? '0' : ''}$s');
    len += 2;
  }
  return buf.toString();
}
