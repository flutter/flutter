// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../painting/box_painter.dart';
import 'dart:sky' show Color, Size;

const Map<int, List<BoxShadow>> shadows = const {
  1: const [
    const BoxShadow(
      color: const Color(0x1F000000),
      offset: const Size(0.0, 1.0),
      blur: 3.0),
    const BoxShadow(
      color: const Color(0x3D000000),
      offset: const Size(0.0, 1.0),
      blur: 2.0),
    ],
  2: const [
    const BoxShadow(
      color: const Color(0x29000000),
      offset: const Size(0.0, 3.0),
      blur: 6.0),
    const BoxShadow(
      color: const Color(0x3B000000),
      offset: const Size(0.0, 3.0),
      blur: 6.0),
  ],
  3: const [
    const BoxShadow(
      color: const Color(0x30000000),
      offset: const Size(0.0, 10.0),
      blur: 20.0),
    const BoxShadow(
      color: const Color(0x3B000000),
      offset: const Size(0.0, 6.0),
      blur: 6.0),
  ],
  4: const [
    const BoxShadow(
      color: const Color(0x40000000),
      offset: const Size(0.0, 14.0),
      blur: 28.0),
    const BoxShadow(
      color: const Color(0x38000000),
      offset: const Size(0.0, 10.0),
      blur: 10.0),
  ],
  5: const [
    const BoxShadow(
      color: const Color(0x4E000000),
      offset: const Size(0.0, 19.0),
      blur: 28.0),
    const BoxShadow(
      color: const Color(0x38000000),
      offset: const Size(0.0, 15.0),
      blur: 12.0),
  ],
};
