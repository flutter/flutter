// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// A [ListTile] containing a dropdown menu that exposes itself as an
/// "Adjustable" to screen readers (e.g. TalkBack on Android and VoiceOver on
/// iOS).
///
/// This allows screen reader users to swipe up/down (on iOS) or use the volume
/// keys (on Android) to switch between the values in the dropdown menu.
/// Depending on what the values in the dropdown menu are this can be a more
/// intuitive way of switching values compared to exposing the content of the
/// drop down menu as a screen overlay from which the user can select.
///
/// Users that do not use a screen reader will just see a regular dropdown menu.
class AdjustableDropdownListTile extends StatelessWidget {
  const AdjustableDropdownListTile({
    this.label,
    this.value,
    this.items,
    this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final int indexOfValue = items.indexOf(value);
    assert(indexOfValue != -1);

    final bool canIncrease = indexOfValue < items.length - 1;
    final bool canDecrease = indexOfValue > 0;

    return Semantics(
      container: true,
      label: label,
      value: value,
      increasedValue: canIncrease ? _increasedValue : null,
      decreasedValue: canDecrease ? _decreasedValue : null,
      onIncrease: canIncrease ? _performIncrease : null,
      onDecrease: canDecrease ? _performDecrease : null,
      child: ExcludeSemantics(
        child: ListTile(
          title: Text(label),
          trailing: DropdownButton<String>(
            value: value,
            onChanged: onChanged,
            items: items.map<DropdownMenuItem<String>>((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
          ),
        ),
      )
    );
  }

  String get _increasedValue {
    final int indexOfValue = items.indexOf(value);
    assert(indexOfValue < items.length - 1);
    return items[indexOfValue + 1];
  }

  String get _decreasedValue {
    final int indexOfValue = items.indexOf(value);
    assert(indexOfValue > 0);
    return items[indexOfValue - 1];
  }

  void _performIncrease() => onChanged(_increasedValue);

  void _performDecrease() => onChanged(_decreasedValue);
}

class AdjustableDropdownExample extends StatefulWidget {
  @override
  AdjustableDropdownExampleState createState() => AdjustableDropdownExampleState();
}

class AdjustableDropdownExampleState extends State<AdjustableDropdownExample> {

  final List<String> items = <String>[
    '1 second',
    '5 seconds',
    '15 seconds',
    '30 seconds',
    '1 minute'
  ];
  String timeout;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Adjustable DropDown'),
        ),
        body: ListView(
          children: <Widget>[
            AdjustableDropdownListTile(
              label: 'Timeout',
              value: timeout ?? items[2],
              items: items,
              onChanged: (String value) {
                setState(() {
                  timeout = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(AdjustableDropdownExample());
}

/*
Sample Catalog

Title: AdjustableDropdownListTile

Summary: A dropdown menu that exposes itself as an "Adjustable" to screen
readers.

Description:
This app presents a dropdown menu to the user that exposes itself as an
"Adjustable" to screen readers (e.g. TalkBack on Android and VoiceOver on iOS).
This allows users of screen readers to cycle through the values of the dropdown
menu by swiping up or down on the screen with one finger (on iOS) or by using
the volume keys (on Android). Depending on the values in the dropdown this
behavior may be more intuitive to screen reader users compared to showing the
classical dropdown overlay on screen to choose a value.

When the screen reader is turned off, the dropdown menu behaves like any
dropdown menu would.

Classes: Semantics

Sample: AdjustableDropdownListTile

*/
