// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/painting/text_style.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/dialog.dart';
import 'package:sky/widgets/drawer.dart';
import 'package:sky/widgets/drawer_divider.dart';
import 'package:sky/widgets/drawer_header.dart';
import 'package:sky/widgets/drawer_item.dart';
import 'package:sky/widgets/flat_button.dart';
import 'package:sky/widgets/floating_action_button.dart';
import 'package:sky/widgets/icon_button.dart';
import 'package:sky/widgets/icon.dart';
import 'package:sky/widgets/material.dart';
import 'package:sky/widgets/navigator.dart';
import 'package:sky/widgets/scaffold.dart';
import 'package:sky/widgets/scrollable_list.dart';
import 'package:sky/widgets/snack_bar.dart';
import 'package:sky/widgets/theme.dart';
import 'package:sky/widgets/tool_bar.dart';
import 'package:sky/widgets/widget.dart';

import 'fitness_types.dart';
import 'fitness_item.dart';
import 'measurement.dart';
import 'meal.dart';

class FitnessItemList extends Component {
  FitnessItemList({ Key key, this.items, this.onDismissed }) : super(key: key);

  final List<FitnessItem> items;
  final FitnessItemHandler onDismissed;

  Widget build() {
    return new Material(
      type: MaterialType.canvas,
      child: new ScrollableList<FitnessItem>(
        items: items,
        itemHeight: kFitnessItemHeight,
        itemBuilder: (item) => new MeasurementRow(
          measurement: item as Measurement,
          onDismissed: onDismissed
        )
      )
    );
  }
}

class FeedFragment extends StatefulComponent {

<<<<<<< HEAD:sky/sdk/example/fitness/lib/feed.dart
  FeedFragment({ this.navigator, this.userData, this.onItemCreated, this.onItemDeleted });
=======
  MeasurementRow({ Measurement measurement, this.onDismissed }) : this.measurement = measurement, super(key: new Key.stringify(measurement.when));

  final Measurement measurement;
  final MeasurementHandler onDismissed;

  static const double kHeight = 79.0;

  Widget build() {

    List<Widget> children = [
      new Flexible(
        child: new Text(
          measurement.displayWeight,
          style: const TextStyle(textAlign: TextAlign.right)
        )
      ),
      new Flexible(
        child: new Text(
          measurement.displayDate,
          style: Theme.of(this).text.caption.copyWith(textAlign: TextAlign.right)
        )
      )
    ];

    return new Dismissable(
      key: new Key.stringify(measurement.when),
      onDismissed: () => onDismissed(measurement),
      child: new Card(
        child: new Container(
          height: kHeight,
          padding: const EdgeDims.all(8.0),
          child: new Flex(
            children,
            alignItems: FlexAlignItems.baseline,
            textBaseline: DefaultTextStyle.of(this).textBaseline
          )
        )
      )
    );
  }
}

class HomeFragment extends StatefulComponent {

  HomeFragment({ this.navigator, this.userData, this.onMeasurementCreated, this.onMeasurementDeleted });
>>>>>>> dk/master:sky/sdk/example/fitness/lib/home.dart

  Navigator navigator;
  List<FitnessItem> userData;
  FitnessItemHandler onItemCreated;
  FitnessItemHandler onItemDeleted;

  FitnessMode _fitnessMode = FitnessMode.feed;

  void initState() {
    // if (debug)
    //   new Timer(new Duration(seconds: 1), dumpState);
    super.initState();
  }

  void syncFields(FeedFragment source) {
    navigator = source.navigator;
    userData = source.userData;
    onItemCreated = source.onItemCreated;
    onItemDeleted = source.onItemDeleted;
  }

  bool _isShowingSnackBar = false;

  void _handleFitnessModeChange(FitnessMode value) {
    setState(() {
      _fitnessMode = value;
      _drawerShowing = false;
    });
  }

  Drawer buildDrawer() {
    if (_drawerStatus == DrawerStatus.inactive)
      return null;
    return new Drawer(
      showing: _drawerShowing,
      level: 3,
      onStatusChanged: _handleDrawerStatusChange,
      navigator: navigator,
      children: [
        new DrawerHeader(children: [new Text('Fitness')]),
        new DrawerItem(
          icon: 'action/list',
          onPressed: () => _handleFitnessModeChange(FitnessMode.feed),
          selected: _fitnessMode == FitnessMode.feed,
          children: [new Text('Feed')]),
        new DrawerItem(
          icon: 'action/assessment',
          onPressed: () => _handleFitnessModeChange(FitnessMode.chart),
          selected: _fitnessMode == FitnessMode.chart,
          children: [new Text('Chart')]),
        new DrawerDivider(),
        new DrawerItem(
          icon: 'action/settings',
          onPressed: _handleShowSettings,
          children: [new Text('Settings')]),
        new DrawerItem(
          icon: 'action/help',
          children: [new Text('Help & Feedback')])
     ]
    );
  }

  bool _drawerShowing = false;
  DrawerStatus _drawerStatus = DrawerStatus.inactive;

  void _handleOpenDrawer() {
    setState(() {
      _drawerShowing = true;
      _drawerStatus = DrawerStatus.active;
    });
  }

  void _handleDrawerStatusChange(DrawerStatus status) {
    setState(() {
      _drawerStatus = status;
    });
  }

  void _handleShowSettings() {
    navigator.pop();
    navigator.pushNamed('/settings');
  }

  // TODO(jackson): We should be localizing
  String get fitnessModeTitle {
    switch(_fitnessMode) {
      case FitnessMode.feed: return "Feed";
      case FitnessMode.chart: return "Chart";
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

  FitnessItem _undoItem;

  void _handleItemDismissed(FitnessItem item) {
    onItemDeleted(item);
    setState(() {
      _undoItem = item;
      _isShowingSnackBar = true;
    });
  }

  Widget buildBody() {
    TextStyle style = Theme.of(this).text.title;
    switch (_fitnessMode) {
      case FitnessMode.feed:
        if (userData.length > 0)
          return new FitnessItemList(
            items: userData,
            onDismissed: _handleItemDismissed
          );
        return new Material(
          type: MaterialType.canvas,
          child: new Flex(
            [new Text("No data yet.\nAdd some!", style: style)],
            justifyContent: FlexJustifyContent.center
          )
        );
      case FitnessMode.chart:
        return new Material(
          type: MaterialType.canvas,
          child: new Flex([
            new Text("Charts are coming soon!", style: style)
          ], justifyContent: FlexJustifyContent.center)
        );
    }
  }

  void _handleUndo() {
    onItemCreated(_undoItem);
    setState(() {
      _undoItem = null;
      _isShowingSnackBar = false;
    });
  }

  Widget buildSnackBar() {
    if (!_isShowingSnackBar)
      return null;
    return new SnackBar(
      content: new Text("Item deleted."),
      actions: [new SnackBarAction(label: "UNDO", onPressed: _handleUndo)]
    );
  }

  bool _isShowingDialog = false;

  Widget buildDialog() {
    return new Dialog(
      title: new Text("New item"),
      content: new Text("What are you trying to do?"),
      onDismiss: navigator.pop,
      actions: [
        new FlatButton(
          child: new Text('CANCEL'),
          onPressed: navigator.pop
        ),
        new FlatButton(
          child: new Text('EAT'),
          onPressed: () {
            navigator.pop();
            navigator.pushNamed("/meals/new");
          }
        ),
        new FlatButton(
          child: new Text('MEASURE'),
          onPressed: () {
            navigator.pop();
            navigator.pushNamed("/measurements/new");
          }
        ),
      ]
    );
  }

  void _handleActionButtonPressed() {
    setState(() {
      _isShowingDialog = true;
    });
  }

  Widget buildFloatingActionButton() {
    switch (_fitnessMode) {
      case FitnessMode.feed:
        return new FloatingActionButton(
          child: new Icon(type: 'content/add', size: 24),
          onPressed: _handleActionButtonPressed
        );
      case FitnessMode.chart:
        return null;
    }
  }

  Widget build() {
    List<Widget> layers = [
      new Scaffold(
        toolbar: buildToolBar(),
        body: buildBody(),
        snackBar: buildSnackBar(),
        floatingActionButton: buildFloatingActionButton(),
        drawer: buildDrawer()
      )
    ];
    if (_isShowingDialog)
      layers.add(buildDialog());
    return new Stack(layers);
  }
}
