// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

enum _Location {
  Barbados,
  Bahamas,
  Bermuda
}

typedef Widget DemoItemBodyBuilder<T, U>(DemoItem<T, U> item);
typedef U Converter<T, U>(T value);

class DualHeaderWithHint extends StatelessWidget {
  DualHeaderWithHint({
    this.name,
    this.value,
    this.hint,
    this.showHint
  });

  final String name;
  final String value;
  final String hint;
  final bool showHint;

  Widget _crossFade(Widget first, Widget second, bool isExpanded) {
    return new AnimatedCrossFade(
      firstChild: first,
      secondChild: second,
      firstCurve: new Interval(0.0, 0.6, curve: Curves.fastOutSlowIn),
      secondCurve: new Interval(0.4, 1.0, curve: Curves.fastOutSlowIn),
      sizeCurve: Curves.fastOutSlowIn,
      crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;

    return new Row(
      children: <Widget>[
        new Flexible(
          flex: 2,
          child: new Container(
            margin: const EdgeInsets.only(left: 24.0),
            child: new Text(name, style: textTheme.body1.copyWith(fontSize: 15.0))
          )
        ),
        new Flexible(
          flex: 3,
          child: new Container(
            margin: const EdgeInsets.only(left: 24.0),
            child: _crossFade(
              new Text(value, style: textTheme.caption.copyWith(fontSize: 15.0)),
              new Text(hint, style: textTheme.caption.copyWith(fontSize: 15.0)),
              showHint
            )
          )
        )
      ]
    );
  }
}

class CollapsibleBody extends StatelessWidget {
  CollapsibleBody({
    this.margin: EdgeInsets.zero,
    this.child,
    this.onSave,
    this.onCancel,
  });

  final EdgeInsets margin;
  final Widget child;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;

    return new Column(
      children: <Widget>[
        new Container(
          margin: const EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            bottom: 24.0
          ) - margin,
          child: new Center(
            child: new DefaultTextStyle(
              style: textTheme.caption.copyWith(fontSize: 15.0),
              child: child
            )
          )
        ),
        new Divider(height: 1.0),
        new Container(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: new Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              new Container(
                margin: const EdgeInsets.only(right: 8.0),
                child: new FlatButton(
                  onPressed: onCancel,
                  child: new Text('CANCEL', style: new TextStyle(
                    color: Colors.black54,
                    fontSize: 15.0,
                    fontWeight: FontWeight.w500
                  ))
                )
              ),
              new Container(
                margin: const EdgeInsets.only(right: 8.0),
                child: new FlatButton(
                  onPressed: onSave,
                  textTheme: ButtonTextTheme.accent,
                  child: new Text('SAVE'),
                )
              )
            ]
          )
        )
      ]
    );
  }
}

class DemoItem<T, U> {
  DemoItem({
    this.name,
    T value,
    this.hint,
    this.builder,
    this.valueToString,
    this.valueToField,
    this.fieldToValue,
  }) {
    _value = value;
    _field = new FormField<U>(initialValue: _valueToField(value));
  }

  final String name;
  final String hint;
  final DemoItemBodyBuilder<T, U> builder;
  final Converter<T, String> valueToString;
  final Converter<T, U> valueToField;
  final Converter<U, T> fieldToValue;

  bool isExpanded = false;

  T get value => _value;
  T _value;

  FormField<U> get field => _field;
  FormField<U> _field;

  U _valueToField(T value) {
    if (valueToField != null)
      return valueToField(value);
    assert(T == U);
    return value as U; // ignore: avoid_as
  }

  T _fieldToValue(U value) {
    if (fieldToValue != null)
      return fieldToValue(value);
    assert(T == U);
    return value as T; // ignore: avoid_as
  }

  void save() {
    _value = _fieldToValue(field.value);
    _field.value = _valueToField(value);
  }

  void cancel() {
    _field.value = _valueToField(value);
  }

  ExpansionPanelHeaderBuilder get headerBuilder {
    return (BuildContext context, bool isExpanded) {
      return new DualHeaderWithHint(
        name: name,
        value: valueToString(value),
        hint: hint,
        showHint: isExpanded,
      );
    };
  }
}

class ExpansionPanelsDemo extends StatefulWidget {
  static const String routeName = '/expansion_panels';

  @override
  _ExpansionPanelsDemoState createState() => new _ExpansionPanelsDemoState();
}

class _ExpansionPanelsDemoState extends State<ExpansionPanelsDemo> {
  List<DemoItem<dynamic, dynamic>> _demoItems;

  VoidCallback _saver(DemoItem<dynamic, dynamic> item) {
    return () {
      setState(() {
        item.save();
        item.isExpanded = false;
      });
    };
  }

  VoidCallback _canceler(DemoItem<dynamic, dynamic> item) {
    return () {
      setState(() {
        item.cancel();
        item.isExpanded = false;
      });
    };
  }

  @override
  void initState() {
    super.initState();

    _demoItems = <DemoItem<dynamic, dynamic>>[
      new DemoItem<String, InputValue>(
        name: 'Trip name',
        value: 'Caribbean cruise',
        hint: 'Change trip name',
        valueToString: (String value) => value,
        valueToField: (String value) => new InputValue(text: value),
        fieldToValue: (InputValue value) => value.text,
        builder: (DemoItem<String, InputValue> item) { // ignore: argument_type_not_assignable, https://github.com/flutter/flutter/issues/5771
          return new CollapsibleBody(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            child: new Input(
              hintText: item.hint,
              labelText: item.name,
              formField: item.field,
            ),
            onSave: _saver(item),
            onCancel: _canceler(item),
          );
        }
      ),
      new DemoItem<_Location, _Location>(
        name: 'Location',
        value: _Location.Bahamas,
        hint: 'Select location',
        valueToString: (_Location location) => location.toString().split(".")[1],
        builder: (DemoItem<_Location, _Location> item) { // ignore: argument_type_not_assignable, https://github.com/flutter/flutter/issues/5771
          void changeLocation(_Location value) {
            setState(() {
              item.field.value = value;
            });
          }
          return new CollapsibleBody(
            child: new Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                new Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    new Radio<_Location>(
                      value: _Location.Bahamas,
                      groupValue: item.field.value,
                      onChanged: changeLocation
                    ),
                    new Text('Bahamas')
                  ]
                ),
                new Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    new Radio<_Location>(
                      value: _Location.Barbados,
                      groupValue: item.field.value,
                      onChanged: changeLocation
                    ),
                    new Text('Barbados')
                  ]
                ),
                new Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    new Radio<_Location>(
                      value: _Location.Bermuda,
                      groupValue: item.field.value,
                      onChanged: changeLocation
                    ),
                    new Text('Bermuda')
                  ]
                )
              ]
            ),
            onSave: _saver(item),
            onCancel: _canceler(item),
          );
        }
      ),
      new DemoItem<double, double>(
        name: 'Sun amount',
        value: 80.0,
        hint: 'Select amount of sun',
        valueToString: (double amount) => '${amount.round()}',
        builder: (DemoItem<double, double> item) { // ignore: argument_type_not_assignable, https://github.com/flutter/flutter/issues/5771
          return new CollapsibleBody(
            child: new Slider(
              value: item.field.value,
              min: 0.0,
              max: 100.0,
              divisions: 5,
              activeColor: Colors.orange[100 + (item.field.value * 5.0).round()],
              label: '${item.field.value.round()}',
              onChanged: (double value) {
                setState(() {
                  item.field.value = value;
                });
              }
            ),
            onSave: _saver(item),
            onCancel: _canceler(item),
          );
        }
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text('Expansion panels')),
      body: new ScrollableViewport(
        child: new Container(
          margin: const EdgeInsets.all(24.0),
          child: new ExpansionPanelList(
            expansionCallback: (int index, bool isExpanded) {
              setState(() {
                _demoItems[index].isExpanded = !isExpanded;
              });
            },
            children: _demoItems.map((DemoItem<dynamic, dynamic> item) {
              return new ExpansionPanel(
                isExpanded: item.isExpanded,
                headerBuilder: item.headerBuilder,
                body: item.builder(item)
              );
            }).toList()
          )
        )
      )
    );
  }
}
