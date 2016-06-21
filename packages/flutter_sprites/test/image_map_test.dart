// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show BASE64;
import 'dart:typed_data';
import 'dart:ui' as ui show Image;

import 'package:flutter/services.dart';
import 'package:flutter_sprites/flutter_sprites.dart';
import 'package:mojo/core.dart' as mojo;
import 'package:test/test.dart';

const String kTestManifest = '''
{
  "assets/image1.png" : [],
  "assets/image2.png" : [],
  "assets/image3.png" : []
}
''';

// Base64 encoding of a 1x1 pixel png image.
const String kTestImageBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABAQMAAAAl21bKAAAAA1BMVEUAAACnej3aAAAAAXRSTlMAQObYZgAAAApJREFUCNdjYAAAAAIAAeIhvDMAAAAASUVORK5CYII=';

class TestAssetBundle extends CachingAssetBundle {
  @override
  Future<mojo.MojoDataPipeConsumer> load(String key) {
    mojo.MojoDataPipe dataPipe = new mojo.MojoDataPipe();
    final Uint8List bytes =
        new Uint8List.fromList(BASE64.decode(kTestImageBase64));
    int numBytesWritten = dataPipe.producer.write(bytes.buffer.asByteData());
    expect(numBytesWritten, equals(bytes.lengthInBytes));
    dataPipe.producer.handle.close();
    return new Future<mojo.MojoDataPipeConsumer>.value(dataPipe.consumer);
  }

  @override
  Future<String> loadString(String key, {bool cache: true}) {
    if (key == 'AssetManifest.json')
      return new Future<String>.value(kTestManifest);
    return null;
  }

  @override
  String toString() => '$runtimeType@$hashCode()';
}

final TestAssetBundle _bundle = new TestAssetBundle();

void main() {
  test('ImageMap Smoke Test', () async {
    ImageMap imageMap = new ImageMap(_bundle);
    final List<String> urls = <String>[
      'assets/image1.png',
      'assets/image2.png',
      'assets/image3.png',
    ];

    urls.forEach((String url) {
      expect(imageMap.getImage(url), isNull);
    });

    List<ui.Image> loadedImages = await imageMap.load(urls);
    expect(loadedImages.length, equals(urls.length));

    urls.forEach((String url) {
      expect(imageMap.getImage(url), isNotNull);
    });
  });
}
