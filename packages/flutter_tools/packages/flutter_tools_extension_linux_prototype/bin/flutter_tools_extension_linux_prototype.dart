// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:flutter_tools_extension_linux_prototype/flutter_tools_extension_linux_prototype.dart';

Future<void> main(List<String> args, [Object? message]) =>
    ToolExtensionEntryPoint.runMain(args, message, linuxExtensionEntryPoint);
