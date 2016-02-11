// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of fitness;

class _SettingsDialog extends StatefulComponent {
  _SettingsDialogState createState() => new _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  final GlobalKey weightGoalKey = new GlobalKey();

  InputValue _goalWeight = InputValue.empty;

  void _handleGoalWeightChanged(InputValue goalWeight) {
    setState(() {
      _goalWeight = goalWeight;
    });
  }

  void _handleGoalWeightSubmitted(InputValue goalWeight) {
    _goalWeight = goalWeight;
    _handleSavePressed();
  }

  void _handleSavePressed() {
    double goalWeight;
    try {
      goalWeight = double.parse(_goalWeight.text);
    } on FormatException {
      goalWeight = 0.0;
    }
    Navigator.pop(context, goalWeight);
  }

  Widget build(BuildContext context) {
    return new Dialog(
      title: new Text("Goal Weight"),
      content: new Input(
        key: weightGoalKey,
        value: _goalWeight,
        autofocus: true,
        hintText: 'Goal weight in lbs',
        keyboardType: KeyboardType.number,
        onChanged: _handleGoalWeightChanged,
        onSubmitted: _handleGoalWeightSubmitted
      ),
      actions: <Widget>[
        new FlatButton(
          child: new Text('CANCEL'),
          onPressed: () {
            Navigator.pop(context);
          }
        ),
        new FlatButton(
          child: new Text('SAVE'),
          onPressed: _handleSavePressed
        ),
      ]
    );
  }
}

typedef void SettingsUpdater({
  BackupMode backup,
  double goalWeight
});

class SettingsFragment extends StatefulComponent {
  SettingsFragment({ this.userData, this.updater });

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
      center: new Text('Settings')
    );
  }

  String get goalWeightText {
    if (config.userData.goalWeight == null || config.userData.goalWeight == 0.0)
      return "None";
    return "${config.userData.goalWeight}";
  }

  Future _handleGoalWeightPressed() async {
    double goalWeight = await showDialog(
      context: context,
      child: new _SettingsDialog()
    );
    config.updater(goalWeight: goalWeight);
  }

  Widget buildSettingsPane(BuildContext context) {
    return new Block(children: <Widget>[
        new DrawerItem(
          onPressed: () { _handleBackupChanged(!(config.userData.backupMode == BackupMode.enabled)); },
          child: new Row(
            children: <Widget>[
              new Flexible(child: new Text('Back up data to the cloud')),
              new Switch(value: config.userData.backupMode == BackupMode.enabled, onChanged: _handleBackupChanged),
            ]
          )
        ),
        new DrawerItem(
          onPressed: () => _handleGoalWeightPressed(),
          child: new Column(
            children: <Widget>[
              new Text('Goal Weight'),
              new Text(goalWeightText, style: Theme.of(context).text.caption),
            ],
            alignItems: FlexAlignItems.start
          )
        ),
      ],
      padding: const EdgeDims.symmetric(vertical: 20.0)
    );
  }

  Widget build(BuildContext context) {
    return new Scaffold(
      toolBar: buildToolBar(),
      body: buildSettingsPane(context)
    );
  }
}
