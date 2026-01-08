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
/// Scrolling is controlled by sending the current DOM scroll position in a
/// [ui.SemanticsAction.scrollToOffset] to the framework where it applies the
/// value to its scrollable and the engine receives a [ui.SemanticsUpdate]
/// containing the new [SemanticsObject.scrollPosition] and child positions.
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

  /// DOM element used to indicate to the browser the total quantity of available
  /// content under this scrollable area. This element is sized based on the
  /// total scroll extent calculated by scrollExtentMax - scrollExtentMin + rect.height
  /// of the [SemanticsObject] managed by this scrollable.
  final DomElement _scrollOverflowElement = createDomElement('flt-semantics-scroll-overflow');

  /// Listens to HTML "scroll" gestures detected by the browser.
  ///
  /// When the browser detects a "scroll" gesture we send the updated DOM scroll position
  /// to the framework in a [ui.SemanticsAction.scrollToOffset].
  @visibleForTesting
  DomEventListener? scrollListener;

  /// Whether this scrollable can scroll vertically or horizontally.
  bool get _canScroll =>
      semanticsObject.isVerticalScrollContainer || semanticsObject.isHorizontalScrollContainer;

  /// The previous value of the "scrollTop" or "scrollLeft" property of this object's
  /// [element], used to determine if the content was scrolled.
  int _previousDomScrollPosition = 0;

  /// Responds to browser-detected "scroll" gestures.
  void _recomputeScrollPosition() {
    if (_domScrollPosition != _previousDomScrollPosition) {
      if (!EngineSemantics.instance.shouldAcceptBrowserGesture('scroll')) {
        return;
      }

      _previousDomScrollPosition = _domScrollPosition;
      _updateScrollableState();
      semanticsObject.recomputePositionAndSize();
      semanticsObject.updateChildrenPositionAndSize();

      final int semanticsId = semanticsObject.id;
      final offsets = Float64List(2);

      // Either SemanticsObject.isVerticalScrollContainer or
      // SemanticsObject.isHorizontalScrollContainer should be
      // true otherwise scrollToOffset cannot be called.
      if (semanticsObject.isVerticalScrollContainer) {
        offsets[0] = 0.0;
        offsets[1] = element.scrollTop;
      } else {
        assert(semanticsObject.isHorizontalScrollContainer);
        offsets[0] = element.scrollLeft;
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
    // On macOS the scrollbar behavior which can be set in the settings application
    // may sometimes insert scrollbars into an application when a peripheral like a
    // mouse or keyboard is plugged in. This causes the clientHeight or clientWidth
    // of the scrollable DOM element to be offset by the width of the scrollbar.
    // This causes issues in the vertical scrolling context because the max scroll
    // extent is calculated by the element's scrollHeight - clientHeight, so when
    // the clientHeight is offset by scrollbar width the browser may there is
    // a greater scroll extent then what is actually available.
    //
    // The scrollbar is already made transparent in SemanticsRole._initElement so here
    // set scrollbar-width to "none" to prevent it from affecting the max scroll extent.
    //
    // Support for scrollbar-width was only added to Safari v18.2+, so versions before
    // that may still experience overscroll issues when macOS inserts scrollbars
    // into the application.
    semanticsObject.element.style.scrollbarWidth = 'none';

    _scrollOverflowElement.style
      ..position = 'absolute'
      ..transformOrigin = '0 0 0'
      // Ignore pointer events since this is a dummy element.
      ..pointerEvents = 'none';
    append(_scrollOverflowElement);
  }

  @override
  void update() {
    super.update();

    semanticsObject.owner.addOneTimePostUpdateCallback(() {
      if (_canScroll) {
        final double? scrollPosition = semanticsObject.scrollPosition;
        assert(scrollPosition != null);
        if (scrollPosition != _domScrollPosition) {
          element.scrollTop = scrollPosition!;
          _previousDomScrollPosition = _domScrollPosition;
        }
      }
      _updateScrollableState();
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

  void _updateScrollableState() {
    // This value is arbitrary.
    final ui.Rect? rect = semanticsObject.rect;
    if (rect == null) {
      printWarning('Warning! the rect attribute of semanticsObject is null');
      return;
    }
    final double? scrollExtentMax = semanticsObject.scrollExtentMax;
    final double? scrollExtentMin = semanticsObject.scrollExtentMin;
    assert(scrollExtentMax != null);
    assert(scrollExtentMin != null);
    final double scrollExtentTotal =
        scrollExtentMax! -
        scrollExtentMin! +
        (semanticsObject.isVerticalScrollContainer ? rect.height : rect.width);
    // Place the _scrollOverflowElement at the beginning of the content
    // and size it based on the total scroll extent so the browser
    // knows how much scrollable content there is.
    if (semanticsObject.isVerticalScrollContainer) {
      _scrollOverflowElement.style
        // The cross axis size should be non-zero so it is taken into
        // account in the scrollable elements scrollHeight.
        ..width = '1px'
        ..height = '${scrollExtentTotal.toStringAsFixed(1)}px';
      semanticsObject
        ..verticalScrollAdjustment = element.scrollTop
        ..horizontalScrollAdjustment = 0.0;
    } else if (semanticsObject.isHorizontalScrollContainer) {
      _scrollOverflowElement.style
        ..width = '${scrollExtentTotal.toStringAsFixed(1)}px'
        // The cross axis size should be non-zero so it is taken into
        // account in the scrollable elements scrollHeight.
        ..height = '1px';
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
