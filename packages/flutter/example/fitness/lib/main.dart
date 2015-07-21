// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/theme/colors.dart' as colors;
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/navigator.dart';
import 'package:sky/widgets/theme.dart';
import 'package:sky/widgets/widget.dart';
import 'package:sky/widgets/task_description.dart';

import 'measurement.dart';
import 'home.dart';
import 'settings.dart';
import 'fitness_types.dart';

class FitnessApp extends App {

  NavigationState _navigationState;

  void initState() {
    _navigationState = new NavigationState([
      new Route(
        name: '/',
        builder: (navigator, route) => new HomeFragment(
          navigator: navigator,
          userData: _userData,
          onMeasurementCreated: _handleMeasurementCreated,
          onMeasurementDeleted: _handleMeasurementDeleted
        )
      ),
      new Route(
        name: '/measurements/new',
        builder: (navigator, route) => new MeasurementFragment(
          navigator: navigator,
          onCreated: _handleMeasurementCreated
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

  void _handleMeasurementCreated(Measurement measurement) {
    setState(() {
      _userData.add(measurement);
      _userData.sort((a, b) => a.when.compareTo(b.when));
    });
  }

  void _handleMeasurementDeleted(Measurement measurement) {
    setState(() {
      _userData.remove(measurement);
    });
  }

  BackupMode backupSetting = BackupMode.disabled;

  void settingsUpdater({ BackupMode backup }) {
    setState(() {
      if (backup != null)
        backupSetting = backup;
    });
  }

  final List<Measurement> _userData = [
    new Measurement(weight: 180.0, when: new DateTime.now().add(const Duration(days: -1))),
    new Measurement(weight: 160.0, when: new DateTime.now()),
  ];

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
