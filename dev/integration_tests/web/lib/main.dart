// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

void main() {
  runApp(Center(
    // Can remove when https://github.com/dart-lang/sdk/issues/35801 is fixed.
    // ignore: prefer_const_constructors
    child: Text('Hello, World', textDirection: TextDirection.ltr),
  ));
}
