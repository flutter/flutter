// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';

void main() {
  enableFlutterDriverExtension(handler: (String? message) async {
    assert(message == 'test');
    const AssetImage provider = AssetImage('test space.png');
    final ImageStream stream = provider.resolve(ImageConfiguration.empty);
    final Completer<bool> completer = Completer<bool>();
    stream.addListener(ImageStreamListener((ImageInfo imageInfo, bool synchronousCall) {
      completer.complete(true);
    }, onError: (dynamic error, StackTrace? st) {
      completer.complete(false);
    }));
    return (await completer.future) ? 'pass' : 'fail';
  });
}
