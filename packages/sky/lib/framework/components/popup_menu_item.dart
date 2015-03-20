// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'animated_component.dart';
import '../animation/animated_value.dart';
import '../fn.dart';
import 'ink_well.dart';

class PopupMenuItem extends AnimatedComponent {
  static final Style _style = new Style('''
    min-width: 112px;
    padding: 16px;''');

  List<Node> children;
  double _opacity;

  PopupMenuItem({ Object key, this.children, AnimatedValue opacity}) : super(key: key) {
    animateField(opacity, #_opacity);
  }

  Node build() {
    return new InkWell(
      style: _style,
      inlineStyle: _opacity == null ? null : 'opacity: ${_opacity}',
      children: children
    );
  }
}
