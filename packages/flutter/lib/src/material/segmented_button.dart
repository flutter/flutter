// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'button_style.dart';
import 'color_scheme.dart';
import 'colors.dart';
import 'icons.dart';
import 'material.dart';
import 'material_state.dart';
import 'segmented_button_theme.dart';
import 'text_button.dart';
import 'text_button_theme.dart';
import 'theme.dart';

/// Data describing a segment of a [SegmentedButton].
class ButtonSegment<T> {
  /// Construct a SegmentData
  ///
  /// One of [icon] or [label] must be non-null.
  const ButtonSegment({
    required this.value,
    this.icon,
    this.label,
    this.enabled = true,
  }) : assert(icon != null || label != null);

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

/// A Material button that allows the user to select from limited set of options.
///
/// Segmented buttons are used to help people select options, switch views, or
/// sort elements. They are typically used in cases where there are only 2-5
/// options.
///
/// The options are represented by segments described with [ButtonSegment]
/// entries in the [segments] field. Each segment has a [ButtonSegment.value]
/// that is used to indicate which segments are selected.
///
/// The [selected] field is a set of selected [ButtonSegment.value]s. This
/// should be updated by the app in response to [onSelectionChanged] updates.
///
/// By default, only a single segment can be selected (for mutually exclusive
/// choices). This can be relaxed with the [multiSelectionEnabled] field.
///
/// Like [ButtonStyleButton]s, the [SegmentedButton]'s visuals can be
/// configured with a [ButtonStyle] [style] field. However, unlike other
/// buttons, some of the style parameters are applied to the entire segmented
/// button, and others are used for each of the segments.
///
/// By default, a checkmark icon is used to show selected items. To configure
/// this behavior, you can use the [showSelectedIcon] and [selectedIcon] fields.
///
/// Individual segments can be enabled or disabled with their
/// [ButtonSegment.enabled] flag. If the [onSelectionChanged] field is null,
/// then the entire segmented button will be disabled, regardless of the
/// individual segment settings.
///
/// {@tool dartpad}
/// This sample shows how to display a [SegmentedButton] with either a single or
/// multiple selection.
///
/// ** See code in examples/api/lib/material/segmented_button/segmented_button.0.dart **
/// {@end-tool}
///
/// See also:
///
///   * Material Design spec: <https://m3.material.io/components/segmented-buttons/overview>
///   * [ButtonStyle], which can be used in the [style] field to configure
///     the appearance of the button and its segments.
///   * [ToggleButtons], a similar widget that was built for Material 2.
///     [SegmentedButton] should be considered as a replacement for
///     [ToggleButtons].
///   * [Radio], an alternative way to present the user with a mutually exclusive set of options.
///   * [FilterChip], [ChoiceChip], which can be used when you need to show more than five options.
class SegmentedButton<T> extends StatelessWidget {
  /// Creates a const [SegmentedButton].
  ///
  /// [segments] must contain at least one segment, but it is recommended
  /// to have two to five segments. If you need only single segment,
  /// consider using a [Checkbox] or [Radio] widget instead. If you need
  /// more than five options, consider using [FilterChip] or [ChoiceChip]
  /// widgets.
  ///
  /// If [onSelectionChanged] is null, then the entire segmented button will
  /// be disabled.
  ///
  /// By default [selected] must only contain one entry. However, if
  /// [multiSelectionEnabled] is true, then [selected] can contain multiple
  /// entries. If [emptySelectionAllowed] is true, then [selected] can be empty.
  const SegmentedButton({
    super.key,
    required this.segments,
    required this.selected,
    this.onSelectionChanged,
    this.multiSelectionEnabled = false,
    this.emptySelectionAllowed = false,
    this.style,
    this.showSelectedIcon = true,
    this.selectedIcon,
  })  : assert(segments.length > 0),
        assert(selected.length > 0 || emptySelectionAllowed),
        assert(selected.length < 2 || multiSelectionEnabled);

  /// Descriptions of the segments in the button.
  ///
  /// This a required parameter and must contain at least one segment,
  /// but it is recommended to contain two to five segments. If you need only
  /// a single segment, consider using a [Checkbox] or [Radio] widget instead.
  /// If you need more than five options, consider using [FilterChip] or
  /// [ChoiceChip] widgets.
  final List<ButtonSegment<T>> segments;

  /// The set of [ButtonSegment.value]s that indicate which [segments] are
  /// selected.
  ///
  /// As the [SegmentedButton] does not maintain the state of the selection,
  /// you will need to update this in response to [onSelectionChanged] calls.
  ///
  /// This is a required parameter.
  final Set<T> selected;

  /// The function that is called when the selection changes.
  ///
  /// The callback's parameter indicates which of the segments are selected.
  ///
  /// When the callback is null, the entire [SegmentedButton] is disabled,
  /// and will not respond to input.
  ///
  /// The default is null.
  final void Function(Set<T>)? onSelectionChanged;

  /// Determines if multiple segments can be selected at one time.
  ///
  /// If true, more than one segment can be selected. When selecting a
  /// segment, the other selected segments will stay selected. Selecting an
  /// already selected segment will unselect it.
  ///
  /// If false, only one segment may be selected at a time. When a segment
  /// is selected, any previously selected segment will be unselected.
  ///
  /// The default is false, so only a single segement may be selected at one
  /// time.
  final bool multiSelectionEnabled;

  /// Determines if having no selected segments is allowed.
  ///
  /// If true, then it is acceptable for none of the segments to be selected.
  /// This means that [selected] can be empty. If the user taps on a
  /// selected segment, it will be removed from the selection set passed into
  /// [onSelectionChanged].
  ///
  /// If false (the default), there must be at least one segment selected. If
  /// the user taps on the only selected segment it will not be deselected, and
  /// [onSelectionChanged] will not be called.
  final bool emptySelectionAllowed;

  /// Customizes this button's appearance.
  ///
  /// The following style properties apply to the entire segmented button:
  ///
  ///   * [ButtonStyle.shadowColor]
  ///   * [ButtonStyle.elevation]
  ///   * [ButtonStyle.side] - which is used for both the outer shape and
  ///     dividers between segments.
  ///   * [ButtonStyle.shape]
  ///
  /// The following style properties are applied to each of the individual
  /// button segments. For properties that are a [MaterialStateProperty],
  /// they will be resolved with the current state of the segment:
  ///
  ///   * [ButtonStyle.textStyle]
  ///   * [ButtonStyle.backgroundColor]
  ///   * [ButtonStyle.foregroundColor]
  ///   * [ButtonStyle.overlayColor]
  ///   * [ButtonStyle.surfaceTintColor]
  ///   * [ButtonStyle.elevation]
  ///   * [ButtonStyle.padding]
  ///   * [ButtonStyle.iconColor]
  ///   * [ButtonStyle.iconSize]
  ///   * [ButtonStyle.mouseCursor]
  ///   * [ButtonStyle.visualDensity]
  ///   * [ButtonStyle.tapTargetSize]
  ///   * [ButtonStyle.animationDuration]
  ///   * [ButtonStyle.enableFeedback]
  ///   * [ButtonStyle.alignment]
  ///   * [ButtonStyle.splashFactory]
  final ButtonStyle? style;

  /// Determines if the [selectedIcon] (usually an icon using [Icons.check])
  /// is displayed on the selected segments.
  ///
  /// If true, the [selectedIcon] will be displayed at the start of the segment.
  /// If both the [ButtonSegment.label] and [ButtonSegment.icon] are provided,
  /// then the icon will be replaced with the [selectedIcon]. If only the icon
  /// or the label is present then the [selectedIcon] will be shown at the start
  /// of the segment.
  ///
  /// If false, then the [selectedIcon] is not used and will not be displayed
  /// on selected segments.
  ///
  /// The default is true, meaning the [selectedIcon] will be shown on selected
  /// segments.
  final bool showSelectedIcon;

  /// An icon that is used to indicate a segment is selected.
  ///
  /// If [showSelectedIcon] is true then for selected segments this icon
  /// will be shown before the [ButtonSegment.label], replacing the
  /// [ButtonSegment.icon] if it is specified.
  ///
  /// Defaults to an [Icon] with [Icons.check].
  final Widget? selectedIcon;

  bool get _enabled => onSelectionChanged != null;

  void _handleOnPressed(T segmentValue) {
    if (!_enabled) {
      return;
    }
    final bool onlySelectedSegment = selected.length == 1 && selected.contains(segmentValue);
    final bool validChange = emptySelectionAllowed || !onlySelectedSegment;
    if (validChange) {
      final bool toggle = multiSelectionEnabled || (emptySelectionAllowed && onlySelectedSegment);
      final Set<T> pressedSegment = <T>{segmentValue};
      late final Set<T> updatedSelection;
      if (toggle) {
        updatedSelection = selected.contains(segmentValue)
          ? selected.difference(pressedSegment)
          : selected.union(pressedSegment);
      } else {
        updatedSelection = pressedSegment;
      }
      if (!setEquals(updatedSelection, selected)) {
        onSelectionChanged!(updatedSelection);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final SegmentedButtonThemeData theme = SegmentedButtonTheme.of(context);
    final SegmentedButtonThemeData defaults = _SegmentedButtonDefaultsM3(context);
    final TextDirection direction = Directionality.of(context);

    const Set<MaterialState> enabledState = <MaterialState>{};
    const Set<MaterialState> disabledState = <MaterialState>{ MaterialState.disabled };
    final Set<MaterialState> currentState = _enabled ? enabledState : disabledState;

    P? effectiveValue<P>(P? Function(ButtonStyle? style) getProperty) {
      late final P? widgetValue  = getProperty(style);
      late final P? themeValue   = getProperty(theme.style);
      late final P? defaultValue = getProperty(defaults.style);
      return widgetValue ?? themeValue ?? defaultValue;
    }

    P? resolve<P>(MaterialStateProperty<P>? Function(ButtonStyle? style) getProperty, [Set<MaterialState>? states]) {
      return effectiveValue(
        (ButtonStyle? style) => getProperty(style)?.resolve(states ?? currentState),
      );
    }

    ButtonStyle segmentStyleFor(ButtonStyle? style) {
      return ButtonStyle(
        textStyle: style?.textStyle,
        backgroundColor: style?.backgroundColor,
        foregroundColor: style?.foregroundColor,
        overlayColor: style?.overlayColor,
        surfaceTintColor: style?.surfaceTintColor,
        elevation: style?.elevation,
        padding: style?.padding,
        iconColor: style?.iconColor,
        iconSize: style?.iconSize,
        shape: const MaterialStatePropertyAll<OutlinedBorder>(RoundedRectangleBorder()),
        mouseCursor: style?.mouseCursor,
        visualDensity: style?.visualDensity,
        tapTargetSize: style?.tapTargetSize,
        animationDuration: style?.animationDuration,
        enableFeedback: style?.enableFeedback,
        alignment: style?.alignment,
        splashFactory: style?.splashFactory,
      );
    }

    final ButtonStyle segmentStyle = segmentStyleFor(style);
    final ButtonStyle segmentThemeStyle = segmentStyleFor(theme.style).merge(segmentStyleFor(defaults.style));
    final Widget? selectedIcon = showSelectedIcon
      ? this.selectedIcon ?? theme.selectedIcon ?? defaults.selectedIcon
      : null;

    Widget buttonFor(ButtonSegment<T> segment) {
      final Widget label = segment.label ?? segment.icon ?? const SizedBox.shrink();
      final bool segmentSelected = selected.contains(segment.value);
      final Widget? icon = (segmentSelected && showSelectedIcon)
        ? selectedIcon
        : segment.label != null
          ? segment.icon
          : null;
      final MaterialStatesController controller = MaterialStatesController(
        <MaterialState>{
          if (segmentSelected) MaterialState.selected,
        }
      );

      final Widget button = icon != null
        ? TextButton.icon(
            style: segmentStyle,
            statesController: controller,
            onPressed: (_enabled && segment.enabled) ? () => _handleOnPressed(segment.value) : null,
            icon: icon,
            label: label,
          )
        : TextButton(
            style: segmentStyle,
            statesController: controller,
            onPressed: (_enabled && segment.enabled) ? () => _handleOnPressed(segment.value) : null,
            child: label,
          );

      return MergeSemantics(
        child: Semantics(
          checked: segmentSelected,
          inMutuallyExclusiveGroup: multiSelectionEnabled ? null : true,
          child: button,
        ),
      );
    }

    final OutlinedBorder resolvedEnabledBorder = resolve<OutlinedBorder?>((ButtonStyle? style) => style?.shape, disabledState) ?? const RoundedRectangleBorder();
    final OutlinedBorder resolvedDisabledBorder = resolve<OutlinedBorder?>((ButtonStyle? style) => style?.shape, disabledState)?? const RoundedRectangleBorder();
    final BorderSide enabledSide = resolve<BorderSide?>((ButtonStyle? style) => style?.side, enabledState) ?? BorderSide.none;
    final BorderSide disabledSide = resolve<BorderSide?>((ButtonStyle? style) => style?.side, disabledState) ?? BorderSide.none;
    final OutlinedBorder enabledBorder = resolvedEnabledBorder.copyWith(side: enabledSide);
    final OutlinedBorder disabledBorder = resolvedDisabledBorder.copyWith(side: disabledSide);

    final List<Widget> buttons = segments.map(buttonFor).toList();

    return Material(
      shape: enabledBorder.copyWith(side: BorderSide.none),
      elevation: resolve<double?>((ButtonStyle? style) => style?.elevation)!,
      shadowColor: resolve<Color?>((ButtonStyle? style) => style?.shadowColor),
      surfaceTintColor: resolve<Color?>((ButtonStyle? style) => style?.surfaceTintColor),
      child: TextButtonTheme(
        data: TextButtonThemeData(style: segmentThemeStyle),
        child: _SegmentedButtonRenderWidget<T>(
          segments: segments,
          enabledBorder: _enabled ? enabledBorder : disabledBorder,
          disabledBorder: disabledBorder,
          direction: direction,
          children: buttons,
        ),
      ),
    );
  }
}
class _SegmentedButtonRenderWidget<T> extends MultiChildRenderObjectWidget {
  const _SegmentedButtonRenderWidget({
    super.key,
    required this.segments,
    required this.enabledBorder,
    required this.disabledBorder,
    required this.direction,
    required super.children,
  }) : assert(children.length == segments.length);

  final List<ButtonSegment<T>> segments;
  final OutlinedBorder enabledBorder;
  final OutlinedBorder disabledBorder;
  final TextDirection direction;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSegmentedButton<T>(
      segments: segments,
      enabledBorder: enabledBorder,
      disabledBorder: disabledBorder,
      textDirection: direction,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderSegmentedButton<T> renderObject) {
    renderObject
      ..segments = segments
      ..enabledBorder = enabledBorder
      ..disabledBorder = disabledBorder
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
    required List<ButtonSegment<T>> segments,
    required OutlinedBorder enabledBorder,
    required OutlinedBorder disabledBorder,
    required TextDirection textDirection,
  }) : _segments = segments,
       _enabledBorder = enabledBorder,
       _disabledBorder = disabledBorder,
       _textDirection = textDirection;

  List<ButtonSegment<T>> get segments => _segments;
  List<ButtonSegment<T>> _segments;
  set segments(List<ButtonSegment<T>> value) {
    if (listEquals(segments, value)) {
      return;
    }
    _segments = value;
    markNeedsLayout();
  }

  OutlinedBorder get enabledBorder => _enabledBorder;
  OutlinedBorder _enabledBorder;
  set enabledBorder(OutlinedBorder value) {
    if (_enabledBorder == value) {
      return;
    }
    _enabledBorder = value;
    markNeedsLayout();
  }

  OutlinedBorder get disabledBorder => _disabledBorder;
  OutlinedBorder _disabledBorder;
  set disabledBorder(OutlinedBorder value) {
    if (_disabledBorder == value) {
      return;
    }
    _disabledBorder = value;
    markNeedsLayout();
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) {
      return;
    }
    _textDirection = value;
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
      final RRect rChildRect = RRect.fromRectAndCorners(childRect);
      childParentData.surroundingRect = rChildRect;
      start += child.size.width;
      child = nextChild(child);
    }
  }

  Size _calculateChildSize(BoxConstraints constraints) {
    double maxHeight = 0;
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
    final Canvas canvas = context.canvas;
    final Rect borderRect = offset & size;
    final Path borderClipPath = enabledBorder.getInnerPath(borderRect, textDirection: textDirection);
    RenderBox? child = firstChild;
    RenderBox? previousChild;
    int index = 0;
    Path? enabledClipPath;
    Path? disabledClipPath;

    canvas..save()..clipPath(borderClipPath);
    while (child != null) {
      final _SegmentedButtonContainerBoxParentData childParentData = child.parentData! as _SegmentedButtonContainerBoxParentData;
      final Rect childRect = childParentData.surroundingRect!.outerRect.shift(offset);

      canvas..save()..clipRect(childRect);
      context.paintChild(child, childParentData.offset + offset);
      canvas.restore();

      // Compute a clip rect for the outer border of the child.
      late final double segmentLeft;
      late final double segmentRight;
      late final double dividerPos;
      final double borderOutset = math.max(enabledBorder.side.strokeOutset, disabledBorder.side.strokeOutset);
      switch (textDirection) {
        case TextDirection.rtl:
          segmentLeft = child == lastChild ? borderRect.left - borderOutset : childRect.left;
          segmentRight = child == firstChild ? borderRect.right + borderOutset : childRect.right;
          dividerPos = segmentRight;
          break;
        case TextDirection.ltr:
          segmentLeft = child == firstChild ? borderRect.left - borderOutset : childRect.left;
          segmentRight = child == lastChild ? borderRect.right + borderOutset : childRect.right;
          dividerPos = segmentLeft;
          break;
      }
      final Rect segmentClipRect = Rect.fromLTRB(
        segmentLeft, borderRect.top - borderOutset,
        segmentRight, borderRect.bottom + borderOutset);

      // Add the clip rect to the appropriate border clip path
      if (segments[index].enabled) {
        enabledClipPath = (enabledClipPath ?? Path())..addRect(segmentClipRect);
      } else {
        disabledClipPath = (disabledClipPath ?? Path())..addRect(segmentClipRect);
      }

      // Paint the divider between this segment and the previous one.
      if (previousChild != null) {
        final BorderSide divider = segments[index - 1].enabled || segments[index].enabled
          ? enabledBorder.side.copyWith(strokeAlign: 0.0)
          : disabledBorder.side.copyWith(strokeAlign: 0.0);
        final Offset top = Offset(dividerPos, childRect.top);
        final Offset bottom = Offset(dividerPos, childRect.bottom);
        canvas.drawLine(top, bottom, divider.toPaint());
      }

      previousChild = child;
      child = childAfter(child);
      index += 1;
    }
    canvas.restore();

    // Paint the outer border for both disabled and enabled clip rect if needed.
    if (disabledClipPath == null) {
      // Just paint the enabled border with no clip.
      enabledBorder.paint(context.canvas, borderRect, textDirection: textDirection);
    } else if (enabledClipPath == null) {
      // Just paint the disabled border with no.
      disabledBorder.paint(context.canvas, borderRect, textDirection: textDirection);
    } else {
      // Paint both of them clipped appropriately for the children segments.
      canvas..save()..clipPath(enabledClipPath);
      enabledBorder.paint(context.canvas, borderRect, textDirection: textDirection);
      canvas..restore()..save()..clipPath(disabledClipPath);
      disabledBorder.paint(context.canvas, borderRect, textDirection: textDirection);
      canvas.restore();
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, { required Offset position }) {
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

// Token database version: v0_162

class _SegmentedButtonDefaultsM3 extends SegmentedButtonThemeData {
  _SegmentedButtonDefaultsM3(this.context);
  final BuildContext context;
  late final ThemeData _theme = Theme.of(context);
  late final ColorScheme _colors = _theme.colorScheme;
  @override ButtonStyle? get style {
    return ButtonStyle(
      textStyle: MaterialStatePropertyAll<TextStyle?>(Theme.of(context).textTheme.labelLarge),
      backgroundColor: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
        if (states.contains(MaterialState.disabled)) {
          return null;
        }
        if (states.contains(MaterialState.selected)) {
          return _colors.secondaryContainer;
        }
        return null;
      }),
      foregroundColor: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
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
          return _colors.onSurface;
        }
      }),
      overlayColor: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
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
      }),
      surfaceTintColor: const MaterialStatePropertyAll<Color>(Colors.transparent),
      elevation: const MaterialStatePropertyAll<double>(0),
      iconSize: const MaterialStatePropertyAll<double?>(18.0),
      side: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
        if (states.contains(MaterialState.disabled)) {
          return BorderSide(color: _colors.onSurface.withOpacity(0.12));
        }
        return BorderSide(color: _colors.outline);
      }),
      shape: const MaterialStatePropertyAll<OutlinedBorder>(StadiumBorder()),
      minimumSize: const MaterialStatePropertyAll<Size?>(Size.fromHeight(40.0)),
    );
  }
  @override
  Widget? get selectedIcon => const Icon(Icons.check);
}

// END GENERATED TOKEN PROPERTIES - SegmentedButton
