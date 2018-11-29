// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';

import 'package:share/share.dart';
import 'package:flutter/material.dart';

class PlaygroundDemo extends StatefulWidget {
  const PlaygroundDemo({
    Key key,
    @required this.previewWidget,
    @required this.configWidget,
    @required this.codePreview,
  })  : assert(previewWidget != null),
        assert(configWidget != null),
        assert(codePreview != null),
        super(key: key);

  @override
  _PlaygroundDemoState createState() => _PlaygroundDemoState();

  final Widget previewWidget;
  final Widget configWidget;
  final String codePreview;
}

class _PlaygroundDemoState extends State<PlaygroundDemo>
    with SingleTickerProviderStateMixin {
  static const double _headerHeight = 60.0;
  static const double _codePadding = 15.0;

  final Color _codeTextColor = Colors.grey[800];

  bool _isCodeOpen = false;
  AnimationController _backdropAnimationController;

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);

    _backdropAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 100),
      value: 1.0,
    );
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _backdropAnimationController.dispose();
    super.dispose();
  }

  void _toggleCode() {
    setState(() => _isCodeOpen = !_isCodeOpen);
    _backdropAnimationController.fling(velocity: _isCodeOpen ? -1.0 : 1.0);
  }

  Animation<RelativeRect> _getLayerAnimation(BuildContext context, BoxConstraints constraints) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double maxHeight = constraints.biggest.height;
    final double openHeight = maxHeight - (_headerHeight + mediaQuery.padding.bottom);
    const double closedHeight = -_headerHeight;
    final double offsetTop = (maxHeight * 0.15).ceilToDouble();

    return RelativeRectTween(
      begin: RelativeRect.fromLTRB(0.0, offsetTop, 0.0, 0.0),
      end: RelativeRect.fromLTRB(0.0, openHeight, 0.0, closedHeight),
    ).animate(CurvedAnimation(
      parent: _backdropAnimationController,
      curve: Curves.linear,
    ));
  }

  Widget _codePreviewLayer(BuildContext context, BoxConstraints constraints) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    return PositionedTransition(
      rect: _getLayerAnimation(context, constraints),
      child: Container(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              height: _headerHeight + mediaQuery.padding.bottom,
              child: FlatButton(
                color: Colors.white,
                padding: EdgeInsets.fromLTRB(_codePadding, 2.0, mediaQuery.padding.right, 0.0),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  child: Stack(
                    children: <Widget>[
                      Align(
                        alignment: const Alignment(-1.0, 0.0),
                        child: Text(
                          'GET SOURCE CODE',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            color: _codeTextColor,
                            fontSize: 14.0,
                          ),
                        ),
                      ),
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
                        ),
                      ),
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
                },
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return SingleChildScrollView(
                    child: Container(
                      height: constraints.maxHeight,
                      padding: const EdgeInsets.all(_codePadding).copyWith(top: 12.0),
                      color: Colors.white,
                      child: Text(
                        widget.codePreview,
                        style: TextStyle(
                          color: _codeTextColor,
                          fontSize: 14.0,
                          height: 1.4,
                          fontFamily: 'Courier',
                        ),
                      ),
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

  List<Widget> _buildStack(BuildContext context, BoxConstraints constraints) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final List<Widget> stack = <Widget>[
      _WidgetPreviewConfigurationLayer(
        previewWidget: widget.previewWidget,
        configWidget: widget.configWidget,
      ),
    ];

    // If code layer is open, add modal
    if (_isCodeOpen) {
      stack.add(GestureDetector(
        onTap: () {
          _toggleCode();
        },
        child: Container(
          color: Colors.blue[700].withOpacity(0.6),
        ),
      ));
    }

    stack.add(_codePreviewLayer(context, constraints));

    // If code layer is open, add share button
    if (_isCodeOpen) {
      stack.add(Positioned(
        bottom: 15.0,
        right: 20.0 + mediaQuery.padding.right,
        child: RaisedButton(
          splashColor: Colors.white,
          child: const Text(
            'SHARE',
            style: TextStyle(
              fontSize: 14.0,
            ),
          ),
          onPressed: () {
            Share.share(widget.codePreview);
          },
        ),
      ));
    }
    return stack;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      return Container(
        child: Stack(
          children: _buildStack(context, constraints),
        ),
      );
    });
  }
}

// Just a column: [preview, divider, config].
class _WidgetPreviewConfigurationLayer extends StatelessWidget {
  const _WidgetPreviewConfigurationLayer({
    Key key,
    @required this.previewWidget,
    @required this.configWidget,
  })  : assert(previewWidget != null),
        assert(configWidget != null),
        super(key: key);

  final Widget previewWidget;
  final Widget configWidget;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    return Container(
      padding: mediaQuery.padding,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            height: 160.0,
            child: previewWidget,
          ),
          const Divider(
            height: 1.0,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: configWidget,
            ),
          ),
        ],
      ),
    );
  }
}
