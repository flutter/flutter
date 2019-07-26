// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:fuchsia/fuchsia.dart' as fuchsia;

// ignore: unused_element
Timer _timer;

void main(List<String> args) {
  print('Hello, Dart!');

  if (args.isNotEmpty && args.first == '--now') {
    print('Goodbye now!');
    fuchsia.exit(23);
  }

  _timer = Timer(const Duration(seconds: 1), () {
    print('Goodbye, Dart!');
    fuchsia.exit(42);
  });
}
