// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart.sky;

// Modeled after Skia's SkRSXform
class RSTransform {
  RSTransform(double scos, double ssin, double tx, double ty) {
    _value
      ..[0] = scos
      ..[1] = ssin
      ..[2] = tx
      ..[3] = ty;
  }

  final Float32List _value = new Float32List(4);
  double get scos => _value[0];
  double get ssin => _value[1];
  double get tx => _value[2];
  double get ty => _value[3];
}
