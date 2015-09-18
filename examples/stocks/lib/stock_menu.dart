// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of stocks;

Future showStockMenu(Navigator navigator, { bool autorefresh, ValueChanged onAutorefreshChanged }) {
  return showMenu(
    navigator: navigator,
    position: new MenuPosition(
      right: sky.view.paddingRight,
      top: sky.view.paddingTop
    ),
    builder: (Navigator navigator) {
      return <PopupMenuItem>[
        new PopupMenuItem(child: new Text('Add stock')),
        new PopupMenuItem(child: new Text('Remove stock')),
        new PopupMenuItem(
          onPressed: () => onAutorefreshChanged(!autorefresh),
          child: new Row([
              new Flexible(child: new Text('Autorefresh')),
              new Checkbox(
                value: autorefresh,
                onChanged: onAutorefreshChanged
              )
            ]
          )
        ),
      ];
    }
  );
}