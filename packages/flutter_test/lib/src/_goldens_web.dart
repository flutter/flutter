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

 /// Returns whether [test] and [master] are pixel by pixel identical.
///
/// This method is not supported on the web and throws an [UnsupportedError]
/// when called.
ComparisonResult compareLists(List<int> test, List<int> master) {
  throw UnsupportedError('Golden testing is not supported on the web.');
}
