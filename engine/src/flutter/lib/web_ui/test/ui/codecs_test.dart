// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import '../common/test_initialization.dart';
import 'utils.dart';

const List<String> _kTestImages = <String>[
  '16x1.png',
  '1x1.png',
  '1x16.png',
  '1x3.png',
  '2x2.png',
  '32bpp-topdown-320x240.bmp',
  '3x1.png',
  '3x3.png',
  'alphabetAnim.gif',
  'apng-test-suite--basic--ignoring-default-image.png',
  'apng-test-suite--basic--trivial-static-image.png',
  'apng-test-suite--basic--using-default-image.png',
  'apng-test-suite--blend-ops--over-on-solid-and-transparent.png',
  'apng-test-suite--blend-ops--over-repeatedly.png',
  'apng-test-suite--blend-ops--source-on-nearly-transparent.png',
  'apng-test-suite--blend-ops--source-on-solid.png',
  'apng-test-suite--dispose-ops--none-basic.png',
  'apng-test-suite--num-plays--0.png',
  'apng-test-suite--num-plays--1.png',
  'apng-test-suite--num-plays--2.png',
  'apng-test-suite--regions--dispose-op-none.png',
  'arrow.png',
  'b78329453.jpeg',
  'baby_tux.png',
  'baby_tux.webp',
  'basn2c16-sbit565.png',
  'blendBG.webp',
  'bmp-size-32x32-8bpp.bmp',
  'box.gif',
  'brickwork_normal-map.jpg',
  'brickwork-texture.jpg',
  'cicp_pq.png',
  'cmyk_yellow_224_224_32.jpg',
  'CMYK.jpg',
  'color_wheel_with_profile.png',
  'color_wheel.gif',
  'color_wheel.jpg',
  'color_wheel.png',
  'color_wheel.webp',
  'colorTables.gif',
  'Connecting.png',
  'crbug1465627.jpeg',
  'crbug807324.png',
  'crbug999986.jpeg',
  'cropped_mandrill.jpg',
  'dog.jpg',
  'ducky.jpg',
  'ducky.png',
  'example_1.png',
  'example_2.png',
  'example_3.png',
  'example_4.png',
  'example_5.png',
  'example_6.png',
  'exif-orientation-2-ur.jpg',
  'explosion_sprites.png',
  'F-exif-chunk-early.png',
  'f16-trc-tables.png',
  'filter_reference.png',
  'flightAnim.gif',
  'flutter_logo.jpg',
  'gainmap_gcontainer_only.jpg',
  'gainmap_gdat_no_gmap.png',
  'gainmap_iso21496_1_adobe_gcontainer.jpg',
  'gainmap_iso21496_1.jpg',
  'gainmap_no_gdat.png',
  'gainmap.png',
  'gamut.png',
  'Generic_Error.png',
  'gif-transparent-index.gif',
  'gradient_adobe_to_p3.jpeg',
  'gradient_adobe_to_p3.png',
  'gradient_adobergb.jpeg',
  'gradient_adobergb.png',
  'gradient_displayp3.jpeg',
  'gradient_displayp3.png',
  'gradient_p3_to_adobe.jpeg',
  'gradient_p3_to_adobe.png',
  'grayscale.jpg',
  'grayscale.png',
  'green15x15.png',
  'half-transparent-white-pixel.png',
  'half-transparent-white-pixel.webp',
  'icc-v2-gbr.jpg',
  'iconstrip.png',
  'index8.png',
  'iphone_13_pro.jpeg',
  'iphone_15.jpeg',
  'lut_identity.png',
  'lut_sepia.png',
  'mandrill_128.png',
  'mandrill_16.png',
  'mandrill_1600.png',
  'mandrill_256.png',
  'mandrill_32.png',
  'mandrill_512_q075.jpg',
  'mandrill_512.png',
  'mandrill_64.png',
  'mandrill_cmyk.jpg',
  'mandrill_h1v1.jpg',
  'mandrill_h2v1.jpg',
  'mandrill_sepia.png',
  'Onboard.png',
  'orientation/1_410.jpg',
  'orientation/1_411.jpg',
  'orientation/1_420.jpg',
  'orientation/1_422.jpg',
  'orientation/1_440.jpg',
  'orientation/1_444.jpg',
  'orientation/1.webp',
  'orientation/2_410.jpg',
  'orientation/2_411.jpg',
  'orientation/2_420.jpg',
  'orientation/2_422.jpg',
  'orientation/2_440.jpg',
  'orientation/2_444.jpg',
  'orientation/2.webp',
  'orientation/3_410.jpg',
  'orientation/3_411.jpg',
  'orientation/3_420.jpg',
  'orientation/3_422.jpg',
  'orientation/3_440.jpg',
  'orientation/3_444.jpg',
  'orientation/3.webp',
  'orientation/4_410.jpg',
  'orientation/4_411.jpg',
  'orientation/4_420.jpg',
  'orientation/4_422.jpg',
  'orientation/4_440.jpg',
  'orientation/4_444.jpg',
  'orientation/4.webp',
  'orientation/5_410.jpg',
  'orientation/5_411.jpg',
  'orientation/5_420.jpg',
  'orientation/5_422.jpg',
  'orientation/5_440.jpg',
  'orientation/5_444.jpg',
  'orientation/5.webp',
  'orientation/6_410.jpg',
  'orientation/6_411.jpg',
  'orientation/6_420.jpg',
  'orientation/6_422.jpg',
  'orientation/6_440.jpg',
  'orientation/6_444.jpg',
  'orientation/6.webp',
  'orientation/7_410.jpg',
  'orientation/7_411.jpg',
  'orientation/7_420.jpg',
  'orientation/7_422.jpg',
  'orientation/7_440.jpg',
  'orientation/7_444.jpg',
  'orientation/7.webp',
  'orientation/8_410.jpg',
  'orientation/8_411.jpg',
  'orientation/8_420.jpg',
  'orientation/8_422.jpg',
  'orientation/8_440.jpg',
  'orientation/8_444.jpg',
  'orientation/8.webp',
  'orientation/exif.jpg',
  'orientation/subifd.jpg',
  'out-of-palette.gif',
  'plane_interlaced.png',
  'plane.png',
  'plte_trns_gama.png',
  'plte_trns.png',
  'png-zero-gamma-color-profile.png',
  'pngsuite/basn0g04.png',
  'pngsuite/basn2c08.png',
  'pngsuite/basn2c16.png',
  'pngsuite/basn3p01.png',
  'purple-displayprofile.png',
  'rainbow-gradient.png',
  'randPixels.bmp',
  'randPixels.gif',
  'randPixels.jpg',
  'randPixels.png',
  'randPixels.webp',
  'randPixelsAnim.gif',
  'randPixelsAnim2.gif',
  'randPixelsOffset.gif',
  'red-hlg-profile.png',
  'red-pq-profile.png',
  'required.gif',
  'required.webp',
  'rle.bmp',
  'shadowreference.png',
  'ship.png',
  'stoplight_h.webp',
  'stoplight.webp',
  'test640x479.gif',
  'text.png',
  'webp-color-profile-crash.webp',
  'webp-color-profile-lossless.webp',
  'webp-color-profile-lossy-alpha.webp',
  'webp-color-profile-lossy.webp',
  'wide_gamut_yellow_224_224_64.jpeg',
  'wide-gamut.png',
  'xOffsetTooBig.gif',
  'yellow_rose.png',
  'yellow_rose.webp',
];

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
  List<TestCodec> createTestCodecs({int testTargetWidth = 300, int testTargetHeight = 300}) {
    final testCodecs = <TestCodec>[];
    for (final String testFile in _kTestImages) {
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
      test('${testCodec.description} can create an image and convert it to byte array', () async {
        final ui.Codec codec = await testCodec.createCodec();

        for (var i = 0; i < codec.frameCount; i++) {
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
