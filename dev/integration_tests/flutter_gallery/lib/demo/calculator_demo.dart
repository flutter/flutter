// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'calculator/home.dart';

class CalculatorDemo extends StatelessWidget {
  const CalculatorDemo({Key key}) : super(key: key);

  static const String routeName = '/calculator';

  @override
  Widget build(BuildContext context) => const Calculator();
}
