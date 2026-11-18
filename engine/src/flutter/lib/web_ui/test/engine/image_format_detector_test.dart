// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';
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
    List<String> testFiles = ((await listingResponse.json() as JSAny?).dartify()! as List<Object?>)
        .cast<String>();
    testFiles = testFiles.map((String baseName) => '/test_images/$baseName').toList();

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
      const animatedWebpFiles = <String>[
        '/test_images/blendBG.webp',
        '/test_images/required.webp',
        '/test_images/stoplight_h.webp',
        '/test_images/stoplight.webp',
      ];

      // GIF files which are known to be animated.
      const animatedGifFiles = <String>[
        '/test_images/alphabetAnim.gif',
        '/test_images/colorTables.gif',
        '/test_images/flightAnim.gif',
        '/test_images/gif-transparent-index.gif',
        '/test_images/randPixelsAnim.gif',
        '/test_images/randPixelsAnim2.gif',
        '/test_images/required.gif',
        '/test_images/test640x479.gif',
        '/test_images/xOffsetTooBig.gif',
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

  test('can decode GIF with many nonstandard Special Purpose Blocks', () async {
    expect(detectImageType(_createTestGif()), ImageType.animatedGif);
  });

  group('detects image type of a Uint8List view into a larger buffer', () {
    Future<Uint8List> fetchBytes(String url) async {
      final HttpFetchResponse response = await httpFetch(url);
      if (!response.hasPayload) {
        throw Exception('Unable to fetch() image test file "$url"');
      }
      return response.asUint8List();
    }

    Future<Uint8List> animatedWebp() => fetchBytes('/test_images/stoplight.webp');
    Future<Uint8List> staticWebp() => fetchBytes('/test_images/baby_tux.webp');
    Future<Uint8List> animatedGif() async => _createTestGif();
    Future<Uint8List> staticGif() async => _createTestGif(numFrames: 1);

    final fixtures = <(String, Future<Uint8List> Function(), ImageType)>[
      ('animated WebP', animatedWebp, ImageType.animatedWebp),
      ('static WebP', staticWebp, ImageType.webp),
      ('animated GIF', animatedGif, ImageType.animatedGif),
      ('static GIF', staticGif, ImageType.gif),
      // The test server does not serve .avif files, so use an in-memory 'ftyp'
      // box, which is all that AVIF detection looks at.
      (
        'AVIF',
        () async => Uint8List.fromList(<int>[
          ...<int>[0x00, 0x00, 0x00, 0x14],
          ...'ftypavif'.codeUnits,
          ...<int>[0x00, 0x00, 0x00, 0x00],
          ...'avif'.codeUnits,
        ]),
        ImageType.avif,
      ),
    ];

    // (leading, trailing) padding byte counts. (3, 1) places the view at an
    // offset that is not 4-byte aligned within its buffer.
    const paddings = <(int, int)>[(32, 0), (0, 16), (32, 16), (48, 16), (3, 1)];

    for (final (String name, Future<Uint8List> Function() loadBytes, ImageType expected)
        in fixtures) {
      for (final (int leading, int trailing) in paddings) {
        test('$name with $leading leading and $trailing trailing padding bytes', () async {
          final Uint8List source = await loadBytes();
          final Uint8List view = _createPaddedSubview(
            source,
            leadingPadding: leading,
            trailingPadding: trailing,
          );
          expect(detectImageType(view), expected);
        });
      }
    }

    final staticAfterAnimated =
        <(String, Future<Uint8List> Function(), Future<Uint8List> Function(), ImageType)>[
          ('static WebP', animatedWebp, staticWebp, ImageType.webp),
          ('static GIF', animatedGif, staticGif, ImageType.gif),
        ];

    for (final (
          String name,
          Future<Uint8List> Function() loadPreceding,
          Future<Uint8List> Function() loadBytes,
          ImageType expected,
        )
        in staticAfterAnimated) {
      test('$name stored right after an animated image in the same buffer', () async {
        final Uint8List preceding = await loadPreceding();
        final Uint8List source = await loadBytes();
        final backing = Uint8List(preceding.length + source.length)
          ..setAll(0, preceding)
          ..setAll(preceding.length, source);
        final view = Uint8List.sublistView(backing, preceding.length);
        expect(detectImageType(view), expected);
      });
    }
  });

  group('handles truncated and malformed image buffers gracefully', () {
    // 21 bytes: the 12-byte RIFF/WEBP header, the 8-byte VP8X chunk header and
    // the VP8X flags byte with the animation bit set.
    final Uint8List animatedWebpHeader = _createWebpVp8xHeader(flags: 0x02);

    for (final (int length, ImageType? expected) in <(int, ImageType?)>[
      (0, null),
      (11, null),
      (12, ImageType.webp),
      (20, ImageType.webp),
      (21, ImageType.animatedWebp),
    ]) {
      test('WebP header truncated to $length bytes is detected as $expected', () {
        final view = Uint8List.sublistView(animatedWebpHeader, 0, length);
        expect(detectImageType(view), expected);
      });
    }

    test('WebpHeaderReader.isAnimated() returns false for truncated buffers', () {
      expect(WebpHeaderReader(ByteData(0)).isAnimated(), isFalse);
      expect(
        WebpHeaderReader(ByteData.sublistView(animatedWebpHeader, 0, 20)).isAnimated(),
        isFalse,
      );
    });

    // Byte layout of the 114-byte `_createTestGif(numFrames: 1)`:
    //   0-5     'GIF89a' header
    //   6-12    logical screen descriptor (no global color table)
    //   13-33   comment extension
    //   34-41   graphic control extension
    //   42-62   comment extension
    //   63-72   image descriptor
    //   73      LZW minimum code size
    //   74-91   image data sub-block (16 bytes) and block terminator
    //   92-112  comment extension
    //   113     trailer (0x3b)
    final Uint8List staticGif = _createTestGif(numFrames: 1);
    Uint8List gifPrefix(int length) => Uint8List.sublistView(staticGif, 0, length);
    final Uint8List firstFrame = gifPrefix(92);
    // The image descriptor, LZW minimum code size and image data of the first
    // frame, used to append another frame.
    final imageFrame = Uint8List.sublistView(staticGif, 63, 92);

    final gifCases = <(String, List<int>, ImageType?)>[
      ('a partial GIF signature', gifPrefix(5), null),
      ('a GIF89a header only', gifPrefix(6), ImageType.gif),
      ('a truncated logical screen descriptor', gifPrefix(12), ImageType.gif),
      (
        // Packed fields 0xf7 declare a 768-byte global color table, but only
        // 7 bytes of it are present.
        'a truncated global color table',
        <int>[...gifPrefix(10), 0xf7, 0, 0, ...List<int>.filled(7, 0)],
        ImageType.gif,
      ),
      ('a truncated graphic control extension', gifPrefix(38), ImageType.gif),
      ('a truncated LZW data sub-block', gifPrefix(80), ImageType.gif),
      ('1 frame and no trailer', firstFrame, ImageType.gif),
      (
        'an unknown extension label',
        <int>[...gifPrefix(13), 0x21, 0x42, 0x03, 0x01, 0x02, 0x03, 0x00, ...staticGif.sublist(13)],
        ImageType.gif,
      ),
      (
        'an image separator that is not 0x2c',
        Uint8List.fromList(staticGif)..[63] = 0x2d,
        ImageType.gif,
      ),
      (
        'a data sub-block declaring 255 bytes when 5 remain',
        <int>[...gifPrefix(74), 0xff, ...List<int>.filled(5, 0x41)],
        ImageType.gif,
      ),
      (
        '1 frame followed by comment and application extensions',
        <int>[
          ...firstFrame,
          ...Uint8List.sublistView(staticGif, 92, 113),
          ...<int>[0x21, 0xff, 0x0b, ...'NETSCAPE2.0'.codeUnits, 0x03, 0x01, 0x00, 0x00, 0x00],
          0x3b,
        ],
        ImageType.gif,
      ),
      ('1 frame followed by a garbage byte', <int>[...firstFrame, 0x00], ImageType.gif),
      for (final int label in <int>[0xfa, 0xfd, 0x80, 0x42])
        (
          // Extension introducer, the label, one 3-byte data sub-block and the
          // block terminator.
          'a 0x${label.toRadixString(16)} extension between 2 frames',
          <int>[...firstFrame, 0x21, label, 0x03, 0x01, 0x02, 0x03, 0x00, ...imageFrame, 0x3b],
          ImageType.animatedGif,
        ),
      (
        'a truncated unknown extension after 1 frame',
        <int>[...firstFrame, 0x21, 0x80, 0x03, 0x01],
        ImageType.gif,
      ),
      (
        // Packed fields 0xf7 declare a 768-byte global color table, which
        // ends exactly where the first frame starts.
        'a full-size global color table and 2 frames',
        <int>[
          ...gifPrefix(10),
          0xf7,
          0,
          0,
          ...List<int>.filled(768, 0),
          ...imageFrame,
          ...imageFrame,
          0x3b,
        ],
        ImageType.animatedGif,
      ),
      (
        // Extension introducer, Plain Text label, block size, 12 bytes of text
        // grid fields, one 1-byte data sub-block and the block terminator.
        'a plain text extension as the first frame',
        <int>[
          ...gifPrefix(13),
          ...<int>[0x21, 0x01, 0x0c, ...List<int>.filled(12, 0), 0x01, 0x41, 0x00],
          ...imageFrame,
          0x3b,
        ],
        ImageType.animatedGif,
      ),
      (
        // Extension introducer, Graphic Control label, a 5-byte data sub-block
        // instead of the usual 4 bytes, and the block terminator.
        'a 5-byte graphic control extension in the first frame',
        <int>[
          ...gifPrefix(13),
          ...<int>[0x21, 0xf9, 0x05, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00],
          ...imageFrame,
          ...imageFrame,
          0x3b,
        ],
        ImageType.animatedGif,
      ),
    ];
    for (final (String name, List<int> bytes, ImageType? expected) in gifCases) {
      test('GIF with $name is detected as $expected', () {
        expect(detectImageType(Uint8List.fromList(bytes)), expected);
      });
    }

    test('GifHeaderReader.isAnimated() returns false for truncated buffers', () {
      expect(GifHeaderReader(ByteData(0)).isAnimated(), isFalse);
      expect(GifHeaderReader(ByteData.sublistView(gifPrefix(6))).isAnimated(), isFalse);
      expect(GifHeaderReader(ByteData.sublistView(firstFrame)).isAnimated(), isFalse);
    });

    test('truncated payloads in a padded subview are detected as static', () {
      final Uint8List webp = _createPaddedSubview(
        Uint8List.sublistView(animatedWebpHeader, 0, 20),
        leadingPadding: 3,
        trailingPadding: 1,
      );
      expect(detectImageType(webp), ImageType.webp);
      final Uint8List gif = _createPaddedSubview(firstFrame, leadingPadding: 3, trailingPadding: 1);
      expect(detectImageType(gif), ImageType.gif);
    });
  });
}

/// Generates a 21-byte WebP header: the RIFF/WEBP file header, a 'VP8X' chunk
/// header and the VP8X [flags] byte.
Uint8List _createWebpVp8xHeader({required int flags}) {
  return Uint8List.fromList(<int>[
    ...'RIFF'.codeUnits,
    ...<int>[0x20, 0x00, 0x00, 0x00],
    ...'WEBP'.codeUnits,
    ...'VP8X'.codeUnits,
    ...<int>[0x0a, 0x00, 0x00, 0x00],
    flags,
  ]);
}

/// Copies [source] into a larger buffer, surrounded by [leadingPadding] and
/// [trailingPadding] bytes set to 0xFF, and returns a view of just the copied
/// bytes.
Uint8List _createPaddedSubview(
  Uint8List source, {
  required int leadingPadding,
  required int trailingPadding,
}) {
  const sentinel = 0xFF;
  final int totalLength = leadingPadding + source.length + trailingPadding;
  final backing = Uint8List(totalLength)
    ..fillRange(0, totalLength, sentinel)
    ..setAll(leadingPadding, source);
  return Uint8List.sublistView(backing, leadingPadding, leadingPadding + source.length);
}

/// Generates a blank GIF with [numFrames] frames to be used in tests.
///
/// Pass `numFrames: 1` for a static GIF.
Uint8List _createTestGif({int numFrames = 2}) {
  const width = 1;
  const height = 1;
  final bytes = <int>[];
  // Generate header.
  bytes.addAll('GIF'.codeUnits);
  bytes.addAll('89a'.codeUnits);

  // Generate logical screen.
  List<int> padInt(int x) {
    assert(x >= 0 && x.bitLength <= 16);
    if (x.bitLength > 8) {
      return <int>[x >> 8, x & 0xff];
    }
    return <int>[0, x];
  }

  bytes.addAll(padInt(width));
  bytes.addAll(padInt(height));
  // Indicate there is no Global Color Table.
  bytes.add(0x70);
  bytes.add(0);
  bytes.add(0);

  // Generate data.
  List<int> generateCommentBlock() {
    final comment = <int>[];
    comment.add(0x21);
    comment.add(0xfe);
    const commentString = 'This is a comment';
    comment.add(commentString.codeUnits.length);
    comment.addAll(commentString.codeUnits);
    comment.add(0);
    return comment;
  }

  for (var i = 0; i < numFrames; i++) {
    bytes.addAll(generateCommentBlock());
    // Add a Graphic Control Extension block.
    bytes.add(0x21);
    bytes.add(0xf9);
    bytes.add(4);
    bytes.add(0);
    // Indicate a delay of 1/10 of a second between frames.
    bytes.add(0);
    bytes.add(10);
    bytes.add(0);
    bytes.add(0);

    bytes.addAll(generateCommentBlock());

    // Add a Table-Based Image.
    bytes.add(0x2c);
    bytes.add(0);
    bytes.add(0);
    bytes.add(0);
    bytes.add(0);
    bytes.addAll(padInt(width));
    bytes.addAll(padInt(height));
    bytes.add(0);

    bytes.add(0);
    const fakeImageData = 'This is an image';
    bytes.add(fakeImageData.codeUnits.length);
    bytes.addAll(fakeImageData.codeUnits);
    bytes.add(0);
  }

  bytes.addAll(generateCommentBlock());

  // Generate trailer.
  bytes.add(0x3b);

  return Uint8List.fromList(bytes);
}
