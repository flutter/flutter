// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/scheduler.dart';
import 'package:flutter/rendering.dart';

import 'framework.dart';
import 'ticker_provider.dart';

abstract class ScrollContext {
  BuildContext get notificationContext;
  TickerProvider get vsync;
  AxisDirection get axisDirection;

  void setIgnorePointer(bool value);
  void setCanDrag(bool value);
}
