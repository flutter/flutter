// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

List<String>? testFiles;

Future<void> testMain() async {
  setUpImplicitView();

  Future<List<String>> createTestFiles() async {
    final HttpFetchResponse listingResponse = await httpFetch('/test_images/');
    List<String> testFiles = (await listingResponse.json() as List<dynamic>).cast<String>();
    testFiles = testFiles.map((String baseName) => '/test_images/$baseName').toList();

    // Also add a nonstandard GIF (regression test for #161376).
    testFiles.add('/test/ui/image/sample_image2.gif');

    // Sanity-check the test file list. If suddenly test files are moved or
    // deleted, and the test server returns an empty list, or is missing some
    // important test files, we want to know.
    assert(testFiles.isNotEmpty);
    assert(testFiles.any((String testFile) => testFile.endsWith('.jpg')));
    assert(testFiles.any((String testFile) => testFile.endsWith('.png')));
    assert(testFiles.any((String testFile) => testFile.endsWith('.gif')));
    assert(testFiles.any((String testFile) => testFile.endsWith('.webp')));
    assert(testFiles.any((String testFile) => testFile.endsWith('.bmp')));

    return testFiles;
  }

  testFiles = await createTestFiles();

  for (final String testFile in testFiles!) {
    test('can detect image type of $testFile', () async {
      final HttpFetchResponse response = await httpFetch(testFile);

      if (!response.hasPayload) {
        throw Exception('Unable to fetch() image test file "$testFile"');
      }

      final Uint8List responseBytes = await response.asUint8List();

      // WebP files which are known to be animated.
      const List<String> animatedWebpFiles = <String>[
        '/test_images/blendBG.webp',
        '/test_images/required.webp',
        '/test_images/stoplight_h.webp',
        '/test_images/stoplight.webp',
      ];

      // GIF files which are known to be animated.
      const List<String> animatedGifFiles = <String>[
        '/test_images/alphabetAnim.gif',
        '/test_images/colorTables.gif',
        '/test_images/flightAnim.gif',
        '/test_images/gif-transparent-index.gif',
        '/test_images/randPixelsAnim.gif',
        '/test_images/randPixelsAnim2.gif',
        '/test_images/required.gif',
        '/test_images/test640x479.gif',
        '/test_images/xOffsetTooBig.gif',
        '/test/ui/image/sample_image2.gif',
      ];

      final String testFileExtension = testFile.substring(testFile.lastIndexOf('.') + 1);
      final ImageType? expectedImageType = switch (testFileExtension) {
        'jpg' => ImageType.jpeg,
        'jpeg' => ImageType.jpeg,
        'gif' => animatedGifFiles.contains(testFile) ? ImageType.animatedGif : ImageType.gif,
        'webp' => animatedWebpFiles.contains(testFile) ? ImageType.animatedWebp : ImageType.webp,
        'avif' => ImageType.avif,
        'bmp' => ImageType.bmp,
        'png' => ImageType.png,
        _ => null,
      };

      expect(detectImageType(responseBytes), expectedImageType);
    });
  }
}
