// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/src/widgets/basic.dart';
import 'package:sky/src/widgets/framework.dart';

abstract class ButtonState<T extends StatefulComponent> extends State<T> {
  bool highlight = false;

  void _handlePointerDown(_) {
    setState(() {
      highlight = true;
    });
  }

  void _handlePointerUp(_) {
    setState(() {
      highlight = false;
    });
  }

  void _handlePointerCancel(_) {
    setState(() {
      highlight = false;
    });
  }

  Widget build(BuildContext context) {
    return new Listener(
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      child: buildContent(context)
    );
  }

  Widget buildContent(BuildContext context);
}
