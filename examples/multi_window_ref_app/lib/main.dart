// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'app/main_window.dart';

void main() {
  final RegularWindowController controller = RegularWindowController(
    contentSize: WindowSizing(
      preferredSize: const Size(800, 600),
      constraints: const BoxConstraints(minWidth: 640, minHeight: 480),
    ),
    title: "Multi-Window Reference Application",
  );
  runWidget(
    RegularWindow(
      controller: controller,
      child: MaterialApp(home: MainWindow(mainController: controller)),
    ),
  );
}
