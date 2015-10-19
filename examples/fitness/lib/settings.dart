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

  final NavigatorState navigator;
  final UserData userData;
  final SettingsUpdater updater;

  SettingsFragmentState createState() => new SettingsFragmentState();
}

class SettingsFragmentState extends State<SettingsFragment> {
  void _handleBackupChanged(bool value) {
    assert(config.updater != null);
    config.updater(backup: value ? BackupMode.enabled : BackupMode.disabled);
  }

  Widget buildToolBar() {
    return new ToolBar(
      left: new IconButton(
        icon: "navigation/arrow_back",
        onPressed: config.navigator.pop
      ),
      center: new Text('Settings')
    );
  }

  String get goalWeightText {
    if (config.userData.goalWeight == null || config.userData.goalWeight == 0.0)
      return "None";
    return "${config.userData.goalWeight}";
  }

  static final GlobalKey weightGoalKey = new GlobalKey();

  double _goalWeight;

  void _handleGoalWeightChanged(String goalWeight) {
    // TODO(jackson): Looking for null characters to detect enter key is a hack
    if (goalWeight.endsWith("\u{0}")) {
      config.navigator.pop(double.parse(goalWeight.replaceAll("\u{0}", "")));
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

  void _handleGoalWeightPressed() {
    showDialog(config.navigator, (NavigatorState navigator) {
      return new Dialog(
        title: new Text("Goal Weight"),
        content: new Input(
          key: weightGoalKey,
          placeholder: 'Goal weight in lbs',
          keyboardType: KeyboardType.NUMBER,
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
    }).then((double goalWeight) => config.updater(goalWeight: goalWeight));
  }

  Widget buildSettingsPane(BuildContext context) {
    return new ScrollableViewport(
      child: new Container(
        padding: const EdgeDims.symmetric(vertical: 20.0),
        child: new BlockBody([
          new DrawerItem(
            onPressed: () { _handleBackupChanged(!(config.userData.backupMode == BackupMode.enabled)); },
            child: new Row([
              new Flexible(child: new Text('Back up data to the cloud')),
              new Switch(value: config.userData.backupMode == BackupMode.enabled, onChanged: _handleBackupChanged),
            ])
          ),
          new DrawerItem(
            onPressed: () => _handleGoalWeightPressed(),
            child: new Column([
                new Text('Goal Weight'),
                new Text(goalWeightText, style: Theme.of(context).text.caption),
              ],
              alignItems: FlexAlignItems.start
            )
          ),
        ])
      )
    );
  }

  Widget build(BuildContext context) {
    return new Scaffold(
      toolBar: buildToolBar(),
      body: buildSettingsPane(context)
    );
  }
}
