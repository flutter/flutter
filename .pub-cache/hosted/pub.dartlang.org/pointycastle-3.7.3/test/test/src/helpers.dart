// See file LICENSE for more information.

library test.test.src.helpers;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/paddings/pkcs7.dart';
import 'package:test/test.dart';

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Format //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

String formatAsTruncated(String str) {
  if (str.length > 26) {
    return str.substring(0, 26) + '[...]';
  } else if (str.isEmpty) {
    return '(empty string)';
  } else {
    return str;
  }
}

String formatAsHumanSize(num size) {
  if (size < 1024) return '$size B';
  if (size < 1024 * 1024) return '${_format(size / 1024)} KB';
  if (size < 1024 * 1024 * 1024) return '${_format(size / (1024 * 1024))} MB';
  return '${_format(size / (1024 * 1024 * 1024))} GB';
}

String formatBytesAsHexString(Uint8List bytes) {
  var result = StringBuffer();
  for (var i = 0; i < bytes.lengthInBytes; i++) {
    var part = bytes[i];
    result.write('${part < 16 ? '0' : ''}${part.toRadixString(16)}');
  }
  return result.toString();
}

String _format(double val) {
  if (val.isInfinite) {
    return 'INF';
  } else if (val.isNaN) {
    return 'NaN';
  } else {
    return val.floor().toString() +
        '.' +
        (100 * (val - val.toInt())).toInt().toString();
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Data ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Uint8List createUint8ListFromString(String s) {
  var ret = Uint8List(s.length);
  for (var i = 0; i < s.length; i++) {
    ret[i] = s.codeUnitAt(i);
  }
  return ret;
}

Uint8List createUint8ListFromHexString(String hex) {
  hex = hex.replaceAll(RegExp(r'\s'), ''); // remove all whitespace, if any

  var result = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < hex.length; i += 2) {
    var num = hex.substring(i, i + 2);
    var byte = int.parse(num, radix: 16);
    result[i ~/ 2] = byte;
  }
  return result;
}

Uint8List createUint8ListFromSequentialNumbers(int len) {
  var ret = Uint8List(len);
  for (var i = 0; i < len; i++) {
    ret[i] = i;
  }
  return ret;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Matchers ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
const isAllZeros = _IsAllZeros();

class _IsAllZeros extends Matcher {
  const _IsAllZeros();

  @override
  bool matches(covariant Iterable<int> item, Map matchState) {
    for (var i in item) {
      if (i != 0) return false;
    }
    return true;
  }

  @override
  Description describe(Description description) =>
      description.add('is all zeros');

  @override
  Description describeMismatch(item, Description mismatchDescription,
          Map matchState, bool verbose) =>
      mismatchDescription.add('is not all zeros');
}

void blockCipherTest(int id, BlockCipher cipher, CipherParameters parameters,
    String input, String output) {
  test('BlockCipher Test: $id ', () {
    var _input = createUint8ListFromHexString(input);
    var _output = createUint8ListFromHexString(output);

    cipher.init(true, parameters);
    var out = Uint8List(_input.length);
    var p = 0;
    while (p < _input.length) {
      p += cipher.processBlock(_input, p, out, p);
    }

    expect(_output, equals(out), reason: '$id did not match output');

    cipher.init(false, parameters);
    out = Uint8List(_output.length);
    p = 0;
    while (p < _output.length) {
      p += cipher.processBlock(_output, p, out, p);
    }

    expect(_input, equals(out), reason: '$id did not match input');
  });
}

void streamCipherTest(int id, StreamCipher cipher, CipherParameters parameters,
    String input, String output) {
  test('StreamCipher Test: $id ', () {
    var _input = createUint8ListFromHexString(input);
    var _output = createUint8ListFromHexString(output);

    cipher.init(true, parameters);
    var out = cipher.process(_input);

    expect(_output, equals(out), reason: '$id did not match output');

    cipher.init(false, parameters);
    out = cipher.process(out);

    expect(_input, equals(out), reason: '$id did not match input');
  });
}

Uint8List addPKCS7Padding(Uint8List bytes, int blockSizeBytes) {
  final padLength = blockSizeBytes - (bytes.length % blockSizeBytes);

  final padded = Uint8List(bytes.length + padLength)..setAll(0, bytes);
  PKCS7Padding().addPadding(padded, bytes.length);

  return padded;
}
