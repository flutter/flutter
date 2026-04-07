// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';

void main() {
  Color color = Color.from(alpha: 1, red: 0, green: 1, blue: 0);
  print(color.opacity);
  print(color.value);
  color = color.withOpacity(0.55);
}
