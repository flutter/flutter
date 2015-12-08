// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'debug.dart';
import 'material.dart';
import 'theme.dart';

class InkResponse extends StatefulComponent {
  InkResponse({
    Key key,
    this.child,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onHighlightChanged,
    this.containedInWell: false,
    this.highlightShape: BoxShape.circle
  }) : super(key: key);

  final Widget child;
  final GestureTapCallback onTap;
  final GestureTapCallback onDoubleTap;
  final GestureLongPressCallback onLongPress;
  final ValueChanged<bool> onHighlightChanged;
  final bool containedInWell;
  final BoxShape highlightShape;

  _InkResponseState createState() => new _InkResponseState<InkResponse>();
}

class _InkResponseState<T extends InkResponse> extends State<T> {

  Set<InkSplash> _splashes;
  InkSplash _currentSplash;
  InkHighlight _lastHighlight;

  void updateHighlight(bool value) {
    if (value == (_lastHighlight != null && _lastHighlight.active))
      return;
    if (value) {
      if (_lastHighlight == null) {
        RenderBox referenceBox = context.findRenderObject();
        assert(Material.of(context) != null);
        _lastHighlight = Material.of(context).highlightAt(
          referenceBox: referenceBox,
          color: Theme.of(context).highlightColor,
          shape: config.highlightShape,
          onRemoved: () {
            assert(_lastHighlight != null);
            _lastHighlight = null;
          }
        );
      } else {
        _lastHighlight.activate();
      }
    } else {
      _lastHighlight.deactivate();
    }
    if (config.onHighlightChanged != null)
      config.onHighlightChanged(value != null);
  }


  void _handleTapDown(Point position) {
    RenderBox referenceBox = context.findRenderObject();
    assert(Material.of(context) != null);
    InkSplash splash;
    splash = Material.of(context).splashAt(
      referenceBox: referenceBox,
      position: referenceBox.globalToLocal(position),
      color: Theme.of(context).splashColor,
      containedInWell: config.containedInWell,
      onRemoved: () {
        if (_splashes != null) {
          assert(_splashes.contains(splash));
          _splashes.remove(splash);
          if (_currentSplash == splash)
            _currentSplash = null;
        } // else we're probably in deactivate()
      }
    );
    _splashes ??= new Set<InkSplash>();
    _splashes.add(splash);
    _currentSplash = splash;
    updateHighlight(true);
  }

  void _handleTap() {
    _currentSplash?.confirm();
    _currentSplash = null;
    updateHighlight(false);
    if (config.onTap != null)
      config.onTap();
  }

  void _handleTapCancel() {
    _currentSplash?.cancel();
    _currentSplash = null;
    updateHighlight(false);
  }

  void _handleDoubleTap() {
    _currentSplash?.confirm();
    _currentSplash = null;
    if (config.onDoubleTap != null)
      config.onDoubleTap();
  }

  void _handleLongPress() {
    _currentSplash?.confirm();
    _currentSplash = null;
    if (config.onLongPress != null)
      config.onLongPress();
  }

  void deactivate() {
    if (_splashes != null) {
      Set<InkSplash> splashes = _splashes;
      _splashes = null;
      for (InkSplash splash in splashes)
        splash.dispose();
      _currentSplash = null;
    }
    assert(_currentSplash == null);
    _lastHighlight?.dispose();
    _lastHighlight = null;
    super.deactivate();
  }

  void dependenciesChanged(Type affectedWidgetType) {
    if (affectedWidgetType == Theme && _lastHighlight != null)
      _lastHighlight.color = Theme.of(context).highlightColor;
  }

  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    final bool enabled = config.onTap != null || config.onDoubleTap != null || config.onLongPress != null;
    return new GestureDetector(
      onTapDown: enabled ? _handleTapDown : null,
      onTap: enabled ? _handleTap : null,
      onTapCancel: enabled ? _handleTapCancel : null,
      onDoubleTap: config.onDoubleTap != null ? _handleDoubleTap : null,
      onLongPress: config.onLongPress != null ? _handleLongPress : null,
      behavior: HitTestBehavior.opaque,
      child: config.child
    );
  }

}

/// An area of a Material that responds to touch.
///
/// Must have an ancestor Material widget in which to cause ink reactions.
class InkWell extends InkResponse {
  InkWell({
    Key key,
    Widget child,
    GestureTapCallback onTap,
    GestureTapCallback onDoubleTap,
    GestureLongPressCallback onLongPress,
    ValueChanged<bool> onHighlightChanged
  }) : super(
    key: key,
    child: child,
    onTap: onTap,
    onDoubleTap: onDoubleTap,
    onLongPress: onLongPress,
    onHighlightChanged: onHighlightChanged,
    containedInWell: true,
    highlightShape: BoxShape.rectangle
  );
}
