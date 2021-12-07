// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

class PaintingBindingSpy extends BindingBase with SchedulerBinding, ServicesBinding, PaintingBinding {
  int counter = 0;
  int get instantiateImageCodecCalledCount => counter;

  @override
  Future<ui.Codec> instantiateImageCodec(Uint8List list, {int? cacheWidth, int? cacheHeight, bool allowUpscaling = false}) {
    counter++;
    return ui.instantiateImageCodec(list);
  }

  @override
  // ignore: MUST_CALL_SUPER
  void initLicenses() {
    // Do not include any licenses, because we're a test, and the LICENSE file
    // doesn't get generated for tests.
  }
}
