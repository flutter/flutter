// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';

/// Wrapper for catching an `ArgumentError` being thrown.
final Matcher throwsArgumentError =
    throwsA(const isInstanceOf<ArgumentError>());
