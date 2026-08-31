// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'basic.dart';
import 'framework.dart';
import 'layout_builder.dart';
import 'safe_area.dart';

/// The slots available for children managed by [EdgeInsetsOverlay] and its layout delegate.
///
/// See also:
///
///  * [EdgeInsetsOverlay.paintOrder], which configures the order in which child
///    and edge overlay widgets are painted and hit-tested.
enum EdgeInsetsOverlaySlot {
  /// The main content widget built by [EdgeInsetsOverlay.builder] that spans the
  /// full available area beneath overlays.
  child,

  /// The overlay widget docked along the left edge.
  left,

  /// The overlay widget docked along the top edge.
  top,

  /// The overlay widget docked along the right edge.
  right,

  /// The overlay widget docked along the bottom edge.
  bottom,
}

/// Signature for building the main content of an [EdgeInsetsOverlay],
/// receiving the measured [overlayPadding] of active edge widgets.
typedef EdgeInsetsOverlayWidgetBuilder =
    Widget Function(BuildContext context, EdgeInsets overlayPadding);

/// A widget that positions edge-docked side widgets and a main content widget
/// built by [builder], providing the measured overlay dimensions as [EdgeInsets].
///
/// The content built by [builder] expands to fill the entire available space,
/// extending across any provided [top], [bottom], [left], or [right] widgets.
/// The [EdgeInsets] passed to [builder] represents the exact dimensions of the
/// active side overlay widgets.
///
/// The relative paint and hit-test order between the main content and the edge
/// widgets is configurable via [paintOrder].
///
/// This allows descendants to explicitly adapt their padding or layout (e.g. for
/// map viewports, lists, or custom painters).
///
/// See also:
///
///  * [SafeArea], which insets its child to avoid operating system intrusions.
class EdgeInsetsOverlay extends StatelessWidget {
  /// Creates a widget that positions edge-docked side widgets and a content widget
  /// built by [builder].
  const EdgeInsetsOverlay({
    super.key,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.paintOrder = EdgeInsetsOverlaySlot.values,
    required this.builder,
  });

  /// A widget to place at the left edge.
  final Widget? left;

  /// A widget to place at the top edge.
  final Widget? top;

  /// A widget to place at the right edge.
  final Widget? right;

  /// A widget to place at the bottom edge.
  final Widget? bottom;

  /// The order in which the child and edge overlay widgets are painted and hit-tested.
  ///
  /// The widgets are painted from first to last in this list. Later widgets in the
  /// list paint on top of earlier ones and receive hit test events first.
  ///
  /// Defaults to [EdgeInsetsOverlaySlot.values].
  final List<EdgeInsetsOverlaySlot> paintOrder;

  /// Called to build the main content for [EdgeInsetsOverlaySlot.child],
  /// receiving the measured `padding` of active edge widgets.
  final EdgeInsetsOverlayWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final Widget finalChild = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        assert(constraints is _EdgeInsetsOverlayBoxConstraints);
        if (constraints is! _EdgeInsetsOverlayBoxConstraints) {
          return const SizedBox.shrink();
        }

        return builder(context, constraints.overlayPadding);
      },
    );

    Widget? buildSlot(EdgeInsetsOverlaySlot slot) => switch (slot) {
      .left => left != null ? LayoutId(id: slot, child: left!) : null,
      .top => top != null ? LayoutId(id: slot, child: top!) : null,
      .right => right != null ? LayoutId(id: slot, child: right!) : null,
      .bottom => bottom != null ? LayoutId(id: slot, child: bottom!) : null,
      .child => LayoutId(id: slot, child: finalChild),
    };

    final orderedSlots = <EdgeInsetsOverlaySlot>{...paintOrder, ...EdgeInsetsOverlaySlot.values};

    return CustomMultiChildLayout(
      delegate: _EdgeInsetsOverlayLayoutDelegate(),
      children: [for (final slot in orderedSlots) ?buildSlot(slot)],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Widget?>('left', left, defaultValue: null));
    properties.add(DiagnosticsProperty<Widget?>('top', top, defaultValue: null));
    properties.add(DiagnosticsProperty<Widget?>('right', right, defaultValue: null));
    properties.add(DiagnosticsProperty<Widget?>('bottom', bottom, defaultValue: null));
    properties.add(
      IterableProperty<EdgeInsetsOverlaySlot>(
        'paintOrder',
        paintOrder,
        defaultValue: EdgeInsetsOverlaySlot.values,
      ),
    );
    properties.add(ObjectFlagProperty<EdgeInsetsOverlayWidgetBuilder>.has('builder', builder));
  }
}

class _EdgeInsetsOverlayLayoutDelegate extends MultiChildLayoutDelegate {
  _EdgeInsetsOverlayLayoutDelegate();

  @override
  void performLayout(Size size) {
    Size leftSize = .zero;
    Size topSize = .zero;
    Size rightSize = .zero;
    Size bottomSize = .zero;

    if (hasChild(EdgeInsetsOverlaySlot.left)) {
      leftSize = layoutChild(
        EdgeInsetsOverlaySlot.left,
        .new(minHeight: size.height, maxHeight: size.height, maxWidth: size.width),
      );
      positionChild(EdgeInsetsOverlaySlot.left, .zero);
    }
    if (hasChild(EdgeInsetsOverlaySlot.top)) {
      topSize = layoutChild(
        EdgeInsetsOverlaySlot.top,
        .new(minWidth: size.width, maxWidth: size.width, maxHeight: size.height),
      );
      positionChild(EdgeInsetsOverlaySlot.top, .zero);
    }
    if (hasChild(EdgeInsetsOverlaySlot.right)) {
      rightSize = layoutChild(
        EdgeInsetsOverlaySlot.right,
        .new(minHeight: size.height, maxHeight: size.height, maxWidth: size.width),
      );
      positionChild(EdgeInsetsOverlaySlot.right, .new(size.width - rightSize.width, 0.0));
    }
    if (hasChild(EdgeInsetsOverlaySlot.bottom)) {
      bottomSize = layoutChild(
        EdgeInsetsOverlaySlot.bottom,
        .new(minWidth: size.width, maxWidth: size.width, maxHeight: size.height),
      );
      positionChild(EdgeInsetsOverlaySlot.bottom, .new(0.0, size.height - bottomSize.height));
    }

    // Aggregate the dimensions of all edge overlays into overlay padding.
    final EdgeInsets overlayPadding = .fromLTRB(
      leftSize.width,
      topSize.height,
      rightSize.width,
      bottomSize.height,
    );

    if (hasChild(EdgeInsetsOverlaySlot.child)) {
      layoutChild(
        EdgeInsetsOverlaySlot.child,
        _EdgeInsetsOverlayBoxConstraints(
          width: size.width,
          height: size.height,
          overlayPadding: overlayPadding,
        ),
      );
      positionChild(EdgeInsetsOverlaySlot.child, .zero);
    }
  }

  @override
  bool shouldRelayout(covariant _EdgeInsetsOverlayLayoutDelegate oldDelegate) => false;
}

/// Custom [BoxConstraints] subclass used to pass the computed overlay padding
/// down to the [LayoutBuilder] wrapping the child widget.
///
/// Because [RenderObject.layout] short-circuits execution if incoming constraints
/// compare equal (`==`), embedding [overlayPadding] directly inside these
/// constraints ensures that changes to overlay dimensions will reliably trigger
/// a relayout and rebuild of the [builder] inside [LayoutBuilder], even when
/// the total outer dimensions remain unchanged.
class _EdgeInsetsOverlayBoxConstraints extends BoxConstraints {
  /// Creates box constraints that also convey [overlayPadding] to the child layout.
  const _EdgeInsetsOverlayBoxConstraints({
    required double width,
    required double height,
    required this.overlayPadding,
  }) : super.tightFor(width: width, height: height);

  /// The padding representing the combined dimensions of the active side overlay widgets.
  final EdgeInsets overlayPadding;

  @override
  bool operator ==(Object other) {
    assert(debugAssertIsValid());
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    assert(other is _EdgeInsetsOverlayBoxConstraints && other.debugAssertIsValid());
    return other is _EdgeInsetsOverlayBoxConstraints &&
        other.overlayPadding == overlayPadding &&
        other.minWidth == minWidth &&
        other.maxWidth == maxWidth &&
        other.minHeight == minHeight &&
        other.maxHeight == maxHeight;
  }

  @override
  int get hashCode {
    assert(debugAssertIsValid());
    return Object.hash(overlayPadding, minWidth, maxWidth, minHeight, maxHeight);
  }
}
