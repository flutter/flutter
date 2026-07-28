// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// A stateful wrapper that hosts a [RadioGroup] with a mutable [groupValue],
/// making it easy to pump and interact with radio buttons in tests.
///
/// See https://github.com/flutter/flutter/issues/177028.
class TestRadioGroup<T> extends StatefulWidget {
  const TestRadioGroup({super.key, required this.child});

  final Widget child;

  @override
  State<StatefulWidget> createState() => TestRadioGroupState<T>();
}

class TestRadioGroupState<T> extends State<TestRadioGroup<T>> {
  T? groupValue;

  @override
  Widget build(BuildContext context) {
    return RadioGroup<T>(
      onChanged: (T? newValue) {
        setState(() {
          groupValue = newValue;
        });
      },
      groupValue: groupValue,
      child: widget.child,
    );
  }
}
