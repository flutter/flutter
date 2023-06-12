// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:string_scanner/string_scanner.dart';
import 'package:test/test.dart';

/// Returns a matcher that asserts that a closure throws a
/// [StringScannerException] with the given [text].
Matcher throwsStringScannerException(String text) =>
    throwsA(const TypeMatcher<StringScannerException>()
        .having((e) => e.span!.text, 'span.text', text));
