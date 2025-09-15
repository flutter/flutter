// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'dart:io';

import 'package:flutter/material.dart';
import 'app/main_window.dart';
import 'package:flutter/src/widgets/_window.dart';

class MainControllerWindowDelegate extends RegularWindowControllerDelegate {
  @override
  void onWindowDestroyed() {
    super.onWindowDestroyed();
    exit(0);
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final RegularWindowController controller = RegularWindowController(
    preferredSize: const Size(800, 600),
    title: 'Multi-Window Reference Application',
    delegate: MainControllerWindowDelegate(),
  );
  runWidget(
    RegularWindow(
      controller: controller,
      child: MaterialApp(home: MainWindow(mainController: controller)),
    ),
  );
}
