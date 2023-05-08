// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('browser') // Uses web-only Flutter SDK
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_plugins/src/navigation/utils.dart';

void main() {
  test('checks base href', () {
    expect(() => checkBaseHref(null), throwsException);
    expect(() => checkBaseHref('foo'), throwsException);
    expect(() => checkBaseHref('/foo'), throwsException);
    expect(() => checkBaseHref('foo/bar'), throwsException);
    expect(() => checkBaseHref('/foo/bar'), throwsException);

    expect(() => checkBaseHref('/'), returnsNormally);
    expect(() => checkBaseHref('/foo/'), returnsNormally);
    expect(() => checkBaseHref('/foo/bar/'), returnsNormally);
  });

  test('extracts pathname from URL', () {
    expect(extractPathname('/'), '/');
    expect(extractPathname('/foo'), '/foo');
    expect(extractPathname('/foo/'), '/foo/');
    expect(extractPathname('/foo/bar'), '/foo/bar');
    expect(extractPathname('/foo/bar/'), '/foo/bar/');

    expect(extractPathname('https://example.com'), '/');
    expect(extractPathname('https://example.com/'), '/');
    expect(extractPathname('https://example.com/foo'), '/foo');
    expect(extractPathname('https://example.com/foo#bar'), '/foo');
    expect(extractPathname('https://example.com/foo/#bar'), '/foo/');
  });
}
