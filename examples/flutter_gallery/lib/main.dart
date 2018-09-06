// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Thanks for checking out Flutter!
// Like what you see? Tweet us @flutterio

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'gallery/app.dart';

void main() {
  // Temporary debugging hook for https://github.com/flutter/flutter/issues/17888
  debugInstrumentationEnabled = true;

  runApp(const GalleryApp());
}
