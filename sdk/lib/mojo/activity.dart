// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:mojom/intents/intents.mojom.dart';
import 'package:sky/mojo/shell.dart' as shell;

void finishCurrentActivity() {
    ActivityManagerProxy activityManager = new ActivityManagerProxy.unbound();
    shell.requestService('mojo:sky_viewer', activityManager);
    activityManager.ptr.finishCurrentActivity();
}