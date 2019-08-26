// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'goldens.dart';

/// An unsupported [GoldenFileComparator] that exists for API compatibility.
class LocalFileComparator extends GoldenFileComparator {
  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) {
    throw UnsupportedError('LocalFileComparator is not supported on the web.');
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) {
    throw UnsupportedError('LocalFileComparator is not supported on the web.');
  }
}

