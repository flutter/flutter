// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/painting/text_style.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/drawer.dart';
import 'package:sky/widgets/drawer_header.dart';
import 'package:sky/widgets/floating_action_button.dart';
import 'package:sky/widgets/icon.dart';
import 'package:sky/widgets/icon_button.dart';
import 'package:sky/widgets/material.dart';
import 'package:sky/widgets/menu_divider.dart';
import 'package:sky/widgets/menu_item.dart';
import 'package:sky/widgets/navigator.dart';
import 'package:sky/widgets/snack_bar.dart';
import 'package:sky/widgets/scaffold.dart';
import 'package:sky/widgets/theme.dart';
import 'package:sky/widgets/tool_bar.dart';
import 'package:sky/widgets/widget.dart';

import 'fitness_types.dart';
import 'measurement.dart';

class HomeFragment extends StatefulComponent {

  HomeFragment(this.navigator, this.userData) {
    // if (debug)
    //   new Timer(new Duration(seconds: 1), dumpState);
    _drawerController = new DrawerController(_handleDrawerStatusChanged);
  }

  Navigator navigator;
  List<Measurement> userData;

  FitnessMode _fitnessMode = FitnessMode.measure;

  void syncFields(HomeFragment source) {
    navigator = source.navigator;
    userData = source.userData;
  }

  bool _isShowingSnackBar = false;
  bool _isRunning = false;

  DrawerController _drawerController;
  bool _drawerShowing = false;

  void _handleDrawerStatusChanged(bool showing) {
    if (!showing && navigator.currentRoute.name == "/drawer") {
      navigator.pop();
    }
    setState(() {
      _drawerShowing = showing;
    });
  }

  void _handleFitnessModeChange(FitnessMode value) {
    setState(() {
      _fitnessMode = value;
    });
    assert(navigator.currentRoute.name == '/drawer');
    navigator.pop();
  }

  Drawer buildDrawer() {
    return new Drawer(
      controller: _drawerController,
      level: 3,
      children: [
        new DrawerHeader(children: [new Text('Fitness')]),
        new MenuItem(
          icon: 'action/assessment',
          onPressed: () => _handleFitnessModeChange(FitnessMode.measure),
          selected: _fitnessMode == FitnessMode.measure,
          children: [new Text('Measure')]),
        new MenuItem(
          icon: 'maps/directions_run',
          onPressed: () => _handleFitnessModeChange(FitnessMode.run),
          selected: _fitnessMode == FitnessMode.run,
          children: [new Text('Run')]),
        new MenuDivider(),
        new MenuItem(
          icon: 'action/settings',
          onPressed: _handleShowSettings,
          children: [new Text('Settings')]),
        new MenuItem(
          icon: 'action/help',
          children: [new Text('Help & Feedback')])
     ]
    );
  }

  void _handleShowSettings() {
    assert(navigator.currentRoute.name == '/drawer');
    navigator.pop();
    assert(navigator.currentRoute.name == '/');
    navigator.pushNamed('/settings');
  }

  void _handleOpenDrawer() {
    _drawerController.open();
    navigator.pushState("/drawer", (_) {
      _drawerController.close();
    });
  }

  // TODO(jackson): We should be localizing
  String get fitnessModeTitle {
    switch(_fitnessMode) {
      case FitnessMode.measure: return "Measure";
      case FitnessMode.run: return "Run";
    }
  }

  Widget buildToolBar() {
    return new ToolBar(
      left: new IconButton(
        icon: "navigation/menu",
        onPressed: _handleOpenDrawer),
      center: new Text(fitnessModeTitle)
    );
  }

  Widget buildBody() {
    TextStyle style = Theme.of(this).text.title;
    switch (_fitnessMode) {
      case FitnessMode.measure:
        return new Material(
          type: MaterialType.canvas,
          child: new Flex(
            [new Text("No measurements yet.\nAdd a new one!", style: style)],
            justifyContent: FlexJustifyContent.center
          )
        );
      case FitnessMode.run:
        return new Material(
          type: MaterialType.canvas,
          child: new Flex([
            new Text(_isRunning ? "Go go go!" : "Start a new run!", style: style)
          ], justifyContent: FlexJustifyContent.center)
        );
    }
  }

  void _handleUndo() {
    setState(() {
      _isShowingSnackBar = false;
    });
  }

  Widget buildSnackBar() {
    if (!_isShowingSnackBar)
      return null;
    return new SnackBar(
      content: new Text("Measurement added!"),
      actions: [new SnackBarAction(label: "UNDO", onPressed: _handleUndo)]
    );
  }

  void _handleMeasurementAdded() {
    setState(() {
      _isShowingSnackBar = true;
    });
  }

  void _handleRunStarted() {
    setState(() {
      _isRunning = true;
    });
  }

  void _handleRunStopped() {
    setState(() {
      _isRunning = false;
    });
  }

  Widget buildFloatingActionButton() {
    switch (_fitnessMode) {
      case FitnessMode.measure:
        return new FloatingActionButton(
          child: new Icon(type: 'content/add', size: 24),
          onPressed: _handleMeasurementAdded
        );
      case FitnessMode.run:
        return new FloatingActionButton(
          child: new Icon(
            type: _isRunning ? 'av/stop' : 'maps/directions_run',
            size: 24
          ),
          onPressed: _isRunning ? _handleRunStopped : _handleRunStarted
        );
    }
  }

  Widget build() {
    return new Scaffold(
      toolbar: buildToolBar(),
      body: buildBody(),
      snackBar: buildSnackBar(),
      floatingActionButton: buildFloatingActionButton(),
      drawer: _drawerShowing ? buildDrawer() : null
    );
  }
}
