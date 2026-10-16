// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:isolate';

import 'package:flutter_tools_extension_linux_prototype/flutter_tools_extension_linux_prototype.dart';

void main(List<String> args, [Object? message]) {
  if (message is SendPort) {
    linuxExtensionEntryPoint(message);
  }
}
