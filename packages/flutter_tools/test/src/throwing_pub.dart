// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/dart/pub.dart';

final class ThrowingPub implements Pub {
  const ThrowingPub();

  @override
  Never noSuchMethod(Invocation invocation) {
    throw UnsupportedError('Attempted to invoke pub during test.');
  }
}
