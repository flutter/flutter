int _upperACodeUnit = 'A'.codeUnitAt(0);
int _lowerACodeUnit = 'a'.codeUnitAt(0);
int _digit0CodeUnit = '0'.codeUnitAt(0);

int? _hexCharValue(int charCode) {
  if (charCode >= _upperACodeUnit && charCode < _upperACodeUnit + 6) {
    return charCode - _upperACodeUnit + 10;
  }
  if (charCode >= _upperACodeUnit && charCode < _lowerACodeUnit + 6) {
    return charCode - _lowerACodeUnit + 10;
  }
  if (charCode >= _digit0CodeUnit && charCode < _digit0CodeUnit + 10) {
    return charCode - _digit0CodeUnit;
  }
  return null;
}

int _hexCodeUint4(int value) {
  value = value & 0xF;
  if (value < 10) {
    return _digit0CodeUnit + value;
  } else {
    return _upperACodeUnit + value - 10;
  }
}

int _hex1CodeUint8(int value) {
  return _hexCodeUint4((value & 0xF0) >> 4);
}

int _hex2CodeUint8(int value) {
  return _hexCodeUint4(value);
}

String byteToHex(int value) {
  return String.fromCharCodes([_hex1CodeUint8(value), _hex2CodeUint8(value)]);
}

String bytesToHex(List<int> bytes) {
  final sb = StringBuffer();
  for (final byte in bytes) {
    sb.write(byteToHex(byte));
  }
  return sb.toString();
}

// It safely ignores non hex data so it can contain spaces or line feed
List<int> hexToBytes(String text) {
  final bytes = <int>[];
  int? firstNibble;

  for (var charCode in text.codeUnits) {
    if (firstNibble == null) {
      firstNibble = _hexCharValue(charCode);
    } else {
      final secondNibble = _hexCharValue(charCode);
      if (secondNibble != null) {
        bytes.add(firstNibble * 16 + secondNibble);
        firstNibble = null;
      }
    }
  }
  return bytes;
}
