// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'animation/home.dart';

class AnimationDemo extends StatelessWidget {
  const AnimationDemo({Key key}) : super(key: key);

  static const String routeName = '/animation';

  @override
  Widget build(BuildContext context) => const AnimationDemoHome();
}
