// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'ink_well.dart';

class ListItem extends StatelessComponent {
  ListItem({
    Key key,
    this.left,
    this.center,
    this.right,
    this.onTap,
    this.onLongPress
  }) : super(key: key) {
    assert(center != null);
  }

  final Widget left;
  final Widget center;
  final Widget right;
  final GestureTapCallback onTap;
  final GestureLongPressCallback onLongPress;

  Widget build(BuildContext context) {
    List<Widget> children = new List<Widget>();

    if (left != null) {
      children.add(new Container(
        margin: new EdgeDims.only(right: 16.0),
        width: 40.0,
        child: left
      ));
    }

    children.add(new Flexible(
      child: center
    ));

    if (right != null) {
      children.add(new Container(
        margin: new EdgeDims.only(left: 16.0),
        child: right
      ));
    }

    return new Padding(
      padding: const EdgeDims.symmetric(horizontal: 16.0),
      child: new InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: new Row(children)
      )
    );
  }
}
