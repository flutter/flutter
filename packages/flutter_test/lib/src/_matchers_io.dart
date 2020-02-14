// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:test_api/src/frontend/async_matcher.dart'; // ignore: implementation_imports
// ignore: deprecated_member_use
import 'package:test_api/test_api.dart' hide TypeMatcher, isInstanceOf;

import 'binding.dart';
import 'finders.dart';
import 'goldens.dart';

/// Render the closest [RepaintBoundary] of the [element] into an image.
///
/// See also:
///
///  * [OffsetLayer.toImage] which is the actual method being called.
Future<ui.Image> captureImage(Element element) {
  RenderObject renderObject = element.renderObject;
  while (!renderObject.isRepaintBoundary) {
    renderObject = renderObject.parent as RenderObject;
    assert(renderObject != null);
  }
  assert(!renderObject.debugNeedsPaint);
  final OffsetLayer layer = renderObject.debugLayer as OffsetLayer;
  return layer.toImage(renderObject.paintBounds);
}

/// The matcher created by [matchesGoldenFile]. This class is enabled when the
/// test is running on a VM using conditional import.
class MatchesGoldenFile extends AsyncMatcher {
  /// Creates an instance of [MatchesGoldenFile]. Called by [matchesGoldenFile].
  const MatchesGoldenFile(this.key, this.version);

  /// Creates an instance of [MatchesGoldenFile]. Called by [matchesGoldenFile].
  MatchesGoldenFile.forStringPath(String path, this.version) : key = Uri.parse(path);

  /// The [key] to the golden image.
  final Uri key;

  /// The [version] of the golden image.
  final int version;

  @override
  Future<String> matchAsync(dynamic item) async {
    Future<ui.Image> imageFuture;
    if (item is Future<ui.Image>) {
      imageFuture = item;
    } else if (item is ui.Image) {
      imageFuture = Future<ui.Image>.value(item);
    } else {
      final Finder finder = item as Finder;
      final Iterable<Element> elements = finder.evaluate();
      if (elements.isEmpty) {
        return 'could not be rendered because no widget was found';
      } else if (elements.length > 1) {
        return 'matched too many widgets';
      }
      imageFuture = captureImage(elements.single);
    }

    final Uri testNameUri = goldenFileComparator.getTestUri(key, version);

    final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized() as TestWidgetsFlutterBinding;
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
