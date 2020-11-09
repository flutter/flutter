// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

// Defines a 'package:test' shim.
// TODO(ianh): Remove this file once https://github.com/dart-lang/matcher/issues/98 is fixed

import 'package:test_api/test_api.dart' hide TypeMatcher, isInstanceOf; // ignore: deprecated_member_use
import 'package:test_api/test_api.dart' as test_package show TypeMatcher; // ignore: deprecated_member_use

export 'package:test_api/test_api.dart' hide TypeMatcher, isInstanceOf; // ignore: deprecated_member_use
export 'package:test_api/fake.dart'; // ignore: deprecated_member_use

/// A matcher that compares the type of the actual value to the type argument T.
test_package.TypeMatcher<T> isInstanceOf<T>() => isA<T>();

/// Whether we are running in a web browser.
const bool isBrowser = identical(0, 0.0);
