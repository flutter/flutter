// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:mojom/intents/intents.mojom.dart';
import 'package:sky/mojo/shell.dart' as shell;

const int NEW_DOCUMENT = 0x00080000;
const int NEW_TASK = 0x10000000;
const int MULTIPLE_TASK = 0x08000000;

ActivityManagerProxy _initActivityManager() {
  ActivityManagerProxy activityManager = new ActivityManagerProxy.unbound();
  shell.requestService('mojo:sky_viewer', activityManager);
  return activityManager;
}

final ActivityManagerProxy _activityManager = _initActivityManager();

void finishCurrentActivity() {
  _activityManager.ptr.finishCurrentActivity();
}

void startActivity(Intent intent) {
  _activityManager.ptr.startActivity(intent);
}
