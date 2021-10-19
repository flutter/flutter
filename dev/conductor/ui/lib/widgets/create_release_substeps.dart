// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Displays all substeps related to the 1st step.
///
/// Uses input fields and dropdowns to capture all the parameters of the conductor start command.
class CreateReleaseSubsteps extends StatefulWidget {
  const CreateReleaseSubsteps({
    Key? key,
    required this.nextStep,
  }) : super(key: key);

  final VoidCallback nextStep;

  @override
  State<CreateReleaseSubsteps> createState() => CreateReleaseSubstepsState();

  static const List<String> substepTitles = <String>[
    'Candidate Branch',
    'Release Channel',
    'Framework Mirror',
    'Engine Mirror',
    'Engine Cherrypicks (if necessary)',
    'Framework Cherrypicks (if necessary)',
    'Dart Revision (if necessary)',
    'Increment',
  ];
}

class CreateReleaseSubstepsState extends State<CreateReleaseSubsteps> {
  // Initialize a public state so it could be accessed in the test file.
  @visibleForTesting
  late Map<String, String?> releaseData = <String, String?>{};

  /// Updates the corresponding [field] in [releaseData] with [data].
  void setReleaseData(String field, String data) {
    setState(() {
      releaseData = <String, String?>{
        ...releaseData,
        field: data,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InputAsSubstep(
          index: 0,
          setReleaseData: setReleaseData,
          hintText: 'The candidate branch the release will be based on.',
        ),
        CheckboxListTileDropdown(
          index: 1,
          releaseData: releaseData,
          setReleaseData: setReleaseData,
          options: const <String>['dev', 'beta', 'stable'],
        ),
        InputAsSubstep(
          index: 2,
          setReleaseData: setReleaseData,
          hintText: "Git remote of the Conductor user's Framework repository mirror.",
        ),
        InputAsSubstep(
          index: 3,
          setReleaseData: setReleaseData,
          hintText: "Git remote of the Conductor user's Engine repository mirror.",
        ),
        InputAsSubstep(
          index: 4,
          setReleaseData: setReleaseData,
          hintText: 'Engine cherrypick hashes to be applied. Multiple hashes delimited by a comma, no spaces.',
        ),
        InputAsSubstep(
          index: 5,
          setReleaseData: setReleaseData,
          hintText: 'Framework cherrypick hashes to be applied. Multiple hashes delimited by a comma, no spaces.',
        ),
        InputAsSubstep(
          index: 6,
          setReleaseData: setReleaseData,
          hintText: 'New Dart revision to cherrypick.',
        ),
        CheckboxListTileDropdown(
          index: 7,
          releaseData: releaseData,
          setReleaseData: setReleaseData,
          options: const <String>['y', 'z', 'm', 'n'],
        ),
        const SizedBox(height: 20.0),
        Center(
          // TODO(Yugue): Add regex validation for each parameter input
          // before Continue button is enabled, https://github.com/flutter/flutter/issues/91925.
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

/// Captures the input values and updates the corresponding field in [releaseData].
class InputAsSubstep extends StatelessWidget {
  const InputAsSubstep({
    Key? key,
    required this.index,
    required this.setReleaseData,
    this.hintText,
  }) : super(key: key);

  final int index;
  final SetReleaseData setReleaseData;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: Key(CreateReleaseSubsteps.substepTitles[index]),
      decoration: InputDecoration(
        labelText: CreateReleaseSubsteps.substepTitles[index],
        hintText: hintText,
      ),
      onChanged: (String data) {
        setReleaseData(CreateReleaseSubsteps.substepTitles[index], data);
      },
    );
  }
}

/// Captures the chosen option and updates the corresponding field in [releaseData].
class CheckboxListTileDropdown extends StatelessWidget {
  const CheckboxListTileDropdown({
    Key? key,
    required this.index,
    required this.releaseData,
    required this.setReleaseData,
    required this.options,
  }) : super(key: key);

  final int index;
  final Map<String, String?> releaseData;
  final SetReleaseData setReleaseData;
  final List<String> options;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          CreateReleaseSubsteps.substepTitles[index],
          style: Theme.of(context).textTheme.subtitle1!.copyWith(color: Colors.grey[700]),
        ),
        const SizedBox(width: 20.0),
        DropdownButton<String>(
          hint: const Text('-'), // Dropdown initially displays the hint when no option is selected.
          key: Key(CreateReleaseSubsteps.substepTitles[index]),
          value: releaseData[CreateReleaseSubsteps.substepTitles[index]],
          icon: const Icon(Icons.arrow_downward),
          items: options.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setReleaseData(CreateReleaseSubsteps.substepTitles[index], newValue!);
          },
        ),
      ],
    );
  }
}
