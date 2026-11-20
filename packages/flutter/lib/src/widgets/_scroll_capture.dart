// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show FlutterView;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'binding.dart';
import 'framework.dart';
import 'list_wheel_scroll_view.dart';
import 'nested_scroll_view.dart';
import 'page_view.dart';
import 'scroll_position.dart';
import 'scrollable.dart';

/// Handles requests from the platform to capture scrolling content that
/// extends beyond the visible area of the implicit Flutter view (for example,
/// Android's "scrolling screenshots", also known as "capture more").
///
/// The platform first asks for the bounds of the primary scrollable content
/// (`ScrollCapture.search`), then starts a session (`ScrollCapture.start`),
/// repeatedly asks for a region of the content to be scrolled into view
/// (`ScrollCapture.scrollTo`), and finally ends the session
/// (`ScrollCapture.end`), at which point the original scroll offset is
/// restored.
///
/// All coordinates exchanged over [SystemChannels.scrollCapture] are in
/// physical pixels. Bounds are relative to the Flutter view, and requested
/// areas are relative to the top of the scroll bounds at the scroll offset
/// that was current when the session started.
///
/// The content is scrolled with [ScrollPosition.jumpTo], so scroll
/// notifications and listeners fire as they would for any other programmatic
/// scroll (which can, for example, trigger loading more items in a lazily
/// loaded list), and any scroll activity in progress is stopped.
///
/// Only Android currently sends these requests. This is used by
/// [WidgetsBinding] and is not intended to be used directly.
@internal
class ScrollCaptureHandler {
  /// Creates a handler that responds to scroll capture requests.
  ScrollCaptureHandler({required this.rootElement});

  /// Returns the root of the element tree to search for scrollables.
  final ValueGetter<Element?> rootElement;

  _ScrollCaptureSession? _session;

  /// Handles a method call received on [SystemChannels.scrollCapture].
  Future<Object?> handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'ScrollCapture.search':
        return _findCandidate()?.physicalBounds.toJson();
      case 'ScrollCapture.start':
        // A previous session that was never ended must not leave its
        // scrollable at the capture offset.
        _endSession();
        final _ScrollCaptureCandidate? candidate = _findCandidate();
        if (candidate == null) {
          return null;
        }
        _session = _ScrollCaptureSession(candidate);
        return candidate.physicalBounds.toJson();
      case 'ScrollCapture.scrollTo':
        final _ScrollCaptureSession? session = _session;
        if (session == null || !session.isValid || !SchedulerBinding.instance.framesEnabled) {
          // Without frames, the requested content would never be rendered.
          return null;
        }
        final args = call.arguments as Map<Object?, Object?>;
        session.scrollTo(
          top: (args['top']! as num).toDouble(),
          bottom: (args['bottom']! as num).toDouble(),
        );
        await SchedulerBinding.instance.endOfFrame;
        if (!identical(session, _session) || !session.isValid) {
          return null;
        }
        // Measured after the frame, in case layout corrected the scroll offset.
        return <String, Object?>{'scrollDelta': session.physicalScrollDelta};
      case 'ScrollCapture.end':
        final bool restored = _endSession();
        if (restored && SchedulerBinding.instance.framesEnabled) {
          await SchedulerBinding.instance.endOfFrame;
        }
        return null;
    }
    throw MissingPluginException();
  }

  /// Ends the current session, if any, restoring its original scroll offset.
  ///
  /// Returns whether the scroll offset was changed.
  bool _endSession() {
    final _ScrollCaptureSession? session = _session;
    _session = null;
    return session != null && session.isValid && session.restore();
  }

  /// Finds the largest vertically scrollable [Scrollable] that is visible to
  /// the user in the implicit view, and that has content extending beyond its
  /// viewport.
  ///
  /// When several candidates have the same area, the first one in tree order
  /// is used.
  _ScrollCaptureCandidate? _findCandidate() {
    final ui.FlutterView? view = WidgetsBinding.instance.platformDispatcher.implicitView;
    final Element? root = rootElement();
    if (view == null || root == null) {
      return null;
    }
    _ScrollCaptureCandidate? best;
    void visit(Element element) {
      if (element is StatefulElement && element.state is ScrollableState) {
        final _ScrollCaptureCandidate? candidate = _ScrollCaptureCandidate.maybeCreate(
          element.state as ScrollableState,
          view,
        );
        if (candidate != null &&
            (best == null || candidate.area > best!.area) &&
            candidate.isVisible()) {
          best = candidate;
        }
      }
      element.visitChildren(visit);
    }

    root.visitChildren(visit);
    return best;
  }
}

/// A rectangle in whole physical pixels.
@immutable
class _PhysicalRect {
  const _PhysicalRect(this.left, this.top, this.right, this.bottom);

  /// The largest rectangle in whole physical pixels inside `logicalRect`.
  factory _PhysicalRect.inside(Rect logicalRect, double devicePixelRatio) {
    return _PhysicalRect(
      (logicalRect.left * devicePixelRatio).ceil(),
      (logicalRect.top * devicePixelRatio).ceil(),
      (logicalRect.right * devicePixelRatio).floor(),
      (logicalRect.bottom * devicePixelRatio).floor(),
    );
  }

  final int left;
  final int top;
  final int right;
  final int bottom;

  int get height => bottom - top;

  bool get isEmpty => left >= right || top >= bottom;

  Map<String, Object?> toJson() {
    return <String, Object?>{'left': left, 'top': top, 'right': right, 'bottom': bottom};
  }
}

class _ScrollCaptureCandidate {
  _ScrollCaptureCandidate._(
    this.scrollable,
    this.renderBox,
    this.view,
    this.logicalBounds,
    this.physicalBounds,
  );

  static _ScrollCaptureCandidate? maybeCreate(ScrollableState scrollable, ui.FlutterView view) {
    if (!scrollable.mounted || axisDirectionToAxis(scrollable.axisDirection) != Axis.vertical) {
      return null;
    }
    final ScrollPosition position = scrollable.position;
    if (!position.hasContentDimensions ||
        !position.hasPixels ||
        position.maxScrollExtent <= position.minScrollExtent) {
      return null;
    }
    // Scrolling these changes the selected page or item, which apps react to,
    // and a wheel's content is not laid out on a plane anyway.
    if (position is PageMetrics || position is FixedExtentMetrics) {
      return null;
    }
    // Scrolling a position of a NestedScrollView also moves the other
    // scrollables it coordinates (for example, by collapsing the header), so
    // the content does not move by the amount it was scrolled.
    final NestedScrollViewState? nestedScrollView = scrollable.context
        .findAncestorStateOfType<NestedScrollViewState>();
    if (nestedScrollView != null &&
        (nestedScrollView.outerController.positions.contains(position) ||
            nestedScrollView.innerController.positions.contains(position))) {
      return null;
    }
    final RenderObject? renderObject = scrollable.context.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize ||
        !_isInView(renderObject, view)) {
      return null;
    }
    // Only scrollables that are not scaled, rotated or otherwise transformed
    // move on screen by the same amount as their scroll offset changes.
    final Offset? origin = MatrixUtils.getAsTranslation(renderObject.getTransformTo(null));
    if (origin == null) {
      return null;
    }
    final Rect viewRect = Offset.zero & (view.physicalSize / view.devicePixelRatio);
    final Rect bounds = _excludePinnedContent(
      origin & renderObject.size,
      renderObject,
      scrollable.axisDirection,
    ).intersect(viewRect);
    if (bounds.isEmpty) {
      return null;
    }
    final physicalBounds = _PhysicalRect.inside(bounds, view.devicePixelRatio);
    if (physicalBounds.isEmpty) {
      return null;
    }
    return _ScrollCaptureCandidate._(scrollable, renderObject, view, bounds, physicalBounds);
  }

  /// Whether `renderObject` is rendered into `view`.
  static bool _isInView(RenderObject renderObject, ui.FlutterView view) {
    var node = renderObject;
    while (node.parent != null) {
      node = node.parent!;
    }
    return node is RenderView && identical(node.flutterView, view);
  }

  /// Removes the content pinned at the leading edge of the scrollable's
  /// viewport (such as a pinned app bar) from `bounds`.
  ///
  /// Pinned content does not move when the scrollable is scrolled, so it would
  /// otherwise be repeated in every captured image, and would cover the content
  /// when capturing towards the leading edge.
  static Rect _excludePinnedContent(Rect bounds, RenderBox renderBox, AxisDirection direction) {
    final RenderViewport? viewport = _findViewport(renderBox);
    if (viewport == null) {
      return bounds;
    }
    // Only the pinned slivers at the start of the content are pinned at the
    // leading edge until the end of the content, so only those are excluded.
    var pinnedExtent = 0.0;
    RenderSliver? sliver = viewport.firstChild;
    while (sliver != null && sliver.constraints.growthDirection == GrowthDirection.forward) {
      final double extent = sliver.geometry?.maxScrollObstructionExtent ?? 0.0;
      if (extent <= 0.0) {
        break;
      }
      pinnedExtent += extent;
      sliver = viewport.childAfter(sliver);
    }
    if (pinnedExtent <= 0.0) {
      return bounds;
    }
    return switch (direction) {
      AxisDirection.up => Rect.fromLTRB(
        bounds.left,
        bounds.top,
        bounds.right,
        bounds.bottom - pinnedExtent,
      ),
      _ => Rect.fromLTRB(bounds.left, bounds.top + pinnedExtent, bounds.right, bounds.bottom),
    };
  }

  /// Returns the first [RenderViewport] at or below `renderObject`.
  static RenderViewport? _findViewport(RenderObject renderObject) {
    if (renderObject is RenderViewport) {
      return renderObject;
    }
    RenderViewport? result;
    renderObject.visitChildren((RenderObject child) {
      result ??= _findViewport(child);
    });
    return result;
  }

  final ScrollableState scrollable;
  final RenderBox renderBox;
  final ui.FlutterView view;

  /// The visible bounds of the scrolling content in logical pixels, relative
  /// to the view.
  final Rect logicalBounds;

  /// The bounds reported to the platform, which are [logicalBounds] rounded
  /// inwards to whole physical pixels.
  final _PhysicalRect physicalBounds;

  double get area => logicalBounds.width * logicalBounds.height;

  /// Whether the scrollable is actually visible to the user, i.e. it is not
  /// obscured (for example by another route) at some point in its bounds.
  bool isVisible() {
    final Offset center = logicalBounds.center;
    final double quarterHeight = logicalBounds.height / 4;
    return _isHitAt(center) ||
        _isHitAt(center.translate(0, -quarterHeight)) ||
        _isHitAt(center.translate(0, quarterHeight));
  }

  bool _isHitAt(Offset position) {
    final result = HitTestResult();
    GestureBinding.instance.hitTestInView(result, position, view.viewId);
    for (final HitTestEntry entry in result.path) {
      final HitTestTarget target = entry.target;
      if (target is! RenderObject) {
        continue;
      }
      RenderObject? node = target;
      while (node != null) {
        if (identical(node, renderBox)) {
          return true;
        }
        node = node.parent;
      }
    }
    return false;
  }
}

class _ScrollCaptureSession {
  _ScrollCaptureSession(this.candidate) : startPixels = candidate.scrollable.position.pixels;

  final _ScrollCaptureCandidate candidate;

  /// The scroll offset when the session started, restored when it ends.
  final double startPixels;

  ScrollableState get _scrollable => candidate.scrollable;

  bool get isValid => _scrollable.mounted && _scrollable.position.hasContentDimensions;

  /// Whether increasing the scroll offset moves the content up on screen.
  bool get _scrollsDown => _scrollable.axisDirection == AxisDirection.down;

  double get _devicePixelRatio => candidate.view.devicePixelRatio;

  /// The vertical distance, in physical pixels, that the content has visually
  /// moved up since the session started.
  double get _physicalDelta {
    final double delta = (_scrollable.position.pixels - startPixels) * _devicePixelRatio;
    return _scrollsDown ? delta : -delta;
  }

  /// [_physicalDelta] rounded to whole physical pixels, as reported to the
  /// platform.
  int get physicalScrollDelta => _physicalDelta.round();

  /// Scrolls so that as much as possible of the vertical range from `top` to
  /// `bottom` is visible, moving as little as possible.
  ///
  /// The `top` and `bottom` arguments are in physical pixels relative to the
  /// top of the scroll bounds at the start of the session.
  void scrollTo({required double top, required double bottom}) {
    // Use the same height as the platform, which only sees the bounds rounded
    // to whole physical pixels.
    final int visibleHeight = candidate.physicalBounds.height;
    final double currentDelta = _physicalDelta;
    var targetDelta = currentDelta;
    if (bottom - top > visibleHeight || top < currentDelta) {
      targetDelta = top;
    } else if (bottom > currentDelta + visibleHeight) {
      targetDelta = bottom - visibleHeight;
    }
    // Snap to whole physical pixels so that the reported delta matches the
    // rendered content exactly.
    final double logicalDelta = targetDelta.roundToDouble() / _devicePixelRatio;
    final ScrollPosition position = _scrollable.position;
    final double targetPixels =
        (_scrollsDown ? startPixels + logicalDelta : startPixels - logicalDelta).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );
    if (targetPixels != position.pixels) {
      position.jumpTo(targetPixels);
    }
  }

  /// Restores the scroll offset to the one at the start of the session.
  ///
  /// Returns whether the scroll offset was changed.
  bool restore() {
    final ScrollPosition position = _scrollable.position;
    final double target = startPixels.clamp(position.minScrollExtent, position.maxScrollExtent);
    if (target == position.pixels) {
      return false;
    }
    position.jumpTo(target);
    return true;
  }
}
