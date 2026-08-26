// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'basic.dart';
import 'framework.dart';
import 'layout_builder.dart';
import 'media_query.dart';
import 'safe_area.dart';

/// The slots available for children managed by [_SafeAreaOverlayLayoutDelegate].
enum _Slot {
  /// The main content widget that spans the full available area beneath overlays.
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

/// The edge-docked sides available for [SafeAreaOverlay] overlays.
///
/// See also:
///
///  * [SafeAreaOverlay.paintOrder], which configures the order in which side
///    overlays are painted and hit-tested.
enum SafeAreaOverlaySide {
  /// The overlay widget docked along the left edge.
  left,

  /// The overlay widget docked along the top edge.
  top,

  /// The overlay widget docked along the right edge.
  right,

  /// The overlay widget docked along the bottom edge.
  bottom,
}

/// A widget that positions edge-docked side widgets over a [child] and updates
/// the descendant [MediaQuery] padding so that descendants can avoid overlapping
/// the side widgets via [SafeArea].
///
/// The [child] widget expands to fill the entire available space, extending
/// beneath any provided [top], [bottom], [left], or [right] widgets. The
/// [MediaQueryData.padding] provided to the [child] is adjusted to include the
/// dimensions of the side widgets.
///
/// See also:
///
///  * [SafeArea], which insets its child to avoid system intrusions.
///  * [MediaQuery], which provides safe area and display insets to widgets.
class SafeAreaOverlay extends StatelessWidget {
  /// Creates a widget that overlays side widgets onto [child] and insets
  /// the safe area padding of the [child].
  const SafeAreaOverlay({
    super.key,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.paintOrder = SafeAreaOverlaySide.values,
    required this.child,
  });

  /// A widget to place at the left edge, overlaying [child].
  final Widget? left;

  /// A widget to place at the top edge, overlaying [child].
  final Widget? top;

  /// A widget to place at the right edge, overlaying [child].
  final Widget? right;

  /// A widget to place at the bottom edge, overlaying [child].
  final Widget? bottom;

  /// The order in which the overlay side widgets are painted and hit-tested.
  ///
  /// The side widgets are painted from first to last in this list, over the [child].
  /// Later widgets in the list paint on top of earlier ones and receive hit test events first.
  ///
  /// Defaults to [SafeAreaOverlaySide.values].
  final List<SafeAreaOverlaySide> paintOrder;

  /// The widget below this widget in the tree, which spans the full available
  /// space and receives adjusted [MediaQueryData.padding].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Widget finalChild = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        assert(constraints is _SafeAreaBoxConstraints);
        if (constraints is! _SafeAreaBoxConstraints) {
          return const SizedBox.shrink();
        }

        final MediaQueryData mediaQuery = MediaQuery.of(context);
        final EdgeInsets basePadding = mediaQuery.padding;
        final EdgeInsets computedPadding = .fromLTRB(
          left != null ? constraints.safeAreaPadding.left : basePadding.left,
          top != null ? constraints.safeAreaPadding.top : basePadding.top,
          right != null ? constraints.safeAreaPadding.right : basePadding.right,
          bottom != null ? constraints.safeAreaPadding.bottom : basePadding.bottom,
        );

        return MediaQuery(
          data: mediaQuery.copyWith(padding: computedPadding),
          child: child,
        );
      },
    );

    Widget? buildSide(SafeAreaOverlaySide side) => switch (side) {
      .left =>
        left != null
            ? LayoutId(
                id: _Slot.left,
                child: MediaQuery.removePadding(context: context, removeRight: true, child: left!),
              )
            : null,
      .top =>
        top != null
            ? LayoutId(
                id: _Slot.top,
                child: MediaQuery.removePadding(context: context, removeBottom: true, child: top!),
              )
            : null,
      .right =>
        right != null
            ? LayoutId(
                id: _Slot.right,
                child: MediaQuery.removePadding(context: context, removeLeft: true, child: right!),
              )
            : null,
      .bottom =>
        bottom != null
            ? LayoutId(
                id: _Slot.bottom,
                child: MediaQuery.removePadding(context: context, removeTop: true, child: bottom!),
              )
            : null,
    };

    final orderedSides = <SafeAreaOverlaySide>{...paintOrder, ...SafeAreaOverlaySide.values};
    final Iterable<Widget> overlayWidgets = orderedSides.map(buildSide).nonNulls;

    return CustomMultiChildLayout(
      delegate: _SafeAreaOverlayLayoutDelegate(),
      children: <Widget>[
        LayoutId(id: _Slot.child, child: finalChild),
        ...overlayWidgets,
      ],
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
      IterableProperty<SafeAreaOverlaySide>(
        'paintOrder',
        paintOrder,
        defaultValue: SafeAreaOverlaySide.values,
      ),
    );
  }
}

class _SafeAreaOverlayLayoutDelegate extends MultiChildLayoutDelegate {
  _SafeAreaOverlayLayoutDelegate();

  @override
  void performLayout(Size size) {
    Size leftSize = .zero;
    Size topSize = .zero;
    Size rightSize = .zero;
    Size bottomSize = .zero;

    if (hasChild(_Slot.left)) {
      leftSize = layoutChild(
        _Slot.left,
        .new(minHeight: size.height, maxHeight: size.height, maxWidth: size.width),
      );
      positionChild(_Slot.left, .zero);
    }
    if (hasChild(_Slot.top)) {
      topSize = layoutChild(
        _Slot.top,
        .new(minWidth: size.width, maxWidth: size.width, maxHeight: size.height),
      );
      positionChild(_Slot.top, .zero);
    }
    if (hasChild(_Slot.right)) {
      rightSize = layoutChild(
        _Slot.right,
        .new(minHeight: size.height, maxHeight: size.height, maxWidth: size.width),
      );
      positionChild(_Slot.right, .new(size.width - rightSize.width, 0.0));
    }
    if (hasChild(_Slot.bottom)) {
      bottomSize = layoutChild(
        _Slot.bottom,
        .new(minWidth: size.width, maxWidth: size.width, maxHeight: size.height),
      );
      positionChild(_Slot.bottom, .new(0.0, size.height - bottomSize.height));
    }

    // Aggregate the dimensions of all edge overlays into safe area padding.
    final EdgeInsets safeAreaPadding = .fromLTRB(
      leftSize.width,
      topSize.height,
      rightSize.width,
      bottomSize.height,
    );

    if (hasChild(_Slot.child)) {
      layoutChild(
        _Slot.child,
        _SafeAreaBoxConstraints(
          width: size.width,
          height: size.height,
          safeAreaPadding: safeAreaPadding,
        ),
      );
      positionChild(_Slot.child, .zero);
    }
  }

  @override
  bool shouldRelayout(covariant _SafeAreaOverlayLayoutDelegate oldDelegate) => false;
}

/// Custom [BoxConstraints] subclass used to pass the computed overlay padding
/// down to the [LayoutBuilder] wrapping the child widget.
///
/// Because [RenderObject.layout] short-circuits execution if incoming constraints
/// compare equal (`==`), embedding [safeAreaPadding] directly inside these
/// constraints ensures that changes to overlay bar dimensions will reliably trigger
/// a relayout and rebuild of the [MediaQuery] inside [LayoutBuilder], even when
/// the total outer dimensions remain unchanged.
class _SafeAreaBoxConstraints extends BoxConstraints {
  /// Creates box constraints that also convey [safeAreaPadding] to the child layout.
  const _SafeAreaBoxConstraints({
    required double width,
    required double height,
    required this.safeAreaPadding,
  }) : super.tightFor(width: width, height: height);

  /// The padding representing the combined intrusions of the active side overlay widgets.
  final EdgeInsets safeAreaPadding;

  @override
  bool operator ==(Object other) {
    assert(debugAssertIsValid());
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    assert(other is _SafeAreaBoxConstraints && other.debugAssertIsValid());
    return other is _SafeAreaBoxConstraints &&
        other.safeAreaPadding == safeAreaPadding &&
        other.minWidth == minWidth &&
        other.maxWidth == maxWidth &&
        other.minHeight == minHeight &&
        other.maxHeight == maxHeight;
  }

  @override
  int get hashCode {
    assert(debugAssertIsValid());
    return Object.hash(safeAreaPadding, minWidth, maxWidth, minHeight, maxHeight);
  }
}
