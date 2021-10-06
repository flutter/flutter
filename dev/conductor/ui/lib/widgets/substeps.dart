// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Group and display all substeps within a step into a widget.
/// 
/// When all substeps are checked, [continueNextStep] can be executed to proceed to the next step.
class ConductorSubsteps extends StatefulWidget {
  const ConductorSubsteps({
    Key? key,
    required this.continueNextStep,
  }) : super(key: key);

  final VoidCallback continueNextStep;

  @override
  ConductorSubstepsState createState() => ConductorSubstepsState();

  static const List<String> _substepTitles = <String>[
    'Substep 1',
    'Substep 2',
    'Substep 3',
  ];
}

class ConductorSubstepsState extends State<ConductorSubsteps> {
  List<bool> substepChecked =
      List<bool>.filled(ConductorSubsteps._substepTitles.length, false);
  bool _continuePressed = false;

  void tapped() {
    setState(() => _continuePressed = true);
  }

  void substepPressed(int index) {
    setState(() {
      substepChecked[index] = !substepChecked[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        CheckboxListTile(
          value: substepChecked[0],
          onChanged: (bool? newValue) {
            substepPressed(0);
          },
          title: Text(ConductorSubsteps._substepTitles[0]),
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: Colors.grey,
          selected: substepChecked[0],
        ),
        CheckboxListTile(
          value: substepChecked[1],
          onChanged: (bool? newValue) {
            substepPressed(1);
          },
          title: Text(ConductorSubsteps._substepTitles[1]),
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: Colors.grey,
          selected: substepChecked[1],
        ),
        CheckboxListTile(
          value: substepChecked[2],
          onChanged: (bool? newValue) {
            substepPressed(2);
          },
          title: Text(ConductorSubsteps._substepTitles[2]),
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: Colors.grey,
          selected: substepChecked[2],
        ),
        if (!substepChecked.contains(false) && !_continuePressed)
          ElevatedButton(
            onPressed: () {
              tapped();
              widget.continueNextStep();
            },
            child: const Text('Continue'),
          ),
      ],
    );
  }
}
