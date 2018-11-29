// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import '../constants.dart';
import '../welcome_step_state.dart';
import 'step_container.dart';

const String _kTitle = 'Interactive widget playground';
const String _kSubtitle = 'Explore the rich native UI widgets in real-time. See and share the code to get up and running, fast.';

class PlaygroundWelcomeStep extends StatefulWidget {
  const PlaygroundWelcomeStep({Key key}) : super(key: key);

  @override
  _PlaygroundWelcomeStepState createState() => _PlaygroundWelcomeStepState();
}

class _PlaygroundWelcomeStepState extends WelcomeStepState<PlaygroundWelcomeStep> {

  @override
  Widget build(BuildContext context) {
    return StepContainer(
      title: _kTitle,
      subtitle: _kSubtitle,
      imageContentBuilder: () {
        return Image.asset('welcome/welcome_playground.png', package: kWelcomeGalleryAssetsPackage);
      },
    );
  }

  @override
  void animate({bool restart = false}) {}
}