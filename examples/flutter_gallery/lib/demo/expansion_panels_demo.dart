// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

enum _Location {
  Barbados,
  Bahamas,
  Bermuda
}

typedef Widget DemoItemBodyBuilder(DemoItem<dynamic> item);
typedef String ValueToString<T>(T value);

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
    this.onCancel
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
                  child: new Text('SAVE')
                )
              )
            ]
          )
        )
      ]
    );
  }
}

class DemoItem<T> {
  DemoItem({
    this.name,
    this.value,
    this.hint,
    this.builder,
    this.valueToString
  });

  final String name;
  final String hint;
  final DemoItemBodyBuilder builder;
  final ValueToString<T> valueToString;
  T value;
  bool isExpanded = false;

  ExpansionPanelHeaderBuilder get headerBuilder {
    return (BuildContext context, bool isExpanded) {
      return new DualHeaderWithHint(
        name: name,
        value: valueToString(value),
        hint: hint,
        showHint: isExpanded
      );
    };
  }
}

class ExpasionPanelsDemo extends StatefulWidget {
  static const String routeName = '/expansion_panels';

  @override
  _ExpansionPanelsDemoState createState() => new _ExpansionPanelsDemoState();
}

class _ExpansionPanelsDemoState extends State<ExpasionPanelsDemo> {
  List<DemoItem<dynamic>> _demoItems;

  @override
  void initState() {
    super.initState();

    GlobalKey<FormState> form1Key = new GlobalKey<FormState>();
    GlobalKey<FormState> form2Key = new GlobalKey<FormState>();
    GlobalKey<FormState> form3Key = new GlobalKey<FormState>();

    _demoItems = <DemoItem<dynamic>>[
      new DemoItem<String>(
        name: 'Trip name',
        value: 'Caribbean cruise',
        hint: 'Change trip name',
        valueToString: (String value) => value,
        builder: (DemoItem<String> item) { // ignore: argument_type_not_assignable, https://github.com/flutter/flutter/issues/5771
          void close() {
            setState(() {
              item.isExpanded = false;
            });
          }

          return new Form(
            key: form1Key,
            child: new CollapsibleBody(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              onSave: () { form1Key.currentState.save(); close(); },
              onCancel: () { form1Key.currentState.reset(); close(); },
              child: new Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: new InputFormField(
                  hintText: item.hint,
                  labelText: item.name,
                  initialValue: new InputValue(text: item.value),
                  onSaved: (InputValue val) { item.value = val.text; },
                ),
              ),
            )
          );
        }
      ),
      new DemoItem<_Location>(
        name: 'Location',
        value: _Location.Bahamas,
        hint: 'Select location',
        valueToString: (_Location location) => location.toString().split(".")[1],
        builder: (DemoItem<_Location> item) { // ignore: argument_type_not_assignable, https://github.com/flutter/flutter/issues/5771
          void close() {
            setState(() {
              item.isExpanded = false;
            });
          }

          return new Form(
            key: form2Key,
            child: new CollapsibleBody(
              onSave: () { form2Key.currentState.save(); close(); },
              onCancel: () { form2Key.currentState.reset(); close(); },
              child: new FormField<_Location>(
                initialValue: item.value,
                onSaved: (_Location result) { item.value = result; },
                builder: (FormFieldState<_Location> field) {
                  return new Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      new Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          new Radio<_Location>(
                            value: _Location.Bahamas,
                            groupValue: field.value,
                            onChanged: field.onChanged,
                          ),
                          new Text('Bahamas')
                        ]
                      ),
                      new Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          new Radio<_Location>(
                            value: _Location.Barbados,
                            groupValue: field.value,
                            onChanged: field.onChanged,
                          ),
                          new Text('Barbados')
                        ]
                      ),
                      new Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          new Radio<_Location>(
                            value: _Location.Bermuda,
                            groupValue: field.value,
                            onChanged: field.onChanged,
                          ),
                          new Text('Bermuda')
                        ]
                      )
                    ]
                  );
                }
              ),
            ),
          );
        }
      ),
      new DemoItem<double>(
        name: 'Sun amount',
        value: 80.0,
        hint: 'Select amount of sun',
        valueToString: (double amount) => '${amount.round()}',
        builder: (DemoItem<double> item) { // ignore: argument_type_not_assignable, https://github.com/flutter/flutter/issues/5771
          void close() {
            setState(() {
              item.isExpanded = false;
            });
          }

          return new Form(
            key: form3Key,
            child: new CollapsibleBody(
              onSave: () { form3Key.currentState.save(); close(); },
              onCancel: () { form3Key.currentState.reset(); close(); },
              child: new FormField<double>(
                initialValue: item.value,
                onSaved: (double value) { item.value = value; },
                builder: (FormFieldState<double> field) {
                  return new Slider(
                    min: 0.0,
                    max: 100.0,
                    divisions: 5,
                    activeColor: Colors.orange[100 + (field.value * 5.0).round()],
                    label: '${field.value.round()}',
                    value: field.value,
                    onChanged: field.onChanged,
                  );
                },
              ),
            )
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
            children: _demoItems.map((DemoItem<dynamic> item) {
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
