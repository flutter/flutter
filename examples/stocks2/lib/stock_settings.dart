// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/theme/colors.dart' as colors;
import 'package:sky/theme/typography.dart' as typography;
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/checkbox.dart';
import 'package:sky/widgets/icon_button.dart';
import 'package:sky/widgets/menu_item.dart';
import 'package:sky/widgets/navigator.dart';
import 'package:sky/widgets/scaffold.dart';
import 'package:sky/widgets/tool_bar.dart';

class StockSettings extends Component {

  StockSettings(this._navigator);

  Navigator _navigator;

  bool _awesome = false;
  void _handleAwesomeChanged(bool value) {
    setState(() {
      _awesome = value;
    });
  }

  Widget buildToolBar() {
    return new ToolBar(
      left: new IconButton(
        icon: 'navigation/arrow_back_white',
        onPressed: _navigator.pop),
      center: new Text('Settings', style: typography.white.title),
      backgroundColor: colors.Purple[500]
    );
  }

  Widget buildSettingsPane() {
    return new Container(
      padding: const EdgeDims.symmetric(vertical: 20.0),
      decoration: new BoxDecoration(backgroundColor: colors.Grey[50]),
      child: new Block([
        new MenuItem(
          icon: 'action/thumb_up',
          onPressed: () => _handleAwesomeChanged(!_awesome),
          children: [
            new Flexible(child: new Text('Everything is awesome')),
            new Checkbox(value: _awesome, onChanged: _handleAwesomeChanged)
          ]
        ),
      ])
    );
  }

  Widget build() {
    return new Scaffold(
      toolbar: buildToolBar(),
      body: buildSettingsPane()
    );
  }
}
