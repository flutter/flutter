// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class GalleryTextScaleValue {
  const GalleryTextScaleValue(this.scale, this.label);

  final double scale;
  final String label;

  @override
  bool operator ==(dynamic other) {
    if (runtimeType != other.runtimeType)
      return false;
    final GalleryTextScaleValue typedOther = other;
    return scale == typedOther.scale && label == typedOther.label;
  }

  @override
  int get hashCode => hashValues(scale, label);

  @override
  String toString() {
    return '$runtimeType($label)';
  }

}

const List<GalleryTextScaleValue> kAllGalleryTextScaleValues = const <GalleryTextScaleValue>[
  const GalleryTextScaleValue(null, 'System Default'),
  const GalleryTextScaleValue(0.8, 'Small'),
  const GalleryTextScaleValue(1.0, 'Normal'),
  const GalleryTextScaleValue(1.3, 'Large'),
  const GalleryTextScaleValue(2.0, 'Huge'),
];
