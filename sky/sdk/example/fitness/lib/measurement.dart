// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/editing/input.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/icon_button.dart';
import 'package:sky/widgets/ink_well.dart';
import 'package:sky/widgets/material.dart';
import 'package:sky/widgets/navigator.dart';
import 'package:sky/widgets/scaffold.dart';
import 'package:sky/widgets/scrollable_viewport.dart';
import 'package:sky/widgets/snack_bar.dart';
import 'package:sky/widgets/tool_bar.dart';

typedef void MeasurementHandler(Measurement measurement);

class Measurement {
  Measurement({ this.when, this.weight });

  final DateTime when;
  final double weight;

  // TODO(jackson): Internationalize
  String get displayWeight => "${weight.toStringAsFixed(2)} lbs";
  String get displayDate => "${when.year.toString()}-${when.month.toString().padLeft(2,'0')}-${when.day.toString().padLeft(2,'0')}";
}

class MeasurementFragment extends StatefulComponent {

  MeasurementFragment({ this.navigator, this.onCreated });

  Navigator navigator;
  MeasurementHandler onCreated;

  void syncFields(MeasurementFragment source) {
    navigator = source.navigator;
    onCreated = source.onCreated;
  }

  String _weight = "";
  String _errorMessage = null;

  void _handleSave() {
    double parsedWeight;
    try {
      parsedWeight = double.parse(_weight);
    } on FormatException {
      setState(() {
        _errorMessage = "Save failed";
      });
      return;
    }
    onCreated(new Measurement(when: new DateTime.now(), weight: parsedWeight));
    navigator.pop();
  }

  Widget buildToolBar() {
    return new ToolBar(
      left: new IconButton(
        icon: "navigation/close",
        onPressed: navigator.pop),
      center: new Text('New Measurement'),
      right: [new InkWell(
        child: new Listener(
          onGestureTap: (_) => _handleSave(),
          child: new Text('SAVE')
        )
      )]
    );
  }

  void _handleWeightChanged(String weight) {
    setState(() {
      _weight = weight;
    });
  }

  Widget buildMeasurementPane() {
    Measurement measurement = new Measurement(when: new DateTime.now());
    return new Material(
      type: MaterialType.canvas,
      child: new ScrollableViewport(
        child: new Container(
          padding: const EdgeDims.all(20.0),
          child: new Block([
            new Text(measurement.displayDate),
            new Input(
              focused: false,
              placeholder: 'Enter weight',
              onChanged: _handleWeightChanged
            ),
          ])
        )
      )
    );
  }

  Widget buildSnackBar() {
    if (_errorMessage == null)
      return null;
    return new SnackBar(content: new Text(_errorMessage));
  }

  Widget build() {
    return new Scaffold(
      toolbar: buildToolBar(),
      body: buildMeasurementPane(),
      snackBar: buildSnackBar()
    );
  }
}
