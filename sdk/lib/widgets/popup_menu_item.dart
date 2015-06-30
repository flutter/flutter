// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../painting/text_style.dart';
import 'basic.dart';
import 'default_text_style.dart';
import 'ink_well.dart';
import 'theme.dart';

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
          constraints: const BoxConstraints(minWidth: 112.0),
          padding: const EdgeDims.all(16.0),
          child: new DefaultTextStyle(
            style: textStyle,
            child: child
          )
        )
      )
    );
  }
}
