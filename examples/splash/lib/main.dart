// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

void main() {
  runApp(
    const DecoratedBox(
      decoration: BoxDecoration(color: Colors.white),
      child: Center(
        child: FlutterLogo(size: 48),
      ),
    ),
  );
}
