// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of fitness;

class Measurement extends FitnessItem {
  Measurement({ DateTime when, this.weight }) : super(when: when);
  Measurement.fromJson(Map json) : super.fromJson(json), weight = json['weight'];

  final double weight;

  // TODO(jackson): Internationalize
  String get displayWeight => "${weight.toStringAsFixed(1)} lbs";

  @override
  Map toJson() {
    Map json = super.toJson();
    json['weight'] = weight;
    return json;
  }

  FitnessItemRow toRow({ FitnessItemHandler onDismissed }) {
    return new MeasurementRow(measurement: this, onDismissed: onDismissed);
  }
}

class MeasurementRow extends FitnessItemRow {
  MeasurementRow({ Measurement measurement, FitnessItemHandler onDismissed })
    : super(item: measurement, onDismissed: onDismissed);

  Widget buildContent() {
    Measurement measurement = item;
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
    return new Flex(
      children,
      alignItems: FlexAlignItems.baseline,
      textBaseline: DefaultTextStyle.of(this).textBaseline
    );
  }
}

class MeasurementFragment extends StatefulComponent {

  MeasurementFragment({ this.navigator, this.onCreated });

  Navigator navigator;
  FitnessItemHandler onCreated;

  void syncFields(MeasurementFragment source) {
    navigator = source.navigator;
    onCreated = source.onCreated;
  }

  String _weight = "";
  String _errorMessage = null;

  EventDisposition _handleSave() {
    double parsedWeight;
    try {
      parsedWeight = double.parse(_weight);
    } on FormatException catch(e) {
      print("Exception $e");
      setState(() {
        _errorMessage = "Save failed";
      });
      return EventDisposition.processed;
    }
    onCreated(new Measurement(when: new DateTime.now(), weight: parsedWeight));
    navigator.pop();
    return EventDisposition.processed;
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

  static final GlobalKey weightKey = new GlobalKey();

  Widget buildBody() {
    Measurement measurement = new Measurement(when: new DateTime.now());
    return new Material(
      type: MaterialType.canvas,
      child: new ScrollableViewport(
        child: new Container(
          padding: const EdgeDims.all(20.0),
          child: new Block([
            new Text(measurement.displayDate),
            new Input(
              key: weightKey,
              placeholder: 'Enter weight',
              keyboardType: KeyboardType_NUMBER,
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
    // TODO(jackson): This doesn't show up, unclear why.
    return new SnackBar(content: new Text(_errorMessage));
  }

  Widget build() {
    return new Scaffold(
      toolbar: buildToolBar(),
      body: buildBody(),
      snackBar: buildSnackBar()
    );
  }
}
