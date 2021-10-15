// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Displays all substeps related to the 1st step.
///
/// Uses input fields and dropdowns to capture all the parameters of the conductor start command.
class Step1Substeps extends StatefulWidget {
  const Step1Substeps({
    Key? key,
    required this.nextStep,
  }) : super(key: key);

  final VoidCallback nextStep;

  @override
  Step1SubstepsState createState() => Step1SubstepsState();

  static const List<String> substepTitles = <String>[
    'Candidate Branch',
    'Release Channel',
    'Framework Mirror',
    'Engine Mirror',
    'Engine Cherrypicks',
    'Framework Cherrypicks',
    'Dart Revision',
    'Increment',
  ];

  /// Default values of release initialization parameters.
  static Map<String, String?> releaseData = <String, String?>{
    'Release Channel': '-',
    'Increment': '-',
  };
}

class Step1SubstepsState extends State<Step1Substeps> {
  /// Updates the corresponding [field] in [Step1Substeps.releaseData] with [data].
  void setReleaseData(String field, String data) {
    setState(() => Step1Substeps.releaseData[field] = data);
    print(Step1Substeps.releaseData);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        CheckboxListTileInput(
          index: 0,
          setReleaseData: setReleaseData,
          hintText: 'The candidate branch the release will be based on.',
        ),
        CheckboxListTileDropdown(
          index: 1,
          setReleaseData: setReleaseData,
          options: const <String>['-', 'stable', 'beta', 'dev'],
        ),
        CheckboxListTileInput(
          index: 2,
          setReleaseData: setReleaseData,
          hintText: 'Framework repo mirror remote.',
        ),
        CheckboxListTileInput(
          index: 3,
          setReleaseData: setReleaseData,
          hintText: 'Engine repo mirror remote.',
        ),
        CheckboxListTileInput(
          index: 4,
          setReleaseData: setReleaseData,
          hintText: 'Engine cherrypick hashes to be applied. Multiple hashes delimited by a coma, no spaces',
        ),
        CheckboxListTileInput(
          index: 5,
          setReleaseData: setReleaseData,
          hintText: 'Framework cherrypick hashes to be applied. Multiple hashes delimited by a coma, no spaces',
        ),
        CheckboxListTileInput(
          index: 6,
          setReleaseData: setReleaseData,
          hintText: 'New Dart revision to cherrypick.',
        ),
        CheckboxListTileDropdown(
          index: 7,
          setReleaseData: setReleaseData,
          options: const <String>['-', 'm', 'n', 'y', 'z'],
        ),
        const SizedBox(height: 20.0),
        Center(
          // TODO(Yugue): Add regex validation for each parameter input
          // when Continue button is pressed, https://github.com/flutter/flutter/issues/91925.
          child: ElevatedButton(
            key: const Key('step1continue'),
            onPressed: () {
              widget.nextStep();
            },
            child: const Text('Continue'),
          ),
        ),
      ],
    );
  }
}

typedef SetReleaseData = void Function(String name, String data);

/// Captures the input values and updates the corresponding field in [Step1Substeps.releaseData].
class CheckboxListTileInput extends StatefulWidget {
  const CheckboxListTileInput({
    Key? key,
    required this.index,
    required this.setReleaseData,
    this.hintText,
  }) : super(key: key);

  final int index;
  final SetReleaseData setReleaseData;
  final String? hintText;

  @override
  CheckboxListTileInputState createState() => CheckboxListTileInputState();
}

class CheckboxListTileInputState extends State<CheckboxListTileInput> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: Key(Step1Substeps.substepTitles[widget.index]),
      decoration: InputDecoration(labelText: Step1Substeps.substepTitles[widget.index], hintText: widget.hintText),
      onChanged: (String data) {
        widget.setReleaseData(Step1Substeps.substepTitles[widget.index], data);
      },
    );
  }
}

/// Captures the chosen option and updates the corresponding field in [Step1Substeps.releaseData].
class CheckboxListTileDropdown extends StatefulWidget {
  const CheckboxListTileDropdown({
    Key? key,
    required this.index,
    required this.setReleaseData,
    required this.options,
  }) : super(key: key);

  final int index;
  final SetReleaseData setReleaseData;
  final List<String> options;

  @override
  CheckboxListTileDropdownState createState() => CheckboxListTileDropdownState();
}

class CheckboxListTileDropdownState extends State<CheckboxListTileDropdown> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          Step1Substeps.substepTitles[widget.index],
          style: Theme.of(context).textTheme.subtitle1!.copyWith(color: Colors.grey[700]),
        ),
        const SizedBox(width: 20.0),
        DropdownButton<String>(
          key: Key(Step1Substeps.substepTitles[widget.index]),
          value: Step1Substeps.releaseData[Step1Substeps.substepTitles[widget.index]],
          icon: const Icon(Icons.arrow_downward),
          items: widget.options.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            widget.setReleaseData(Step1Substeps.substepTitles[widget.index], newValue!);
          },
        ),
      ],
    );
  }
}
