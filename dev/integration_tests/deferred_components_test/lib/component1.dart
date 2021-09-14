// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library component1;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';


class LogoScreen extends StatelessWidget {
  const LogoScreen({Key? key}) : super(key: key);

  static const String _testSentinel = 'Running deferred code';

  @override
  Widget build(BuildContext context) {
    print(_testSentinel);
    return Container(
      child: Column(
        children: <Widget>[
            const Text('DeferredWidget', key: Key('DeferredWidget')),
            Image.asset('customassets/flutter_logo.png', key: const Key('DeferredImage')),
          ]
        ),
        padding: const EdgeInsets.all(25),
        color: Colors.blue,
      );
   }
}
