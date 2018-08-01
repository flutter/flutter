// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class ProgressIndicatorDemo extends StatefulWidget {
  static const String routeName = '/material/progress-indicator';

  @override
  _ProgressIndicatorDemoState createState() => new _ProgressIndicatorDemoState();
}

class _ProgressIndicatorDemoState extends State<ProgressIndicatorDemo> with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = new AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();

    _animation = new CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.9, curve: Curves.fastOutSlowIn),
      reverseCurve: Curves.fastOutSlowIn
    )..addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.dismissed)
        _controller.forward();
      else if (status == AnimationStatus.completed)
        _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.stop();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      // valueAnimation.isAnimating is part of our build state
      if (_controller.isAnimating) {
        _controller.stop();
      } else {
        switch (_controller.status) {
          case AnimationStatus.dismissed:
          case AnimationStatus.forward:
            _controller.forward();
            break;
          case AnimationStatus.reverse:
          case AnimationStatus.completed:
            _controller.reverse();
            break;
        }
      }
    });
  }

  Widget _buildIndicators(BuildContext context, Widget child) {
    final List<Widget> indicators = <Widget>[
      const SizedBox(
        width: 200.0,
        child: const LinearProgressIndicator()
      ),
      const LinearProgressIndicator(),
      const LinearProgressIndicator(),
      new LinearProgressIndicator(value: _animation.value),
      new Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          const CircularProgressIndicator(),
          new SizedBox(
              width: 20.0,
              height: 20.0,
              child: new CircularProgressIndicator(value: _animation.value)
          ),
          new SizedBox(
            width: 100.0,
            height: 20.0,
            child: new Text('${(_animation.value * 100.0).toStringAsFixed(1)}%',
              textAlign: TextAlign.right
            ),
          ),
        ],
      ),
    ];
    return new Column(
      children: indicators
        .map((Widget c) => new Container(child: c, margin: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0)))
        .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: const Text('Progress indicators')),
      body: new Center(
        child: new SingleChildScrollView(
          child: new DefaultTextStyle(
            style: Theme.of(context).textTheme.title,
            child: new GestureDetector(
              onTap: _handleTap,
              behavior: HitTestBehavior.opaque,
              child: new SafeArea(
                top: false,
                bottom: false,
                child: new Container(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                  child: new AnimatedBuilder(
                    animation: _animation,
                    builder: _buildIndicators
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
