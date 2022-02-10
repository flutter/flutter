// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

// ignore_for_file: avoid_print

@pragma('vm:entry-point')
void main() {
  print('entrypoint: main');
  runApp(const ColoredBox(color: Color(0xffcc0000)));
}

@pragma('vm:entry-point')
void entrypoint() {
  print('entrypoint: entrypoint');
  runApp(const ColoredBox(color: Color(0xff00cc00)));
}
