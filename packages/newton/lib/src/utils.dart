// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of newton;

const double _simulationEpsilon = 0.2;

bool _nearEqual(double a, double b) =>
    (a > (b - _simulationEpsilon)) && (a < (b + _simulationEpsilon));

bool _nearZero(double a) => _nearEqual(a, 0.0);
