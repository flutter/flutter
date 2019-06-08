// Copyright 2018 The Chromium Authors. All rights reserved.
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

/// The dart:io implementation of [matchesGoldenFile].
AsyncMatcher matchesGoldenFile(dynamic key) {
  if (key is Uri) {
    return _MatchesGoldenFile(key);
  } else if (key is String) {
    return _MatchesGoldenFile.forStringPath(key);
  }
  throw ArgumentError('Unexpected type for golden file: ${key.runtimeType}');
}

class _MatchesGoldenFile extends AsyncMatcher {
  const _MatchesGoldenFile(this.key);

  _MatchesGoldenFile.forStringPath(String path) : key = Uri.parse(path);

  final Uri key;

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
      imageFuture = _captureImage(elements.single);
    }

    final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();
    return binding.runAsync<String>(() async {
      final ui.Image image = await imageFuture;
      final ByteData bytes = await image.toByteData(format: ui.ImageByteFormat.png)
        .timeout(const Duration(seconds: 10), onTimeout: () => null);
      if (bytes == null)
        return 'Failed to generate screenshot from engine within the 10,000ms timeout.';
      if (autoUpdateGoldenFiles) {
        await goldenFileComparator.update(key, bytes.buffer.asUint8List());
        return null;
      }
      try {
        final bool success = await goldenFileComparator.compare(bytes.buffer.asUint8List(), key);
        return success ? null : 'does not match';
      } on TestFailure catch (ex) {
        return ex.message;
      }
    }, additionalTime: const Duration(seconds: 11));
  }

  @override
  Description describe(Description description) =>
      description.add('one widget whose rasterized image matches golden image "$key"');
}

Future<ui.Image> _captureImage(Element element) {
  RenderObject renderObject = element.renderObject;
  while (!renderObject.isRepaintBoundary) {
    renderObject = renderObject.parent;
    assert(renderObject != null);
  }
  assert(!renderObject.debugNeedsPaint);
  final OffsetLayer layer = renderObject.layer;
  return layer.toImage(renderObject.paintBounds);
}