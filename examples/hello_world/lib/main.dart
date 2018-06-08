// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

void main() => runApp(new MyWidget());


class MyWidget extends StatefulWidget {
  @override
  State createState() => new MyWidgetState();
}

class MyWidgetState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) {
    final Widget child = new ListView.builder(
      itemBuilder: (BuildContext context, int index) {
        final BoxDecoration decoration = index.isEven
            ? const BoxDecoration(color: Colors.black)
            : const BoxDecoration(color: Colors.white);
        final Widget textChild = index.isEven
            ? const DefaultTextStyle(
              style: const TextStyle(color: Colors.white, fontSize: 16.0),
              child: const Text('Light'))
            : const DefaultTextStyle(
            style: const TextStyle(color: Colors.black, fontSize: 16.0),
            child: const Text('Dark'));
        return new AnnotatedRegion<SystemUiOverlayStyle>(
          value: index.isEven ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          child: new DecoratedBox(
            decoration: decoration,
            child: textChild ,
          ),
        );
      },
      itemExtent: 400.0,
      itemCount: 100,
    );
    return new Directionality(textDirection: TextDirection.ltr, child: child);
  }
}