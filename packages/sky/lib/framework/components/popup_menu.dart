// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../animation/animated_value.dart';
import '../fn.dart';
import '../theme/colors.dart';
import 'material.dart';
import 'popup_menu_item.dart';

const double _kItemInitialOpacity = 0.0;
const double _kItemFinalOpacity = 1.0;
const double _kItemFadeDuration = 500.0;
const double _kItemFadeDelay = 200.0;

class PopupMenu extends Component {
  static final Style _style = new Style('''
    border-radius: 2px;
    padding: 8px 0;
    background-color: ${Grey[50]};'''
  );

  List<List<Node>> items;
  int level;
  List<AnimatedValue> _opacities;

  PopupMenu({ Object key, this.items, this.level }) : super(key: key) {
    _opacities = new List.from(items.map(
        (item) => new AnimatedValue(_kItemInitialOpacity)));
  }

  // TODO(abarth): Rather than using didMount, we should have the parent
  // component kick off these animations.
  void didMount() {
    int i = 0;
    _opacities.forEach((opacity) {
      opacity.animateTo(_kItemFinalOpacity, _kItemFadeDuration,
                        initialDelay: _kItemFadeDelay * i++);
    });
  }

  Node build() {
    List<Node> children = [];
    int i = 0;
    items.forEach((List<Node> item) {
      children.add(
          new PopupMenuItem(key: i, children: item, opacity: _opacities[i]));
      ++i;
    });

    return new Material(
      style: _style,
      children: children,
      level: level
    );
  }
}
