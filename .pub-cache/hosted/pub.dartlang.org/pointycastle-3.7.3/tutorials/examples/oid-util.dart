/// Converts an Object Identifier from one format to another.
///
/// Shows the BER encoding for a dotted OID or decodes a BER encoding and
/// shows its value as a dotted OID.
///
/// Example:
///     oid-util 2.16.840.1.101.3.4.2.1
///     oid-util 0609608648016503040201
///
/// This program was written to check some of the "magic values" in the
/// Pointy Castle source code.

import 'dart:typed_data';

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

//----------------------------------------------------------------
// Decode a hexadecimal string into a sequence of bytes.

Uint8List hex2bin(String hexStr) {
  if (hexStr.length % 2 != 0) {
    throw const FormatException('not an even number of hexadecimal characters');
  }
  final result = Uint8List(hexStr.length ~/ 2);
  for (var i = 0; i < result.length; i++) {
    result[i] = int.parse(hexStr.substring(2 * i, 2 * (i + 1)), radix: 16);
  }
  return result;
}

//----------------------------------------------------------------

List<int> decodeBERObjectIdentifier(Uint8List bytes) {
  if (bytes.length < 2) {
    throw const FormatException('BER missing tag and length');
  }

  // final tag = bytes[0];

  // Decode the length

  int contentLength;
  int contentStart;

  var n = bytes[1] & 0x7F;
  if (bytes[1] & 0x80 == 0) {
    // Length is <128 and encoded completely in the second byte
    contentStart = 2; // skipping over tag and one-byte length
    contentLength = n;
  } else {
    // Length is encoded in the following n bytes
    if (bytes.length < 1 + 1 + n) {
      throw const FormatException('BER length is incomplete');
    }
    contentStart = 1 + n; // skipping over tag and bytes for the length
    contentLength = 0;
    while (0 < n) {
      contentLength = (contentLength << 8) | bytes[n];
      n--;
    }
  }
  if (contentLength == 0) {
    throw const FormatException('BER has no content');
  }
  if (bytes.length < contentStart + contentLength) {
    throw const FormatException('BER is incomplete');
  }

  // Decode the content as an Object Identifier

  // First two components are encoded in the first byte

  final components = <int>[bytes[contentStart] ~/ 40, bytes[contentStart] % 40];
  if (components[0] == 0 || components[1] == 0) {
    throw const FormatException('invalid zero OID component');
  }

  // Process rest of bytes in the content

  var v = 0; // partial or complete component value
  for (var n = contentStart + 1; n < contentStart + contentLength; n++) {
    final byte = bytes[n];

    v = (v << 7) + (byte & 0x7F);
    if (byte & 0x80 == 0) {
      // Value is complete
      if (v == 0) {
        throw const FormatException('invalid zero OID component');
      }
      components.add(v);
      v = 0;
    } else {
      // Value continues in next byte(s)
      assert(v != 0);
    }
  }
  if (v != 0) {
    throw const FormatException('incomplete OID content');
  }
  if ((contentStart + contentLength) < bytes.length) {
    throw const FormatException(('extra bytes after OID'));
  }

  return components;
}

//----------------------------------------------------------------

Uint8List encodeBERObjectIdentifier(String oidStr, {int tag = 0x06}) {
  assert((0 <= tag) && (tag <= 255), 'tag does not fit into a byte');

  // Convert the string "1.2.3.4" into list of numbers [1, 2, 3, 4]
  final components = oidStr.split('.').map(int.parse);

  // Encode the content

  final bytes = <int>[tag, -1]; // with a placeholder for a one-byte length

  late int firstComponent;
  var componentIndex = 0;
  for (final component in components) {
    if (component <= 0) {
      throw FormatException('invalid OID component: $component');
    }
    if (componentIndex == 0) {
      // Save for processing with the second component
      firstComponent = component;
    } else if (componentIndex == 1) {
      // Encode first two components into the first byte
      bytes.add(firstComponent * 40 + component);
    } else {
      // Subsequent components
      if (component <= 0x7F) {
        // Represent with a single byte
        bytes.add(component);
      } else {
        // Represent by multiple bytes
        final code = <int>[];

        var v = component;
        while (0 < v) {
          code.add((v & 0x7F) | 0x80); // 7-bits and the continue flag set
          v >>= 7;
        }
        code[0] &= 0x7F; // clear flag on least-significant-byte

        bytes.addAll(code.reversed); // include with most-significant-byte first
      }
    }
    componentIndex++;
  }

  // Fix up tag and length

  if (bytes.length - 2 < 127) {
    // Length can be represented by a single byte: use the bytes as the result
    bytes[1] = (bytes.length - 2);
    return Uint8List.fromList(bytes);
  } else {
    // Length needs multiple bytes: create bigger list and copy the bytes to it

    final lengthEnc = <int>[]; // first encode the length (temporary LSB order)
    var v = (bytes.length - 2);
    while (0 < v) {
      lengthEnc.add(v & 0x7F);
      v >>= 7;
    }

    // Create a new list and populate it

    final result = Uint8List(1 + 1 + lengthEnc.length + (bytes.length - 2));

    result[0] = tag;

    result[1] = lengthEnc.length | 0x80; // number bytes representing length
    result.insertAll(2, lengthEnc.reversed); // in correct MSB order

    final startOfContent = 1 + 1 + lengthEnc.length;
    for (var x = 0; x < bytes.length - 2; x++) {
      result[startOfContent + x] = bytes[2 + x];
    }

    return result;
  }
}

//----------------------------------------------------------------

int main(List<String> args) {
  if (args.isNotEmpty && !args.contains('-h') && !args.contains('--help')) {
    for (final str in args) {
      try {
        if (str.contains('.')) {
          // Encode a OID into BER
          final enc = encodeBERObjectIdentifier(str);
          print(bin2hex(enc));
        } else {
          // Decode hex BER into components and show in dotted form
          final bytes = hex2bin(str);
          final components = decodeBERObjectIdentifier(bytes);
          print(components.map((n) => '$n').join('.'));
        }
      } catch (e) {
        print('Error: $str: $e');
      }
    }
  } else {
    print('Usage: oid-util values...');
    print('  values are either dotted OIDs (e.g. "2.16.840.1.101.3.4.2.1") or');
    print('  DER encoding of OIDs in hex (e.g. "0609608648016503040201")');
    print('  This program convert from one format to the other.');
  }
  return 0;
}
