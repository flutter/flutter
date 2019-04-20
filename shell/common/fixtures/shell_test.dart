// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:isolate';

main() {}

@pragma('vm:entry-point')
fixturesAreFunctionalMain() {
  SayHiFromFixturesAreFunctionalMain();
}

void SayHiFromFixturesAreFunctionalMain() native "SayHiFromFixturesAreFunctionalMain";

void NotifyNative() native "NotifyNative";

void secondaryIsolateMain(String message) {
  print("Secondary isolate got message: " + message);
  NotifyNative();
}

@pragma('vm:entry-point')
void testCanLaunchSecondaryIsolate() {
  Isolate.spawn(secondaryIsolateMain, "Hello from root isolate.");
  NotifyNative();
}
