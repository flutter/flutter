// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/framework/fn2.dart';
import 'package:sky/framework/components2/popup_menu.dart';
import 'package:sky/framework/components2/checkbox.dart';
import 'package:sky/framework/theme/view_configuration.dart';

class StockMenu extends Component {

  StockMenu({
    Object key,
    this.controller,
    this.autorefresh: false,
    this.onAutorefreshChanged
  }) : super(key: key);

  final PopupMenuController controller;
  final bool autorefresh;
  final ValueChanged onAutorefreshChanged;

  UINode build() {
    var checkbox = new Checkbox(
      checked: this.autorefresh,
      onChanged: this.onAutorefreshChanged
    );

    return new StackPositionedChild(
      new PopupMenu(
        controller: controller,
        items: [
          [new Text('Add stock')],
          [new Text('Remove stock')],
          [new FlexExpandingChild(new Text('Autorefresh')), checkbox],
        ],
        level: 4
      ),
      right: 8.0,
      top: 8.0 + kStatusBarHeight
    );
  }
}
