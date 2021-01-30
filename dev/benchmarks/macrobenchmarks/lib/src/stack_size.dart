// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:flutter/material.dart';

import '../common.dart';

class StackSizePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        children: <Widget>[
          Container(
            width: 200,
            height: 100,
            child: ParentWidget(),
          ),
        ],
      ),
    );
  }
}

class ParentWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final int myStackSize = 10;//io.ProcessInfo.currentStackSize;
    return ChildWidget(parentStackSize: myStackSize);
  }
}

class ChildWidget extends StatelessWidget {
  const ChildWidget({this.parentStackSize, Key key}) : super(key: key);
  final int parentStackSize;

  @override
  Widget build(BuildContext context) {
    final int myStackSize = 100; //io.ProcessInfo.currentStackSize;
    // Captures the stack size difference between parent widget and child widget
    // during the rendering pipeline, i.e. one layer of stateless widget.
    return Text(
      '${myStackSize - parentStackSize}',
      key: const ValueKey<String>(kStackSizeKey),
    );
  }
}
