// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Flutter code sample for [SegmentedButton].

import 'package:flutter/material.dart';

void main() {
  runApp(const SegmentedButtonApp());
}

class SegmentedButtonApp extends StatelessWidget {
  const SegmentedButtonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const <Widget>[
              Spacer(),
              Text('Single choice'),
              SingleChoice(),
              SizedBox(height: 20),
              Text('Multiple choice'),
              MultipleChoice(),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

enum Calendar { day, week, month, year }

class SingleChoice extends StatefulWidget {
  const SingleChoice({super.key});

  @override
  State<SingleChoice> createState() => _SingleChoiceState();
}

class _SingleChoiceState extends State<SingleChoice> {

  Calendar _selected = Calendar.day;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<Calendar>(
      segments: const <ButtonSegment<Calendar>>[
        ButtonSegment<Calendar>(value: Calendar.day, label: Text('Day'), icon: Icon(Icons.calendar_view_day)),
        ButtonSegment<Calendar>(value: Calendar.week, label: Text('Week'), icon: Icon(Icons.calendar_view_week)),
        ButtonSegment<Calendar>(value: Calendar.month, label: Text('Month'), icon: Icon(Icons.calendar_view_month)),
        ButtonSegment<Calendar>(value: Calendar.year, label: Text('Year'), icon: Icon(Icons.calendar_today)),
      ],
      selected: <Calendar>{_selected},
      onSelectionChanged: (Set<Calendar> selected) {
        setState(() {
          _selected = selected.first;
        });
      },
    );
  }
}

enum Sizes { extraSmall, small, medium, large, extraLarge }

class MultipleChoice extends StatefulWidget {
  const MultipleChoice({super.key});

  @override
  State<MultipleChoice> createState() => _MultipleChoiceState();
}

class _MultipleChoiceState extends State<MultipleChoice> {
  Set<Sizes> _selected = <Sizes>{Sizes.large, Sizes.extraLarge};

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<Sizes>(
      segments: const <ButtonSegment<Sizes>>[
        ButtonSegment<Sizes>(value: Sizes.extraSmall, label: Text('XS')),
        ButtonSegment<Sizes>(value: Sizes.small, label: Text('S')),
        ButtonSegment<Sizes>(value: Sizes.medium, label: Text('M')),
        ButtonSegment<Sizes>(value: Sizes.large, label: Text('L'),),
        ButtonSegment<Sizes>(value: Sizes.extraLarge, label: Text('XL')),
      ],
      selected: _selected,
      onSelectionChanged: (Set<Sizes> selected) {
        setState(() {
          _selected = selected;
        });
      },
      multiSelectionEnabled: true,
    );
  }
}
