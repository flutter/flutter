// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class SimpleAnimationPage extends StatelessWidget {
  const SimpleAnimationPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: LinearProgressIndicator());
  }
}
