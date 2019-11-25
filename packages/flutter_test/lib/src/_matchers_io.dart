// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:test_api/src/frontend/async_matcher.dart'; // ignore: implementation_imports
import 'package:test_api/test_api.dart' hide TypeMatcher, isInstanceOf;

import 'binding.dart';
import 'finders.dart';
import 'goldens.dart';

Future<ui.Image> captureImage(Element element) {
  RenderObject renderObject = element.renderObject;
  while (!renderObject.isRepaintBoundary) {
    renderObject = renderObject.parent;
    assert(renderObject != null);
  }
  assert(!renderObject.debugNeedsPaint);
  final OffsetLayer layer = renderObject.debugLayer;
  return layer.toImage(renderObject.paintBounds);
}

class MatchesGoldenFile extends AsyncMatcher {
  const MatchesGoldenFile(this.key, this.version);

  MatchesGoldenFile.forStringPath(String path, this.version) : key = Uri.parse(path);

  final Uri key;
  final int version;

  @override
  Future<String> matchAsync(dynamic item) async {
    Future<ui.Image> imageFuture;
    if (item is Future<ui.Image>) {
      imageFuture = item;
    } else if (item is ui.Image) {
      imageFuture = Future<ui.Image>.value(item);
    } else {
      final Finder finder = item;
      final Iterable<Element> elements = finder.evaluate();
      if (elements.isEmpty) {
        return 'could not be rendered because no widget was found';
      } else if (elements.length > 1) {
        return 'matched too many widgets';
      }
      imageFuture = captureImage(elements.single);
    }

    final Uri testNameUri = goldenFileComparator.getTestUri(key, version);

    final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();
    return binding.runAsync<String>(() async {
      final ui.Image image = await imageFuture;
      final ByteData bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null)
        return 'could not encode screenshot.';
      if (autoUpdateGoldenFiles) {
        await goldenFileComparator.update(testNameUri, bytes.buffer.asUint8List());
        return null;
      }
      try {
        final bool success = await goldenFileComparator.compare(bytes.buffer.asUint8List(), testNameUri);
        return success ? null : 'does not match';
      } on TestFailure catch (ex) {
        return ex.message;
      }
    }, additionalTime: const Duration(minutes: 1));
  }

  @override
  Description describe(Description description) {
    final Uri testNameUri = goldenFileComparator.getTestUri(key, version);
    return description.add('one widget whose rasterized image matches golden image "$testNameUri"');
  }
}
