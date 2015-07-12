// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/painting/text_style.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/default_text_style.dart';
import 'package:sky/widgets/ink_well.dart';
import 'package:sky/widgets/theme.dart';

const double kMenuItemHeight = 48.0;
const double kBaselineOffsetFromBottom = 20.0;

class PopupMenuItem extends Component {
  PopupMenuItem({ String key, this.child, this.opacity}) : super(key: key);

  final Widget child;
  final double opacity;

  TextStyle get textStyle => Theme.of(this).text.subhead;

  Widget build() {
    return new Opacity(
      opacity: opacity,
      child: new InkWell(
        child: new Container(
          height: kMenuItemHeight,
          child: new DefaultTextStyle(
            style: textStyle,
            child: new Baseline(
              baseline: kMenuItemHeight - kBaselineOffsetFromBottom,
              child: child
            )
          )
        )
      )
    );
  }
}
