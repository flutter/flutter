// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library fitness;

import 'package:sky/theme/colors.dart' as colors;
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/navigator.dart';
import 'package:sky/widgets/theme.dart';
import 'package:sky/widgets/widget.dart';
import 'package:sky/widgets/task_description.dart';
import 'package:sky/painting/text_style.dart';
import 'package:sky/widgets/button_base.dart';
import 'package:sky/widgets/dialog.dart';
import 'package:sky/widgets/drawer.dart';
import 'package:sky/widgets/drawer_divider.dart';
import 'package:sky/widgets/drawer_header.dart';
import 'package:sky/widgets/drawer_item.dart';
import 'package:sky/widgets/flat_button.dart';
import 'package:sky/widgets/floating_action_button.dart';
import 'package:sky/widgets/icon_button.dart';
import 'package:sky/widgets/icon.dart';
import 'package:sky/widgets/ink_well.dart';
import 'package:sky/widgets/material.dart';
import 'package:sky/widgets/radio.dart';
import 'package:sky/widgets/scaffold.dart';
import 'package:sky/widgets/scrollable_list.dart';
import 'package:sky/widgets/scrollable_viewport.dart';
import 'package:sky/widgets/snack_bar.dart';
import 'package:sky/widgets/tool_bar.dart';
import 'package:sky/widgets/card.dart';
import 'package:sky/widgets/dismissable.dart';
import 'package:sky/editing/input.dart';
import 'package:sky/widgets/default_text_style.dart';
import 'package:sky/widgets/switch.dart';

part 'feed.dart';
part 'fitness_item.dart';
part 'fitness_types.dart';
part 'meal.dart';
part 'measurement.dart';
part 'settings.dart';

class FitnessApp extends App {

  NavigationState _navigationState;
  final List<FitnessItem> _userData = [
    new Measurement(weight: 180.0, when: new DateTime.now().add(const Duration(days: -1))),
    new Measurement(weight: 160.0, when: new DateTime.now()),
  ];

  void initState() {
    _navigationState = new NavigationState([
      new Route(
        name: '/',
        builder: (navigator, route) => new FeedFragment(
          navigator: navigator,
          userData: _userData,
          onItemCreated: _handleItemCreated,
          onItemDeleted: _handleItemDeleted
        )
      ),
      new Route(
        name: '/meals/new',
        builder: (navigator, route) => new MealFragment(
          navigator: navigator,
          onCreated: _handleItemCreated
        )
      ),
      new Route(
        name: '/measurements/new',
        builder: (navigator, route) => new MeasurementFragment(
          navigator: navigator,
          onCreated: _handleItemCreated
        )
      ),
      new Route(
        name: '/settings',
        builder: (navigator, route) => new SettingsFragment(navigator, backupSetting, settingsUpdater)
      ),
    ]);
    super.initState();
  }

  void onBack() {
    if (_navigationState.hasPrevious()) {
      setState(() {
        _navigationState.pop();
      });
    } else {
      super.onBack();
    }
  }

  void _handleItemCreated(FitnessItem item) {
    setState(() {
      _userData.add(item);
      _userData.sort((a, b) => a.when.compareTo(b.when));
    });
  }

  void _handleItemDeleted(FitnessItem item) {
    setState(() {
      _userData.remove(item);
    });
  }

  BackupMode backupSetting = BackupMode.disabled;

  void settingsUpdater({ BackupMode backup }) {
    setState(() {
      if (backup != null)
        backupSetting = backup;
    });
  }

  Widget build() {
    return new Theme(
      data: new ThemeData(
        brightness: ThemeBrightness.light,
        primarySwatch: colors.Indigo,
        accentColor: colors.PinkAccent[200]
      ),
      child: new TaskDescription(
        label: 'Fitness',
        child: new Navigator(_navigationState)
      )
    );
  }
}

void main() {
  runApp(new FitnessApp());
}
