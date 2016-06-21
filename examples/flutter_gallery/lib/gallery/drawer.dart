// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class GalleryDrawer extends StatelessWidget {
  GalleryDrawer({
    Key key,
    this.useLightTheme,
    this.onThemeChanged,
    this.timeDilation,
    this.onTimeDilationChanged,
    this.showPerformanceOverlay,
    this.onShowPerformanceOverlayChanged
  }) : super(key: key) {
    assert(onThemeChanged != null);
    assert(onTimeDilationChanged != null);
  }

  final bool useLightTheme;
  final ValueChanged<bool> onThemeChanged;

  final double timeDilation;
  final ValueChanged<double> onTimeDilationChanged;

  final bool showPerformanceOverlay;
  final ValueChanged<bool> onShowPerformanceOverlayChanged;

  @override
  Widget build(BuildContext context) {
    return new Drawer(
      child: new Block(
        children: <Widget>[
          new DrawerHeader(
            content: new Center(child: new Text('Flutter gallery'))
          ),
          new DrawerItem(
            icon: new Icon(Icons.brightness_5),
            onPressed: () { onThemeChanged(true); },
            selected: useLightTheme,
            child: new Row(
              children: <Widget>[
                new Flexible(child: new Text('Light')),
                new Radio<bool>(
                  value: true,
                  groupValue: useLightTheme,
                  onChanged: onThemeChanged
                )
              ]
            )
          ),
          new DrawerItem(
            icon: new Icon(Icons.brightness_7),
            onPressed: () { onThemeChanged(false); },
            selected: useLightTheme,
            child: new Row(
              children: <Widget>[
                new Flexible(child: new Text('Dark')),
                new Radio<bool>(
                  value: false,
                  groupValue: useLightTheme,
                  onChanged: onThemeChanged
                )
              ]
            )
          ),
          new Divider(),
          new DrawerItem(
            icon: new Icon(Icons.hourglass_empty),
            selected: timeDilation != 1.0,
            onPressed: () { onTimeDilationChanged(timeDilation != 1.0 ? 1.0 : 20.0); },
            child: new Row(
              children: <Widget>[
                new Flexible(child: new Text('Animate Slowly')),
                new Checkbox(
                  value: timeDilation != 1.0,
                  onChanged: (bool value) { onTimeDilationChanged(value ? 20.0 : 1.0); }
                )
              ]
            )
          ),
          new DrawerItem(
            icon: new Icon(Icons.assessment),
            onPressed: () { onShowPerformanceOverlayChanged(!showPerformanceOverlay); },
            selected: showPerformanceOverlay,
            child: new Row(
              children: <Widget>[
                new Flexible(child: new Text('Performance Overlay')),
                new Checkbox(
                  value: showPerformanceOverlay,
                  onChanged: (bool value) { onShowPerformanceOverlayChanged(!showPerformanceOverlay); }
                )
              ]
            )
          ),
        ]
      )
    );
  }
}
