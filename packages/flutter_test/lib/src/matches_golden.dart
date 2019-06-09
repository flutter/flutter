// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:test_api/src/frontend/async_matcher.dart'; // ignore: implementation_imports
import 'package:test_api/test_api.dart' hide TypeMatcher, isInstanceOf;

import '_matches_golden_io.dart'
  if (dart.library.html) '_matches_golden_web.dart' as _golden;
import 'finders.dart';
import 'goldens.dart';

typedef _MatchesGoldenFile = AsyncMatcher Function(dynamic key);

/// Asserts that a [Finder], [Future<ui.Image>], or [ui.Image] matches the
/// golden image file identified by [key].
///
/// For the case of a [Finder], the [Finder] must match exactly one widget and
/// the rendered image of the first [RepaintBoundary] ancestor of the widget is
/// treated as the image for the widget.
///
/// [key] may be either a [Uri] or a [String] representation of a URI.
///
/// This is an asynchronous matcher, meaning that callers should use
/// [expectLater] when using this matcher and await the future returned by
/// [expectLater].
///
/// ## Sample code
///
/// ```dart
/// await expectLater(find.text('Save'), matchesGoldenFile('save.png'));
/// await expectLater(image, matchesGoldenFile('save.png'));
/// await expectLater(imageFuture, matchesGoldenFile('save.png'));
/// ```
///
/// Golden image files can be created or updated by running `flutter test
/// --update-goldens` on the test.
///
/// See also:
///
///  * [goldenFileComparator], which acts as the backend for this matcher.
///  * [matchesReferenceImage], which should be used instead if you want to
///    verify that two different code paths create identical images.
///  * [flutter_test] for a discussion of test configurations, whereby callers
///    may swap out the backend for this matcher.
// TODO(jonahwilliams): remove when https://github.com/dart-lang/sdk/issues/37149 is fixed.
// ignore: prefer_const_declarations
final _MatchesGoldenFile matchesGoldenFile = _golden.matchesGoldenFile;