// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
part of engine;

/// Implements vertical and horizontal scrolling functionality for semantics
/// objects.
///
/// Scrolling is implemented using a "joystick" method. The absolute value of
/// "scrollTop" in HTML is not important. We only need to know in whether the
/// value changed in the positive or negative direction. If it changes in the
/// positive direction we send a [ui.SemanticsAction.scrollUp]. Otherwise, we
/// send [ui.SemanticsAction.scrollDown]. The actual scrolling is then handled
/// by the framework and we receive a [ui.SemanticsUpdate] containing the new
/// [scrollPosition] and child positions.
///
/// "scrollTop" or "scrollLeft" is always reset to an arbitrarily chosen non-
/// zero "neutral" scroll position value. This is done so we have a
/// predictable range of DOM scroll position values. When the amount of
/// contents is less than the size of the viewport the browser snaps
/// "scrollTop" back to zero. If there is more content than available in the
/// viewport "scrollTop" may take positive values.
class Scrollable extends RoleManager {
  Scrollable(SemanticsObject semanticsObject)
      : super(Role.scrollable, semanticsObject);

  /// Disables browser-driven scrolling in the presence of pointer events.
  GestureModeCallback? _gestureModeListener;

  /// Listens to HTML "scroll" gestures detected by the browser.
  ///
  /// This gesture is converted to [ui.SemanticsAction.scrollUp] or
  /// [ui.SemanticsAction.scrollDown], depending on the direction.
  html.EventListener? _scrollListener;

  /// The value of the "scrollTop" or "scrollLeft" property of this object's
  /// [element] that has zero offset relative to the [scrollPosition].
  int _effectiveNeutralScrollPosition = 0;

  /// Responds to browser-detected "scroll" gestures.
  void _recomputeScrollPosition() {
    if (_domScrollPosition != _effectiveNeutralScrollPosition) {
      if (!semanticsObject.owner.shouldAcceptBrowserGesture('scroll')) {
        return;
      }
      final bool doScrollForward =
          _domScrollPosition > _effectiveNeutralScrollPosition;
      _neutralizeDomScrollPosition();
      semanticsObject.recomputePositionAndSize();

      final int semanticsId = semanticsObject.id;
      if (doScrollForward) {
        if (semanticsObject.isVerticalScrollContainer) {
          EnginePlatformDispatcher.instance.invokeOnSemanticsAction(
              semanticsId, ui.SemanticsAction.scrollUp, null);
        } else {
          assert(semanticsObject.isHorizontalScrollContainer);
          EnginePlatformDispatcher.instance.invokeOnSemanticsAction(
              semanticsId, ui.SemanticsAction.scrollLeft, null);
        }
      } else {
        if (semanticsObject.isVerticalScrollContainer) {
          EnginePlatformDispatcher.instance.invokeOnSemanticsAction(
              semanticsId, ui.SemanticsAction.scrollDown, null);
        } else {
          assert(semanticsObject.isHorizontalScrollContainer);
          EnginePlatformDispatcher.instance.invokeOnSemanticsAction(
              semanticsId, ui.SemanticsAction.scrollRight, null);
        }
      }
    }
  }

  @override
  void update() {
    if (_scrollListener == null) {
      // We need to set touch-action:none explicitly here, despite the fact
      // that we already have it on the <body> tag because overflow:scroll
      // still causes the browser to take over pointer events in order to
      // process scrolling. We don't want that when scrolling is handled by
      // the framework.
      //
      // This is effective only in Chrome. Safari does not implement this
      // CSS property. In Safari the `PointerBinding` uses `preventDefault`
      // to prevent browser scrolling.
      semanticsObject.element.style.touchAction = 'none';
      _gestureModeDidChange();

      // We neutralize the scroll position after all children have been
      // updated. Otherwise the browser does not yet have the sizes of the
      // child nodes and resets the scrollTop value back to zero.
      semanticsObject.owner.addOneTimePostUpdateCallback(() {
        _neutralizeDomScrollPosition();
      });

      // Memoize the tear-off because Dart does not guarantee that two
      // tear-offs of a method on the same instance will produce the same
      // object.
      _gestureModeListener = (_) {
        _gestureModeDidChange();
      };
      semanticsObject.owner.addGestureModeListener(_gestureModeListener);

      _scrollListener = (_) {
        _recomputeScrollPosition();
      };
      semanticsObject.element.addEventListener('scroll', _scrollListener);
    }
  }

  /// The value of "scrollTop" or "scrollLeft", depending on the scroll axis.
  int get _domScrollPosition {
    if (semanticsObject.isVerticalScrollContainer) {
      return semanticsObject.element.scrollTop;
    } else {
      assert(semanticsObject.isHorizontalScrollContainer);
      return semanticsObject.element.scrollLeft;
    }
  }

  /// Resets the scroll position (top or left) to the neutral value.
  ///
  /// The scroll position of the scrollable HTML node that's considered to
  /// have zero offset relative to Flutter's notion of scroll position is
  /// referred to as "neutral scroll position".
  ///
  /// We always set the scroll position to a non-zero value in order to
  /// be able to scroll in the negative direction. When scrollTop/scrollLeft is
  /// zero the browser will refuse to scroll back even when there is more
  /// content available.
  void _neutralizeDomScrollPosition() {
    // This value is arbitrary.
    const int _canonicalNeutralScrollPosition = 10;

    final html.Element element = semanticsObject.element;
    if (semanticsObject.isVerticalScrollContainer) {
      element.scrollTop = _canonicalNeutralScrollPosition;
      // Read back because the effective value depends on the amount of content.
      _effectiveNeutralScrollPosition = element.scrollTop;
      semanticsObject
        ..verticalContainerAdjustment =
            _effectiveNeutralScrollPosition.toDouble()
        ..horizontalContainerAdjustment = 0.0;
    } else {
      element.scrollLeft = _canonicalNeutralScrollPosition;
      // Read back because the effective value depends on the amount of content.
      _effectiveNeutralScrollPosition = element.scrollLeft;
      semanticsObject
        ..verticalContainerAdjustment = 0.0
        ..horizontalContainerAdjustment =
            _effectiveNeutralScrollPosition.toDouble();
    }
  }

  void _gestureModeDidChange() {
    final html.Element element = semanticsObject.element;
    switch (semanticsObject.owner.gestureMode) {
      case GestureMode.browserGestures:
        // overflow:scroll will cause the browser report "scroll" events when
        // the accessibility focus shifts outside the visible bounds.
        //
        // Note that on Android overflow:hidden also works. However, we prefer
        // "scroll" because it works both on Android and iOS.
        if (semanticsObject.isVerticalScrollContainer) {
          element.style.overflowY = 'scroll';
        } else {
          assert(semanticsObject.isHorizontalScrollContainer);
          element.style.overflowX = 'scroll';
        }
        break;
      case GestureMode.pointerEvents:
        // We use "hidden" instead of "scroll" so that the browser does
        // not "steal" pointer events. Flutter gesture recognizers need
        // all pointer events in order to recognize gestures correctly.
        if (semanticsObject.isVerticalScrollContainer) {
          element.style.overflowY = 'hidden';
        } else {
          assert(semanticsObject.isHorizontalScrollContainer);
          element.style.overflowX = 'hidden';
        }
        break;
    }
  }

  @override
  void dispose() {
    final html.CssStyleDeclaration style = semanticsObject.element.style;
    assert(_gestureModeListener != null);
    style.removeProperty('overflowY');
    style.removeProperty('overflowX');
    style.removeProperty('touch-action');
    if (_scrollListener != null) {
      semanticsObject.element.removeEventListener('scroll', _scrollListener);
    }
    semanticsObject.owner.removeGestureModeListener(_gestureModeListener);
    _gestureModeListener = null;
  }
}
