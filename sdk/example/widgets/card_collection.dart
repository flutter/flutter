// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:vector_math/vector_math.dart';
import 'package:sky/animation/animation_performance.dart';
import 'package:sky/base/lerp.dart';
import 'package:sky/painting/text_style.dart';
import 'package:sky/theme/colors.dart';
import 'package:sky/widgets/animation_builder.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/card.dart';
import 'package:sky/widgets/scaffold.dart';
import 'package:sky/widgets/variable_height_scrollable.dart';
import 'package:sky/widgets/theme.dart';
import 'package:sky/widgets/tool_bar.dart';
import 'package:sky/widgets/widget.dart';


const int _kCardDismissFadeoutMS = 300;
const double _kMinFlingVelocity = 700.0;
const double _kMinFlingVelocityDelta = 400.0;
const double _kDismissCardThreshold = 0.6;

class CardCollectionApp extends App {

  final TextStyle cardLabelStyle =
    new TextStyle(color: White, fontSize: 18.0, fontWeight: bold);

  final List<double> cardHeights = [
    48.0, 64.0, 82.0, 46.0, 60.0, 55.0, 84.0, 96.0, 50.0,
    48.0, 64.0, 82.0, 46.0, 60.0, 55.0, 84.0, 96.0, 50.0,
    48.0, 64.0, 82.0, 46.0, 60.0, 55.0, 84.0, 96.0, 50.0,
    48.0, 64.0, 82.0, 46.0, 60.0, 55.0, 84.0, 96.0, 50.0
  ];

  List<int> visibleCardIndices;

  CardCollectionApp() {
    _activeCardTransform = new AnimationBuilder()
      ..position = new AnimatedType<Point>(Point.origin)
      ..opacity = new AnimatedType<double>(1.0, end: 0.0);

    _activeCardAnimation = _activeCardTransform.createPerformance(
        [_activeCardTransform.position, _activeCardTransform.opacity],
        duration: new Duration(milliseconds: _kCardDismissFadeoutMS));
    _activeCardAnimation.addListener(_handleAnimationProgressChanged);

    visibleCardIndices = new List.generate(cardHeights.length, (i) => i);
  }

  int _activeCardIndex = -1;
  AnimationBuilder _activeCardTransform;
  AnimationPerformance _activeCardAnimation;
  double _activeCardWidth;
  double _activeCardDragX = 0.0;
  bool _activeCardDragUnderway = false;

  Point get _activeCardDragEndPoint {
    return new Point(_activeCardDragX.sign * _activeCardWidth * _kDismissCardThreshold, 0.0);
  }

  void _handleAnimationProgressChanged() {
    setState(() {
      if (_activeCardAnimation.isCompleted && !_activeCardDragUnderway)
        visibleCardIndices.remove(_activeCardIndex);
    });
  }

  void _handleSizeChanged(Size newSize) {
    _activeCardWidth = newSize.width;
    _activeCardTransform.position.end = _activeCardDragEndPoint;
  }

  void _handlePointerDown(sky.PointerEvent event, int cardIndex) {
    setState(() {
      _activeCardIndex = cardIndex;
      _activeCardDragUnderway = true;
      _activeCardDragX = 0.0;
      _activeCardAnimation.progress = 0.0;
    });
  }

  void _handlePointerMove(sky.PointerEvent event) {
    if (_activeCardWidth == null || _activeCardIndex < 0)
      return;

    double oldDragX = _activeCardDragX;
    _activeCardDragX += event.dx;
    setState(() {
      if (!_activeCardAnimation.isAnimating) {
        if (oldDragX.sign != _activeCardDragX.sign)
          _activeCardTransform.position.end = _activeCardDragEndPoint;
        _activeCardAnimation.progress = _activeCardDragX.abs() / (_activeCardWidth * _kDismissCardThreshold);
      }
    });
  }

  void _handlePointerUpOrCancel(_) {
    if (_activeCardWidth == null || _activeCardIndex < 0)
      return;

    setState(() {
      _activeCardDragUnderway = false;
      if (_activeCardAnimation.isCompleted)
        visibleCardIndices.remove(_activeCardIndex);
      else if (!_activeCardAnimation.isAnimating)
        _activeCardAnimation.progress = 0.0;
    });
  }

  bool _isHorizontalFlingGesture(sky.GestureEvent event) {
    double vx = event.velocityX.abs();
    double vy = event.velocityY.abs();
    return vx - vy > _kMinFlingVelocityDelta && vx > _kMinFlingVelocity;
  }

  void _handleFlingStart(sky.GestureEvent event) {
    if (_activeCardWidth == null || _activeCardIndex < 0)
      return;

    _activeCardDragUnderway = false;

    if (_isHorizontalFlingGesture(event)) {
      double distance = 1.0 - _activeCardAnimation.progress;
      if (distance > 0.0) {
        double duration = 250.0 * 1000.0 * distance / event.velocityX.abs();
        _activeCardDragX = event.velocityX.sign;
        _activeCardAnimation.timeline.animateTo(1.0, duration: duration);
      }
    }
  }

  Widget _buildCard(int cardIndex) {
    Widget label = new Center(child: new Text("Item ${cardIndex}", style: cardLabelStyle));
    Color color = lerpColor(Red[500], Blue[500], cardIndex / cardHeights.length);
    Widget card = new Card(
      child: new Padding(child: label, padding: const EdgeDims.all(8.0)),
      color: color
    );

    // TODO(hansmuller) The code below changes the card's widget tree when
    // the user starts dragging it. Currently this causes Sky to drop the
    // rest of the pointer gesture, see https://github.com/domokit/mojo/issues/312.
    // As a workaround, always create the Transform and Opacity nodes.
    if (cardIndex == _activeCardIndex) {
      card = _activeCardTransform.build(card);
    } else {
      card = new Transform(child: card, transform: new Matrix4.identity());
      card = new Opacity(child: card, opacity: 1.0);
    }

    return new Listener(
      key: "$cardIndex",
      child: new Container(child: card, height: cardHeights[cardIndex]),
      onPointerDown: (event) { _handlePointerDown(event, cardIndex); },
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUpOrCancel,
      onPointerCancel: _handlePointerUpOrCancel,
      onGestureFlingStart: _handleFlingStart
    );
  }

  Widget _builder(int index) {
    if (index >= visibleCardIndices.length)
      return null;
    return _buildCard(visibleCardIndices[index]);
  }

  Widget build() {
    Widget cardCollection = new Container(
      padding: const EdgeDims.symmetric(vertical: 12.0, horizontal: 8.0),
      decoration: new BoxDecoration(backgroundColor: Theme.of(this).primarySwatch[50]),
      child: new VariableHeightScrollable(
        builder: _builder,
        token: visibleCardIndices.length
      )
    );

    return new Scaffold(
      toolbar: new ToolBar(center: new Text('Swipe Away')),
      body: new SizeObserver(child: cardCollection, callback: _handleSizeChanged)
    );
  }
}

void main() {
  runApp(new CardCollectionApp());
}
