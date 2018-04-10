// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';

const double _kFrontHeadingHeight = 32.0; // front layer beveled rectangle
const double _kFrontClosedHeight = 72.0; // front layer height when closed
const double _kBackAppBarHeight = 56.0; // back layer (options) appbar height

// The size of the front layer heading's left and right beveled corners.
final Tween<BorderRadius> _kFrontHeadingBevelRadius = new BorderRadiusTween(
  begin: new BorderRadius.only(
    topLeft: const Radius.circular(12.0),
    topRight: const Radius.circular(12.0),
  ),
  end: new BorderRadius.only(
    topLeft: const Radius.circular(_kFrontHeadingHeight),
    topRight: const Radius.circular(_kFrontHeadingHeight),
  ),
);

class _CrossFadeTransition extends AnimatedWidget {
  const _CrossFadeTransition({
    Key key,
    this.alignment: Alignment.center,
    Animation<double> progress,
    this.child0,
    this.child1,
  }) : super(key: key, listenable: progress);

  final AlignmentGeometry alignment;
  final Widget child0;
  final Widget child1;

  @override
  Widget build(BuildContext context) {
    final Animation<double> progress = listenable;

    final double opacity1 = new CurvedAnimation(
      parent: new ReverseAnimation(progress),
      curve: const Interval(0.5, 1.0),
    ).value;

    final double opacity2 = new CurvedAnimation(
      parent: progress,
      curve: const Interval(0.5, 1.0),
    ).value;

    return new Stack(
      alignment: alignment,
      children: <Widget>[
        new IgnorePointer(
          ignoring: opacity1 < 1.0,
          child: new Opacity(
            opacity: opacity1,
            child: child1,
          ),
        ),
        new IgnorePointer(
          ignoring: opacity2 <1.0,
          child: new Opacity(
            opacity: opacity2,
            child: child0,
          ),
        ),
      ],
    );
  }
}

class _RenderIgnorePointer extends RenderIgnorePointer {
  _RenderIgnorePointer({
    RenderBox child,
    bool ignoring: true,
    bool ignoringSemantics,
    ScrollController scrollController,
    double offsetThreshold,
  }) : _scrollController = scrollController,
       _offsetThreshold = offsetThreshold,
  super(
    child: child,
    ignoring: ignoring,
    ignoringSemantics: ignoringSemantics,
  );

  ScrollController get scrollController => _scrollController;
  ScrollController _scrollController;
  set scrollController(ScrollController value) {
    assert(value != null);
    if (value == _scrollController)
      return;
    _scrollController = value;
    if (ignoringSemantics == null)
      markNeedsSemanticsUpdate();
  }

  double get offsetThreshold => _offsetThreshold;
  double _offsetThreshold;
  set offsetThreshold(double value) {
    assert(value != null);
    if (value == _offsetThreshold)
      return;
    _offsetThreshold = value;
    if (ignoringSemantics == null)
      markNeedsSemanticsUpdate();
  }

  @override
  bool hitTest(HitTestResult result, { Offset position }) {
    // True  if position is within the scrollable's top padding, rather than
    // in the scrollable content below the padding. So: if the user taps in
    // the front layer's padding, the scrollable ignores the hit and the
    // back layer gets the tap.
    final bool isScrollablePadding = offsetThreshold - position.dy > scrollController.offset;
    return isScrollablePadding ? false : super.hitTest(result, position: position);
  }
}

class _IgnorePointer extends IgnorePointer {
  const _IgnorePointer({
    Key key,
    bool ignoring: true,
    bool ignoringSemantics,
    this.scrollController,
    this.offsetThreshold,
    Widget child,
  }) : super(
    key: key,
    ignoring: ignoring,
    ignoringSemantics: ignoringSemantics,
    child: child,
  );

  final ScrollController scrollController;
  final double offsetThreshold;

  @override
  _RenderIgnorePointer createRenderObject(BuildContext context) {
    return new _RenderIgnorePointer(
      ignoring: ignoring,
      ignoringSemantics: ignoringSemantics,
      scrollController: scrollController,
      offsetThreshold: offsetThreshold,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderIgnorePointer renderObject) {
    renderObject
      ..ignoring = ignoring
      ..ignoringSemantics = ignoringSemantics
      ..scrollController = scrollController
      ..offsetThreshold = offsetThreshold;
  }
}

class _BackAppBar extends StatelessWidget {
  const _BackAppBar({
    Key key,
    this.leading: const SizedBox(width: 56.0),
    this.title,
    this.trailing,
  }) : assert(leading != null), assert(title != null), super(key: key);

  final Widget leading;
  final Widget title;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[
      new Container(
        alignment: Alignment.center,
        width: 56.0,
        child: leading,
      ),
      new Expanded(
        child: title,
      ),
    ];

    if (trailing != null) {
      children.add(
        new Container(
          alignment: Alignment.center,
          width: 56.0,
          child: trailing,
        ),
      );
    }

    final ThemeData theme = Theme.of(context);

    return IconTheme.merge(
      data: theme.primaryIconTheme,
      child: new DefaultTextStyle(
        style: theme.primaryTextTheme.title,
        child: new SizedBox(
          height: _kBackAppBarHeight,
          child: new Row(children: children),
        ),
      ),
    );
  }
}

class _LayerViewportLayout extends SingleChildLayoutDelegate {
  const _LayerViewportLayout({ Listenable relayout, this.offset }) : super(relayout: relayout);

  final double offset;

  @override
  Size getSize(BoxConstraints constraints) {
    return constraints.biggest;
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    assert(constraints.hasBoundedHeight);
    return constraints.copyWith(
      minWidth: constraints.maxWidth,
      maxHeight: constraints.maxHeight - offset,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return new Offset(0.0, offset);
  }

  @override
  bool shouldRelayout(_LayerViewportLayout oldDelegate) {
    return offset != oldDelegate.offset;
  }
}

class _LayerViewport extends StatelessWidget {
  const _LayerViewport({ Key key, this.offset, this.child }) : super(key: key);

  final Widget child;
  final double offset;

  @override
  Widget build(BuildContext context) {
    return new ClipRect(
      child: new CustomSingleChildLayout(
        delegate: new _LayerViewportLayout(offset: offset),
        child: child,
      ),
    );
  }
}

class _ScrollProgressAnimation extends Animation<double> with
    AnimationLazyListenerMixin,
    AnimationLocalListenersMixin,
    AnimationLocalStatusListenersMixin
{
  @override
  double get value => _value;
  double _value = 1.0;
  set value(double newValue) {
    assert(value >= 0.0 && value <= 1.0);
    if (_value == newValue)
      return;

    AnimationStatus newStatus;
    if (newValue == 0.0)
      newStatus = AnimationStatus.dismissed;
    else if (newValue == 1.0)
      newStatus = AnimationStatus.completed;
    else if (newValue > _value)
      newStatus = AnimationStatus.forward;
    else
      newStatus = AnimationStatus.reverse;

    _value = newValue;
    final bool statusChanged = _status != newStatus;
    _status = newStatus;

    notifyListeners();
    if (statusChanged)
      notifyStatusListeners(_status);
  }

  @override
  AnimationStatus get status => _status;
  AnimationStatus _status = AnimationStatus.completed;

  @override
  void didStartListening() { }

  @override
  void didStopListening() { }

  @override
  String toStringDetails() {
    return '${super.toStringDetails()} ${value.toStringAsFixed(3)}';
  }
}

class Backdrop extends StatefulWidget {
  const Backdrop({
    this.frontAction,
    this.frontTitle,
    this.frontLayer,
    this.backTitle,
    this.backLayer,
  });

  final Widget frontAction;
  final Widget frontTitle;
  final Widget frontLayer;
  final Widget backTitle;
  final Widget backLayer;

  @override
  _BackdropState createState() => new _BackdropState();
}

class _BackdropState extends State<Backdrop> {
  ScrollController _scrollController;
  _ScrollProgressAnimation _scrollProgress = new _ScrollProgressAnimation();
  double _frontOpenOffset;
  bool _frontIsOpen = true;

  void _openFrontPanel() {
    setState(() {
      _frontIsOpen = true;
    });
    _scrollController.animateTo(
      _frontOpenOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.fastOutSlowIn,
    );
  }

  void _closeFrontPanel() {
    setState(() {
      _frontIsOpen = false;
    });
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.fastOutSlowIn,
    );
  }

  double get _frontOpenProgress {
    return (_scrollController.offset / _frontOpenOffset).clamp(0.0, 1.0);
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    _scrollProgress.value = _frontOpenProgress;
    return false;
  }

  Widget _buildFrontLayer(BuildContext context, BoxConstraints constraints) {
    final Size size = constraints.biggest;

    _frontOpenOffset = size.height - _kBackAppBarHeight - _kFrontClosedHeight;
    _scrollController ??= new ScrollController(initialScrollOffset: _frontOpenOffset);

    return new _LayerViewport(
      offset: -_kFrontHeadingHeight,
      child: new _IgnorePointer(
        ignoring: !_frontIsOpen,
        scrollController: _scrollController,
        offsetThreshold: size.height - _kFrontClosedHeight + _kFrontHeadingHeight,
        child: new NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: new SingleChildScrollView(
            controller: _scrollController,
            padding: new EdgeInsets.only(
              top: _kFrontHeadingHeight + size.height - _kFrontClosedHeight,
            ),
            child: new AnimatedBuilder(
              animation: _scrollController,
              builder: (BuildContext context, Widget child) {
                return new Container(
                  constraints: constraints.copyWith(
                    minHeight: math.max(0.0, size.height - _kBackAppBarHeight),
                    maxHeight: double.infinity,
                  ),
                  decoration: new ShapeDecoration(
                    color: Colors.white,
                    shape: new BeveledRectangleBorder(
                      borderRadius: _kFrontHeadingBevelRadius.lerp(_frontOpenProgress),
                    ),
                  ),
                  child: child,
                );
              },
              child: widget.frontLayer,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return new SizedBox.expand(
      child: new Stack(
        children: <Widget>[
          new Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              new _BackAppBar(
                leading: new _CrossFadeTransition(
                  progress: _scrollProgress,
                  child0: widget.frontAction,
                  child1: new IconButton(
                    icon: new BackButtonIcon(),
                    onPressed: _openFrontPanel,
                  ),
                ),
                title: new _CrossFadeTransition(
                  progress: _scrollProgress,
                  alignment: AlignmentDirectional.centerStart,
                  child0: widget.frontTitle,
                  child1: widget.backTitle,
                ),
                trailing: new _CrossFadeTransition(
                  progress: _scrollProgress,
                  child0: new IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: _closeFrontPanel,
                  ),
                  child1: new SizedBox()
                )
              ),
              new Expanded(
                child: widget.backLayer,
              ),
            ],
          ),
          new LayoutBuilder(builder: _buildFrontLayer),
        ],
      ),
    );
  }
}
