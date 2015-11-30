// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of stocks;

enum _MenuItems { autorefresh, autorefreshCheckbox, add, remove }

const double _kMenuMargin = 16.0; // 24.0 on tablet

Future showStockMenu({BuildContext context, bool autorefresh, ValueChanged<bool> onAutorefreshChanged }) async {
  switch (await showMenu(
    context: context,
    position: new ModalPosition(
      right: ui.window.padding.right + _kMenuMargin,
      top: ui.window.padding.top + _kMenuMargin
    ),
    items: <PopupMenuItem>[
      new PopupMenuItem(
        value: _MenuItems.autorefresh,
        child: new Row(<Widget>[
            new Flexible(child: new Text('Autorefresh')),
            new Checkbox(
              value: autorefresh,
              onChanged: (bool value) {
                // TODO(ianh): https://github.com/flutter/flutter/issues/187
                autorefresh = value;
                Navigator.pop(context, _MenuItems.autorefreshCheckbox);
              }
            )
          ]
        )
      ),
      new PopupMenuItem(
        value: _MenuItems.add,
        child: new Text('Add stock')
      ),
      new PopupMenuItem(
        value: _MenuItems.remove,
        child: new Text('Remove stock')
      ),
    ]
  )) {
    case _MenuItems.autorefresh:
      // TODO(ianh): https://github.com/flutter/flutter/issues/187
      autorefresh = !autorefresh;
      continue autorefreshNotify;
    autorefreshNotify:
    case _MenuItems.autorefreshCheckbox:
      onAutorefreshChanged(autorefresh);
      break;
    case _MenuItems.add:
    case _MenuItems.remove:
      await showDialog(
        context: context,
        child: new Dialog(
          title: new Text('Not Implemented'),
          content: new Text('This feature has not yet been implemented.'),
          actions: <Widget>[
            new FlatButton(
              child: new Row(<Widget>[
                new Icon(
                  icon: 'device/dvr',
                  size: IconSize.s18
                ),
                new Container(
                  width: 8.0
                ),
                new Text('DUMP APP TO CONSOLE'),
              ]),
              onPressed: () { debugDumpApp(); }
            ),
            new FlatButton(
              child: new Text('OH WELL'),
              onPressed: () {
                Navigator.pop(context, false);
              }
            ),
          ]
        )
      );
      break;
    default:
      // menu was canceled.
  }
}
