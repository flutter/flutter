/// Digest with SHA-256 demonstrator
///
/// Calculates the SHA-256 digest for each of the arguments.
///
/// For example:
///
///     dart digest-direct.dart "Hello world!"
///
/// Use a different SHA-256 calculator to check the results. Note: the "-n"
/// option to echo is important, otherwise the bytes being processed will
/// include an extra linefeed at the end and produce a different digest.
///
///     echo -n 'Hello world!' | shasum -a 256
///
/// Note: this example use Pointy Castle WITHOUT the registry.

import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

// BEGIN EXAMPLE in "../digest.md"

Uint8List sha256Digest(Uint8List dataToDigest) {
  final d = SHA256Digest();

  return d.process(dataToDigest);
}

// END EXAMPLE

void main(List<String> args) {
  if (args.contains('-h') || args.contains('--help')) {
    print('Usage: digest-direct {stringsToDigest}');
    return;
  }

  final valuesToDigest = (args.isNotEmpty) ? args : ['Hello world!'];

  for (final data in valuesToDigest) {
    print('Data: "$data"');
    final hash = sha256Digest(utf8.encode(data) as Uint8List);
    print('SHA-256: $hash');
    print('SHA-256: ${bin2hex(hash)}'); // output in hexadecimal
  }
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
