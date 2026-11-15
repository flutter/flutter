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
import 'scroll_position.dart';
import 'scrollable.dart';
import 'view.dart';

/// Handles requests from the platform to capture scrolling content that
/// extends beyond the visible area of a Flutter view (for example, Android's
/// "scrolling screenshots", also known as "capture more").
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
/// This is used by [WidgetsBinding] and is not intended to be used directly.
@internal
class ScrollCaptureHandler {
  /// Creates a handler that responds to scroll capture requests.
  ScrollCaptureHandler({required this.rootElement});

  /// Returns the root of the element tree to search for scrollables.
  final ValueGetter<Element?> rootElement;

  _ScrollCaptureSession? _session;

  /// Handles a method call received on [SystemChannels.scrollCapture].
  Future<Object?> handleMethodCall(MethodCall call) async {
    final args = call.arguments as Map<Object?, Object?>?;
    final int? viewId = (args?['viewId'] as int?) ?? _implicitViewId;
    switch (call.method) {
      case 'ScrollCapture.search':
        final _ScrollCaptureCandidate? candidate = _findCandidate(viewId);
        return candidate == null ? null : _rectToJson(candidate.physicalBounds);
      case 'ScrollCapture.start':
        _session = null;
        final _ScrollCaptureCandidate? candidate = _findCandidate(viewId);
        if (candidate == null) {
          return null;
        }
        _session = _ScrollCaptureSession(candidate);
        return _rectToJson(candidate.physicalBounds);
      case 'ScrollCapture.scrollTo':
        final _ScrollCaptureSession? session = _session;
        if (session == null || !session.isValid) {
          return null;
        }
        final double scrollDelta = session.scrollTo(
          top: (args!['top']! as num).toDouble(),
          bottom: (args['bottom']! as num).toDouble(),
        );
        await SchedulerBinding.instance.endOfFrame;
        return <String, Object?>{'scrollDelta': scrollDelta.round()};
      case 'ScrollCapture.end':
        final _ScrollCaptureSession? session = _session;
        _session = null;
        if (session != null && session.isValid) {
          session.restore();
          await SchedulerBinding.instance.endOfFrame;
        }
        return null;
    }
    throw MissingPluginException();
  }

  int? get _implicitViewId => WidgetsBinding.instance.platformDispatcher.implicitView?.viewId;

  /// Finds the largest vertically scrollable [Scrollable] that is visible to
  /// the user in the view with the given `viewId`, and that has content
  /// extending beyond its viewport.
  _ScrollCaptureCandidate? _findCandidate(int? viewId) {
    final Element? root = rootElement();
    if (viewId == null || root == null) {
      return null;
    }
    _ScrollCaptureCandidate? best;
    void visit(Element element) {
      if (element is StatefulElement && element.state is ScrollableState) {
        final _ScrollCaptureCandidate? candidate = _ScrollCaptureCandidate.maybeCreate(
          element.state as ScrollableState,
          viewId,
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

  static Map<String, Object?> _rectToJson(Rect rect) {
    return <String, Object?>{
      'left': rect.left.ceil(),
      'top': rect.top.ceil(),
      'right': rect.right.floor(),
      'bottom': rect.bottom.floor(),
    };
  }
}

class _ScrollCaptureCandidate {
  _ScrollCaptureCandidate._(this.scrollable, this.renderBox, this.view, this.logicalBounds);

  static _ScrollCaptureCandidate? maybeCreate(ScrollableState scrollable, int viewId) {
    if (!scrollable.mounted || axisDirectionToAxis(scrollable.axisDirection) != Axis.vertical) {
      return null;
    }
    final ScrollPosition position = scrollable.position;
    if (!position.hasContentDimensions ||
        !position.hasPixels ||
        position.maxScrollExtent <= position.minScrollExtent) {
      return null;
    }
    final ui.FlutterView? view = View.maybeOf(scrollable.context);
    if (view == null || view.viewId != viewId) {
      return null;
    }
    final RenderObject? renderObject = scrollable.context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached || !renderObject.hasSize) {
      return null;
    }
    final Size viewSize = view.physicalSize / view.devicePixelRatio;
    final Rect bounds = MatrixUtils.transformRect(
      renderObject.getTransformTo(null),
      Offset.zero & renderObject.size,
    ).intersect(Offset.zero & viewSize);
    if (bounds.isEmpty) {
      return null;
    }
    return _ScrollCaptureCandidate._(scrollable, renderObject, view, bounds);
  }

  final ScrollableState scrollable;
  final RenderBox renderBox;
  final ui.FlutterView view;

  /// The visible bounds of the scrollable's viewport in logical pixels,
  /// relative to the view.
  final Rect logicalBounds;

  double get area => logicalBounds.width * logicalBounds.height;

  Rect get physicalBounds => Rect.fromLTRB(
    logicalBounds.left * view.devicePixelRatio,
    logicalBounds.top * view.devicePixelRatio,
    logicalBounds.right * view.devicePixelRatio,
    logicalBounds.bottom * view.devicePixelRatio,
  );

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

  /// The vertical distance, in logical pixels, that the content has visually
  /// moved up since the session started.
  double get _visualDelta {
    final double delta = _scrollable.position.pixels - startPixels;
    return _scrollsDown ? delta : -delta;
  }

  /// Scrolls so that as much as possible of the vertical range from `top` to
  /// `bottom` is visible, moving as little as possible.
  ///
  /// The `top` and `bottom` arguments are in physical pixels relative to the
  /// top of the scroll bounds at the start of the session.
  ///
  /// Returns the resulting scroll delta, in physical pixels, since the start
  /// of the session.
  double scrollTo({required double top, required double bottom}) {
    final double dpr = _devicePixelRatio;
    final double requestTop = top / dpr;
    final double requestBottom = bottom / dpr;
    final double visibleHeight = candidate.logicalBounds.height;
    final double currentDelta = _visualDelta;
    var targetDelta = currentDelta;
    if (requestBottom - requestTop > visibleHeight || requestTop < currentDelta) {
      targetDelta = requestTop;
    } else if (requestBottom > currentDelta + visibleHeight) {
      targetDelta = requestBottom - visibleHeight;
    }
    // Snap to whole physical pixels so that the reported delta matches the
    // rendered content exactly.
    targetDelta = (targetDelta * dpr).roundToDouble() / dpr;
    final ScrollPosition position = _scrollable.position;
    final double targetPixels =
        (_scrollsDown ? startPixels + targetDelta : startPixels - targetDelta).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );
    if (targetPixels != position.pixels) {
      position.jumpTo(targetPixels);
    }
    return _visualDelta * dpr;
  }

  /// Restores the scroll offset to the one at the start of the session.
  void restore() {
    final ScrollPosition position = _scrollable.position;
    final double target = startPixels.clamp(position.minScrollExtent, position.maxScrollExtent);
    if (target != position.pixels) {
      position.jumpTo(target);
    }
  }
}
