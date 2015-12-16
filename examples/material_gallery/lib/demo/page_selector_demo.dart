// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class PageSelectorDemo extends StatelessComponent {
  Widget _buildTabView(String iconName) {
    return new Container(
      key: new ValueKey<String>(iconName),
      padding: const EdgeDims.all(12.0),
      child: new Card(
        child: new Center(
          child: new Icon(icon: 'action/$iconName', size:IconSize.s48)
        )
      )
    );
  }

  void _handleArrowButtonPress(BuildContext context, int delta) {
    final TabBarSelectionState selection = TabBarSelection.of(context);
    if (!selection.valueIsChanging)
      selection.value = selection.values[(selection.index + delta).clamp(0, selection.values.length - 1)];
  }

  Widget build(BuildContext notUsed) { // Can't find the TabBarSelection from this context.
    final List<String> iconNames = <String>['event', 'home', 'android', 'alarm', 'face', 'language'];

    return new Scaffold(
      toolBar: new ToolBar(center: new Text('Page Selector')),
      body: new TabBarSelection(
        values: iconNames,
        child: new Builder(
          builder: (BuildContext context) {
            return new Column(
              children: <Widget>[
                new Container(
                  margin: const EdgeDims.only(top: 16.0),
                  child: new Row(
                    children: <Widget>[
                      new IconButton(
                        icon: 'navigation/arrow_back',
                        onPressed: () { _handleArrowButtonPress(context, -1); },
                        tooltip: 'Back'
                      ),
                      new TabPageSelector<String>(),
                      new IconButton(
                        icon: 'navigation/arrow_forward',
                        onPressed: () { _handleArrowButtonPress(context, 1); },
                        tooltip: 'Forward'
                      )
                    ],
                    justifyContent: FlexJustifyContent.spaceBetween
                  )
                ),
                new Flexible(
                  child: new TabBarView(
                    children: iconNames.map(_buildTabView).toList()
                  )
                )
              ]
            );
          }
        )
      )
    );
  }
}
