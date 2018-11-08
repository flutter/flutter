// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter/cupertino.dart';
//void main() => runApp(const Center(child: Text('Hello, world!', textDirection: TextDirection.ltr)));
void main() {
   Color backgroundColor = Color.fromRGBO(0, 0, 255, .5);
  runApp(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        color: const Color.fromRGBO(255, 0, 0, 1.0),
        child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          height: 300.0,
          width: 300.0,
          child: CupertinoPicker(
            backgroundColor: backgroundColor,
            itemExtent: 15.0,
            children: const <Widget>[
              Text('1'),
              Text('1'),
              Text('1'),
              Text('1'),
              Text('1'),
              Text('1'),
              Text('1'),
            ],
            onSelectedItemChanged: (int i) {},
          ),
        ),
      ),
    ),
    ),

  );
}