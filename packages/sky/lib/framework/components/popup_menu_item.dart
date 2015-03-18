// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../animation/animated_value.dart';
import '../fn.dart';
import 'material.dart';

class PopupMenuItem extends Component {
  static final Style _style = new Style('''
    min-width: 112px;
    padding: 16px;''');

  List<Node> children;
  AnimatedValueListener _opacity;

  PopupMenuItem({ Object key, this.children, AnimatedValue opacity}) : super(key: key) {
    _opacity = new AnimatedValueListener(this, opacity);
  }

  void didUnmount() {
    _opacity.stopListening();
  }

  Node build() {
    _opacity.ensureListening();

    return new Material(
      style: _style,
      inlineStyle: _opacity.value == null ? null : 'opacity: ${_opacity.value}',
      children: children
    );
  }
}
