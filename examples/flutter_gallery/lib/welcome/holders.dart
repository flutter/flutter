// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class WelcomePopAnimationChild {
  WelcomePopAnimationChild(
      {this.top, this.right, this.bottom, this.left, @required this.child});

  double top;
  double right;
  double bottom;
  double left;
  Widget child;
}
