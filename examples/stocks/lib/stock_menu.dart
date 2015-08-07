// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of stocks;

class StockMenu extends Component {
  StockMenu({
    Key key,
    this.showing,
    this.onDismissed,
    this.navigator,
    this.autorefresh: false,
    this.onAutorefreshChanged
  }) : super(key: key);

  final bool showing;
  final PopupMenuDismissedCallback onDismissed;
  final Navigator navigator;
  final bool autorefresh;
  final ValueChanged onAutorefreshChanged;

  Widget build() {
    var checkbox = new Checkbox(
      value: this.autorefresh,
      onChanged: this.onAutorefreshChanged
    );

    return new Positioned(
      child: new PopupMenu(
        items: [
          new PopupMenuItem(child: new Text('Add stock')),
          new PopupMenuItem(child: new Text('Remove stock')),
          new PopupMenuItem(
            onPressed: () => onAutorefreshChanged(!autorefresh),
            child: new Flex([new Flexible(child: new Text('Autorefresh')), checkbox])
          ),
        ],
        level: 4,
        showing: showing,
        onDismissed: onDismissed,
        navigator: navigator
      ),
      right: sky.view.paddingRight,
      top: sky.view.paddingTop
    );
  }
}
