// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Group and display all substeps within a step into a widget.
///
/// When all substeps are checked, [nextStep] can be executed to proceed to the next step.
class Step1Substeps extends StatefulWidget {
  const Step1Substeps({
    Key? key,
    required this.nextStep,
  }) : super(key: key);

  final VoidCallback nextStep;

  @override
  Step1SubstepsState createState() => Step1SubstepsState();

  static const List<String> _substepTitles = <String>[
    'Candidate Branch',
    'Release Channel',
    'Framework Mirror',
    'Engine Mirror',
    'Engine Cherrypicks',
    'Framework Cherrypicks',
    'Dart Revision',
    'Increment',
  ];
}

class Step1SubstepsState extends State<Step1Substeps> {
  List<bool> substepChecked = List<bool>.filled(Step1Substeps._substepTitles.length, false);
  bool _nextStepPressed = false;
  final Map<String, String?> _releaseData = <String, String?>{
    'Candidate Branch': '',
    'Release Channel': 'stable',
    'Increment': 'm',
  };

  // Hide the continue button once it is pressed.
  void tapped() {
    setState(() => _nextStepPressed = true);
  }

  // When substepChecked[0] is true, the first substep is checked. If it false, it is unchecked.
  void substepPressed(int index) {
    setState(() {
      substepChecked[index] = !substepChecked[index];
    });
  }

  void setReleaseData(String name, String data) {
    setState(() => _releaseData[name] = data);
    print(_releaseData);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        CheckboxListTileInput(
          index: 0,
          substepChecked: substepChecked,
          substepPressed: substepPressed,
          setReleaseData: setReleaseData,
          hintText: 'The candidate branch the release will be based on.',
        ),
        CheckboxListTileDropdown(
          index: 1,
          substepChecked: substepChecked,
          substepPressed: substepPressed,
          releaseData: _releaseData,
          setReleaseData: setReleaseData,
          options: const <String>['stable', 'beta', 'dev'],
        ),
        CheckboxListTileInput(
          index: 2,
          substepChecked: substepChecked,
          substepPressed: substepPressed,
          setReleaseData: setReleaseData,
          hintText: 'Framework repo mirror remote.',
        ),
        CheckboxListTileInput(
          index: 3,
          substepChecked: substepChecked,
          substepPressed: substepPressed,
          setReleaseData: setReleaseData,
          hintText: 'Engine repo mirror remote.',
        ),
        CheckboxListTileInput(
          index: 4,
          substepChecked: substepChecked,
          substepPressed: substepPressed,
          setReleaseData: setReleaseData,
          hintText: 'Engine cherrypick hashes to be applied.',
        ),
        CheckboxListTileInput(
          index: 5,
          substepChecked: substepChecked,
          substepPressed: substepPressed,
          setReleaseData: setReleaseData,
          hintText: 'Framework cherrypick hashes to be applied.',
        ),
        CheckboxListTileInput(
          index: 6,
          substepChecked: substepChecked,
          substepPressed: substepPressed,
          setReleaseData: setReleaseData,
          hintText: 'New Dart revision to cherrypick.',
        ),
        CheckboxListTileDropdown(
          index: 7,
          substepChecked: substepChecked,
          substepPressed: substepPressed,
          releaseData: _releaseData,
          setReleaseData: setReleaseData,
          options: const <String>['m', 'n', 'y', 'z'],
        ),
        const SizedBox(
          height: 20.0,
        ),
        if (!substepChecked.contains(false) && !_nextStepPressed)
          ElevatedButton(
            onPressed: () {
              tapped();
              widget.nextStep();
            },
            child: const Text('Continue'),
          ),
      ],
    );
  }
}

typedef SubstepPressed = void Function(int index);
typedef SetReleaseData = void Function(String name, String data);

class CheckboxListTileInput extends StatefulWidget {
  const CheckboxListTileInput({
    Key? key,
    required this.index,
    required this.substepChecked,
    required this.substepPressed,
    required this.setReleaseData,
    this.hintText,
  }) : super(key: key);

  final int index;
  final List<bool> substepChecked;
  final SubstepPressed substepPressed;
  final SetReleaseData setReleaseData;
  final String? hintText;

  @override
  CheckboxListTileInputState createState() => CheckboxListTileInputState();
}

class CheckboxListTileInputState extends State<CheckboxListTileInput> {
  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: widget.substepChecked[widget.index],
      onChanged: (bool? newValue) {
        widget.substepPressed(widget.index);
      },
      title: TextFormField(
        decoration: InputDecoration(labelText: Step1Substeps._substepTitles[widget.index], hintText: widget.hintText),
        onChanged: (String data) {
          widget.setReleaseData(Step1Substeps._substepTitles[widget.index], data);
        },
      ),
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: Colors.grey,
      selected: widget.substepChecked[widget.index],
    );
  }
}

class CheckboxListTileDropdown extends StatefulWidget {
  const CheckboxListTileDropdown({
    Key? key,
    required this.index,
    required this.substepChecked,
    required this.substepPressed,
    required this.releaseData,
    required this.setReleaseData,
    required this.options,
  }) : super(key: key);

  final int index;
  final List<bool> substepChecked;
  final SubstepPressed substepPressed;
  final Map<String, String?> releaseData;
  final SetReleaseData setReleaseData;
  final List<String> options;

  @override
  CheckboxListTileDropdownState createState() => CheckboxListTileDropdownState();
}

class CheckboxListTileDropdownState extends State<CheckboxListTileDropdown> {
  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: widget.substepChecked[widget.index],
      onChanged: (bool? newValue) {
        widget.substepPressed(widget.index);
      },
      title: DropdownButton<String>(
        value: widget.releaseData[Step1Substeps._substepTitles[widget.index]],
        icon: const Icon(Icons.arrow_downward),
        items: widget.options.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (String? newValue) {
          widget.setReleaseData(Step1Substeps._substepTitles[widget.index], newValue!);
        },
      ),
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: Colors.grey,
      selected: widget.substepChecked[widget.index],
    );
  }
}
