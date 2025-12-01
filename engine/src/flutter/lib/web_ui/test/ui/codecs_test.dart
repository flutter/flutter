// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import '../common/test_initialization.dart';
import 'utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

abstract class TestCodec {
  TestCodec.fromTestFile(this.testFile, {required this.description});

  final String testFile;
  final String description;

  Future<ui.Codec> createCodecFromTestFile(String testFile);

  Future<ui.Codec> createCodec() {
    return createCodecFromTestFile(testFile);
  }
}

class UrlTestCodec extends TestCodec {
  UrlTestCodec(super.testFile, this.codecFactory, String function)
    : super.fromTestFile(description: 'created with $function("$testFile")');

  final Future<ui.Codec> Function(String) codecFactory;

  @override
  Future<ui.Codec> createCodecFromTestFile(String testFile) {
    return codecFactory(testFile);
  }
}

class FetchTestCodec extends TestCodec {
  FetchTestCodec(super.testFile, this.codecFactory, String function)
    : super.fromTestFile(
        description:
            'created with $function from bytes '
            'fetch()\'ed from "$testFile"',
      );

  final Future<ui.Codec> Function(Uint8List) codecFactory;

  @override
  Future<ui.Codec> createCodecFromTestFile(String testFile) async {
    final HttpFetchResponse response = await httpFetch('/test_images/$testFile');

    if (!response.hasPayload) {
      throw Exception('Unable to fetch() image test file "$testFile"');
    }

    final Uint8List responseBytes = await response.asUint8List();
    return codecFactory(responseBytes);
  }
}

class BitmapTestCodec extends TestCodec {
  BitmapTestCodec(super.testFile, this.codecFactory, String function)
    : super.fromTestFile(
        description:
            'created with $function from ImageBitmap'
            ' created from "$testFile"',
      );

  final Future<ui.Image> Function(DomImageBitmap) codecFactory;

  @override
  Future<ui.Codec> createCodecFromTestFile(String testFile) async {
    final DomHTMLImageElement imageElement = createDomHTMLImageElement();
    imageElement.src = '/test_images/$testFile';
    imageElement.decoding = 'async';

    await imageElement.decode();

    final DomImageBitmap bitmap = await createImageBitmap(imageElement, (
      x: 0,
      y: 0,
      width: imageElement.naturalWidth.toInt(),
      height: imageElement.naturalHeight.toInt(),
    ));

    final ui.Image image = await codecFactory(bitmap);
    return BitmapSingleFrameCodec(bitmap, image);
  }
}

class BitmapSingleFrameCodec implements ui.Codec {
  BitmapSingleFrameCodec(this.bitmap, this.image);

  final DomImageBitmap bitmap;
  final ui.Image image;

  @override
  void dispose() {
    image.dispose();
    bitmap.close();
  }

  @override
  int get frameCount => 1;

  @override
  Future<ui.FrameInfo> getNextFrame() async {
    return SingleFrameInfo(image);
  }

  @override
  int get repetitionCount => 0;
}

Future<void> testMain() async {
  final HttpFetchResponse listingResponse = await httpFetch('/test_images/');
  final List<String> testFiles =
      ((await listingResponse.json() as JSAny?).dartify()! as List<Object?>).cast<String>();

  List<TestCodec> createTestCodecs({int testTargetWidth = 300, int testTargetHeight = 300}) {
    // Sanity-check the test file list. If suddenly test files are moved or
    // deleted, and the test server returns an empty list, or is missing some
    // important test files, we want to know.
    assert(testFiles.isNotEmpty);
    assert(testFiles.any((String testFile) => testFile.endsWith('.jpg')));
    assert(testFiles.any((String testFile) => testFile.endsWith('.png')));
    assert(testFiles.any((String testFile) => testFile.endsWith('.gif')));
    assert(testFiles.any((String testFile) => testFile.endsWith('.webp')));
    assert(testFiles.any((String testFile) => testFile.endsWith('.bmp')));

    final testCodecs = <TestCodec>[];
    for (final testFile in testFiles) {
      if (testFile == 'xOffsetTooBig.gif' && isSafari) {
        // This file causes Safari to crash with `EncodingError`. See:
        // https://github.com/flutter/flutter/issues/152709
        continue;
      }
      testCodecs.add(
        UrlTestCodec(
          testFile,
          (String file) =>
              renderer.instantiateImageCodecFromUrl(Uri.tryParse('/test_images/$file')!),
          'renderer.instantiateImageFromUrl',
        ),
      );
      testCodecs.add(
        FetchTestCodec(
          testFile,
          (Uint8List bytes) => renderer.instantiateImageCodec(bytes),
          'renderer.instantiateImageCodec',
        ),
      );
      testCodecs.add(
        FetchTestCodec(
          testFile,
          (Uint8List bytes) => renderer.instantiateImageCodec(
            bytes,
            targetWidth: testTargetWidth,
            targetHeight: testTargetHeight,
          ),
          'renderer.instantiateImageCodec ($testTargetWidth x $testTargetHeight)',
        ),
      );
      testCodecs.add(
        BitmapTestCodec(
          testFile,
          (DomImageBitmap bitmap) async => renderer.createImageFromImageBitmap(bitmap),
          'renderer.createImageFromImageBitmap',
        ),
      );
    }

    return testCodecs;
  }

  group('Images', () {
    setUpUnitTests(withImplicitView: true);

    tearDown(() {
      mockHttpFetchResponseFactory = null;
    });

    void runCodecTest(TestCodec testCodec) {
      const problematicChromeImages = <String, Set<int>>{
        // Frame 2 cause Chrome to crash.
        // https://issues.chromium.org/456445108
        'crbug445556737.png': {2},
        // Frames 2 and 3 cause Chrome to crash.
        // https://issues.chromium.org/456445108
        'interlaced-multiframe-with-blending.png': {2, 3},
      };

      test('${testCodec.description} can create an image and convert it to byte array', () async {
        final ui.Codec codec = await testCodec.createCodec();

        final Set<int> problematicFrames;
        if (isChromium && problematicChromeImages.containsKey(testCodec.testFile)) {
          // Encountered an image with known problematic frames on Chromium.
          problematicFrames = problematicChromeImages[testCodec.testFile]!;
        } else {
          problematicFrames = <int>{};
        }

        for (var i = 0; i < codec.frameCount; i++) {
          if (problematicFrames.contains(i)) {
            printWarning(
              'Skipping frame $i of ${testCodec.description} due to known Chromium crash bug.',
            );
            continue;
          }

          final ui.Image image;
          try {
            final ui.FrameInfo frameInfo = await codec.getNextFrame();
            image = frameInfo.image;
          } catch (e) {
            codec.dispose();
            throw TestFailure('Failed to get image at frame $i for ${testCodec.description}: $e');
          }

          expect(image.width, isNonZero);
          expect(image.height, isNonZero);

          final ByteData? byteData = await image.toByteData();
          expect(
            byteData,
            isNotNull,
            reason: '${testCodec.description} toByteData() should not be null',
          );
          expect(
            byteData!.lengthInBytes,
            isNonZero,
            reason: '${testCodec.description} toByteData() should not be empty',
          );
          expect(
            byteData.buffer.asUint8List().any((int byte) => byte > 0),
            isTrue,
            reason:
                '${testCodec.description} toByteData() should '
                'contain nonzero value',
          );
        }

        // After all frames are decoded and tested, dispose the codec.
        codec.dispose();
      });
    }

    group('Codecs (default browserSupportsImageDecoder)', () {
      createTestCodecs().forEach(runCodecTest);
    }, skip: isWimp); // https://github.com/flutter/flutter/issues/175371

    if (browserSupportsImageDecoder) {
      // For the sake of completeness, test codec fallback logic on browsers that support
      // `ImageDecoder`.
      group('Codecs (browserSupportsImageDecoder=false)', () {
        setUpAll(() {
          browserSupportsImageDecoder = false;
        });
        tearDownAll(() {
          debugResetBrowserSupportsImageDecoder();
        });

        createTestCodecs().forEach(runCodecTest);
      }, skip: isWimp); // https://github.com/flutter/flutter/issues/175371
    }
  });

  test('crossOrigin requests cause an error', () async {
    final String otherOrigin = domWindow.location.origin.replaceAll('localhost', '127.0.0.1');
    var gotError = false;
    try {
      final ui.Codec _ = await renderer.instantiateImageCodecFromUrl(
        Uri.parse('$otherOrigin/test_images/1x1.png'),
      );
    } catch (e) {
      gotError = true;
    }
    expect(gotError, isTrue, reason: 'Should have got CORS error');
  });

  test('isAvif', () {
    expect(isAvif(Uint8List.fromList(<int>[])), isFalse);
    expect(isAvif(Uint8List.fromList(<int>[1, 2, 3])), isFalse);
    expect(
      isAvif(
        Uint8List.fromList(<int>[
          0x00,
          0x00,
          0x00,
          0x1c,
          0x66,
          0x74,
          0x79,
          0x70,
          0x61,
          0x76,
          0x69,
          0x66,
          0x00,
          0x00,
          0x00,
          0x00,
        ]),
      ),
      isTrue,
    );
    expect(
      isAvif(
        Uint8List.fromList(<int>[
          0x00,
          0x00,
          0x00,
          0x20,
          0x66,
          0x74,
          0x79,
          0x70,
          0x61,
          0x76,
          0x69,
          0x66,
          0x00,
          0x00,
          0x00,
          0x00,
        ]),
      ),
      isTrue,
    );
  });
}
