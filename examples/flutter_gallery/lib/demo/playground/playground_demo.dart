// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// ignore: must_be_immutable
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
  String codePreview();

  void updateConfiguration(VoidCallback updates) => _state.updateState(updates);
}

class _PlaygroundWidgetState extends State<PlaygroundDemo> {
  @override
  Widget build(BuildContext context) {
    return Column(
      key: GlobalKey(),
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
        Container(
          height: 60.0,
          child: FlatButton(
            child: Text('GET SOURCE CODE',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14.0,
                )),
            shape: BeveledRectangleBorder(
              side: BorderSide(
                color: Colors.grey[300],
                width: 1.0,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16.0),
                topRight: Radius.circular(16.0),
              ),
            ),
            onPressed: () {
              showModalBottomSheet<void>(
                  context: context,
                  builder: (BuildContext context) {
                    return SingleChildScrollView(
                        padding: const EdgeInsets.all(20.0),
                        child: RichText(
                          text: TextSpan(
                              text: widget.codePreview(),
                              style: TextStyle(
                                color: Colors.grey[850],
                                fontSize: 14.0,
                                height: 1.6,
                                fontFamily: 'Monospace',
                              )),
                        ));
                  });
            },
          ),
        ),
      ],
    );
  }

  void updateState(VoidCallback stateCallback) => setState(stateCallback);
}
