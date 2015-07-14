// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of newton;

class Tolerance {
  final double distance;
  final double time;
  final double velocity;

  const Tolerance({this.distance: epsilonDefault, this.time: epsilonDefault,
      this.velocity: epsilonDefault});
}

const double epsilonDefault = 1e-3;
const Tolerance toleranceDefault = const Tolerance();
