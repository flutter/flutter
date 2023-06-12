// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

///a function that checks if an image needs to be resized or not
bool imageResizeNeeded(double? maxWidth, double? maxHeight, int? imageQuality) {
  return imageQuality != null
      ? isImageQualityValid(imageQuality)
      : (maxWidth != null || maxHeight != null);
}

/// a function that checks if image quality is between 0 to 100
bool isImageQualityValid(int imageQuality) {
  return imageQuality >= 0 && imageQuality <= 100;
}

/// a function that calculates the size of the downScaled image.
/// imageWidth is the width of the image
/// imageHeight is the height of  the image
/// maxWidth is the maximum width of the scaled image
/// maxHeight is the maximum height of the scaled image
Size calculateSizeOfDownScaledImage(
    Size imageSize, double? maxWidth, double? maxHeight) {
  final double widthFactor = maxWidth != null ? imageSize.width / maxWidth : 1;
  final double heightFactor =
      maxHeight != null ? imageSize.height / maxHeight : 1;
  final double resizeFactor = max(widthFactor, heightFactor);
  return resizeFactor > 1 ? imageSize ~/ resizeFactor : imageSize;
}
