// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:vector_math/vector_math.dart';
import 'package:sky/animation/animation_performance.dart';
import 'package:sky/base/lerp.dart';
import 'package:sky/painting/text_style.dart';
import 'package:sky/theme/colors.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/card.dart';
import 'package:sky/widgets/scaffold.dart';
import 'package:sky/widgets/theme.dart';
import 'package:sky/widgets/tool_bar.dart';
import 'package:sky/widgets/widget.dart';


const int _kCardDismissFadeoutMS = 300;
const double _kMinCardFlingVelocity = 0.4;
const double _kDismissCardThreshold = 0.70;

class CardCollectionApp extends App {

  final TextStyle cardLabelStyle =
    new TextStyle(color: White, fontSize: 18.0, fontWeight: bold);

  CardCollectionApp() {
    _activeCardAnimation = new AnimationPerformance()
      ..variable = new AnimatedType(0.0, 1.0)
      ..duration = new Duration(milliseconds: _kCardDismissFadeoutMS);
    _activeCardAnimation.timeline.onValueChanged.listen(_handleAnimationProgressChanged);
  }

  int _activeCardIndex = -1;
  double _activeCardAnchorX;
  AnimationPerformance _activeCardAnimation;
  double _activeCardWidth;
  bool _activeCardDragUnderway = false;
  Set<int> _dismissedCardIndices = new Set<int>();

  double get _activeCardOpacity => 1.0 - _activeCardAnimation.progress;

  double get _activeCardOffset {
    return _activeCardAnimation.progress * _activeCardWidth * _kDismissCardThreshold;
  }

  void _handleAnimationProgressChanged(_) {
    setState(() {
      if (_activeCardAnimation.isCompleted && !_activeCardDragUnderway)
        _dismissedCardIndices.add(_activeCardIndex);
    });
  }

  void _handleSizeChanged(Size newSize) {
    _activeCardWidth = newSize.width;
  }

  void _handlePointerDown(sky.PointerEvent event, int cardIndex) {
    setState(() {
      _activeCardIndex = cardIndex;
      _activeCardDragUnderway = true;
      _activeCardAnchorX = null;
      _activeCardAnimation.progress = 0.0;
    });
  }

  void _handlePointerMove(sky.PointerEvent event) {
    if (_activeCardWidth == null || _activeCardIndex < 0)
      return;

    if (_activeCardAnchorX == null)
      _activeCardAnchorX = event.x - event.dx;

    setState(() {
      double eventOffsetX = event.x - _activeCardAnchorX;
      if (!_activeCardAnimation.isAnimating)
        _activeCardAnimation.progress = eventOffsetX / (_activeCardWidth * _kDismissCardThreshold);
    });
  }

  void _handlePointerUpOrCancel(_) {
    if (_activeCardWidth == null || _activeCardIndex < 0)
      return;

    setState(() {
      _activeCardDragUnderway = false;
      if (_activeCardAnimation.isCompleted)
        _dismissedCardIndices.add(_activeCardIndex);
      else if (!_activeCardAnimation.isAnimating)
        _activeCardAnimation.progress = 0.0;
    });
  }

  void _handleFlingStart(sky.GestureEvent event) {
    if (_activeCardWidth == null || _activeCardIndex < 0)
      return;

    _activeCardDragUnderway = false;
    double velocityX = event.velocityX / 1000;
    if (velocityX.abs() >= _kMinCardFlingVelocity)
      _activeCardAnimation.fling(velocity: velocityX / _activeCardWidth);
  }

  Widget _buildCard(int index, Color color) {
    Widget label = new Center(child: new Text("Item ${index}", style: cardLabelStyle));
    Widget card = new Card(
      child: new Padding(child: label, padding: const EdgeDims.all(8.0)),
      color: color
    );

    if (index == _activeCardIndex && _activeCardOffset > 0.0) {
      Matrix4 transform = new Matrix4.identity();
      transform.translate(_activeCardOffset, 0.0);
      card = new Transform(child: card, transform: transform);
      if (_activeCardAnimation != null)
        card = new Opacity(child: card, opacity: _activeCardOpacity);
    }

    return new Listener(
      child: card,
      onPointerDown: (event) { _handlePointerDown(event, index); }
    );
  }

  Widget _buildCardCollection(List<double> heights) {
    List<Widget> items = <Widget>[];
    for(int index = 0; index < heights.length; index++) {
      if (_dismissedCardIndices.contains(index))
        continue;
      Color color = lerpColor(Red[500], Blue[500], index / heights.length);
      items.add(new Container(
        child: _buildCard(index, color),
        height: heights[index]
      ));
    }

    Widget collection = new Container(
      child: new SizeObserver(child: new Block(items), callback: _handleSizeChanged),
      padding: const EdgeDims.symmetric(vertical: 12.0, horizontal: 8.0),
      decoration: new BoxDecoration(backgroundColor: Theme.of(this).primarySwatch[50])
    );

    return new Listener(
      child: collection,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUpOrCancel,
      onPointerCancel: _handlePointerUpOrCancel,
      onGestureFlingStart: _handleFlingStart
    );
  }

  Widget build() {
    return new Scaffold(
      toolbar: new ToolBar(center: new Text('Swipe Away')),
      body: _buildCardCollection(
          [48.0, 64.0, 82.0, 46.0, 60.0, 55.0, 84.0, 96.0, 50.0,
           48.0, 64.0, 82.0, 46.0, 60.0, 55.0, 84.0, 96.0, 50.0])
    );
  }
}

void main() {
  runApp(new CardCollectionApp());
}
