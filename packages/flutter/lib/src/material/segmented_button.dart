// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'button_style.dart';
import 'color_scheme.dart';
import 'icons.dart';
import 'material_state.dart';
import 'segmented_button_theme.dart';
import 'text_button.dart';
import 'theme.dart';

// TODO(darrenaustin): do we really need this?
const double _kMinSegmentedButtonHeight = 28.0;

/// Data describing a segment of a [SegmentedButton].
class SegmentData<T> {
  /// Construct a SegmentData
  const SegmentData({
    required this.value,
    this.icon,
    this.label,
    this.enabled = true,
  });

  /// Value used to identify the segment.
  ///
  /// This value must be unique across all segments in a [SegmentedButton].
  final T value;

  /// Optional icon displayed in the segment.
  final Widget? icon;

  /// Optional label displayed in the segment.
  final Widget? label;

  /// Determines if the segment is available for selection.
  final bool enabled;
}

/// DMA: Document this.
class SegmentedButton<T> extends StatelessWidget {
  /// DMA: Document this.
  const SegmentedButton({
    super.key,
    required this.segments,
    required this.selected,
    this.onSelectionChanged,
    this.multiSelectEnabled = false,
    this.emptySelectionAllowed = false,
    this.showSelectedCheckboxes = true,
  })  : assert(segments != null),
        assert(segments.length > 0),
        assert(selected != null),
        assert(selected.length > 0 || emptySelectionAllowed),
        assert(selected.length < 2 || multiSelectEnabled);

  /// Descriptions of the segments in the button.
  final List<SegmentData<T>> segments;

  /// Set of values that indicate which [segments] are selected.
  final Set<T> selected;

  /// Function that is called back when the selection changes.
  ///
  /// The passed set of values indicates which of the segments are selected.
  ///
  /// When the callback is null, the entire segmented button is disabled.
  final void Function(Set<T>)? onSelectionChanged;

  /// Determines if multiple segments can be selected at one time.
  ///
  /// If true, more than one segment can be selected. When selecting a
  /// segment, the other selected segments will stay selected. Selecting an
  /// already selected segment will unselect it.
  ///
  /// If false, only one segment will be selected at a time. When a segment
  /// is selected, any previously selected segment will be unselected.
  final bool multiSelectEnabled;

  /// Determines if having no selected segments is allowed.
  final bool emptySelectionAllowed;

  /// Determines if checkboxes are displayed on the selected segments.
  ///
  /// If true a checkbox icon will be displayed at the start of the segment.
  /// If both the [SegmentData.label] and [SegmentData.icon] is provided,
  /// then the icon will be replaced with a checkbox. If only the icon or
  /// the label is present then the checkbox will be shown at the start of
  /// the segment.
  ///
  /// If false, then no checkbox will be displayed for selected segments.
  final bool showSelectedCheckboxes;

  bool get _enabled => onSelectionChanged != null;

  void _handleOnPressed(T segmentValue) {
    if (_enabled) {
      final bool onlySelectedSegment = selected.length == 1 && selected.contains(segmentValue);
      final bool validChange = emptySelectionAllowed || !onlySelectedSegment;
      if (validChange) {
        final bool toggle = multiSelectEnabled || (emptySelectionAllowed && onlySelectedSegment);
        if (toggle) {
          final Set<T> updatedSelection = selected.contains(segmentValue)
            ? selected.difference(<T>{segmentValue})
            : selected.union(<T>{segmentValue});
          onSelectionChanged!(updatedSelection);
        } else {
          onSelectionChanged!(<T>{segmentValue});
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final SegmentedButtonThemeData theme = SegmentedButtonTheme.of(context);
    final SegmentedButtonThemeData defaults = _SegmentedButtonDefaultsM3(context);
    final TextDirection direction = Directionality.of(context);

    TextButton buttonFor(SegmentData<T> segment, {bool start = false, bool end = false}) {
      final Widget label = segment.label ?? segment.icon ?? const SizedBox.shrink();
      final bool segmentSelected = selected.contains(segment.value);
      final Widget? icon = (segmentSelected && showSelectedCheckboxes)
        ? const Icon(Icons.check)
        : segment.label != null
          ? segment.icon
          : null;
      final ButtonStyle style = ButtonStyle(
        backgroundColor: theme.backgroundColor ?? defaults.backgroundColor,
        foregroundColor: theme.foregroundColor ?? defaults.foregroundColor,
        overlayColor: theme.overlayColor ?? defaults.overlayColor,
        textStyle: theme.textStyle ?? defaults.textStyle,
        shape: start
          ? theme.startSegmentShape ?? defaults.startSegmentShape ?? theme.segmentShape ?? defaults.segmentShape
          : end
            ? theme.endSegmentShape ?? defaults.endSegmentShape ?? theme.segmentShape ?? defaults.segmentShape
            : theme.segmentShape ?? defaults.segmentShape,
        iconSize: theme.iconSize ?? defaults.iconSize,
      );
      final MaterialStatesController controller = MaterialStatesController(
        segmentSelected ? <MaterialState>{ MaterialState.selected } : <MaterialState>{}
      );

      if (icon != null) {
        return TextButton.icon(
          style: style,
          statesController: controller,
          onPressed: (_enabled && segment.enabled) ? () => _handleOnPressed(segment.value) : null,
          icon: icon,
          label: label,
        );
      }
      return TextButton(
        style: style,
        statesController: controller,
        onPressed: (_enabled && segment.enabled) ? () => _handleOnPressed(segment.value) : null,
        child: label,
      );
    }

    final List<Widget> buttons = <Widget>[];
    final List<BorderSide?> dividers = <BorderSide?>[];
    final MaterialStateProperty<BorderSide?>? divider = theme.divider ?? defaults.divider;
    for (int i = 0; i < segments.length; i++) {
      final bool last = i == segments.length - 1;
      buttons.add(buttonFor(segments[i], start: i == 0, end: last));
      if (!last) {
        if (divider != null) {
          final bool dividerEnabled = _enabled && (segments[i].enabled || segments[i + 1].enabled);
          final Set<MaterialState> dividerState = dividerEnabled ? <MaterialState>{} : <MaterialState>{ MaterialState.disabled };
          dividers.add(divider.resolve(dividerState));
        } else {
          dividers.add(null);
        }
      }
    }

    return _SegmentedButtonRenderWidget<T>(
      dividers: dividers,
      direction: direction,
      children: buttons,
    );
  }
}
class _SegmentedButtonRenderWidget<T> extends MultiChildRenderObjectWidget {
  _SegmentedButtonRenderWidget({
    super.key,
    required this.dividers,
    required this.direction,
    required super.children,
  }) : assert(children.length == dividers.length + 1);

  final List<BorderSide?> dividers;
  final TextDirection direction;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSegmentedButton<T>(
      dividers: dividers,
      textDirection: direction,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderSegmentedButton<T> renderObject) {
    renderObject
      ..dividers = dividers
      ..textDirection = direction;
  }
}

class _SegmentedButtonContainerBoxParentData extends ContainerBoxParentData<RenderBox> {
  RRect? surroundingRect;
}

typedef _NextChild = RenderBox? Function(RenderBox child);

class _RenderSegmentedButton<T> extends RenderBox with
     ContainerRenderObjectMixin<RenderBox, ContainerBoxParentData<RenderBox>>,
     RenderBoxContainerDefaultsMixin<RenderBox, ContainerBoxParentData<RenderBox>> {
  _RenderSegmentedButton({
    required List<BorderSide?> dividers,
    required TextDirection textDirection,
  }) : _dividers = dividers,
       _textDirection = textDirection;

  List<BorderSide?> get dividers => _dividers;
  List<BorderSide?> _dividers;
  set dividers(List<BorderSide?> value) {
    if (_dividers == value) {
      return;
    }
    _dividers = value;
    markNeedsPaint();
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) {
      return;
    }
    _textDirection = value;
    print('Layout needed for $_textDirection');
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    RenderBox? child = firstChild;
    double minWidth = 0.0;
    while (child != null) {
      final _SegmentedButtonContainerBoxParentData childParentData = child.parentData! as _SegmentedButtonContainerBoxParentData;
      final double childWidth = child.getMinIntrinsicWidth(height);
      minWidth = math.max(minWidth, childWidth);
      child = childParentData.nextSibling;
    }
    return minWidth * childCount;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    RenderBox? child = firstChild;
    double maxWidth = 0.0;
    while (child != null) {
      final _SegmentedButtonContainerBoxParentData childParentData = child.parentData! as _SegmentedButtonContainerBoxParentData;
      final double childWidth = child.getMaxIntrinsicWidth(height);
      maxWidth = math.max(maxWidth, childWidth);
      child = childParentData.nextSibling;
    }
    return maxWidth * childCount;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    RenderBox? child = firstChild;
    double minHeight = 0.0;
    while (child != null) {
      final _SegmentedButtonContainerBoxParentData childParentData = child.parentData! as _SegmentedButtonContainerBoxParentData;
      final double childHeight = child.getMinIntrinsicHeight(width);
      minHeight = math.max(minHeight, childHeight);
      child = childParentData.nextSibling;
    }
    return minHeight;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    RenderBox? child = firstChild;
    double maxHeight = 0.0;
    while (child != null) {
      final _SegmentedButtonContainerBoxParentData childParentData = child.parentData! as _SegmentedButtonContainerBoxParentData;
      final double childHeight = child.getMaxIntrinsicHeight(width);
      maxHeight = math.max(maxHeight, childHeight);
      child = childParentData.nextSibling;
    }
    return maxHeight;
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToHighestActualBaseline(baseline);
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _SegmentedButtonContainerBoxParentData) {
      child.parentData = _SegmentedButtonContainerBoxParentData();
    }
  }

  void _layoutRects(_NextChild nextChild, RenderBox? leftChild, RenderBox? rightChild) {
    RenderBox? child = leftChild;
    double start = 0.0;
    while (child != null) {
      final _SegmentedButtonContainerBoxParentData childParentData = child.parentData! as _SegmentedButtonContainerBoxParentData;
      final Offset childOffset = Offset(start, 0.0);
      childParentData.offset = childOffset;
      final Rect childRect = Rect.fromLTWH(start, 0.0, child.size.width, child.size.height);
      final RRect rChildRect;
      if (child == leftChild) {
        final double radius = childRect.height / 2;
        rChildRect = RRect.fromRectAndCorners(
          childRect,
          topLeft: Radius.circular(radius),
          bottomLeft: Radius.circular(radius),
        );
      } else if (child == rightChild) {
        final double radius = childRect.height / 2;
        rChildRect = RRect.fromRectAndCorners(
          childRect,
          topRight: Radius.circular(radius),
          bottomRight: Radius.circular(radius),
        );
      } else {
        rChildRect = RRect.fromRectAndCorners(childRect);
      }
      childParentData.surroundingRect = rChildRect;
      start += child.size.width;
      child = nextChild(child);
    }
  }

  Size _calculateChildSize(BoxConstraints constraints) {
    double maxHeight = _kMinSegmentedButtonHeight;
    double childWidth = constraints.minWidth / childCount;
    RenderBox? child = firstChild;
    while (child != null) {
      childWidth = math.max(childWidth, child.getMaxIntrinsicWidth(double.infinity));
      child = childAfter(child);
    }
    childWidth = math.min(childWidth, constraints.maxWidth / childCount);
    child = firstChild;
    while (child != null) {
      final double boxHeight = child.getMaxIntrinsicHeight(childWidth);
      maxHeight = math.max(maxHeight, boxHeight);
      child = childAfter(child);
    }
    return Size(childWidth, maxHeight);
  }

  Size _computeOverallSizeFromChildSize(Size childSize) {
    return constraints.constrain(Size(childSize.width * childCount, childSize.height));
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final Size childSize = _calculateChildSize(constraints);
    return _computeOverallSizeFromChildSize(childSize);
  }

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;
    final Size childSize = _calculateChildSize(constraints);

    final BoxConstraints childConstraints = BoxConstraints.tightFor(
      width: childSize.width,
      height: childSize.height,
    );

    RenderBox? child = firstChild;
    while (child != null) {
      child.layout(childConstraints, parentUsesSize: true);
      child = childAfter(child);
    }

    switch (textDirection) {
      case TextDirection.rtl:
        _layoutRects(
          childBefore,
          lastChild,
          firstChild,
        );
        break;
      case TextDirection.ltr:
        _layoutRects(
          childAfter,
          firstChild,
          lastChild,
        );
        break;
    }

    size = _computeOverallSizeFromChildSize(childSize);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    RenderBox? child = firstChild;
    RenderBox? lastChild;
    int index = 0;
    while (child != null) {
      _paintChild(context, offset, child, index);
      if (lastChild != null) {
        final BorderSide? divider = dividers[index - 1];
        if (divider != null) {
          final _SegmentedButtonContainerBoxParentData lastParentData = lastChild.parentData! as _SegmentedButtonContainerBoxParentData;
          late final double middle;
          switch (textDirection) {
            case TextDirection.rtl:
              middle = lastParentData.surroundingRect!.left;
              break;
            case TextDirection.ltr:
              middle = lastParentData.surroundingRect!.right;
              break;
          }
          final Offset top = Offset(middle, lastParentData.surroundingRect!.top);
          final Offset bottom = Offset(middle, lastParentData.surroundingRect!.bottom);
          context.canvas.drawLine(top + offset, bottom + offset, divider.toPaint());
        }
      }
      lastChild = child;
      child = childAfter(child);
      index += 1;
    }
  }

  void _paintChild(PaintingContext context, Offset offset, RenderBox child, int childIndex) {
    assert(child != null);
    final _SegmentedButtonContainerBoxParentData childParentData = child.parentData! as _SegmentedButtonContainerBoxParentData;
    context.paintChild(child, childParentData.offset + offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, { required Offset position }) {
    assert(position != null);
    RenderBox? child = lastChild;
    while (child != null) {
      final _SegmentedButtonContainerBoxParentData childParentData = child.parentData! as _SegmentedButtonContainerBoxParentData;
      if (childParentData.surroundingRect!.contains(position)) {
        return result.addWithPaintOffset(
          offset: childParentData.offset,
          position: position,
          hitTest: (BoxHitTestResult result, Offset localOffset) {
            assert(localOffset == position - childParentData.offset);
            return child!.hitTest(result, position: localOffset);
          },
        );
      }
      child = childParentData.previousSibling;
    }
    return false;
  }
}

// BEGIN GENERATED TOKEN PROPERTIES - SegmentedButton

// Do not edit by hand. The code between the "BEGIN GENERATED" and
// "END GENERATED" comments are generated from data in the Material
// Design token database by the script:
//   dev/tools/gen_defaults/bin/gen_defaults.dart.

// Token database version: v0_132

class _SegmentedButtonDefaultsM3 extends SegmentedButtonThemeData {
  _SegmentedButtonDefaultsM3(this.context);

  final BuildContext context;
  late final ThemeData _theme = Theme.of(context);
  late final ColorScheme _colors = _theme.colorScheme;

  @override
  MaterialStateProperty<Color?>? get backgroundColor {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        return null;
      }
      if (states.contains(MaterialState.selected)) {
        return _colors.secondaryContainer;
      }
      return null;
    });
  }

  @override
  MaterialStateProperty<Color?>? get foregroundColor {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        return _colors.onSurface.withOpacity(0.38);
      }
      if (states.contains(MaterialState.selected)) {
        if (states.contains(MaterialState.pressed)) {
          return _colors.onSecondaryContainer;
        }
        if (states.contains(MaterialState.hovered)) {
          return _colors.onSecondaryContainer;
        }
        if (states.contains(MaterialState.focused)) {
          return _colors.onSecondaryContainer;
        }
        return _colors.onSecondaryContainer;
      } else {
        if (states.contains(MaterialState.pressed)) {
          return _colors.onSurface;
        }
        if (states.contains(MaterialState.hovered)) {
          return _colors.onSurface;
        }
        if (states.contains(MaterialState.focused)) {
          return _colors.onSurface;
        }
        return null;
      }
    });
  }

  @override
  MaterialStateProperty<Color?>? get overlayColor {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        if (states.contains(MaterialState.hovered)) {
          return _colors.onSecondaryContainer.withOpacity(0.08);
        }
        if (states.contains(MaterialState.focused)) {
          return _colors.onSecondaryContainer.withOpacity(0.12);
        }
        if (states.contains(MaterialState.pressed)) {
          return _colors.onSecondaryContainer.withOpacity(0.12);
        }
      } else {
        if (states.contains(MaterialState.hovered)) {
          return _colors.onSurface.withOpacity(0.08);
        }
        if (states.contains(MaterialState.focused)) {
          return _colors.onSurface.withOpacity(0.12);
        }
        if (states.contains(MaterialState.pressed)) {
          return _colors.onSurface.withOpacity(0.12);
        }
      }
      return null;
    });
  }

  @override MaterialStateProperty<TextStyle?>? get textStyle =>
    MaterialStatePropertyAll<TextStyle?>(Theme.of(context).textTheme.labelLarge);

  @override MaterialStateProperty<double?>? get iconSize =>
    const MaterialStatePropertyAll<double?>(18.0);

  @override
  MaterialStateProperty<OutlinedBorder?>? get segmentShape {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        return PartialRectOutlinedBorder(side: BorderSide(color: _colors.onSurface.withOpacity(0.12)), top: true, bottom: true);
      }
      return PartialRectOutlinedBorder(side: BorderSide(color: _colors.outline), top: true, bottom: true);
    });
  }

  @override
  MaterialStateProperty<OutlinedBorder?>? get startSegmentShape {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        return HalfStadiumBorder(side: BorderSide(color: _colors.onSurface.withOpacity(0.12)));
      }
      return HalfStadiumBorder(side: BorderSide(color: _colors.outline));
    });
  }

  @override
  MaterialStateProperty<OutlinedBorder?>? get endSegmentShape {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        return HalfStadiumBorder(roundStart: false, side: BorderSide(color: _colors.onSurface.withOpacity(0.12)));
      }
      return HalfStadiumBorder(roundStart: false, side: BorderSide(color: _colors.outline));
    });
  }

  @override
  MaterialStateProperty<BorderSide?>? get divider {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        return BorderSide(color: _colors.onSurface.withOpacity(0.12));
      }
      return BorderSide(color: _colors.outline);
    });
  }
}

// END GENERATED TOKEN PROPERTIES - SegmentedButton
