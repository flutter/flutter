// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:ui/ui.dart' as ui;

import '../../html_image_codec.dart';

class EngineImageShader implements ui.ImageShader {
  EngineImageShader(ui.Image image, this.tileModeX, this.tileModeY,
      this.matrix4, this.filterQuality)
      : this.image = image as HtmlImage;

  final ui.TileMode tileModeX;
  final ui.TileMode tileModeY;
  final Float64List matrix4;
  final ui.FilterQuality? filterQuality;
  final HtmlImage image;
}
