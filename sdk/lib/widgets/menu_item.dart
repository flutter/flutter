// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/painting/text_style.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/button_base.dart';
import 'package:sky/widgets/default_text_style.dart';
import 'package:sky/widgets/icon.dart';
import 'package:sky/widgets/ink_well.dart';
import 'package:sky/widgets/theme.dart';
import 'package:sky/widgets/widget.dart';

const BoxDecoration _kHighlightDecoration = const BoxDecoration(
  backgroundColor: const Color.fromARGB(102, 153, 153, 153)
);

// TODO(abarth): We shouldn't need _kHighlightBoring, but currently Container
//               isn't smart enough to retain the components it builds when we
//               add or remove a |decoration|. For now, we use a transparent
//               decoration to avoid changing the structure of the tree. The
//               right fix, however, is to make Container smarter about how it
//               syncs its subcomponents.
const BoxDecoration _kHighlightBoring = const BoxDecoration(
  backgroundColor: const Color.fromARGB(0, 0, 0, 0)
);

class MenuItem extends ButtonBase {
  MenuItem({ String key, this.icon, this.children, this.onPressed, this.selected: false })
    : super(key: key);

  String icon;
  List<Widget> children;
  Function onPressed;
  bool selected;

  void syncFields(MenuItem source) {
    icon = source.icon;
    children = source.children;
    onPressed = source.onPressed;
    selected = source.selected;
    super.syncFields(source);
  }

  TextStyle get textStyle {
    TextStyle result = Theme.of(this).text.body2;
    if (highlight)
      result = result.copyWith(color: Theme.of(this).primaryColor);
    return result;
  }

  Widget buildContent() {
    List<Widget> flexChildren = new List<Widget>();
    if (icon != null) {
      flexChildren.add(
        new Opacity(
          opacity: selected ? 1.0 : 0.45,
          child: new Padding(
            padding: const EdgeDims.symmetric(horizontal: 16.0),
            child: new Icon(type: icon, size: 24)
          )
        )
      );
    }
    flexChildren.add(
      new Flexible(
        child: new Padding(
          padding: const EdgeDims.symmetric(horizontal: 16.0),
          child: new DefaultTextStyle(
            style: textStyle,
            child: new Flex(children, direction: FlexDirection.horizontal)
          )
        )
      )
    );
    return new Listener(
      onGestureTap: (_) {
        if (onPressed != null)
          onPressed();
      },
      child: new Container(
        height: 48.0,
        decoration: selected ? _kHighlightDecoration : _kHighlightBoring,
        child: new Container(
          decoration: highlight ? _kHighlightDecoration : _kHighlightBoring,
          child: new InkWell(
            child: new Flex(flexChildren)
          )
        )
      )
    );
  }
}
