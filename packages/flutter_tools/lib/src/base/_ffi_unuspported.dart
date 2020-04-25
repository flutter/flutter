// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'ffi.dart';

/// An implementation of [FFIService] that will return safe default values.
class FFIServiceImpl implements FFIService {
  @override
  bool isFileHidden(String path) {
    return false;
  }
}
