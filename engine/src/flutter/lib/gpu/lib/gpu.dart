// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The Flutter GPU library.
///
/// To use, import `package:flutter_gpu/gpu.dart`.
///
/// See also:
///
///  * [Flutter GPU Wiki page](https://github.com/flutter/flutter/wiki/Flutter-GPU).
library flutter_gpu;

import 'dart:ffi';
import 'dart:nativewrappers';
import 'dart:typed_data';
// ignore: uri_does_not_exist
import 'dart:ui' as ui;

export 'src/smoketest.dart';

part 'src/buffer.dart';
part 'src/command_buffer.dart';
part 'src/context.dart';
part 'src/formats.dart';
part 'src/texture.dart';
part 'src/render_pass.dart';
part 'src/render_pipeline.dart';
part 'src/shader.dart';
part 'src/shader_library.dart';
