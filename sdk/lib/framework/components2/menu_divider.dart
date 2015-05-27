// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../fn2.dart';

class MenuDivider extends Component {
  static final Style _style = new Style('''
    margin: 8px 0;
    border-bottom: 1px solid rgba(0, 0, 0, 0.12);'''
  );

  MenuDivider({ Object key }) : super(key: key);

  UINode build() {
    return new Container(
      style: _style
    );
  }
}
