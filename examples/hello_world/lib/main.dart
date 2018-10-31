// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';

//void main() => runApp(const Center(child: Text('Hello, world!', textDirection: TextDirection.ltr)));

void main() {
  runApp(
    MaterialApp(
      theme: ThemeData(platform: TargetPlatform.android),
      home: Material(
        child: FlexibleSpaceBar.createSettings(
          currentExtent: 4.0,
          maxExtent: 8.0,
          minExtent: 2.0,
          toolbarOpacity: 0.2,
          child: AppBar()
        ),
      ),
    ),
  );
}