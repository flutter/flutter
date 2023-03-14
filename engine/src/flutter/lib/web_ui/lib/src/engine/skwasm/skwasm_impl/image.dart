// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:ui/ui.dart' as ui;

class SkwasmImage implements ui.Image {
  @override
  int get width {
    throw UnimplementedError();
  }

  @override
  int get height {
    throw UnimplementedError();
  }

  @override
  Future<ByteData?> toByteData(
      {ui.ImageByteFormat format = ui.ImageByteFormat.rawRgba}) {
    throw UnimplementedError();
  }

  @override
  ui.ColorSpace get colorSpace => ui.ColorSpace.sRGB;

  @override
  void dispose() {
    throw UnimplementedError();
  }

  @override
  bool get debugDisposed {
    throw UnimplementedError();
  }

  @override
  SkwasmImage clone() => this;

  @override
  bool isCloneOf(ui.Image other) => identical(this, other);

  @override
  List<StackTrace>? debugGetOpenHandleStackTraces() => null;

  @override
  String toString() => '[$width\u00D7$height]';
}
