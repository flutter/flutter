// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/context.dart';
import '../base/process.dart';

class XCode {
  static void initGlobal() {
    context[XCode] = new XCode();
  }

  bool get isInstalled => exitsHappy(<String>['xcode-select', '--print-path']);
}
