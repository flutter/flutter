// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

final String message = 'HELLO'; // HOT RELOAD MARKER

void main() {
  print(message);
  runApp(Center(child: Text(message, textDirection: TextDirection.ltr)));
}
