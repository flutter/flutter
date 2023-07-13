// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines because it contains golden tests; see:
// https://github.com/flutter/flutter/wiki/Writing-a-golden-file-test-for-package:flutter#reduced-test-set-tag
@Tags(<String>['reduced-test-set'])
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ImageDecoration.lerp', (WidgetTester tester) async {
    final MemoryImage green = MemoryImage(Uint8List.fromList(<int>[
      0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a,  0x00, 0x00, 0x00, 0x0d, 0x49, 0x48, 0x44, 0x52,
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,  0x01, 0x03, 0x00, 0x00, 0x00, 0x25, 0xdb, 0x56,
      0xca, 0x00, 0x00, 0x00, 0x03, 0x50, 0x4c, 0x54,  0x45, 0x00, 0xff, 0x00, 0x34, 0x5e, 0xc0, 0xa8,
      0x00, 0x00, 0x00, 0x0a, 0x49, 0x44, 0x41, 0x54,  0x08, 0xd7, 0x63, 0x60, 0x00, 0x00, 0x00, 0x02,
      0x00, 0x01, 0xe2, 0x21, 0xbc, 0x33, 0x00, 0x00,  0x00, 0x00, 0x49, 0x45, 0x4e, 0x44, 0xae, 0x42,
      0x60, 0x82,
    ]));
    final MemoryImage red = MemoryImage(Uint8List.fromList(<int>[
      0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a,  0x00, 0x00, 0x00, 0x0d, 0x49, 0x48, 0x44, 0x52,
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,  0x01, 0x03, 0x00, 0x00, 0x00, 0x25, 0xdb, 0x56,
      0xca, 0x00, 0x00, 0x00, 0x03, 0x50, 0x4c, 0x54,  0x45, 0xff, 0x00, 0x00, 0x19, 0xe2, 0x09, 0x37,
      0x00, 0x00, 0x00, 0x0a, 0x49, 0x44, 0x41, 0x54,  0x08, 0xd7, 0x63, 0x60, 0x00, 0x00, 0x00, 0x02,
      0x00, 0x01, 0xe2, 0x21, 0xbc, 0x33, 0x00, 0x00,  0x00, 0x00, 0x49, 0x45, 0x4e, 0x44, 0xae, 0x42,
      0x60, 0x82,
    ]));

    await tester.runAsync(() async {
      await load(green);
      await load(red);
    });

    await tester.pumpWidget(
      ColoredBox(
        color: Colors.white,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            child: Wrap(
              textDirection: TextDirection.ltr,
              children: <Widget>[
                TestImage(
                  DecorationImage(image: green, repeat: ImageRepeat.repeat)
                ),
                TestImage(DecorationImage.lerp(
                  DecorationImage(image: green, repeat: ImageRepeat.repeat),
                  DecorationImage(image: red, repeat: ImageRepeat.repeat),
                  0.0,
                )),
                TestImage(DecorationImage.lerp(
                  DecorationImage(image: green, repeat: ImageRepeat.repeat),
                  DecorationImage(image: red, repeat: ImageRepeat.repeat),
                  0.1,
                )),
                TestImage(DecorationImage.lerp(
                  DecorationImage(image: green, repeat: ImageRepeat.repeat),
                  DecorationImage(image: red, repeat: ImageRepeat.repeat),
                  0.2,
                )),
                TestImage(DecorationImage.lerp(
                  DecorationImage(image: green, repeat: ImageRepeat.repeat),
                  DecorationImage(image: red, repeat: ImageRepeat.repeat),
                  0.5,
                )),
                TestImage(DecorationImage.lerp(
                  DecorationImage(image: green, repeat: ImageRepeat.repeat),
                  DecorationImage(image: red, repeat: ImageRepeat.repeat),
                  0.8,
                )),
                TestImage(DecorationImage.lerp(
                  DecorationImage(image: green, repeat: ImageRepeat.repeat),
                  DecorationImage(image: red, repeat: ImageRepeat.repeat),
                  0.9,
                )),
                TestImage(DecorationImage.lerp(
                  DecorationImage(image: green, repeat: ImageRepeat.repeat),
                  DecorationImage(image: red, repeat: ImageRepeat.repeat),
                  1.0,
                )),
                TestImage(
                  DecorationImage(image: red, repeat: ImageRepeat.repeat),
                ),
                for (double t = 0.0; t < 1.0; t += 0.125)
                  TestImage(DecorationImage.lerp(
                    DecorationImage.lerp(
                      DecorationImage(image: green, repeat: ImageRepeat.repeat),
                      DecorationImage(image: green, repeat: ImageRepeat.repeat),
                      t,
                    ),
                    DecorationImage.lerp(
                      DecorationImage(image: green, repeat: ImageRepeat.repeat),
                      DecorationImage(image: green, repeat: ImageRepeat.repeat),
                      t,
                    ),
                    t,
                  )),
                for (double t = 0.0; t < 1.0; t += 0.125)
                  TestImage(DecorationImage.lerp(
                    DecorationImage.lerp(
                      DecorationImage(image: green, repeat: ImageRepeat.repeat),
                      DecorationImage(image: green, repeat: ImageRepeat.repeat),
                      1.0 - t,
                    ),
                    DecorationImage.lerp(
                      DecorationImage(image: green, repeat: ImageRepeat.repeat),
                      DecorationImage(image: green, repeat: ImageRepeat.repeat),
                      t,
                    ),
                    t,
                  )),
                for (double t = 0.0; t < 1.0; t += 0.125)
                  TestImage(DecorationImage.lerp(
                    DecorationImage.lerp(
                      DecorationImage(image: green, repeat: ImageRepeat.repeat),
                      DecorationImage(image: green, repeat: ImageRepeat.repeat),
                      t,
                    ),
                    DecorationImage.lerp(
                      DecorationImage(image: green, repeat: ImageRepeat.repeat),
                      DecorationImage(image: green, repeat: ImageRepeat.repeat),
                      1.0 - t,
                    ),
                    t,
                  )),
                for (double t = 0.0; t < 1.0; t += 0.125)
                  TestImage(DecorationImage.lerp(
                    DecorationImage.lerp(
                      DecorationImage(image: green, repeat: ImageRepeat.repeat),
                      DecorationImage(image: green, repeat: ImageRepeat.repeat),
                      1.0 - t,
                    ),
                    DecorationImage.lerp(
                      DecorationImage(image: green, repeat: ImageRepeat.repeat),
                      DecorationImage(image: green, repeat: ImageRepeat.repeat),
                      1.0 - t,
                    ),
                    t,
                  )),
              ],
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(Wrap),
      matchesGoldenFile('decoration_image.lerp.0.png'),
    );
  });

  testWidgets('ImageDecoration.lerp', (WidgetTester tester) async {
    final MemoryImage cmyk = MemoryImage(Uint8List.fromList(<int>[
      0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a,  0x00, 0x00, 0x00, 0x0d, 0x49, 0x48, 0x44, 0x52,
      0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x04,  0x02, 0x03, 0x00, 0x00, 0x00, 0xd4, 0x9f, 0x76,
      0xed, 0x00, 0x00, 0x00, 0x0c, 0x50, 0x4c, 0x54,  0x45, 0x00, 0xff, 0xff, 0xff, 0x01, 0xfd, 0xff,
      0xfe, 0x01, 0x00, 0x00, 0x00, 0xe5, 0xa5, 0x06,  0x71, 0x00, 0x00, 0x00, 0x0e, 0x49, 0x44, 0x41,
      0x54, 0x08, 0xd7, 0x63, 0x60, 0x05, 0xc2, 0xf5,  0x0c, 0xeb, 0x01, 0x03, 0x00, 0x01, 0x69, 0x19,
      0xea, 0x34, 0x7b, 0x00, 0x00, 0x00, 0x00, 0x49,  0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82,
    ]));
    final MemoryImage wrgb = MemoryImage(Uint8List.fromList(<int>[
      0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a,  0x00, 0x00, 0x00, 0x0d, 0x49, 0x48, 0x44, 0x52,
      0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x04,  0x02, 0x03, 0x00, 0x00, 0x00, 0xd4, 0x9f, 0x76,
      0xed, 0x00, 0x00, 0x00, 0x0c, 0x50, 0x4c, 0x54,  0x45, 0xff, 0xff, 0xff, 0x01, 0x02, 0xff, 0x00,
      0xff, 0x00, 0xff, 0x00, 0x00, 0x4b, 0x18, 0xa8,  0x22, 0x00, 0x00, 0x00, 0x0e, 0x49, 0x44, 0x41,
      0x54, 0x08, 0xd7, 0x63, 0xe0, 0x07, 0xc2, 0xa5,  0x0c, 0x4b, 0x01, 0x03, 0x50, 0x01, 0x69, 0x4a,
      0x78, 0x1d, 0x41, 0x00, 0x00, 0x00, 0x00, 0x49,  0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82,
    ]));

    await tester.runAsync(() async {
      await load(cmyk);
      await load(wrgb);
    });

    await tester.pumpWidget(
      ColoredBox(
        color: Colors.white,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            child: Wrap(
              textDirection: TextDirection.ltr,
              children: <Widget>[
                TestImage(DecorationImage.lerp(
                  DecorationImage(image: wrgb, fit: BoxFit.contain),
                  DecorationImage(image: cmyk, fit: BoxFit.contain),
                  0.0,
                )),
                TestImage(DecorationImage.lerp(
                  DecorationImage(image: wrgb, fit: BoxFit.contain),
                  DecorationImage(image: cmyk, fit: BoxFit.contain),
                  0.1,
                )),
                TestImage(DecorationImage.lerp(
                  DecorationImage(image: wrgb, fit: BoxFit.contain),
                  DecorationImage(image: cmyk, fit: BoxFit.contain),
                  0.2,
                )),
                TestImage(DecorationImage.lerp(
                  DecorationImage(image: wrgb, fit: BoxFit.contain),
                  DecorationImage(image: cmyk, fit: BoxFit.contain),
                  0.5,
                )),
                TestImage(DecorationImage.lerp(
                  DecorationImage(image: wrgb, fit: BoxFit.contain),
                  DecorationImage(image: cmyk, fit: BoxFit.contain),
                  0.8,
                )),
                TestImage(DecorationImage.lerp(
                  DecorationImage(image: wrgb, fit: BoxFit.contain),
                  DecorationImage(image: cmyk, fit: BoxFit.contain),
                  0.9,
                )),
                TestImage(DecorationImage.lerp(
                  DecorationImage(image: wrgb, fit: BoxFit.contain),
                  DecorationImage(image: cmyk, fit: BoxFit.contain),
                  1.0,
                )),
                TestImage(DecorationImage.lerp(
                  DecorationImage(image: wrgb, fit: BoxFit.cover),
                  DecorationImage(image: cmyk, repeat: ImageRepeat.repeat),
                  0.5,
                )),
                TestImage(DecorationImage.lerp(
                  DecorationImage(image: wrgb, repeat: ImageRepeat.repeat),
                  DecorationImage(image: cmyk, repeat: ImageRepeat.repeatY),
                  0.5,
                )),
                TestImage(DecorationImage.lerp(
                  DecorationImage(image: wrgb, repeat: ImageRepeat.repeatX),
                  DecorationImage(image: cmyk, repeat: ImageRepeat.repeat),
                  0.5,
                )),
                TestImage(DecorationImage.lerp(
                  DecorationImage(image: wrgb, repeat: ImageRepeat.repeat, opacity: 0.2),
                  DecorationImage(image: cmyk, repeat: ImageRepeat.repeat, opacity: 0.2),
                  0.25,
                )),
                TestImage(DecorationImage.lerp(
                  DecorationImage(image: wrgb, repeat: ImageRepeat.repeat, opacity: 0.2),
                  DecorationImage(image: cmyk, repeat: ImageRepeat.repeat, opacity: 0.2),
                  0.5,
                )),
                TestImage(DecorationImage.lerp(
                  DecorationImage(image: wrgb, repeat: ImageRepeat.repeat, opacity: 0.2),
                  DecorationImage(image: cmyk, repeat: ImageRepeat.repeat, opacity: 0.2),
                  0.75,
                )),
                TestImage(DecorationImage.lerp(
                  DecorationImage(image: wrgb, scale: 0.5, repeat: ImageRepeat.repeatX),
                  DecorationImage(image: cmyk, scale: 0.25, repeat: ImageRepeat.repeatY),
                  0.5,
                )),
                TestImage(DecorationImage.lerp(
                  DecorationImage(image: cmyk, centerSlice: const Rect.fromLTWH(2.0, 2.0, 1.0, 1.0)),
                  DecorationImage(image: cmyk, centerSlice: const Rect.fromLTWH(2.0, 2.0, 1.0, 1.0)),
                  0.0,
                )),
                TestImage(DecorationImage.lerp(
                  DecorationImage(image: cmyk, centerSlice: const Rect.fromLTWH(2.0, 2.0, 1.0, 1.0)),
                  DecorationImage(image: cmyk, centerSlice: const Rect.fromLTWH(2.0, 2.0, 1.0, 1.0)),
                  0.25,
                )),
                TestImage(DecorationImage.lerp(
                  DecorationImage(image: cmyk, centerSlice: const Rect.fromLTWH(2.0, 2.0, 1.0, 1.0)),
                  DecorationImage(image: cmyk, centerSlice: const Rect.fromLTWH(2.0, 2.0, 1.0, 1.0)),
                  0.5,
                )),
                TestImage(DecorationImage.lerp(
                  DecorationImage(image: cmyk, centerSlice: const Rect.fromLTWH(2.0, 2.0, 1.0, 1.0)),
                  DecorationImage(image: cmyk, centerSlice: const Rect.fromLTWH(2.0, 2.0, 1.0, 1.0)),
                  0.75,
                )),
                TestImage(DecorationImage.lerp(
                  DecorationImage(image: cmyk, centerSlice: const Rect.fromLTWH(2.0, 2.0, 1.0, 1.0)),
                  DecorationImage(image: cmyk, centerSlice: const Rect.fromLTWH(2.0, 2.0, 1.0, 1.0)),
                  1.0,
                )),
                TestImage(DecorationImage.lerp(
                  DecorationImage(image: cmyk, centerSlice: const Rect.fromLTWH(0.0, 0.0, 1.0, 1.0)),
                  DecorationImage(image: cmyk, centerSlice: const Rect.fromLTWH(2.0, 2.0, 1.0, 1.0)),
                  0.0,
                )),
                TestImage(DecorationImage.lerp(
                  DecorationImage(image: cmyk, centerSlice: const Rect.fromLTWH(0.0, 0.0, 1.0, 1.0)),
                  DecorationImage(image: cmyk, centerSlice: const Rect.fromLTWH(2.0, 2.0, 1.0, 1.0)),
                  0.25,
                )),
                TestImage(DecorationImage.lerp(
                  DecorationImage(image: cmyk, centerSlice: const Rect.fromLTWH(0.0, 0.0, 1.0, 1.0)),
                  DecorationImage(image: cmyk, centerSlice: const Rect.fromLTWH(2.0, 2.0, 1.0, 1.0)),
                  0.5,
                )),
                TestImage(DecorationImage.lerp(
                  DecorationImage(image: cmyk, centerSlice: const Rect.fromLTWH(0.0, 0.0, 1.0, 1.0)),
                  DecorationImage(image: cmyk, centerSlice: const Rect.fromLTWH(2.0, 2.0, 1.0, 1.0)),
                  0.75,
                )),
                TestImage(DecorationImage.lerp(
                  DecorationImage(image: cmyk, centerSlice: const Rect.fromLTWH(0.0, 0.0, 1.0, 1.0)),
                  DecorationImage(image: cmyk, centerSlice: const Rect.fromLTWH(2.0, 2.0, 1.0, 1.0)),
                  1.0,
                )),
              ],
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(Wrap),
      matchesGoldenFile('decoration_image.lerp.1.png'),
    );
  });
}

Future<void> load(MemoryImage image) {
  final ImageStream stream = image.resolve(ImageConfiguration.empty);
  final Completer<ImageInfo> completer = Completer<ImageInfo>();
  void listener(ImageInfo image, bool syncCall) {
    completer.complete(image);
  }
  stream.addListener(ImageStreamListener(listener));
  return completer.future;
}

class TestImage extends StatelessWidget {
  TestImage(this.image); // ignore: use_key_in_widget_constructors, prefer_const_constructors_in_immutables

  final DecorationImage? image;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: SizedBox(
        width: 20,
        height: 20,
        child: DecoratedBox(
          decoration: BoxDecoration(
            image: image,
          ),
        ),
      ),
    );
  }
}
