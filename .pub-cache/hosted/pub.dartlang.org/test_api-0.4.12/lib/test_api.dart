// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Deprecated('package:test_api is not intended for general use. '
    'Please use package:test.')
library test_api;

export 'expect.dart';
export 'hooks.dart' show TestFailure;
export 'scaffolding.dart';
// Deprecated exports not surfaced through focused libraries.
export 'src/expect/expect.dart' show ErrorFormatter;
export 'src/expect/expect_async.dart' show expectAsync;
export 'src/expect/throws_matcher.dart' show throws, Throws;
// Not yet deprecated, but not exposed through focused libraries.
export 'src/scaffolding/utils.dart' show registerException;
