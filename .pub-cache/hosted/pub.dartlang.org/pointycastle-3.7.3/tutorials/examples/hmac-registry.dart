/// HMAC with SHA-256
///
/// Calculates a HMAC SHA-256 from a key and data provided on the command line.
///
/// For example:
///
///     dart hmac-sha256.dart "mykey" "Hello world!"
///
/// Note: this example use Pointy Castle WITH the registry.

import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/pointycastle.dart';

Uint8List hmacSha256(Uint8List hmacKey, Uint8List data) {
  final hmac = Mac('SHA-256/HMAC')..init(KeyParameter(hmacKey));

  return hmac.process(data);
}

void main(List<String> args) {
  if (args.length != 2) {
    print('Usage: hmac-registry key data');
    return;
  }

  final key = utf8.encode(args[0]); // first argument is the key
  final data = utf8.encode(args[1]); // second argument is the data

  final hmacValue =
      hmacSha256(Uint8List.fromList(key), Uint8List.fromList(data));
  print('HMAC SHA-256: $hmacValue');
  print('HMAC SHA-256: ${bin2hex(hmacValue)}');
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
