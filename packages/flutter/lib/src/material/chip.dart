// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'icon.dart';

const TextStyle _kLabelStyle = const TextStyle(
  inherit: false,
  fontSize: 13.0,
  fontWeight: FontWeight.w400,
  color: Colors.black87,
  textBaseline: TextBaseline.alphabetic
);

final ColorFilter _kIconColorFilter = new ColorFilter.mode(
  Colors.black54, TransferMode.dstIn);

class Chip extends StatelessComponent {
  const Chip({
    Key key,
    this.icon,
    this.label,
    this.onDeleted
  }) : super(key: key);

  final Widget icon;
  final Widget label;
  final VoidCallback onDeleted;

  Widget build(BuildContext context) {
    final bool deletable = onDeleted != null;

    List<Widget> children = <Widget>[
      new DefaultTextStyle(
        style: _kLabelStyle,
        child: label
      )
    ];

    if (deletable) {
      children.add(new GestureDetector(
        onTap: onDeleted,
        child: new Container(
          padding: const EdgeDims.symmetric(horizontal: 4.0),
          child: new Icon(
            icon: 'navigation/cancel',
            size: IconSize.s18,
            colorFilter: _kIconColorFilter
          )
        )
      ));
    }

    EdgeDims padding = deletable ?
      new EdgeDims.only(left: 12.0) :
      new EdgeDims.symmetric(horizontal: 12.0);

    return new Container(
      height: 32.0,
      padding: padding,
      decoration: new BoxDecoration(
        backgroundColor: Colors.grey[300],
        borderRadius: 16.0
      ),
      child: new Row(children, justifyContent: FlexJustifyContent.collapse)
    );
  }
}
