// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

void main() {
  runApp(const Directionality(
    textDirection: TextDirection.ltr,
   child: const Example(),
  ));
}


class Example extends StatefulWidget {
  const Example();

  @override
  _ExampleState createState() => new _ExampleState();
}

class _ExampleState extends State<Example> {
  @override
  Widget build(BuildContext context) {
    return new ListView.builder(
      itemBuilder: _builder,
      itemCount: 100,
      itemExtent: 500.0,
    );
  }

  Widget _builder(BuildContext context, int index) {
    if (index.isEven) {
      return const AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: const DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.black,
          ),
        ),
      );
    }
    return const AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: const DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
      ),
    );
  }
}

