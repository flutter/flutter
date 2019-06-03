// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import '../../build_info.dart';
import '../build_system.dart';

// TODO(jonahwilliams): remove import when target uses specific file paths.
import 'windows.dart';

/// Copies the Linux desktop embedding files to the copy directory.
const Target unpackLinux = Target(
  name: 'unpack_linux',
  inputs: <Source>[
    Source.pattern('{CACHE_DIR}/{platform}/libflutter_linux.so'),
    Source.pattern('{CACHE_DIR}/{platform}/flutter_export.h'),
    Source.pattern('{CACHE_DIR}/{platform}/flutter_messenger.h'),
    Source.pattern('{CACHE_DIR}/{platform}/flutter_plugin_registrar.h'),
    Source.pattern('{CACHE_DIR}/{platform}/flutter_glfw.h'),
    Source.pattern('{CACHE_DIR}/{platform}/icudtl.dat'),
    Source.pattern('{CACHE_DIR}/{platform}/cpp_client_wrapper/*'),
  ],
  outputs: <Source>[
    Source.pattern('{PROJECT_DIR}/linux/flutter/libflutter_linux.so'),
    Source.pattern('{PROJECT_DIR}/linux/flutter/flutter_export.h'),
    Source.pattern('{PROJECT_DIR}/linux/flutter/flutter_messenger.h'),
    Source.pattern('{PROJECT_DIR}/linux/flutter/flutter_plugin_registrar.h'),
    Source.pattern('{PROJECT_DIR}/linux/flutter/flutter_glfw.h'),
    Source.pattern('{PROJECT_DIR}/linux/flutter/icudtl.dat'),
    Source.pattern('{PROJECT_DIR}/linux/flutter/cpp_client_wrapper/*'),
  ],
  dependencies: <Target>[],
  platforms: <TargetPlatform>[
    TargetPlatform.linux_x64,
  ],
  invocation: copyDesktopAssets,
);
