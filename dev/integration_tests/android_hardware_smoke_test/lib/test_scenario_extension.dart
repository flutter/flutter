// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'src/messages.g.dart';

/// Extension utility to format a legacy string identifier for a [TestScenario].
extension TestScenarioExtension on TestScenario {
  /// The legacy string name associated with this scenario (e.g. `'blueRectangleTest'`).
  String get testName => '${name}Test';
}
