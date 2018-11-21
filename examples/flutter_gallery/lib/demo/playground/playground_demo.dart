// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

// ignore: must_be_immutable
abstract class PlaygroundDemo extends StatefulWidget {
  _PlaygroundWidgetState _state;

  @override
  _PlaygroundWidgetState createState() {
    _state = _PlaygroundWidgetState();
    return _state;
  }

  String tabName();
  Widget previewWidget(BuildContext context);
  Widget configWidget(BuildContext context);
  String code();

  void updateConfiguration(VoidCallback updates) => _state.updateState(updates);
}

class _PlaygroundWidgetState extends State<PlaygroundDemo> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          height: 200.0,
          child: widget.previewWidget(context),
        ),
        const Divider(
          height: 1.0,
        ),
        Expanded(
          child: SingleChildScrollView(
            child: widget.configWidget(context),
          ),
        ),
      ],
    );
  }

  void updateState(VoidCallback stateCallback) => setState(stateCallback);
}
