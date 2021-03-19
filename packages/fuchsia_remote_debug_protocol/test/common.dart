// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';

export 'package:test/test.dart' hide isInstanceOf;

/// A matcher that compares the type of the actual value to the type argument T.
TypeMatcher<T> isInstanceOf<T>() => isA<T>();
