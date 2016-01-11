// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';

import 'widget_demo.dart';

final List<String> _iconNames = <String>["event", "home", "android", "alarm", "face", "language"];

class TabViewDemo extends StatelessComponent {
  Widget _buildTabIndicator(BuildContext context, String iconName) {
    final Color color = Theme.of(context).primaryColor;
    final AnimatedColorValue _selectedColor = new AnimatedColorValue(Colors.transparent, end: color, curve: Curves.ease);
    final AnimatedColorValue _previousColor = new AnimatedColorValue(color, end: Colors.transparent, curve: Curves.ease);
    final TabBarSelectionState selection = TabBarSelection.of(context);

    return new BuilderTransition(
      performance: selection.performance,
      variables: <AnimatedColorValue>[_selectedColor, _previousColor],
      builder: (BuildContext context) {
        Color background = selection.value == iconName ? _selectedColor.end : _selectedColor.begin;
        if (selection.valueIsChanging) {
          // Then the selection's performance is animating from previousValue to value.
          if (selection.value == iconName)
            background = _selectedColor.value;
          else if (selection.previousValue == iconName)
            background = _previousColor.value;
        }
        return new Container(
          width: 12.0,
          height: 12.0,
          margin: new EdgeDims.all(4.0),
          decoration: new BoxDecoration(
            backgroundColor: background,
            border: new Border.all(color: _selectedColor.end),
            shape: BoxShape.circle
          )
        );
      }
    );
  }

  Widget _buildTabView(String iconName) {
    return new Container(
      key: new ValueKey<String>(iconName),
      padding: const EdgeDims.all(12.0),
      child: new Card(
        child: new Center(
          child: new Icon(icon: "action/$iconName", size:IconSize.s48)
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
    return new TabBarSelection(
      values: _iconNames,
      child: new Builder(
        builder: (BuildContext context) {
          return new Column(
            children: <Widget>[
              new Container(
                margin: const EdgeDims.only(top: 16.0),
                child: new Row(
                  children: <Widget>[
                    new IconButton(
                      icon: "navigation/arrow_back",
                      onPressed: () { _handleArrowButtonPress(context, -1); }
                    ),
                    new Row(
                      children: _iconNames.map((String name) => _buildTabIndicator(context, name)).toList(),
                      justifyContent: FlexJustifyContent.collapse
                    ),
                    new IconButton(
                      icon: "navigation/arrow_forward",
                      onPressed: () { _handleArrowButtonPress(context, 1); }
                    )
                  ],
                  justifyContent: FlexJustifyContent.spaceBetween
                )
              ),
              new Flexible(
                child: new TabBarView(
                  children: _iconNames.map(_buildTabView).toList()
                )
              )
            ]
          );
        }
      )
    );
  }
}

final WidgetDemo kPageSelectorDemo = new WidgetDemo(
  title: 'Page Selector',
  routeName: '/page-selector',
  builder: (_) => new TabViewDemo()
);
