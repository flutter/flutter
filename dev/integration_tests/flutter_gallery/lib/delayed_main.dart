// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'gallery/app.dart';

Object? createGarbage() {
  final garbage = <dynamic>[];
  for (var index = 0; index < 1000; index += 1) {
    final moreGarbage = List<int>.filled(1000, index);
    if (index.isOdd) {
      garbage.add(moreGarbage);
    }
  }
  return garbage;
}

Future<void> main() async {
  // Create some garbage, and simulate some delays between that could be
  // plugin or network call related.
  final garbage = <dynamic>[];
  for (var index = 0; index < 20; index += 1) {
    final Object? moreGarbage = createGarbage();
    if (index.isOdd) {
      garbage.add(moreGarbage);
      await Future<void>.delayed(const Duration(milliseconds: 7));
    }
  }

  runApp(const GalleryApp());
}
