/// Digest with SHA-256 demonstrator
///
/// Calculates the MD5 digest for each of the arguments.
///
/// For example:
///
///     dart digest-registry.dart "Hello world!"
///
/// Use a different MD5 calculator to check the results. Note: the "-n"
///
///     md5 -s 'Hello world!'
///
/// Note: this example use Pointy Castle WITH the registry.

import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/pointycastle.dart';

Uint8List md5Digest(Uint8List dataToDigest) {
  var d = Digest('MD5');

  return d.process(dataToDigest);
}

void main(List<String> args) {
  if (args.contains('-h') || args.contains('--help')) {
    print('Usage: digest-registry {stringsToDigest}');
    return;
  }

  final valuesToDigest = (args.isNotEmpty) ? args : ['Hello world!'];

  for (final data in valuesToDigest) {
    print('Data: "$data"');
    final hash = md5Digest(Uint8List.fromList(utf8.encode(data)));
    print('MD5: $hash');
    print('MD5: ${bin2hex(hash)}'); // output in hexadecimal
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
