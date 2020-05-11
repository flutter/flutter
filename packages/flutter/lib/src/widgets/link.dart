// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'framework.dart';

///
class Link extends StatelessWidget {
  ///
  const Link.external({
    Key key,
    String url,
    this.label,
    this.target,
    this.child,
  })  : isExternal = true,
        destination = url,
        super(key: key);

  ///
  const Link.internal({
    Key key,
    String routeName,
    LinkTarget target,
    this.label,
    this.child,
  })  : isExternal = false,
        destination = routeName,
        target = target ?? LinkTarget.defaultTarget,
        super(key: key);

  ///
  final bool isExternal;

  ///
  final String destination;

  ///
  final LinkTarget target;

  ///
  final String label;

  ///
  final Widget child;

  void _handleTap() {
    print('Link._handleTap');
    if (isExternal) {
      // TODO: url_launcher.
    } else {
      // TODO: Navigator.pushNamed.
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<Type, GestureRecognizerFactory> gestures =
        <Type, GestureRecognizerFactory>{};

    // Use _TransparentTapGestureRecognizer so that TextSelectionGestureDetector
    // can receive the same tap events that a selection handle placed visually
    // on top of it also receives.
    gestures[_TransparentTapGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<_TransparentTapGestureRecognizer>(
      () => _TransparentTapGestureRecognizer(debugOwner: this),
      (_TransparentTapGestureRecognizer instance) {
        instance.onTap = _handleTap;
      },
    );
    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: gestures,
      child: _Link(
        destination: destination,
        target: target,
        label: label,
        child: child,
      ),
    );
  }
}

class _Link extends SingleChildRenderObjectWidget {
  const _Link({
    Key key,
    @required this.destination,
    @required this.target,
    @required this.label,
    @required Widget child,
  }) : super(key: key, child: child);

  ///
  final String destination;

  ///
  final LinkTarget target;

  ///
  final String label;

  @override
  RenderLink createRenderObject(BuildContext context) {
    return RenderLink(destination: destination, target: target, label: label);
  }

  @override
  void updateRenderObject(BuildContext context, RenderLink renderObject) {
    renderObject
      ..destination = destination
      ..target = target
      ..label = label;
  }
}

class _TransparentTapGestureRecognizer extends TapGestureRecognizer {
  _TransparentTapGestureRecognizer({
    Object debugOwner,
  }) : super(debugOwner: debugOwner);

  @override
  void rejectGesture(int pointer) {
    // Accept new gestures that another recognizer has already won.
    // Specifically, this needs to accept taps on the text selection handle on
    // behalf of the text field in order to handle double tap to select. It must
    // not accept other gestures like longpresses and drags that end outside of
    // the text field.
    if (state == GestureRecognizerState.ready) {
      acceptGesture(pointer);
    } else {
      super.rejectGesture(pointer);
    }
  }
}
