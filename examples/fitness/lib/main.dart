// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library fitness;

import 'package:playfair/playfair.dart' as playfair;
import 'package:sky/editing/input.dart';
import 'package:sky/painting/text_style.dart';
import 'package:sky/theme/colors.dart' as colors;
import 'package:sky/widgets.dart';
import 'user_data.dart';
import 'date_utils.dart';
import 'dart:async';
import 'dart:math' as math;

part 'feed.dart';
part 'fitness_item.dart';
part 'fitness_types.dart';
part 'meal.dart';
part 'measurement.dart';
part 'settings.dart';

abstract class UserData {
  BackupMode get backupMode;
  double get goalWeight;
  List<FitnessItem> get items;
}

class UserDataImpl extends UserData {
  UserDataImpl();

  List<FitnessItem> _items = [];

  BackupMode _backupMode;
  BackupMode get backupMode => _backupMode;
  void set backupMode(BackupMode value) {
    _backupMode = value;
  }

  double _goalWeight;
  double get goalWeight => _goalWeight;
  void set goalWeight(double value) {
    _goalWeight = value;
  }

  List<FitnessItem> get items => _items;

  void sort() {
    _items.sort((a, b) => a.when.compareTo(b.when));
  }

  void add(FitnessItem item) {
    _items.add(item);
    sort();
  }

  void remove(FitnessItem item) {
    _items.remove(item);
  }

  Future save() => saveFitnessData(this);

  UserDataImpl.fromJson(Map json) {
    json['items'].forEach((item) {
      _items.add(new Measurement.fromJson(item));
    });
    try {
      _backupMode = BackupMode.values.firstWhere((BackupMode mode) {
        return mode.toString() == json['backupMode'];
      });
    } catch(e) {
      print("Failed to load backup mode: ${e}");
    }
    _goalWeight = json['goalWeight'];
  }

  Map toJson() {
    Map json = new Map();
    json['items'] = _items.map((item) => item.toJson()).toList();
    json['backupMode'] = _backupMode.toString();
    json['goalWeight'] = _goalWeight;
    return json;
  }
}

class FitnessApp extends App {
  NavigationState _navigationState;
  UserDataImpl _userData;

  void didMount() {
    super.didMount();
    loadFitnessData().then((UserData data) {
      setState(() => _userData = data);
    }).catchError((e) => print("Failed to load data: $e"));
  }

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
        builder: (navigator, route) => new SettingsFragment(
          navigator: navigator,
          userData: _userData as UserData,
          updater: settingsUpdater
        )
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
    setState(() {
      _userData.add(item);
      _userData.save();
    });
  }

  void _handleItemDeleted(FitnessItem item) {
    setState(() {
      _userData.remove(item);
      _userData.save();
    });
  }

  void settingsUpdater({ BackupMode backup, double goalWeight }) {
    setState(() {
      if (backup != null)
        _userData.backupMode = backup;
      if (goalWeight != null)
        _userData.goalWeight = goalWeight;
      _userData.save();
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
