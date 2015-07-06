// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../painting/text_style.dart';
import 'basic.dart';
import 'widget.dart';

class DefaultTextStyle extends Inherited {

  DefaultTextStyle({
    String key,
    this.style,
    Widget child
  }) : super(key: key, child: child) {
    assert(style != null);
    assert(child != null);
  }

  final TextStyle style;

  static TextStyle of(Component component) {
    DefaultTextStyle result = component.inheritedOfType(DefaultTextStyle);
    return result == null ? null : result.style;
  }

  bool syncShouldNotify(DefaultTextStyle old) => style != old.style;

}
