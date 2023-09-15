// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:matcher/expect.dart';
import 'package:matcher/src/expect/async_matcher.dart'; // ignore: implementation_imports

import 'image_golden_matcher.dart';

/// Returns a [Matcher] for [matchesGoldenFile].
AsyncMatcher makeGoldenFileMatcher(Uri key, int? version) =>
    ImageGoldenMatcher(key, version);

/// Returns a [Matcher] for [matchesGoldenFile] which takes a String path.
AsyncMatcher makeGoldenFileMatcherForString(String path, int? version) =>
    ImageGoldenMatcher.forStringPath(path, version);
