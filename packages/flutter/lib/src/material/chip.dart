// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'debug.dart';
import 'icon.dart';
import 'icons.dart';
import 'tooltip.dart';

const double _kChipHeight = 32.0;
const double _kAvatarDiamater = _kChipHeight;

const TextStyle _kLabelStyle = const TextStyle(
  inherit: false,
  fontSize: 13.0,
  fontWeight: FontWeight.w400,
  color: Colors.black87,
  textBaseline: TextBaseline.alphabetic
);

class Chip extends StatelessWidget {
  const Chip({
    Key key,
    this.avatar,
    this.label,
    this.onDeleted
  }) : super(key: key);

  final Widget avatar;
  final Widget label;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    final bool deletable = onDeleted != null;
    double leftPadding = 12.0;
    double rightPadding = 12.0;

    List<Widget> children = <Widget>[];

    if (avatar != null) {
      leftPadding = 0.0;
      children.add(new ExcludeSemantics(
        child: new Container(
          margin: const EdgeInsets.only(right: 8.0),
          width: _kAvatarDiamater,
          height: _kAvatarDiamater,
          child: avatar
        )
      ));
    }

    children.add(new DefaultTextStyle(
      style: _kLabelStyle,
      child: label
    ));

    if (deletable) {
      rightPadding = 0.0;
      children.add(new GestureDetector(
        onTap: onDeleted,
        child: new Tooltip(
          message: 'Delete "$label"',
          child: new Container(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: new Icon(
              icon: Icons.cancel,
              size: 18.0,
              color: Colors.black54
            )
          )
        )
      ));
    }

    return new Semantics(
      container: true,
      child: new Container(
        height: _kChipHeight,
        padding: new EdgeInsets.only(left: leftPadding, right: rightPadding),
        decoration: new BoxDecoration(
          backgroundColor: Colors.grey[300],
          borderRadius: 16.0
        ),
        child: new Row(
          children: children,
          mainAxisAlignment: MainAxisAlignment.collapse
        )
      )
    );
  }
}
