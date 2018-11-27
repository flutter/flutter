// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:share/share.dart';
import 'package:flutter/material.dart';

const int _animationInterval = 100;

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

class _PlaygroundWidgetState extends State<PlaygroundDemo>
    with SingleTickerProviderStateMixin {
  final double _headerHeight = 60.0;
  final double _codePadding = 15.0;
  final Color _codeTextColor = Colors.grey[800];

  bool _isCodeOpen = false;

  AnimationController _backdropAnimationController;

  @override
  void initState() {
    super.initState();
    _backdropAnimationController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: _animationInterval),
        value: 1.0);
  }

  @override
  void dispose() {
    super.dispose();
    _backdropAnimationController.dispose();
  }

  void _toggleCode() {
    setState(() => _isCodeOpen = !_isCodeOpen);
    _backdropAnimationController.fling(velocity: _isCodeOpen ? -1.0 : 1.0);
  }

  Animation<RelativeRect> _getLayerAnimation(BoxConstraints constraints) {
    final double maxHeight = constraints.biggest.height;
    final double backPanelHeight = maxHeight - _headerHeight;
    final double frontPanelHeight = -_headerHeight;
    const double offsetTop = 130.0;

    return RelativeRectTween(
            begin: const RelativeRect.fromLTRB(0.0, offsetTop, 0.0, 0.0),
            end: RelativeRect.fromLTRB(
                0.0, backPanelHeight, 0.0, frontPanelHeight))
        .animate(CurvedAnimation(
            parent: _backdropAnimationController, curve: Curves.linear));
  }

  Widget _widgetPreviewConfigurationLayer() {
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

  Widget _codePreviewLayer(BoxConstraints constraints) {
    return PositionedTransition(
      rect: _getLayerAnimation(constraints),
      child: Container(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              height: _headerHeight,
              child: FlatButton(
                  color: Colors.white,
                  padding: EdgeInsets.fromLTRB(_codePadding, 2.0, 0.0, 0.0),
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    child: Stack(
                      children: <Widget>[
                        Align(
                            alignment: const Alignment(-1.0, 0.0),
                            child: Text('GET SOURCE CODE',
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  color: _codeTextColor,
                                  fontSize: 14.0,
                                ))),
                        Align(
                            alignment: const Alignment(1.0, 0.0),
                            child: RotatedBox(
                              quarterTurns: _isCodeOpen ? 1 : -1,
                              child: IconButton(
                                icon: const Icon(Icons.chevron_right),
                                color: _codeTextColor,
                                onPressed: () {
                                  _toggleCode();
                                },
                              ),
                            )),
                      ],
                    ),
                  ),
                  splashColor: Colors.white,
                  shape: BeveledRectangleBorder(
                    side: BorderSide(
                      color: Colors.grey[200],
                      width: 1.0,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(13.0),
                      topRight: Radius.circular(13.0),
                    ),
                  ),
                  onPressed: () {
                    _toggleCode();
                  }),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return SingleChildScrollView(
                    child: Container(
                      height: constraints.maxHeight,
                      padding: EdgeInsets.all(_codePadding).copyWith(top: 12.0),
                      color: Colors.white,
                      child: Text(widget.codePreview(),
                          style: TextStyle(
                            color: _codeTextColor,
                            fontSize: 14.0,
                            height: 1.6,
                            fontFamily: 'Courier',
                          )),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modalContainer() {
    return GestureDetector(
      onTap: () {
        _toggleCode();
      },
      child: Container(
        color: Colors.blue[700].withOpacity(0.6),
      ),
    );
  }

  Widget _shareButton() {
    return Positioned(
        bottom: 15.0,
        right: 20.0,
        child: RaisedButton(
            splashColor: Colors.white,
            child: const Text('SHARE',
                style: TextStyle(
                  fontSize: 16.0,
                )),
            onPressed: () {
              Share.share(widget.codePreview());
            }));
  }

  List<Widget> _layersStack(BoxConstraints constraints) {
    final List<Widget> stack = <Widget>[
      _widgetPreviewConfigurationLayer(),
    ];

    // If code layer is open, add modal
    if (_isCodeOpen) {
      stack.add(_modalContainer());
    }

    stack.add(_codePreviewLayer(constraints));

    // If code layer is open, add share button
    if (_isCodeOpen) {
      stack.add(_shareButton());
    }
    return stack;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      return Container(
        child: Stack(
          children: _layersStack(constraints),
        ),
      );
    });
  }

  void updateState(VoidCallback stateCallback) => setState(stateCallback);
}
