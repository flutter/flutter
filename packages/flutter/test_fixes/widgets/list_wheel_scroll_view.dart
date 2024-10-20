// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

void main() {
  // Changes made in https://flutter.dev/docs/release/breaking-changes/clip-behavior
  ListWheelScrollView listWheelScrollView = ListWheelScrollView();
  listWheelScrollView = ListWheelScrollView(clipToSize: true);
  listWheelScrollView = ListWheelScrollView(clipToSize: false);
  listWheelScrollView = ListWheelScrollView(error: '');
  listWheelScrollView = ListWheelScrollView.useDelegate();
  listWheelScrollView = ListWheelScrollView.useDelegate(clipToSize: true);
  listWheelScrollView = ListWheelScrollView.useDelegate(clipToSize: false);
  listWheelScrollView = ListWheelScrollView.useDelegate(error: '');
  listWheelScrollView.clipToSize;
}
