// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import '../../build_info.dart';
import '../build_system.dart';

// TODO(jonahwilliams): remove import when target uses specific file paths.
import 'windows.dart';

/// Copies the Linux desktop embedder files to the copy directory.
const Target unpackLinux = Target(
  name: 'unpack_linux',
  inputs: <Source>[
    Source.pattern('{CACHE_DIR}/{platform}/libflutter_linux.so'),
    Source.pattern('{CACHE_DIR}/{platform}/flutter_export.h'),
    Source.pattern('{CACHE_DIR}/{platform}/flutter_messenger.h'),
    Source.pattern('{CACHE_DIR}/{platform}/flutter_plugin_registrar.h'),
    Source.pattern('{CACHE_DIR}/{platform}/flutter_glfw.h'),
    Source.pattern('{CACHE_DIR}/{platform}/icudtl.dat'),
    Source.function(listClientWrapperInput),
  ],
  outputs: <Source>[
    Source.pattern('{COPY_DIR}/libflutter_linux.so'),
    Source.pattern('{COPY_DIR}/flutter_export.h'),
    Source.pattern('{COPY_DIR}/flutter_messenger.h'),
    Source.pattern('{COPY_DIR}/flutter_plugin_registrar.h'),
    Source.pattern('{COPY_DIR}/flutter_glfw.h'),
    Source.pattern('{COPY_DIR}/icudtl.dat'),
    Source.function(listClientWrapperOutput),
  ],
  dependencies: <Target>[],
  platforms: <TargetPlatform>[
    TargetPlatform.linux_x64,
  ],
  invocation: copyDesktopAssets,
);
