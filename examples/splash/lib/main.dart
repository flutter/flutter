// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

const Color _white = Color(0xFFFFFFFF);
const Color _black87 = Color(0xDD000000);

void main() {
  runApp(
    const DecoratedBox(
      decoration: BoxDecoration(color: _white),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          textDirection: TextDirection.ltr,
          children: <Widget>[
            FlutterLogo(size: 48),
            Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'This app is only meant to be run under the Flutter debugger',
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                style: TextStyle(color: _black87),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
