// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'basic.dart';
import 'button_base.dart';
import 'icon.dart';
import 'ink_well.dart';
import 'widget.dart';

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
  MenuItem({ String key, this.icon, this.children, this.onPressed })
    : super(key: key);

  String icon;
  List<Widget> children;
  Function onPressed;

  void syncFields(MenuItem source) {
    icon = source.icon;
    children = source.children;
    onPressed = source.onPressed;
    super.syncFields(source);
  }

  Widget buildContent() {
    return new Listener(
      onGestureTap: (_) {
        if (onPressed != null)
          onPressed();
      },
      child: new Container(
        height: 48.0,
        decoration: highlight ? _kHighlightDecoration : _kHighlightBoring,
        child: new InkWell(
          child: new Flex([
            new Padding(
              padding: const EdgeDims.symmetric(horizontal: 16.0),
              child: new Icon(type: "${icon}_grey600", size: 24)
            ),
            new Flexible(
              flex: 1,
              child: new Padding(
                padding: const EdgeDims.symmetric(horizontal: 16.0)
                child: new Flex(children, direction: FlexDirection.horizontal),
              )
            )
          ])
        )
      )
    );
  }
}
