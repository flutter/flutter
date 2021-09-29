// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart';
import 'package:conductor_core/proto.dart' as pb;
import 'package:flutter/material.dart';

class MainProgression extends StatefulWidget {
  const MainProgression({
    Key? key,
    required this.releaseState,
    required this.stateFilePath,
  }) : super(key: key);

  final pb.ConductorState? releaseState;
  final String stateFilePath;

  @override
  MainProgressionState createState() => MainProgressionState();
}

/// Shows the progression and each step of the release.
///
/// 1. ...
/// 2. ...
/// 3. ...
class MainProgressionState extends State<MainProgression> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Scrollbar(
        isAlwaysShown: true,
        child: ListView(
          children: <Widget>[
            SelectableText(
              widget.releaseState != null
                  ? presentState(widget.releaseState!)
                  : 'No persistent state file found at ${widget.stateFilePath}',
            ),
          ],
        ),
      ),
    );
  }
}
