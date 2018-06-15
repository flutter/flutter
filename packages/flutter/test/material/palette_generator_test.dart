// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

Future<ui.Image> loadImage(String name) async {
  File imagePath = new File(path.joinAll(name.split('/')));
  if (path.split(Directory.current.absolute.path).last != 'test') {
    imagePath = new File(path.join('test',imagePath.path));
  }
  final FileImage image = new FileImage(imagePath);
  final Completer<ui.Image> resultCompleter = new Completer<ui.Image>();
  final ImageStreamCompleter completer = image.load(image);
  completer.addListener((ImageInfo imageInfo, bool synchronousCall) {
    resultCompleter.complete(imageInfo.image);
  });
  return resultCompleter.future;
}

void main() {
  test('PaletteGenerator works on 1-pixel wide blue image', () async {
    final ui.Image image = await loadImage('test_assets/material/tall_blue.png');
    final PaletteGenerator palette = await PaletteGenerator.fromImage(image);
    expect(palette.paletteColors.length, equals(1));
    expect(palette.paletteColors[0].color, within<Color>(distance: 8, from: const Color(0xff0000ff)));
  });

  test('PaletteGenerator works on 1-pixel high red image', () async {
    final ui.Image image = await loadImage('test_assets/material/wide_red.png');
    final PaletteGenerator palette = await PaletteGenerator.fromImage(image);
    expect(palette.paletteColors.length, equals(1));
    expect(palette.paletteColors[0].color, within<Color>(distance: 8, from: const Color(0xffff0000)));
  });

  test('PaletteGenerator finds dominant color and text colors', () async {
    final ui.Image image = await loadImage('test_assets/material/dominant.png');
    final PaletteGenerator palette = await PaletteGenerator.fromImage(image);
    expect(palette.paletteColors.length, equals(3));
    expect(palette.dominantColor.color, within<Color>(distance: 8, from: const Color(0xff0000ff)));
    expect(palette.dominantColor.titleTextColor, within<Color>(distance: 8, from: const Color(0xbc000000)));
    expect(palette.dominantColor.bodyTextColor, within<Color>(distance: 8, from: const Color(0xda000000)));
  });

  test('PaletteGenerator works with regions', () async {
    final ui.Image image = await loadImage('test_assets/material/dominant.png');
    Rect region = new Rect.fromLTRB(0.0, 0.0, image.width.toDouble(), image.height.toDouble());
    PaletteGenerator palette = await PaletteGenerator.fromImage(image, region: region);
    expect(palette.paletteColors.length, equals(3));
    expect(palette.dominantColor.color, within<Color>(distance: 8, from: const Color(0xff0000ff)));

    region = new Rect.fromLTRB(0.0, 0.0, 10.0, 10.0);
    palette = await PaletteGenerator.fromImage(image, region: region);
    expect(palette.paletteColors.length, equals(1));
    expect(palette.dominantColor.color, within<Color>(distance: 8, from: const Color(0xffff0000)));

    region = new Rect.fromLTRB(0.0, 0.0, 30.0, 20.0);
    palette = await PaletteGenerator.fromImage(image, region: region);
    expect(palette.paletteColors.length, equals(3));
    expect(palette.dominantColor.color, within<Color>(distance: 8, from: const Color(0xff00ff00)));
  });

  test('PaletteGenerator works as expected on a real image', () async {
    final ui.Image image = await loadImage('test_assets/material/landscape.png');
    final PaletteGenerator palette = await PaletteGenerator.fromImage(image);
    final List<PaletteColor> expectedSwatches = <PaletteColor>[
      new PaletteColor(const Color(0xff3f630c), 10137),
      new PaletteColor(const Color(0xff82b2e9), 4733),
      new PaletteColor(const Color(0xffc0d6ec), 4714),
      new PaletteColor(const Color(0xff4c4f50), 2465),
      new PaletteColor(const Color(0xff303433), 2420),
      new PaletteColor(const Color(0xff5d6162), 2418),
      new PaletteColor(const Color(0xff6c7fa2), 2370),
      new PaletteColor(const Color(0xff486321), 2353),
      new PaletteColor(const Color(0xff64713f), 1229),
      new PaletteColor(const Color(0xff9692a1), 1205),
      new PaletteColor(const Color(0xffbaacb1), 1152),
      new PaletteColor(const Color(0xff445166), 1040),
      new PaletteColor(const Color(0xff475d83), 1019),
      new PaletteColor(const Color(0xff7d7460), 563),
      new PaletteColor(const Color(0xffcd9b39), 282),
      new PaletteColor(const Color(0xfff2bc35), 281),
    ];
    final Iterable<Color> expectedColors = expectedSwatches.map<Color>((PaletteColor swatch) => swatch.color);
    expect(palette.paletteColors, containsAll(expectedSwatches));
    expect(palette.vibrantColor.color, within<Color>(distance: 8, from: const Color(0xffcd9b39)));
    expect(palette.lightVibrantColor.color, within<Color>(distance: 8, from: const Color(0xff82b2e9)));
    expect(palette.darkVibrantColor.color, within<Color>(distance: 8, from: const Color(0xff3f630c)));
    expect(palette.mutedColor.color, within<Color>(distance: 8, from: const Color(0xff6c7fa2)));
    expect(palette.lightMutedColor.color, within<Color>(distance: 8, from: const Color(0xffc0d6ec)));
    expect(palette.darkMutedColor.color, within<Color>(distance: 8, from: const Color(0xff445166)));
    expect(palette.colors, containsAllInOrder(expectedColors));
    expect(palette.colors.length, equals(palette.paletteColors.length));
  });

  test('PaletteGenerator limits max colors', () async {
    final ui.Image image = await loadImage('test_assets/material/landscape.png');
    PaletteGenerator palette = await PaletteGenerator.fromImage(image, maximumColorCount: 32);
    expect(palette.paletteColors.length, equals(32));
    palette = await PaletteGenerator.fromImage(image, maximumColorCount: 1);
    expect(palette.paletteColors.length, equals(1));
    palette = await PaletteGenerator.fromImage(image, maximumColorCount: 15);
    expect(palette.paletteColors.length, equals(15));
  });

  test('PaletteGenerator Filters work', () async {
    final ui.Image image = await loadImage('test_assets/material/landscape.png');
    // First, test that supplying the default filter is the same as not supplying one.
    List<PaletteFilter> filters = <PaletteFilter>[avoidRedBlackWhitePaletteFilter];
    PaletteGenerator palette = await PaletteGenerator.fromImage(image, filters: filters);
    final List<PaletteColor> expectedSwatches = <PaletteColor>[
      new PaletteColor(const Color(0xff3f630c), 10137),
      new PaletteColor(const Color(0xff82b2e9), 4733),
      new PaletteColor(const Color(0xffc0d6ec), 4714),
      new PaletteColor(const Color(0xff4c4f50), 2465),
      new PaletteColor(const Color(0xff303433), 2420),
      new PaletteColor(const Color(0xff5d6162), 2418),
      new PaletteColor(const Color(0xff6c7fa2), 2370),
      new PaletteColor(const Color(0xff486321), 2353),
      new PaletteColor(const Color(0xff64713f), 1229),
      new PaletteColor(const Color(0xff9692a1), 1205),
      new PaletteColor(const Color(0xffbaacb1), 1152),
      new PaletteColor(const Color(0xff445166), 1040),
      new PaletteColor(const Color(0xff475d83), 1019),
      new PaletteColor(const Color(0xff7d7460), 563),
      new PaletteColor(const Color(0xffcd9b39), 282),
      new PaletteColor(const Color(0xfff2bc35), 281),
    ];
    final Iterable<Color> expectedColors = expectedSwatches.map<Color>((PaletteColor swatch) => swatch.color);
    expect(palette.paletteColors, containsAll(expectedSwatches));
    expect(palette.dominantColor.color, within<Color>(distance: 8, from: const Color(0xff3f630c)));
    expect(palette.colors, containsAllInOrder(expectedColors));

    // A non-default filter works (and the default filter isn't applied too).
    filters = <PaletteFilter>[onlyBluePaletteFilter];
    palette = await PaletteGenerator.fromImage(image, filters: filters);
    final List<PaletteColor> blueSwatches = <PaletteColor>[
      new PaletteColor(const Color(0xff8dc3f8), 2051),
      new PaletteColor(const Color(0xff4c586d), 1991),
      new PaletteColor(const Color(0xffa4c4e8), 1965),
      new PaletteColor(const Color(0xff8796b7), 1147),
      new PaletteColor(const Color(0xff86b0e4), 1138),
      new PaletteColor(const Color(0xffb3d2f3), 1088),
      new PaletteColor(const Color(0xff4a4f5a), 1070),
      new PaletteColor(const Color(0xff6d7991), 1015),
      new PaletteColor(const Color(0xff6b9fdf), 986),
      new PaletteColor(const Color(0xffc9dbee), 855),
      new PaletteColor(const Color(0xff516382), 651),
      new PaletteColor(const Color(0xff232731), 585),
      new PaletteColor(const Color(0xff3c424e), 557),
      new PaletteColor(const Color(0xff5a85c5), 512),
      new PaletteColor(const Color(0xff688cc4), 507),
      new PaletteColor(const Color(0xff5f6e87), 381),
    ];
    final Iterable<Color> expectedBlues = blueSwatches.map<Color>((PaletteColor swatch) => swatch.color);

    expect(palette.paletteColors, containsAll(blueSwatches));
    expect(palette.dominantColor.color, within<Color>(distance: 8, from: const Color(0xff8dc3f8)));
    expect(palette.colors, containsAllInOrder(expectedBlues));

    // More than one filter is the intersection of the two filters.
    filters = <PaletteFilter>[onlyBluePaletteFilter, onlyCyanPaletteFilter];
    palette = await PaletteGenerator.fromImage(image, filters: filters);
    final List<PaletteColor> blueGreenSwatches = <PaletteColor>[
      new PaletteColor(const Color(0xffc8e8f8), 87),
      new PaletteColor(const Color(0xff5c6c74), 73),
      new PaletteColor(const Color(0xff6f8088), 49),
      new PaletteColor(const Color(0xff687880), 49),
      new PaletteColor(const Color(0xff506068), 45),
      new PaletteColor(const Color(0xff485860), 39),
      new PaletteColor(const Color(0xff405058), 21),
      new PaletteColor(const Color(0xffd6ebf3), 11),
      new PaletteColor(const Color(0xff2f3f47), 7),
      new PaletteColor(const Color(0xff0f1f27), 6),
      new PaletteColor(const Color(0xffc0e0f0), 6),
      new PaletteColor(const Color(0xff203038), 3),
      new PaletteColor(const Color(0xff788890), 2),
      new PaletteColor(const Color(0xff384850), 2),
      new PaletteColor(const Color(0xff98a8b0), 1),
      new PaletteColor(const Color(0xffa8b8c0), 1),
    ];
    final Iterable<Color> expectedBlueGreens = blueGreenSwatches.map<Color>((PaletteColor swatch) => swatch.color);

    expect(palette.paletteColors, containsAll(blueGreenSwatches));
    expect(palette.dominantColor.color, within<Color>(distance: 8, from: const Color(0xffc8e8f8)));
    expect(palette.colors, containsAllInOrder(expectedBlueGreens));

    // Mutually exclusive filters return an empty palette.
    filters = <PaletteFilter>[onlyBluePaletteFilter, onlyGreenPaletteFilter];
    palette = await PaletteGenerator.fromImage(image, filters: filters);
    expect(palette.paletteColors, isEmpty);
    expect(palette.dominantColor, isNull);
    expect(palette.colors, isEmpty);
  });

  test('PaletteGenerator targets work', () async {
    final ui.Image image = await loadImage('test_assets/material/landscape.png');
    // Passing an empty set of targets works the same as passing a null targets
    // list.
    PaletteGenerator palette = await PaletteGenerator.fromImage(image, targets: <PaletteTarget>[]);
    expect(palette.selectedSwatches, isNotEmpty);
    expect(palette.vibrantColor, isNotNull);
    expect(palette.lightVibrantColor, isNotNull);
    expect(palette.darkVibrantColor, isNotNull);
    expect(palette.mutedColor, isNotNull);
    expect(palette.lightMutedColor, isNotNull);
    expect(palette.darkMutedColor, isNotNull);

    // Passing targets augments the baseTargets, and those targets are found.
    final List<PaletteTarget> saturationExtremeTargets = <PaletteTarget>[
      new PaletteTarget(minimumSaturation: 0.85),
      new PaletteTarget(maximumSaturation: .25),
    ];
    palette = await PaletteGenerator.fromImage(image, targets: saturationExtremeTargets);
    expect(palette.vibrantColor, isNotNull);
    expect(palette.lightVibrantColor, isNotNull);
    expect(palette.darkVibrantColor, isNotNull);
    expect(palette.mutedColor, isNotNull);
    expect(palette.lightMutedColor, isNotNull);
    expect(palette.darkMutedColor, isNotNull);
    expect(palette.selectedSwatches.length, equals(PaletteTarget.baseTargets.length + 2));
    expect(palette.selectedSwatches[saturationExtremeTargets[0]].color, equals(const Color(0xff3f630c)));
    expect(palette.selectedSwatches[saturationExtremeTargets[1]].color, equals(const Color(0xff7d7460)));
  });

  test('PaletteGenerator produces consistent results', () async {
    final ui.Image image = await loadImage('test_assets/material/landscape.png');

    PaletteGenerator lastPalette = await PaletteGenerator.fromImage(image);
    for (int i = 0; i < 5; ++i) {
      final PaletteGenerator palette = await PaletteGenerator.fromImage(image);
      expect(palette.paletteColors.length, lastPalette.paletteColors.length);
      expect(palette.vibrantColor, equals(lastPalette.vibrantColor));
      expect(palette.lightVibrantColor, equals(lastPalette.lightVibrantColor));
      expect(palette.darkVibrantColor, equals(lastPalette.darkVibrantColor));
      expect(palette.mutedColor, equals(lastPalette.mutedColor));
      expect(palette.lightMutedColor, equals(lastPalette.lightMutedColor));
      expect(palette.darkMutedColor, equals(lastPalette.darkMutedColor));
      expect(palette.dominantColor.color, within<Color>(distance: 8, from: lastPalette.dominantColor.color));
      lastPalette = palette;
    }
  });
}

bool onlyBluePaletteFilter(HSLColor hslColor) {
  const double blueLineMinHue = 185.0;
  const double blueLineMaxHue = 260.0;
  const double blueLineMaxSaturation = 0.82;
  return hslColor.hue >= blueLineMinHue && hslColor.hue <= blueLineMaxHue && hslColor.saturation <= blueLineMaxSaturation;
}

bool onlyCyanPaletteFilter(HSLColor hslColor) {
  const double cyanLineMinHue = 165.0;
  const double cyanLineMaxHue = 200.0;
  const double cyanLineMaxSaturation = 0.82;
  return hslColor.hue >= cyanLineMinHue && hslColor.hue <= cyanLineMaxHue && hslColor.saturation <= cyanLineMaxSaturation;
}

bool onlyGreenPaletteFilter(HSLColor hslColor) {
  const double greenLineMinHue = 80.0;
  const double greenLineMaxHue = 165.0;
  const double greenLineMaxSaturation = 0.82;
  return hslColor.hue >= greenLineMinHue && hslColor.hue <= greenLineMaxHue && hslColor.saturation <= greenLineMaxSaturation;
}
