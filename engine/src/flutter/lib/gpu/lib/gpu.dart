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

export 'src/smoketest.dart';

part 'src/formats.dart';
part 'src/context.dart';
part 'src/buffer.dart';
