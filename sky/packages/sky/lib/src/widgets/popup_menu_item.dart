// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/painting.dart';
import 'package:sky/src/widgets/basic.dart';
import 'package:sky/src/widgets/default_text_style.dart';
import 'package:sky/src/widgets/framework.dart';
import 'package:sky/src/widgets/gesture_detector.dart';
import 'package:sky/src/widgets/ink_well.dart';
import 'package:sky/src/widgets/popup_menu.dart';
import 'package:sky/src/widgets/theme.dart';

const double _kMenuItemHeight = 48.0;
const double _kBaselineOffsetFromBottom = 20.0;

class PopupMenuItem extends Component {
  PopupMenuItem({
    Key key,
    this.onPressed,
    this.value,
    this.child
  }) : super(key: key);

  final Widget child;
  final Function onPressed;
  final dynamic value;

  TextStyle get textStyle => Theme.of(this).text.subhead;

  PopupMenu findAncestorPopupMenu() {
    Widget ancestor = parent;
    while (ancestor != null && ancestor is! PopupMenu)
      ancestor = ancestor.parent;
    return ancestor;
  }

  void handlePressed() {
    if (onPressed != null)
      onPressed();
    PopupMenu menu = findAncestorPopupMenu();
    menu?.itemPressed(this);
  }

  Widget build() {
    return new GestureDetector(
      onTap: handlePressed,
      child: new InkWell(
        child: new Container(
          height: _kMenuItemHeight,
          child: new DefaultTextStyle(
            style: textStyle,
            child: new Baseline(
              baseline: _kMenuItemHeight - _kBaselineOffsetFromBottom,
              child: child
            )
          )
        )
      )
    );
  }
}
