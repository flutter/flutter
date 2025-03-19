// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

class DisposeTester extends StatefulWidget {
  DisposeTester({required this.child}) : super(key: child.key);

  final Widget child;

  @override
  State<DisposeTester> createState() => DisposeTesterState();
}

class DisposeTesterState extends State<DisposeTester> {
  bool _widgetDisposed = false;

  void disposeWidget() {
    setState(() {
      _widgetDisposed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _widgetDisposed ? Container() : widget.child;
  }
}
