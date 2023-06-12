import 'dart:typed_data';

/// Parses IPv4/IPv6 address.
///
Uint8List parseIp(String source) {
  // Find first '.' or ':'
  for (var i = 0; i < source.length; i++) {
    final c = source.substring(i, i + 1);
    switch (c) {
      case ':':
        return Uri.parseIPv6Address(source) as Uint8List;
      case '.':
        return Uri.parseIPv4Address(source) as Uint8List;
    }
  }
  // Not an IP address
  return throw ArgumentError.value(source, 'source');
}

String stringFromIp(Uint8List bytes) {
  switch (bytes.length) {
    case 4:
      return bytes.map((item) => item.toString()).join('.');
    case 16:
      return _stringFromIp6(bytes);
    default:
      throw ArgumentError.value(bytes);
  }
}

String _stringFromIp6(Uint8List bytes) {
  // ---------------------------
  // Find longest span of zeroes
  // ---------------------------

  // Longest seen span
  int? longestStart;
  var longestLength = 0;

  // Current span
  int? start;
  var length = 0;

  // Iterate
  for (var i = 0; i < 16; i++) {
    if (bytes[i] == 0) {
      // Zero byte
      if (start == null) {
        if (i % 2 == 0) {
          // First byte of a span
          start = i;
          length = 1;
        }
      } else {
        length++;
      }
    } else if (start != null) {
      // End of a span
      if (length > longestLength) {
        // Longest so far
        longestStart = start;
        longestLength = length;
      }
      start = null;
    }
  }
  if (start != null && length > longestLength) {
    // End of the longest span
    longestStart = start;
    longestLength = length;
  }

  // Longest length must be a whole group
  longestLength -= longestLength % 2;

  // Ignore longest zero span if it's less than 4 bytes.
  if (longestLength < 4) {
    longestStart = null;
  }

  // ----
  // Print
  // -----
  final sb = StringBuffer();
  var colon = false;
  for (var i = 0; i < 16; i++) {
    if (i == longestStart) {
      sb.write('::');
      i += longestLength - 1;
      colon = false;
      continue;
    }
    final byte = bytes[i];
    if (i % 2 == 0) {
      //
      // First byte of a group
      //
      if (colon) {
        sb.write(':');
      } else {
        colon = true;
      }
      if (byte != 0) {
        sb.write(byte.toRadixString(16));
      }
    } else {
      //
      // Second byte of a group
      //
      // If this is a single-digit number and the previous byte was non-zero,
      // we must add zero
      if (byte < 16 && bytes[i - 1] != 0) {
        sb.write('0');
      }
      sb.write(byte.toRadixString(16));
    }
  }
  return sb.toString();
}
