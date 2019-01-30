// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' show VoidCallback;

List<String> captureOutput(VoidCallback fn) {
  final List<String> log = <String>[];

  runZoned<void>(fn, zoneSpecification: ZoneSpecification(
    print: (Zone self,
            ZoneDelegate parent,
            Zone zone,
            String line) {
              log.add(line);
            },
  ));

  return log;
}
