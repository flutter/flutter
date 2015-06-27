// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/framework/fn.dart';
import 'package:sky/framework/layout.dart';
import 'package:sky/framework/components/popup_menu.dart';
import 'package:sky/framework/components/checkbox.dart';
import 'package:sky/framework/theme/view_configuration.dart';

class StockMenu extends Component {
  static final Style _style = new Style('''
    position: absolute;
    right: 8px;
    top: ${8 + kStatusBarHeight}px;''');

  PopupMenuController controller;

  StockMenu({Object key, this.controller, this.autorefresh: false, this.onAutorefreshChanged}) : super(key: key);

  final bool autorefresh;
  final ValueChanged onAutorefreshChanged;

  static FlexBoxParentData _flex1 = new FlexBoxParentData()..flex = 1;

  UINode build() {
    var checkbox = new Checkbox(
      checked: this.autorefresh,
      onChanged: this.onAutorefreshChanged
    );

    return new StyleNode(
      new PopupMenu(
        controller: controller,
        items: [
          [new Text('Add stock')],
          [new Text('Remove stock')],
          [new ParentDataNode(new Text('Autorefresh'), _flex1), checkbox],
        ],
        level: 4),
        _style
    );
  }
}
