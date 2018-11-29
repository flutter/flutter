// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../constants.dart';
import '../welcome_step_state.dart';
import 'step_container.dart';

const String _kTitle = 'Welcome to Flutter!';
const String _kSubtitle = 'Flutter allows you to build beautiful native mobile apps from a single codebase.';

class FlutterWelcomeStep extends StatefulWidget {
  const FlutterWelcomeStep({Key key}) : super(key: key);

  @override
  _FlutterWelcomeStepState createState() => _FlutterWelcomeStepState();
}

class _FlutterWelcomeStepState extends WelcomeStepState<FlutterWelcomeStep> {
  @override
  Widget build(BuildContext context) {
    return StepContainer(
      title: _kTitle,
      subtitle: _kSubtitle,
      imageContentBuilder: () {
        return Image.asset('welcome/welcome_hello.png', package: kWelcomeGalleryAssetsPackage);
      },
    );
  }

  @override
  void animate({bool restart = false}) {}
}
