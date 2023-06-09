// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

void main() {
  // Change made in https://github.com/flutter/flutter/pull/128522
  Text();
  Text.rich();
  Text.rich(textScaleFactor: 2.0);
  Text(textScaleFactor: 2.0)
    .textScaleFactor;
}
