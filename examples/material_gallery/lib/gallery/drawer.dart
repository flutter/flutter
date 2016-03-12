// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter/widgets.dart';

import 'app.dart';

class GalleryDrawer extends StatelessWidget {
  GalleryDrawer({ Key key }) : super(key: key);

  void _changeTheme(BuildContext context, bool value) {
    GalleryApp.of(context).lightTheme = value;
  }

  void _toggleAnimationSpeed(BuildContext context) {
    GalleryApp.of(context).setState(() {
      timeDilation = (timeDilation != 1.0) ? 1.0 : 5.0;
    });
  }

  Widget build(BuildContext context) {
    return new Drawer(
      child: new Block(
        children: <Widget>[
          new DrawerHeader(child: new Text('Flutter Gallery')),
          new DrawerItem(
            icon: Icons.brightness_5,
            onPressed: () { _changeTheme(context, true); },
            selected: GalleryApp.of(context).lightTheme,
            child: new Row(
              children: <Widget>[
                new Flexible(child: new Text('Light')),
                new Radio<bool>(
                  value: true,
                  groupValue: GalleryApp.of(context).lightTheme,
                  onChanged: (bool value) { _changeTheme(context, value); }
                )
              ]
            )
          ),
          new DrawerItem(
            icon: Icons.brightness_7,
            onPressed: () { _changeTheme(context, false); },
            selected: !GalleryApp.of(context).lightTheme,
            child: new Row(
              children: <Widget>[
                new Flexible(child: new Text('Dark')),
                new Radio<bool>(
                  value: false,
                  groupValue: GalleryApp.of(context).lightTheme,
                  onChanged: (bool value) { _changeTheme(context, value); }
                )
              ]
            )
          ),
          new Divider(),
          new DrawerItem(
            icon: Icons.hourglass_empty,
            selected: timeDilation != 1.0,
            onPressed: () { _toggleAnimationSpeed(context); },
            child: new Row(
              children: <Widget>[
                new Flexible(child: new Text('Animate Slowly')),
                new Checkbox(
                  value: timeDilation != 1.0,
                  onChanged: (bool value) { _toggleAnimationSpeed(context); }
                )
              ]
            )
          )
        ]
      )
    );
  }
}
