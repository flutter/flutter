// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// ignore: must_be_immutable
abstract class PlaygroundDemo extends StatefulWidget {
  // PlaygroundDemo({this.controller});

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

class _PlaygroundWidgetState extends State<PlaygroundDemo>
    with SingleTickerProviderStateMixin {
  static const double headerHeight = 60.0;

  bool _open = false;

  AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
        vsync: this, duration: Duration(milliseconds: 100), value: 1.0);
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  bool get isCodeVisible {
    final AnimationStatus status = controller.status;
    return status == AnimationStatus.completed ||
        status == AnimationStatus.forward;
  }

  Animation<RelativeRect> getPanelAnimation(BoxConstraints constraints) {
    final double maxHeight = constraints.biggest.height;
    final double backPanelHeight = maxHeight - headerHeight;
    const double frontPanelHeight = -headerHeight;
    const double offsetTop = 130.0;

    return RelativeRectTween(
            begin: const RelativeRect.fromLTRB(0.0, offsetTop, 0.0, 0.0),
            end: RelativeRect.fromLTRB(
                0.0, backPanelHeight, 0.0, frontPanelHeight))
        .animate(CurvedAnimation(parent: controller, curve: Curves.linear));
  }

  Widget widgetPreviewConfigurationLayer() {
    return Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            height: 160.0,
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
        ]);
  }

  Widget codePreviewLayer(BoxConstraints constraints) {
    return PositionedTransition(
      rect: getPanelAnimation(constraints),
      child: Container(
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              height: headerHeight,
              child: FlatButton(
                  child: Text('GET SOURCE CODE',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14.0,
                      )),
                  splashColor: Colors.white,
                  shape: BeveledRectangleBorder(
                    side: BorderSide(
                      color: Colors.grey[200],
                      width: 1.0,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16.0),
                      topRight: Radius.circular(16.0),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _open = _open ? false : true;             
                    });
                    controller.fling(velocity: isCodeVisible ? -1.0 : 1.0);
                  }),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Text(widget.codePreview(),
                    style: TextStyle(
                      color: Colors.grey[850],
                      fontSize: 14.0,
                      height: 1.6,
                      fontFamily: 'Monospace',
                    )),
              ),
            ),
          ],
        ),
      ),
      // ),
    );
  }

  Widget codeContainer() {
    return Container(
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
    );
  }

  List<Widget> layersStack(BoxConstraints constraints) {
    List<Widget> stack = <Widget>[];
    stack.add(widgetPreviewConfigurationLayer());

    if (_open) {
      stack.add(Opacity(
        opacity: 0.6,
        child: Container(
          color: Colors.blue[700],
        ),
      ));
    }

    stack.add(codePreviewLayer(constraints));
    return stack;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      return Container(
        child: Stack(
          children: layersStack(constraints),
          // <Widget>[
          //   // widgetPreviewConfigurationLayer(),
          //   // codePreviewLayer(constraints),
          // ],
        ),
      );
    });
  }

  void updateState(VoidCallback stateCallback) => setState(stateCallback);
}
