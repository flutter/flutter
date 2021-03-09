// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:test_api/test_api.dart' as test_package show TypeMatcher; // ignore: deprecated_member_use
import 'package:test_api/test_api.dart' hide TypeMatcher, isInstanceOf; // ignore: deprecated_member_use
// ignore: deprecated_member_use
export 'package:test_core/test_core.dart' hide TypeMatcher, isInstanceOf, test; // Defines a 'package:test' shim.

/// A matcher that compares the type of the actual value to the type argument T.
// TODO(ianh): Remove this once https://github.com/dart-lang/matcher/issues/98 is fixed
test_package.TypeMatcher<T> isInstanceOf<T>() => isA<T>();
