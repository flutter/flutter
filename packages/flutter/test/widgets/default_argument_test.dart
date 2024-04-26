// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_redundant_argument_values

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// If you add or change a default argument for any class in
/// `/packages/flutter/lib/src/widgets/`, feel free to update this file.
void main() {
  const Widget child = SizedBox.shrink();
  const Color color = Color(0x00000000);

  testWidgets('implicit_animations.dart default args', (WidgetTester tester) async {
    const AnimatedPhysicalModel animatedPhysicalModel = AnimatedPhysicalModel(
      elevation: 0,
      color: color,
      shadowColor: color,
      duration: Duration.zero,
      child: child,
    );
    const AnimatedPhysicalModel explicitAnimatedPhysicalModel = AnimatedPhysicalModel(
      shape: BoxShape.rectangle,
      clipBehavior: Clip.none,
      borderRadius: BorderRadius.zero,

      elevation: 0,
      color: color,
      shadowColor: color,
      duration: Duration.zero,
      child: child,
    );
    expect(identical(animatedPhysicalModel, explicitAnimatedPhysicalModel), isTrue);
    // TODO(nate-thegrate): add every class!
  });
  // TODO(nate-thegrate): add every file!
}
