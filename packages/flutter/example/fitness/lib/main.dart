// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/theme/colors.dart' as colors;
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/navigator.dart';
import 'package:sky/widgets/theme.dart';
import 'package:sky/widgets/widget.dart';
import 'package:sky/widgets/task_description.dart';

import 'meal.dart';
import 'measurement.dart';
import 'feed.dart';
import 'settings.dart';
import 'fitness_item.dart';
import 'fitness_types.dart';

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
