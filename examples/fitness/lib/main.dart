// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library fitness;

import 'package:sky/editing/input.dart';
import 'package:sky/painting/text_style.dart';
import 'package:sky/theme/colors.dart' as colors;
import 'package:sky/widgets.dart';
import 'user_data.dart';
import 'date_utils.dart';
import 'dart:async';

part 'feed.dart';
part 'fitness_item.dart';
part 'fitness_types.dart';
part 'meal.dart';
part 'measurement.dart';
part 'settings.dart';

class UserData {
  List<FitnessItem> _items = [];

  List<FitnessItem> get items => _items;
  void set items(List<FitnessItem> newItems) {
    _items = [];
    _items.addAll(newItems);
    sort();
  }

  void sort() {
    _items.sort((a, b) => -a.when.compareTo(b.when));
  }

  void addAndSave(FitnessItem item) {
    _items.add(item);
    sort();
    save();
  }

  void removeAndSave(FitnessItem item) {
    _items.remove(item);
    save();
  }

  Future save() => saveFitnessData(_items);
}

class FitnessApp extends App {
  NavigationState _navigationState;
  final UserData _userData = new UserData();

  void didMount() {
    super.didMount();
    loadFitnessData().then((List<Measurement> list) {
      setState(() => _userData.items = list);
    }).catchError((e) => print("Failed to load data: $e"));
  }

  void save() {
    _userData.save().catchError((e) => print("Failed to load data: $e"));
  }

  void initState() {
    _navigationState = new NavigationState([
      new Route(
        name: '/',
        builder: (navigator, route) => new FeedFragment(
          navigator: navigator,
          userData: _userData.items,
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
      setState(() => _navigationState.pop());
    } else {
      super.onBack();
    }
  }

  void _handleItemCreated(FitnessItem item) {
    setState(() => _userData.addAndSave(item));
  }

  void _handleItemDeleted(FitnessItem item) {
    setState(() => _userData.removeAndSave(item));
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
