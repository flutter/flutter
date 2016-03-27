// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui show Image;

import 'package:flutter/services.dart';

class TestImageInfo implements ImageInfo {
  const TestImageInfo(this.value) : image = null, scale = null;

  @override
  final ui.Image image; // ignored in test

  @override
  final double scale; // ignored in test

  final int value;

  @override
  String toString() => '$runtimeType($value)';
}

class TestProvider extends ImageProvider {
  const TestProvider(this.equalityValue, this.imageValue);
  final int imageValue;
  final int equalityValue;

  @override
  Future<ImageInfo> loadImage() async {
    return new TestImageInfo(imageValue);
  }

  @override
  bool operator ==(dynamic other) {
    if (other is! TestProvider)
      return false;
    final TestProvider typedOther = other;
    return equalityValue == typedOther.equalityValue;
  }

  @override
  int get hashCode => equalityValue.hashCode;

  @override
  String toString() => '$runtimeType($equalityValue, $imageValue)';
}
