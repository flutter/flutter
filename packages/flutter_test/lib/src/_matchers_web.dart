// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:test_api/src/frontend/async_matcher.dart'; // ignore: implementation_imports
import 'package:test_api/test_api.dart' hide TypeMatcher, isInstanceOf;

import 'binding.dart';
import 'finders.dart';
import 'goldens.dart';

Future<ui.Image> captureImage(Element element) {
  throw UnsupportedError('captureImage is not supported on the web.');
}

class MatchesGoldenFile extends AsyncMatcher {
  const MatchesGoldenFile(this.key, this.version);

  MatchesGoldenFile.forStringPath(String path, this.version) : key = Uri.parse(path);

  final Uri key;
  final int version;

  @override
  Future<String> matchAsync(dynamic item) async {
    if (item is! Finder) {
      return 'web goldens only supports matching finders.';
    }
    final Finder finder = item;
    final Iterable<Element> elements = finder.evaluate();
    if (elements.isEmpty) {
      return 'could not be rendered because no widget was found';
    } else if (elements.length > 1) {
      return 'matched too many widgets';
    }
    final Element element = elements.single;
    final RenderObject renderObject = _findRepaintBoundary(element);
    final Size size = renderObject.paintBounds.size;
    final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();
    final Element e = binding.renderViewElement;
    _renderElement(binding.window, renderObject);
    final result = await binding.runAsync<String>(() async {
      if (autoUpdateGoldenFiles) {
        await webGoldenComparator.update(key, element, size);
        return null;
      }
      try {
        final bool success = await webGoldenComparator.compare(element, size, key);
        return success ? null : 'does not match';
      } on TestFailure catch (ex) {
        return ex.message;
      }
    }, additionalTime: const Duration(seconds: 11));
    _renderElement(binding.window, _findRepaintBoundary(e));
    return result;
  }

  @override
  Description describe(Description description) {
    final Uri testNameUri = webGoldenComparator.getTestUri(key, version);
    return description.add('one widget whose rasterized image matches golden image "$testNameUri"');
  }
}

RenderObject _findRepaintBoundary(Element element) {
  RenderObject renderObject = element.renderObject;
  while (!renderObject.isRepaintBoundary) {
    renderObject = renderObject.parent;
    assert(renderObject != null);
  }
  return renderObject;
}

void _renderElement(ui.Window window, RenderObject renderObject) {
  final layer = renderObject.debugLayer;
  final sceneBuilder = ui.SceneBuilder();
  if (layer is OffsetLayer) {
    sceneBuilder.pushOffset(-layer.offset.dx, -layer.offset.dy);
  }
  layer.updateSubtreeNeedsAddToScene();
  layer.addToScene(sceneBuilder);
  sceneBuilder.pop();
  window.render(sceneBuilder.build());
}
