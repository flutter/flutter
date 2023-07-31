// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:stack_trace/stack_trace.dart';
import 'package:test/test.dart';

/// Returns a matcher that runs [matcher] against a [Frame]'s `member` field.
Matcher frameMember(Object? matcher) =>
    isA<Frame>().having((p0) => p0.member, 'member', matcher);

/// Returns a matcher that runs [matcher] against a [Frame]'s `library` field.
Matcher frameLibrary(Object? matcher) =>
    isA<Frame>().having((p0) => p0.library, 'library', matcher);
