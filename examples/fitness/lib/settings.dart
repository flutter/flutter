// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of fitness;

typedef void SettingsUpdater({
  BackupMode backup,
  double goalWeight
});

class SettingsFragment extends StatefulComponent {

  SettingsFragment({ this.navigator, this.userData, this.updater });

  Navigator navigator;
  UserData userData;
  SettingsUpdater updater;

  void syncFields(SettingsFragment source) {
    navigator = source.navigator;
    userData = source.userData;
    updater = source.updater;
  }

  void _handleBackupChanged(bool value) {
    assert(updater != null);
    updater(backup: value ? BackupMode.enabled : BackupMode.disabled);
  }

  void _goalWeightChanged(double value) {
    assert(updater != null);
    setState(() {
      optimism = value ? StockMode.optimistic : StockMode.pessimistic;
    });
    sendUpdates();
  }

  Widget buildToolBar() {
    return new ToolBar(
      left: new IconButton(
        icon: "navigation/arrow_back",
        onPressed: navigator.pop),
      center: new Text('Settings')
    );
  }

  String get goalWeightText {
    if (userData.goalWeight == null || userData.goalWeight == 0.0)
      return "None";
    else
      return "${userData.goalWeight}";
  }

  static final GlobalKey weightGoalKey = new GlobalKey();

  double _goalWeight;

  void _handleGoalWeightChanged(String goalWeight) {
    // TODO(jackson): Looking for null characters to detect enter key is a hack
    if (goalWeight.endsWith("\u{0}")) {
      navigator.pop(double.parse(goalWeight.replaceAll("\u{0}", "")));
    } else {
      setState(() {
        try {
          _goalWeight = double.parse(goalWeight);
        } on FormatException {
          _goalWeight = 0.0;
        }
      });
    }
  }

  EventDisposition _handleGoalWeightPressed() {
    showDialog(navigator, (navigator) {
      return new Dialog(
        title: new Text("Goal Weight"),
        content: new Input(
          key: weightGoalKey,
          placeholder: 'Goal weight in lbs',
          keyboardType: KeyboardType_NUMBER,
          onChanged: _handleGoalWeightChanged
        ),
        onDismiss: () {
          navigator.pop();
        },
        actions: [
          new FlatButton(
            child: new Text('CANCEL'),
            onPressed: () {
              navigator.pop();
            }
          ),
          new FlatButton(
            child: new Text('SAVE'),
            onPressed: () {
              navigator.pop(_goalWeight);
            }
          ),
        ]
      );
    }).then((double goalWeight) => updater(goalWeight: goalWeight));
    return EventDisposition.processed;
  }

  Widget buildSettingsPane() {
    return new Material(
      type: MaterialType.canvas,
      child: new ScrollableViewport(
        child: new Container(
          padding: const EdgeDims.symmetric(vertical: 20.0),
          child: new Block([
            new DrawerItem(
              onPressed: () { _handleBackupChanged(!(userData.backupMode == BackupMode.enabled)); },
              children: [
                new Flexible(child: new Text('Back up data to the cloud')),
                new Switch(value: userData.backupMode == BackupMode.enabled, onChanged: _handleBackupChanged)
              ]
            ),
            new DrawerItem(
              onPressed: () => _handleGoalWeightPressed(),
              children: [
                new Flex([
                  new Text('Goal Weight'),
                  new Text(goalWeightText, style: Theme.of(this).text.caption),
                ], direction: FlexDirection.vertical, alignItems: FlexAlignItems.start)
              ]
            ),
          ])
        )
      )
    );
  }

  Widget build() {
    return new Scaffold(
      toolbar: buildToolBar(),
      body: buildSettingsPane()
    );
  }
}
