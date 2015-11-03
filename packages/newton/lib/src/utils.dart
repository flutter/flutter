// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of newton;

bool _nearEqual(double a, double b, double epsilon) =>
    (a > (b - epsilon)) && (a < (b + epsilon));

bool _nearZero(double a, double epsilon) => _nearEqual(a, 0.0, epsilon);
