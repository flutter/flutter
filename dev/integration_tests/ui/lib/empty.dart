// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';

/// This application does nothing but show a empty screen.
void main() {
  enableFlutterDriverExtension();
  runApp(Empty());
}

class Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container();
}
