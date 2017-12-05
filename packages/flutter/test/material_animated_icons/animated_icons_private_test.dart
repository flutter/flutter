// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This is the test for the private implementation of animated icons.
// To make the private API accessible from the test we do not import the 
// material material_animated_icons library, but instead, this test file is an
// implementation of that library, using some of the parts of the real
// material_animated_icons, this give the test access to the private APIs.
library material_animated_icons;

import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

part '../../lib/src/material_animated_icons/animated_icons.dart';
part '../../lib/src/material_animated_icons/animated_icons_data.dart';
part '../../lib/src/material_animated_icons/data/menu_arrow.g.dart';

void main () {
  testWidgets('Can test private API', (WidgetTester tester) async {
    await tester.pumpWidget(
      new AnimatedIcon(
        progress: const AlwaysStoppedAnimation<double>(0.0),
        color: Colors.blue,
        icon: AnimatedIcons.menu_arrow,
      ),
    );
  });
}
