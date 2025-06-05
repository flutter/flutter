// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@Tags(<String>['flutter-test-driver'])
@Skip('https://github.com/flutter/flutter/issues/169304')
library;

import '../src/common.dart';

import 'test_data/expression_evaluation_web_common.dart';

void main() async {
  await testAll(useDDCLibraryBundleFormat: false);
}
