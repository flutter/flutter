// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

Animation<double> initAnimation({
  @required double from,
  @required double to,
  @required Curve curve,
  @required AnimationController controller,
}) {
  final CurvedAnimation animation = CurvedAnimation(
    parent: controller,
    curve: curve,
  );
  return Tween<double>(begin: from, end: to).animate(animation);
}
