// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library fitness;

import 'package:playfair/playfair.dart' as playfair;
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

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

  List<FitnessItem> _items = <FitnessItem>[];

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
    _items.sort((FitnessItem a, FitnessItem b) => a.when.compareTo(b.when));
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
      print("Failed to load backup mode: $e");
    }
    _goalWeight = json['goalWeight'];
  }

  Map toJson() {
    Map json = new Map();
    json['items'] = _items.map((FitnessItem item) => item.toJson()).toList();
    json['backupMode'] = _backupMode.toString();
    json['goalWeight'] = _goalWeight;
    return json;
  }
}

class FitnessApp extends StatefulComponent {
  FitnessAppState createState() => new FitnessAppState();
}

class FitnessAppState extends State<FitnessApp> {
  UserDataImpl _userData;

  void initState() {
    super.initState();
    loadFitnessData().then((UserData data) {
      setState(() => _userData = data);
    }).catchError((e) {
      print("Failed to load data: $e");
      setState(() => _userData = new UserDataImpl());
    });
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

  Widget build(BuildContext context) {
    return new MaterialApp(
      theme: new ThemeData(
        brightness: ThemeBrightness.light,
        primarySwatch: Colors.indigo,
        accentColor: Colors.pinkAccent[200]
      ),
      title: 'Fitness',
      routes: <String, RouteBuilder>{
        '/': (RouteArguments args) {
          return new FeedFragment(
            userData: _userData,
            onItemCreated: _handleItemCreated,
            onItemDeleted: _handleItemDeleted
          );
        },
        '/meals/new': (RouteArguments args) {
          return new MealFragment(
            onCreated: _handleItemCreated
          );
        },
        '/measurements/new': (RouteArguments args) {
          return new MeasurementFragment(
            onCreated: _handleItemCreated
          );
        },
        '/settings': (RouteArguments args) {
          return new SettingsFragment(
            userData: _userData,
            updater: settingsUpdater
          );
        }
      }
    );
  }
}

void main() {
  runApp(new FitnessApp());
}
