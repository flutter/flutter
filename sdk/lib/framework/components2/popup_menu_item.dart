// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../fn2.dart';
import 'ink_well.dart';

class PopupMenuItem extends Component {
  PopupMenuItem({ Object key, this.children, this.opacity}) : super(key: key);

  final List<UINode> children;
  final double opacity;

  UINode build() {
    return new Opacity(
      opacity: opacity,
      child: new InkWell(
        children: [new Container(
          constraints: const BoxConstraints(minWidth: 112.0),
          padding: const EdgeDims.all(16.0),
          child: new Flex(children)
        )]
      )
    );
  }
}
