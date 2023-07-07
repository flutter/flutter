// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/src/fife.dart';

void main() {
  group('addSizeDirectiveToUrl', () {
    const double size = 20;

    group('Old style URLs', () {
      const String base =
          'https://lh3.googleusercontent.com/-ukEAtRyRhw8/AAAAAAAAAAI/AAAAAAAAAAA/ACHi3rfhID9XACtdb9q_xK43VSXQvBV11Q.CMID';
      const String expected = '$base/s20-c/photo.jpg';

      test('with directives, sets size', () {
        const String url = '$base/s64-c/photo.jpg';
        expect(addSizeDirectiveToUrl(url, size), expected);
      });

      test('no directives, sets size and crop', () {
        const String url = '$base/photo.jpg';
        expect(addSizeDirectiveToUrl(url, size), expected);
      });

      test('no crop, sets size and crop', () {
        const String url = '$base/s64/photo.jpg';
        expect(addSizeDirectiveToUrl(url, size), expected);
      });
    });

    group('New style URLs', () {
      const String base =
          'https://lh3.googleusercontent.com/a-/AAuE7mC0Lh4F4uDtEaY7hpe-GIsbDpqfMZ3_2UhBQ8Qk';
      const String expected = '$base=c-s20';

      test('with directives, sets size', () {
        const String url = '$base=s120-c';
        expect(addSizeDirectiveToUrl(url, size), expected);
      });

      test('no directives, sets size and crop', () {
        const String url = base;
        expect(addSizeDirectiveToUrl(url, size), expected);
      });

      test('no directives, but with an equals sign, sets size and crop', () {
        const String url = '$base=';
        expect(addSizeDirectiveToUrl(url, size), expected);
      });

      test('no crop, adds crop', () {
        const String url = '$base=s120';
        expect(addSizeDirectiveToUrl(url, size), expected);
      });

      test('many directives, sets size and crop, preserves other directives',
          () {
        const String url = '$base=s120-c-fSoften=1,50,0';
        const String expected = '$base=c-fSoften=1,50,0-s20';
        expect(addSizeDirectiveToUrl(url, size), expected);
      });
    });
  });
}
