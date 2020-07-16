// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class LongListVariableExtent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ScrollController controller = ScrollController();
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(),
        body: CupertinoScrollbar(
          controller: controller,
          isAlwaysShown: true,
          child: ListView.builder(
            controller: controller,
            itemCount: 1000,

            // !!!!!!!!!! REMOVE THIS LINE TO SEE THE SLOW VERSION !!!!!!!!!!!!
            itemExtents: List<double>.generate(1000, (int index) => index % 2 * 20 + 20.0),

            itemBuilder: (BuildContext context, int index) {
              return SizedBox(
                height: index % 2 * 20 + 20.0,
                child: Container(
                  color: index % 2 == 0 ? Colors.blue : Colors.green,
                  child: Center(child: Text('$index')),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
