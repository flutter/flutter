// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test_api/test_api.dart' hide TypeMatcher, isInstanceOf;
import 'package:test_api/test_api.dart' as test_package show TypeMatcher;

export 'package:test_api/test_api.dart' hide TypeMatcher, isInstanceOf; // Defines a 'package:test' shim.

/// A matcher that compares the type of the actual value to the type argument T.
// TODO(ianh): Remove this once https://github.com/dart-lang/matcher/issues/98 is fixed
Matcher isInstanceOf<T>() => test_package.TypeMatcher<T>();
