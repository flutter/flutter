// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/src/services/sensitive_content.dart' show ContentSensitivity;
import 'package:flutter/widgets.dart';

/// Widget to test disposing a [SensitiveContent] widget.
class DisposeTester extends StatefulWidget {
  DisposeTester({required this.child}) : super(key: child.key);

  final SensitiveContent child;

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

/// Widget to test changing the `sensitivity` of a [SensitiveContent] widget.
///
/// Contains optional [child] parameter that can be used to test finding
/// a particular widget; otherwise, the child widget is a [Container].
class ChangeContentSensitivityTester extends StatefulWidget {
  const ChangeContentSensitivityTester({
    super.key,
    required this.initialContentSensitivity,
    this.child,
  });

  final ContentSensitivity initialContentSensitivity;

  final Widget? child;

  @override
  State<ChangeContentSensitivityTester> createState() => ChangeContentSensitivityTesterState();
}

class ChangeContentSensitivityTesterState extends State<ChangeContentSensitivityTester> {
  late ContentSensitivity _contentSensitivity;

  @override
  void initState() {
    super.initState();
    _contentSensitivity = widget.initialContentSensitivity;
  }

  void changeContentSensitivityTo(ContentSensitivity newContentSensitivity) {
    setState(() {
      _contentSensitivity = newContentSensitivity;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SensitiveContent(
      key: widget.key,
      sensitivity: _contentSensitivity,
      child: widget.child ?? Container(),
    );
  }
}
