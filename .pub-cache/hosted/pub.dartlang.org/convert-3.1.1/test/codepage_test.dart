// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:test/test.dart';

void main() {
  var bytes = Uint8List.fromList([for (var i = 0; i < 256; i++) i]);
  for (var cp in [
    latin2,
    latin3,
    latin4,
    latin5,
    latin6,
    latin7,
    latin8,
    latin9,
    latin10,
    latinCyrillic,
    latinGreek,
    latinHebrew,
    latinThai,
    latinArabic
  ]) {
    test('${cp.name} codepage', () {
      // All ASCII compatible.
      for (var byte = 0x20; byte < 0x7f; byte++) {
        expect(cp[byte], byte);
      }
      // Maps both directions.
      for (var byte = 0; byte < 256; byte++) {
        var char = cp[byte];
        if (char != 0xFFFD) {
          var string = String.fromCharCode(char);
          expect(cp.encode(string), [byte]);
          expect(cp.decode([byte]), string);
        }
      }
      expect(() => cp.decode([0xfffd]), throwsA(isA<FormatException>()));
      // Decode works like operator[].
      expect(cp.decode(bytes, allowInvalid: true),
          String.fromCharCodes([for (var i = 0; i < 256; i++) cp[i]]));
    });
  }
  test('latin-2 roundtrip', () {
    // Data from http://www.columbia.edu/kermit/latin2.html
    var latin2text = '\xa0Ą˘Ł¤ĽŚ§¨ŠŞŤŹ\xadŽŻ°ą˛ł´ľśˇ¸šşťź˝žżŔÁÂĂÄĹĆÇČÉĘËĚÍÎĎĐŃŇ'
        'ÓÔŐÖ×ŘŮÚŰÜÝŢßŕáâăäĺćçčéęëěíîďđńňóôőö÷řůúűüýţ˙';
    expect(latin2.decode(latin2.encode(latin2text)), latin2text);
  });

  test('latin-3 roundtrip', () {
    // Data from http://www.columbia.edu/kermit/latin3.html
    var latin2text = '\xa0Ħ˘£¤\u{FFFD}Ĥ§¨İŞĞĴ\xad\u{FFFD}Ż°ħ²³´µĥ·¸ışğĵ½'
        '\u{FFFD}żÀÁÂ\u{FFFD}ÄĊĈÇÈÉÊËÌÍÎÏ\u{FFFD}ÑÒÓÔĠÖ×ĜÙÚÛÜŬŜßàáâ'
        '\u{FFFD}äċĉçèéêëìíîï\u{FFFD}ñòóôġö÷ĝùúûüŭŝ˙';
    var encoded = latin3.encode(latin2text, invalidCharacter: 0);
    var decoded = latin3.decode(encoded, allowInvalid: true);
    expect(decoded, latin2text);
  });

  test('Custom code page', () {
    var cp = CodePage('custom', "ABCDEF${"\uFFFD" * 250}");
    var result = cp.encode('BADCAFE');
    expect(result, [1, 0, 3, 2, 0, 5, 4]);
    expect(() => cp.encode('GAD'), throwsFormatException);
    expect(cp.encode('GAD', invalidCharacter: 0x3F), [0x3F, 0, 3]);
    expect(cp.decode([1, 0, 3, 2, 0, 5, 4]), 'BADCAFE');
    expect(() => cp.decode([6, 1, 255]), throwsFormatException);
    expect(cp.decode([6, 1, 255], allowInvalid: true), '\u{FFFD}B\u{FFFD}');
  });
}
