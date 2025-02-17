// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

void main() {
  // Changes made in https://github.com/flutter/flutter/pull/163314
  TooltipThemeData tooltipThemeData = TooltipThemeData();
  tooltipThemeData = TooltipThemeData(height: 15.0);
  tooltipThemeData = TooltipThemeData(height: null);
  tooltipThemeData.height;
  tooltipThemeData.copyWith(height: 10.0);
}
