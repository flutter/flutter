// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// The reduced test set tag is missing. This should fail analysis.
@Tags(<String>['some-other-tag'])

import 'package:test/test.dart';

import 'golden_class.dart';

void main() {
  matchesGoldenFile('missing_tag.png');
}
