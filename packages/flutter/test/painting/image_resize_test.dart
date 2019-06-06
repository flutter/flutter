// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../painting/image_data.dart';

const String _kAssetPath = 'assets/1x1.png';

class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle(this._assetBundleMap);

  Map<String, List<String>> _assetBundleMap;

  String get _assetBundleContents {
    return json.encode(_assetBundleMap);
  }

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.json')
      return ByteData.view(
          Uint8List.fromList(const Utf8Encoder().convert(_assetBundleContents))
              .buffer);
    if (key == _kAssetPath) {
      return ByteData.view(Uint8List.fromList(kTransparentImage).buffer);
    }
    return null;
  }
}

void main() {
  AutomatedTestWidgetsFlutterBinding();

  test('Resize Asset Image', () async {
    final Map<String, List<String>> assetBundleMap = <String, List<String>>{};
    assetBundleMap[_kAssetPath] = <String>[];

    final ImageProvider assetImage = ResizedImage(
      AssetImage(_kAssetPath, bundle: _FakeAssetBundle(assetBundleMap)),
    );

    const Size resizedSize = Size(18, 7);
    final ImageConfiguration configuration =
        ImageConfiguration.empty.copyWith(size: resizedSize);

    final Size size =
        await _resolveAndGetSize(assetImage, configuration: configuration);
    expect(size, resizedSize);
  });

  test('Resize File Image', () async {
    final Directory systemTempDir = Directory.systemTemp;
    final Uint8List bytes = Uint8List.fromList(kTransparentImage);
    final File tmpImg = File('${systemTempDir.path}/temp_file.png');
    tmpImg.writeAsBytesSync(bytes);

    final ImageProvider assetImage = ResizedImage(FileImage(tmpImg));
    const Size resizedSize = Size(18, 7);
    final ImageConfiguration configuration =
        ImageConfiguration.empty.copyWith(size: resizedSize);

    final Size size =
        await _resolveAndGetSize(assetImage, configuration: configuration);
    expect(size, resizedSize);
  });

  test('MemoryImage ResizedImage resizes to the correct dimensions', () async {
    final Uint8List bytes = Uint8List.fromList(kTransparentImage);
    final MemoryImage imageProvider = MemoryImage(bytes);
    final Size rawImageSize = await _resolveAndGetSize(imageProvider);
    expect(rawImageSize, const Size(1, 1));

    final ResizedImage resizedImage = ResizedImage(MemoryImage(bytes));
    const Size resizeDims = Size(18, 7);
    final ImageConfiguration resizeConfig =
        ImageConfiguration.empty.copyWith(size: resizeDims);
    final Size resizedImageSize =
        await _resolveAndGetSize(resizedImage, configuration: resizeConfig);
    expect(resizedImageSize, resizeDims);
  });

  test('MemoryImage ResizedImage does not resize when no size is passed',
      () async {
    final Uint8List bytes = Uint8List.fromList(kTransparentImage);
    final MemoryImage imageProvider = MemoryImage(bytes);
    final Size rawImageSize = await _resolveAndGetSize(imageProvider);
    expect(rawImageSize, const Size(1, 1));

    final ResizedImage resizedImage = ResizedImage(MemoryImage(bytes));
    final Size resizedImageSize = await _resolveAndGetSize(resizedImage);
    expect(resizedImageSize, const Size(1, 1));
  });
}

Future<Size> _resolveAndGetSize(ImageProvider imageProvider,
    {ImageConfiguration configuration = ImageConfiguration.empty}) async {
  final ImageStream stream = imageProvider.resolve(configuration);
  final Completer<Size> completer = Completer<Size>();
  stream.addListener(ImageStreamListener((ImageInfo info, bool syncCall) {
    final int height = info.image.height;
    final int width = info.image.width;
    completer.complete(Size(width.toDouble(), height.toDouble()));
  }));
  return await completer.future;
}
