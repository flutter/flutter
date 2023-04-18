// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../gallery/demo.dart';

@visibleForTesting
enum Location {
  Barbados,
  Bahamas,
  Bermuda
}

typedef DemoItemBodyBuilder<T> = Widget Function(DemoItem<T> item);
typedef ValueToString<T> = String? Function(T value);

class DualHeaderWithHint extends StatelessWidget {
  const DualHeaderWithHint({
    super.key,
    this.name,
    this.value,
    this.hint,
    this.showHint,
  });

  final String? name;
  final String? value;
  final String? hint;
  final bool? showHint;

  Widget _crossFade(final Widget first, final Widget second, final bool isExpanded) {
    return AnimatedCrossFade(
      firstChild: first,
      secondChild: second,
      firstCurve: const Interval(0.0, 0.6, curve: Curves.fastOutSlowIn),
      secondCurve: const Interval(0.4, 1.0, curve: Curves.fastOutSlowIn),
      sizeCurve: Curves.fastOutSlowIn,
      crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;

    return Row(
      children: <Widget>[
        Expanded(
          flex: 2,
          child: Container(
            margin: const EdgeInsets.only(left: 24.0),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                name!,
                style: textTheme.bodyMedium!.copyWith(fontSize: 15.0),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(
            margin: const EdgeInsets.only(left: 24.0),
            child: _crossFade(
              Text(value!, style: textTheme.bodySmall!.copyWith(fontSize: 15.0)),
              Text(hint!, style: textTheme.bodySmall!.copyWith(fontSize: 15.0)),
              showHint!,
            ),
          ),
        ),
      ],
    );
  }
}

class CollapsibleBody extends StatelessWidget {
  const CollapsibleBody({
    super.key,
    this.margin = EdgeInsets.zero,
    this.child,
    this.onSave,
    this.onCancel,
  });

  final EdgeInsets margin;
  final Widget? child;
  final VoidCallback? onSave;
  final VoidCallback? onCancel;

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;

    return Column(
      children: <Widget>[
        Container(
          margin: const EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            bottom: 24.0,
          ) - margin,
          child: Center(
            child: DefaultTextStyle(
              style: textTheme.bodySmall!.copyWith(fontSize: 15.0),
              child: child!,
            ),
          ),
        ),
        const Divider(height: 1.0),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Container(
                margin: const EdgeInsets.only(right: 8.0),
                child: TextButton(
                  onPressed: onCancel,
                  child: const Text('CANCEL', style: TextStyle(
                    color: Colors.black54,
                    fontSize: 15.0,
                    fontWeight: FontWeight.w500,
                  )),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 8.0),
                child: TextButton(
                  onPressed: onSave,
                  child: const Text('SAVE'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DemoItem<T> {
  DemoItem({
    this.name,
    this.value,
    this.hint,
    this.builder,
    required this.valueToString,
  }) : textController = TextEditingController(text: valueToString(value));

  final String? name;
  final String? hint;
  final TextEditingController textController;
  final DemoItemBodyBuilder<T>? builder;
  final ValueToString<T?> valueToString;
  T? value;
  bool isExpanded = false;

  ExpansionPanelHeaderBuilder get headerBuilder {
    return (final BuildContext context, final bool isExpanded) {
      return DualHeaderWithHint(
        name: name,
        value: valueToString(value),
        hint: hint,
        showHint: isExpanded,
      );
    };
  }

  Widget build() => builder!(this);
}

class ExpansionPanelsDemo extends StatefulWidget {
  const ExpansionPanelsDemo({super.key});

  static const String routeName = '/material/expansion_panels';

  @override
  State<ExpansionPanelsDemo> createState() => _ExpansionPanelsDemoState();
}

class _ExpansionPanelsDemoState extends State<ExpansionPanelsDemo> {
  late List<DemoItem<dynamic>> _demoItems;

  @override
  void initState() {
    super.initState();

    _demoItems = <DemoItem<dynamic>>[
      DemoItem<String>(
        name: 'Trip',
        value: 'Caribbean cruise',
        hint: 'Change trip name',
        valueToString: (final String? value) => value,
        builder: (final DemoItem<String> item) {
          void close() {
            setState(() {
              item.isExpanded = false;
            });
          }

          return Form(
            child: Builder(
              builder: (final BuildContext context) {
                return CollapsibleBody(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  onSave: () { Form.of(context).save(); close(); },
                  onCancel: () { Form.of(context).reset(); close(); },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextFormField(
                      controller: item.textController,
                      decoration: InputDecoration(
                        hintText: item.hint,
                        labelText: item.name,
                      ),
                      onSaved: (final String? value) { item.value = value; },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      DemoItem<Location>(
        name: 'Location',
        value: Location.Bahamas,
        hint: 'Select location',
        valueToString: (final Location? location) => location.toString().split('.')[1],
        builder: (final DemoItem<Location> item) {
          void close() {
            setState(() {
              item.isExpanded = false;
            });
          }
          return Form(
            child: Builder(
              builder: (final BuildContext context) {
                return CollapsibleBody(
                  onSave: () { Form.of(context).save(); close(); },
                  onCancel: () { Form.of(context).reset(); close(); },
                  child: FormField<Location>(
                    initialValue: item.value,
                    onSaved: (final Location? result) { item.value = result; },
                    builder: (final FormFieldState<Location> field) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          RadioListTile<Location>(
                            value: Location.Bahamas,
                            title: const Text('Bahamas'),
                            groupValue: field.value,
                            onChanged: field.didChange,
                          ),
                          RadioListTile<Location>(
                            value: Location.Barbados,
                            title: const Text('Barbados'),
                            groupValue: field.value,
                            onChanged: field.didChange,
                          ),
                          RadioListTile<Location>(
                            value: Location.Bermuda,
                            title: const Text('Bermuda'),
                            groupValue: field.value,
                            onChanged: field.didChange,
                          ),
                        ],
                      );
                    },
                  ),
                );
              }
            ),
          );
        },
      ),
      DemoItem<double>(
        name: 'Sun',
        value: 80.0,
        hint: 'Select sun level',
        valueToString: (final double? amount) => '${amount!.round()}',
        builder: (final DemoItem<double> item) {
          void close() {
            setState(() {
              item.isExpanded = false;
            });
          }

          return Form(
            child: Builder(
              builder: (final BuildContext context) {
                return CollapsibleBody(
                  onSave: () { Form.of(context).save(); close(); },
                  onCancel: () { Form.of(context).reset(); close(); },
                  child: FormField<double>(
                    initialValue: item.value,
                    onSaved: (final double? value) { item.value = value; },
                    builder: (final FormFieldState<double> field) {
                      return Container(
                        // Allow room for the value indicator.
                        padding: const EdgeInsets.only(top: 44.0),
                        child: Slider(
                          max: 100.0,
                          divisions: 5,
                          activeColor: Colors.orange[100 + (field.value! * 5.0).round()],
                          label: '${field.value!.round()}',
                          value: field.value!,
                          onChanged: field.didChange,
                        ),
                      );
                    },
                  ),
                );
              }
            ),
          );
        },
      ),
    ];
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expansion panels'),
        actions: <Widget>[
          MaterialDemoDocumentationButton(ExpansionPanelsDemo.routeName),
        ],
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          top: false,
          bottom: false,
          child: Container(
            margin: const EdgeInsets.all(24.0),
            child: ExpansionPanelList(
              expansionCallback: (final int index, final bool isExpanded) {
                setState(() {
                  _demoItems[index].isExpanded = !isExpanded;
                });
              },
              children: _demoItems.map<ExpansionPanel>((final DemoItem<dynamic> item) {
                return ExpansionPanel(
                  isExpanded: item.isExpanded,
                  headerBuilder: item.headerBuilder,
                  body: item.build(),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
