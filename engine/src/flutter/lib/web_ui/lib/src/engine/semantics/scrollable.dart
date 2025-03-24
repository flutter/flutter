// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

/// Implements vertical and horizontal scrolling functionality for semantics
/// objects.
///
/// Scrolling is implement by calculating a delta between the current dom scroll
/// position and the previous dom scroll position. This delta is then applied to
/// the current [SemanticsObject.scrollPosition], and sent in a [ui.SemanticsAction.scrollToOffset]
/// to the framework where it applies the value to its scrollable and we receive a
/// [ui.SemanticsUpdate] containing the new [SemanticsObject.scrollPosition] and
/// child positions.
class SemanticScrollable extends SemanticRole {
  SemanticScrollable(SemanticsObject semanticsObject)
    : super.withBasics(
        EngineSemanticsRole.scrollable,
        semanticsObject,
        preferredLabelRepresentation: LabelRepresentation.ariaLabel,
      ) {
    // Mark as group to prevent the browser from merging this element along with
    // all the children into one giant node. This is what happened with the
    // repro provided in https://github.com/flutter/flutter/issues/130950.
    setAriaRole('group');
  }

  /// Disables browser-driven scrolling in the presence of pointer events.
  GestureModeCallback? _gestureModeListener;

  /// DOM element used as a workaround for: https://github.com/flutter/flutter/issues/104036
  ///
  /// When the assistive technology gets to the last element of the scrollable
  /// list, the browser thinks the scrollable area doesn't have any more content,
  /// so it overrides the value of "scrollTop"/"scrollLeft" with zero. As a result,
  /// the user can't scroll back up/left.
  ///
  /// As a workaround, we add this DOM element and set its size to
  /// [canonicalNeutralScrollPosition] so the browser believes
  /// that the scrollable area still has some more content, and doesn't override
  /// scrollTop/scrollLetf with zero.
  final DomElement _scrollOverflowElement = createDomElement('flt-semantics-scroll-overflow');

  /// Listens to HTML "scroll" gestures detected by the browser.
  ///
  /// When we detect a "scroll" gesture we calculate a delta and apply
  /// it to the current [SemanticsObject.scrollPosition], this is then
  /// converted to a [ui.SemanticsAction.scrollToOffset].
  @visibleForTesting
  DomEventListener? scrollListener;

  /// Whether this scrollable can scroll vertically or horizontally.
  bool get _canScroll =>
      semanticsObject.isVerticalScrollContainer || semanticsObject.isHorizontalScrollContainer;

  /// The previous value of the "scrollTop" or "scrollLeft" property of this object's
  /// [element], used to calculate a delta between the current value of "scrollTop"
  /// or "scrollLeft" and this value.
  int _previousDomScrollPosition = 0;

  /// Responds to browser-detected "scroll" gestures.
  void _recomputeScrollPosition() {
    if (_domScrollPosition != _previousDomScrollPosition) {
      if (!EngineSemantics.instance.shouldAcceptBrowserGesture('scroll')) {
        return;
      }

      final double scrollDelta = (_domScrollPosition - _previousDomScrollPosition).toDouble();
      final double? scrollOffset = semanticsObject.scrollPosition;
      final double newScrollOffset = scrollOffset! + scrollDelta;
      print(
        'recomputing scroll position \n current dom position: $_domScrollPosition \n previous scroll position $_previousDomScrollPosition\n delta: $scrollDelta\n current offset: $scrollOffset \n new offset $newScrollOffset\nprevious size height: ${element.style.height}\n previous size width: ${element.style.width}',
      );

      _previousDomScrollPosition = _domScrollPosition;
      _neutralizeDomScrollPosition();
      semanticsObject.recomputePositionAndSize();
      semanticsObject.updateChildrenPositionAndSize();
      print('new size height: ${element.style.height}\n new size width: ${element.style.width}\n');

      final int semanticsId = semanticsObject.id;
      final Float64List offsets = Float64List(2);

      if (semanticsObject.isVerticalScrollContainer) {
        offsets[0] = 0.0;
        offsets[1] = newScrollOffset;
      } else {
        assert(semanticsObject.isHorizontalScrollContainer);
        offsets[0] = newScrollOffset;
        offsets[1] = 0.0;
      }

      final ByteData? message = const StandardMessageCodec().encodeMessage(offsets);
      EnginePlatformDispatcher.instance.invokeOnSemanticsAction(
        viewId,
        semanticsId,
        ui.SemanticsAction.scrollToOffset,
        message,
      );
    }
  }

  @override
  void initState() {
    // Scrolling is controlled by setting overflow-y/overflow-x to 'scroll`. The
    // default overflow = "visible" needs to be unset.
    semanticsObject.element.style.overflow = '';

    _scrollOverflowElement.style
      ..position = 'absolute'
      ..transformOrigin = '0 0 0'
      // Ignore pointer events since this is a dummy element.
      ..pointerEvents = 'none';
    append(_scrollOverflowElement);
    print(
      'init scrollable state,  rect size ${semanticsObject.rect}, scroll extent max ${semanticsObject.scrollExtentMax}',
    );
  }

  @override
  void update() {
    super.update();

    semanticsObject.owner.addOneTimePostUpdateCallback(() {
      _neutralizeDomScrollPosition();
      semanticsObject.recomputePositionAndSize();
      semanticsObject.updateChildrenPositionAndSize();
    });

    _updateCssOverflow();

    if (scrollListener == null) {
      // We need to set touch-action:none explicitly here, despite the fact
      // that we already have it on the <body> tag because overflow:scroll
      // still causes the browser to take over pointer events in order to
      // process scrolling. We don't want that when scrolling is handled by
      // the framework.
      //
      // This is effective only in Chrome. Safari does not implement this
      // CSS property. In Safari the `PointerBinding` uses `preventDefault`
      // to prevent browser scrolling.
      element.style.touchAction = 'none';

      // Memoize the tear-off because Dart does not guarantee that two
      // tear-offs of a method on the same instance will produce the same
      // object.
      _gestureModeListener = (_) {
        _updateCssOverflow();
      };
      EngineSemantics.instance.addGestureModeListener(_gestureModeListener!);

      scrollListener = createDomEventListener((DomEvent _) {
        if (!_canScroll) {
          return;
        }
        _recomputeScrollPosition();
      });
      addEventListener('scroll', scrollListener);
    }
  }

  /// The value of "scrollTop" or "scrollLeft", depending on the scroll axis.
  int get _domScrollPosition {
    if (semanticsObject.isVerticalScrollContainer) {
      return element.scrollTop.toInt();
    } else {
      assert(semanticsObject.isHorizontalScrollContainer);
      return element.scrollLeft.toInt();
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
    const int canonicalNeutralScrollPosition = 10;
    final ui.Rect? rect = semanticsObject.rect;
    if (rect == null) {
      printWarning('Warning! the rect attribute of semanticsObject is null');
      return;
    }
    if (semanticsObject.isVerticalScrollContainer) {
      // Place the _scrollOverflowElement at the end of the content and
      // make sure that when we neutralize the scrolling position,
      // so it doesn't scroll into the visible area.
      final int verticalOffset = rect.height.ceil() + canonicalNeutralScrollPosition;
      _scrollOverflowElement.style
        ..transform = 'translate(0px,${verticalOffset}px)'
        ..width = '${rect.width.round()}px'
        ..height = '${canonicalNeutralScrollPosition}px';
      semanticsObject
        ..verticalScrollAdjustment = element.scrollTop
        ..horizontalScrollAdjustment = 0.0;
    } else if (semanticsObject.isHorizontalScrollContainer) {
      // Place the _scrollOverflowElement at the end of the content and
      // make sure that when we neutralize the scrolling position,
      // it doesn't scroll into the visible area.
      final int horizontalOffset = rect.width.ceil() + canonicalNeutralScrollPosition;
      _scrollOverflowElement.style
        ..transform = 'translate(${horizontalOffset}px,0px)'
        ..width = '${canonicalNeutralScrollPosition}px'
        ..height = '${rect.height.round()}px';
      semanticsObject
        ..verticalScrollAdjustment = 0.0
        ..horizontalScrollAdjustment = element.scrollLeft;
    } else {
      _scrollOverflowElement.style
        ..transform = 'translate(0px,0px)'
        ..width = '0px'
        ..height = '0px';
      element.scrollLeft = 0.0;
      element.scrollTop = 0.0;
      semanticsObject
        ..verticalScrollAdjustment = 0.0
        ..horizontalScrollAdjustment = 0.0;
    }
  }

  void _updateCssOverflow() {
    switch (EngineSemantics.instance.gestureMode) {
      case GestureMode.browserGestures:
        // overflow:scroll will cause the browser report "scroll" events when
        // the accessibility focus shifts outside the visible bounds.
        //
        // Note that on Android overflow:hidden also works. However, we prefer
        // "scroll" because it works both on Android and iOS.
        if (semanticsObject.isVerticalScrollContainer) {
          // This will reset both `overflow-x` and `overflow-y`.
          element.style.removeProperty('overflow');
          element.style.overflowY = 'scroll';
        } else if (semanticsObject.isHorizontalScrollContainer) {
          // This will reset both `overflow-x` and `overflow-y`.
          element.style.removeProperty('overflow');
          element.style.overflowX = 'scroll';
        } else {
          element.style.overflow = 'hidden';
        }
      case GestureMode.pointerEvents:
        // We use "hidden" instead of "scroll" so that the browser does
        // not "steal" pointer events. Flutter gesture recognizers need
        // all pointer events in order to recognize gestures correctly.
        element.style.overflow = 'hidden';
    }
  }

  @override
  void dispose() {
    super.dispose();
    final DomCSSStyleDeclaration style = element.style;
    assert(_gestureModeListener != null);
    style.removeProperty('overflowY');
    style.removeProperty('overflowX');
    style.removeProperty('touch-action');
    if (scrollListener != null) {
      removeEventListener('scroll', scrollListener);
      scrollListener = null;
    }
    if (_gestureModeListener != null) {
      EngineSemantics.instance.removeGestureModeListener(_gestureModeListener!);
      _gestureModeListener = null;
    }
  }

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}
