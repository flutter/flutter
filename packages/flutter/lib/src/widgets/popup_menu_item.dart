// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/painting/text_style.dart';
import 'package:sky/src/widgets/basic.dart';
import 'package:sky/src/widgets/default_text_style.dart';
import 'package:sky/src/widgets/framework.dart';
import 'package:sky/src/widgets/gesture_detector.dart';
import 'package:sky/src/widgets/ink_well.dart';
import 'package:sky/src/widgets/theme.dart';

const double _kMenuItemHeight = 48.0;
const double _kBaselineOffsetFromBottom = 20.0;

class PopupMenuItem extends Component {
  PopupMenuItem({
    Key key,
    this.onPressed,
    this.child
  }) : super(key: key);

  final Widget child;
  final Function onPressed;

  TextStyle get textStyle => Theme.of(this).text.subhead;

  Widget build() {
    return new GestureDetector(
      onTap: onPressed,
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
