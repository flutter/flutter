// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Thanks for checking out Flutter!
// Like what you see? Tweet us @flutterio

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'gallery/app.dart';

void main() {
  // Temporary debugging hook for https://github.com/flutter/flutter/issues/17956
  debugInstrumentationEnabled = true;

  // Overriding https://github.com/flutter/flutter/issues/13736 for better
  // visual effect at the cost of performance.
  MaterialPageRoute.debugEnableFadingRoutes = true; // ignore: deprecated_member_use
  runApp(const GalleryApp());
}
