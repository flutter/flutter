// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class SimpleScroll extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        for (int n = 0; n < 200; n += 1)
          Container(height: 40.0, child: Text('$n')),
      ],
    );
  }
}
