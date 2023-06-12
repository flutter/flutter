// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Deprecated('package:test_core is not intended for general use. '
    'Please use package:test.')
library test_core;

export 'package:test_api/expect.dart';
export 'package:test_api/hooks.dart' show TestFailure;
// Not yet deprecated, but not exposed through focused libraries.
export 'package:test_api/test_api.dart' show registerException;
// Deprecated exports not surfaced through focused libraries.
export 'package:test_api/test_api.dart'
    show ErrorFormatter, expectAsync, throws, Throws;

export 'scaffolding.dart';
