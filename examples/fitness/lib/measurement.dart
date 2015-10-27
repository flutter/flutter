// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of fitness;

class Measurement extends FitnessItem {
  Measurement({ DateTime when, this.weight }) : super(when: when);
  Measurement.fromJson(Map json) : weight = json['weight'], super.fromJson(json);

  final double weight;

  // TODO(jackson): Internationalize
  String get displayWeight => "${weight.toStringAsFixed(1)} lbs";

  @override
  Map toJson() {
    Map json = super.toJson();
    json['weight'] = weight;
    json['type'] = runtimeType.toString();
    return json;
  }

  FitnessItemRow toRow({ FitnessItemHandler onDismissed }) {
    return new MeasurementRow(measurement: this, onDismissed: onDismissed);
  }
}

class MeasurementRow extends FitnessItemRow {
  MeasurementRow({ Measurement measurement, FitnessItemHandler onDismissed })
    : super(item: measurement, onDismissed: onDismissed);

  Widget buildContent(BuildContext context) {
    Measurement measurement = item;
    List<Widget> children = <Widget>[
      new Flexible(
        child: new Text(
          measurement.displayWeight,
          style: Theme.of(context).text.subhead
        )
      ),
      new Flexible(
        child: new Text(
          measurement.displayDate,
          style: Theme.of(context).text.caption.copyWith(textAlign: TextAlign.right)
        )
      )
    ];
    return new Row(
      children,
      alignItems: FlexAlignItems.baseline,
      textBaseline: DefaultTextStyle.of(context).textBaseline
    );
  }
}

class MeasurementDateDialog extends StatefulComponent {
  MeasurementDateDialog({ this.previousDate });

  final DateTime previousDate;

  MeasurementDateDialogState createState() => new MeasurementDateDialogState();
}

class MeasurementDateDialogState extends State<MeasurementDateDialog> {
  @override
  void initState() {
    _selectedDate = config.previousDate;
  }

  DateTime _selectedDate;

  void _handleDateChanged(DateTime value) {
    setState(() {
      _selectedDate = value;
    });
  }

  Widget build(BuildContext context) {
    return new Dialog(
      content: new DatePicker(
        selectedDate: _selectedDate,
        firstDate: new DateTime(2015, 8),
        lastDate: new DateTime(2101),
        onChanged: _handleDateChanged
      ),
      contentPadding: EdgeDims.zero,
      actions: <Widget>[
        new FlatButton(
          child: new Text('CANCEL'),
          onPressed: () {
            Navigator.of(context).pop();
          }
        ),
        new FlatButton(
          child: new Text('OK'),
          onPressed: () {
            Navigator.of(context).pop(_selectedDate);
          }
        ),
      ]
    );
  }
}

class MeasurementFragment extends StatefulComponent {
  MeasurementFragment({ this.onCreated });

  final FitnessItemHandler onCreated;

  MeasurementFragmentState createState() => new MeasurementFragmentState();
}

class MeasurementFragmentState extends State<MeasurementFragment> {
  final GlobalKey<PlaceholderState> _snackBarPlaceholderKey = new GlobalKey<PlaceholderState>();

  String _weight = "";
  DateTime _when = new DateTime.now();

  void _handleSave() {
    double parsedWeight;
    try {
      parsedWeight = double.parse(_weight);
    } on FormatException catch(e) {
      print("Exception $e");
      showSnackBar(
        context: context,
        placeholderKey: _snackBarPlaceholderKey,
        content: new Text('Save failed')
      );
    }
    config.onCreated(new Measurement(when: _when, weight: parsedWeight));
    Navigator.of(context).pop();
  }

  Widget buildToolBar() {
    return new ToolBar(
      left: new IconButton(
        icon: "navigation/close",
        onPressed: Navigator.of(context).pop),
      center: new Text('New Measurement'),
      right: <Widget>[
        // TODO(abarth): Should this be a FlatButton?
        new InkWell(
          onTap: _handleSave,
          child: new Text('SAVE')
        )
      ]
    );
  }

  void _handleWeightChanged(String weight) {
    setState(() {
      _weight = weight;
    });
  }

  static final GlobalKey weightKey = new GlobalKey();

  Future _handleDatePressed() async {
    DateTime value = await showDialog(
      context: context,
      child: new MeasurementDateDialog(previousDate: _when)
    );
    if (value != null) {
      setState(() {
        _when = value;
      });
    }
  }

  Widget buildBody(BuildContext context) {
    Measurement measurement = new Measurement(when: _when);
    // TODO(jackson): Revisit the layout of this pane to be more maintainable
    return new Container(
      padding: const EdgeDims.all(20.0),
      child: new Column(<Widget>[
        new GestureDetector(
          onTap: _handleDatePressed,
          child: new Container(
            height: 50.0,
            child: new Column(<Widget>[
              new Text('Measurement Date'),
              new Text(measurement.displayDate, style: Theme.of(context).text.caption),
            ], alignItems: FlexAlignItems.start)
          )
        ),
        new Input(
          key: weightKey,
          placeholder: 'Enter weight',
          keyboardType: KeyboardType.NUMBER,
          onChanged: _handleWeightChanged
        ),
      ], alignItems: FlexAlignItems.stretch)
    );
  }

  Widget build(BuildContext context) {
    return new Scaffold(
      toolBar: buildToolBar(),
      body: buildBody(context),
      snackBar: new Placeholder(key: _snackBarPlaceholderKey)
    );
  }
}
