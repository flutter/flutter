// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';

void main() async {
  // Changes made in https://github.com/flutter/flutter/pull/82939
  final FlutterDriver driver = FlutterDriver();
  await driver.enableAccessibility();

  // Changes made in https://github.com/flutter/flutter/pull/79310
  final Timeline timeline = Timeline.fromJson({});
  TimelineSummary.summarize(timeline).writeSummaryToFile('traceName');
  TimelineSummary.summarize(timeline).writeSummaryToFile(
    'traceName',
    destinationDirectory: 'destination',
    pretty: false,
  );
}
