// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart';
import 'package:conductor_core/proto.dart' as pb;
import 'package:flutter/material.dart';

/// Display the current conductor state
class ConductorStatus extends StatefulWidget {
  const ConductorStatus({
    Key? key,
    this.releaseState,
    required this.stateFilePath,
  }) : super(key: key);

  final pb.ConductorState? releaseState;
  final String stateFilePath;

  @override
  ConductorStatusState createState() => ConductorStatusState();
}

class ConductorStatusState extends State<ConductorStatus> {
  @override
  Widget build(BuildContext context) {
    return SelectableText(
      widget.releaseState != null
          ? presentState(widget.releaseState!)
          : 'No persistent state file found at ${widget.stateFilePath}',
    );
  }
}
