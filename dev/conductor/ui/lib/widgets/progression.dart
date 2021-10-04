// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/proto.dart' as pb;
import 'package:flutter/material.dart';

import 'conductor_status.dart';
import 'substeps.dart';

const int numSteps = 5;

/// Displays the progression and each step of the release from the conductor.
///
// TODO(Yugue): Add documentation to explain
// each step of the release, https://github.com/flutter/flutter/issues/90981.
class MainProgression extends StatefulWidget {
  const MainProgression({
    Key? key,
    this.releaseState,
    required this.stateFilePath,
  }) : super(key: key);

  final pb.ConductorState? releaseState;
  final String stateFilePath;

  @override
  MainProgressionState createState() => MainProgressionState();
}

class MainProgressionState extends State<MainProgression> {
  int _currentStep = 0;
  int _navigateStep = 0; // allow users to navigate already completed steps

  void tapped(int step) {
    setState(() => _navigateStep = step);
  }

  void continued() {
    if (_currentStep < numSteps - 1) {
      setState(() => _currentStep += 1);
      setState(() => _navigateStep = _currentStep);
    }
  }

  void cancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
      setState(() => _navigateStep = _currentStep);
    }
  }

  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Scrollbar(
        isAlwaysShown: true,
        controller: _scrollController,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          physics: const ClampingScrollPhysics(),
          children: <Widget>[
            ConductorStatus(
              releaseState: widget.releaseState,
              stateFilePath: widget.stateFilePath,
            ),
            Stepper(
              controlsBuilder: (BuildContext context, ControlsDetails details) {
                return Row(
                  children: const <Widget>[],
                );
              },
              type: StepperType.vertical,
              physics: const ScrollPhysics(),
              currentStep: _navigateStep,
              onStepTapped: (int step) => tapped(step),
              onStepContinue: continued,
              onStepCancel: cancel,
              steps: <Step>[
                Step(
                  title: const Text('Initialize a New Flutter Release'),
                  content: Column(
                    children: <Widget>[
                      ConductorSubsteps(continued: continued),
                    ],
                  ),
                  isActive: true,
                  state: _currentStep >= 1
                      ? StepState.complete
                      : StepState.disabled,
                ),
                Step(
                  title: const Text('Flutter Engine Cherrypicks'),
                  content: Column(
                    children: <Widget>[
                      ConductorSubsteps(continued: continued),
                    ],
                  ),
                  isActive: true,
                  state: _currentStep >= 2
                      ? StepState.complete
                      : StepState.disabled,
                ),
                Step(
                  title: const Text('Flutter Framework Cherrypicks'),
                  content: Column(
                    children: <Widget>[
                      ConductorSubsteps(continued: continued),
                    ],
                  ),
                  isActive: true,
                  state: _currentStep >= 3
                      ? StepState.complete
                      : StepState.disabled,
                ),
                Step(
                  title: const Text('Publish the Release'),
                  content: Column(
                    children: <Widget>[
                      ConductorSubsteps(continued: continued),
                    ],
                  ),
                  isActive: true,
                  state: _currentStep >= 4
                      ? StepState.complete
                      : StepState.disabled,
                ),
                Step(
                  title: const Text('Release is Successfully published'),
                  content: Column(
                    children: const <Widget>[],
                  ),
                  isActive: true,
                  state: _currentStep >= 4
                      ? StepState.complete
                      : StepState.disabled,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
