// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/painting/text_style.dart';
import 'package:sky/theme/typography.dart' as typography;
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/default_text_style.dart';
import 'package:sky/widgets/material.dart';
import 'package:sky/widgets/theme.dart';

class SnackBarAction extends Component {
  SnackBarAction({String key, this.label, this.onPressed }) : super(key: key) {
    assert(label != null);
  }

  final String label;
  final Function onPressed;

  Widget build() {
    return new Listener(
      onGestureTap: (_) => onPressed(),
      child: new Container(
        margin: const EdgeDims.only(left: 24.0),
        padding: const EdgeDims.only(top: 14.0, bottom: 14.0),
        child: new Text(label)
      )
    );
  }
}

class SnackBar extends Component {

  SnackBar({
    String key,
    this.content,
    this.actions
  }) : super(key: key) {
    assert(content != null);
  }

  final Widget content;
  final List<SnackBarAction> actions;

  Widget build() {
    List<Widget> children = [
      new Flexible(
        child: new Container(
          margin: const EdgeDims.symmetric(vertical: 14.0),
          child: new DefaultTextStyle(
            style: typography.white.subhead,
            child: content
          )
        )
      )
    ]..addAll(actions);
    return new Material(
      level: 2,
      color: const Color(0xFF323232),
      type: MaterialType.canvas,
      child: new Container(
        margin: const EdgeDims.symmetric(horizontal: 24.0),
        child: new DefaultTextStyle(
          style: new TextStyle(color: Theme.of(this).accentColor),
          child: new Flex(children)
        )
      )
    );
  }
}
