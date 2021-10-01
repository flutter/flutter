// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

const int numSubsteps = 3;

/// Group and display all substeps within a step into a widget.
/// When all substeps are checked, [continued] can be executed to proceed to the next step.
class ConductorSubsteps extends StatefulWidget {
  const ConductorSubsteps({
    Key? key,
    required this.continued,
  }) : super(key: key);

  final VoidCallback continued;

  @override
  ConductorSubstepsState createState() => ConductorSubstepsState();
}

class ConductorSubstepsState extends State<ConductorSubsteps> {
  List<bool> substepChecked = List<bool>.filled(numSubsteps, false);
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
          title: const Text('Substep 1'),
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: Colors.grey,
          selected: substepChecked[0],
        ),
        CheckboxListTile(
          value: substepChecked[1],
          onChanged: (bool? newValue) {
            substepPressed(1);
          },
          title: const Text('Substep 2'),
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: Colors.grey,
          selected: substepChecked[1],
        ),
        CheckboxListTile(
          value: substepChecked[2],
          onChanged: (bool? newValue) {
            substepPressed(2);
          },
          title: const Text('Substep 3'),
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: Colors.grey,
          selected: substepChecked[2],
        ),
        if (!substepChecked.contains(false) && !_continuePressed)
          ElevatedButton(
            onPressed: () {
              tapped();
              widget.continued();
            },
            child: const Text('Continue'),
          ),
      ],
    );
  }
}
