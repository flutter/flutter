// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'gallery/app.dart';

Object? createGarbage() {
  final List<dynamic> garbage = <dynamic>[];
  for (int index = 0; index < 1000; index += 1) {
    List<int>? moreGarbage = List<int>.filled(1000, index);
    if (index % 2 == 0) {
      garbage.add(moreGarbage);
    }
  }
  return garbage;
}

void main() async {
  // Create some garbage, and simulate some delays between that could be
  // plugin or network call related.
  final List<dynamic> garbage = <dynamic>[];
  for (int index = 0; index < 20; index += 1) {
    final Object? moreGarbage = createGarbage();
    if (index % 2 == 0) {
      garbage.add(moreGarbage);
      await Future<void>.delayed(Duration(milliseconds: 7));
    }
  }

  runApp(const GalleryApp());
}
