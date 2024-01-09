// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// The tag is missing. This should fail analysis.

import 'golden_class.dart';

void main() {
  matchesGoldenFile('missing_tag.png');
}
