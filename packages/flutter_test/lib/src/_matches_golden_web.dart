// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html; // ignore: uri_does_not_exist
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:test_api/src/frontend/async_matcher.dart'; // ignore: implementation_imports
import 'package:test_api/test_api.dart' hide TypeMatcher, isInstanceOf;

import 'binding.dart';
import 'finders.dart';

/// The dart:html implementation of [matchesGoldenFile].
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
    final Rect boundsInScreen = _captureBounds(elements.single);
    final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();
    return binding.runAsync<String>(() async {
      final html.HttpRequest request = await html.HttpRequest.request(
        'flutter_goldens',
        method: 'POST',
        sendData: json.encode(<String, Object>{
          'key': key.toString(),
          'left': boundsInScreen.left,
          'right': boundsInScreen.right,
          'top': boundsInScreen.top,
          'bottom': boundsInScreen.bottom,
        }),
      );
      final Object response = request.response;
      print(response);
      return response == 'true' ? null : 'does not match';
    }, additionalTime: const Duration(seconds: 11));
  }

  @override
  Description describe(Description description) =>
      description.add('one widget whose rasterized image matches golden image "$key"');
}

Rect _captureBounds(Element element) {
  RenderObject renderObject = element.renderObject;
  while (!renderObject.isRepaintBoundary) {
    renderObject = renderObject.parent;
    assert(renderObject != null);
  }
  assert(!renderObject.debugNeedsPaint);
  final RenderBox renderBox = renderObject;
  return Rect.fromPoints(
    renderBox.localToGlobal(element.renderObject.paintBounds.topLeft),
    renderBox.localToGlobal(element.renderObject.paintBounds.bottomRight),
  );
}
