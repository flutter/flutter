// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart' show clampDouble;
import 'package:flutter/widgets.dart';

import 'chip.dart';
import 'chip_theme.dart';
import 'debug.dart';
import 'icons.dart';
import 'theme.dart';
import 'theme_data.dart';

/// A Material Design input chip.
///
/// Input chips represent a complex piece of information, such as an entity
/// (person, place, or thing) or conversational text, in a compact form.
///
/// Input chips can be made selectable by setting [onSelected], deletable by
/// setting [onDeleted], and pressable like a button with [onPressed]. They have
/// a [label], and they can have a leading icon (see [avatar]) and a trailing
/// icon ([deleteIcon]). Colors and padding can be customized.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// Input chips work together with other UI elements. They can appear:
///
///  * In a [Wrap] widget.
///  * In a horizontally scrollable list, like a [ListView] whose
///    scrollDirection is [Axis.horizontal].
///
/// {@tool snippet}
///
/// ```dart
/// InputChip(
///   avatar: CircleAvatar(
///     backgroundColor: Colors.grey.shade800,
///     child: const Text('AB'),
///   ),
///   label: const Text('Aaron Burr'),
///   onPressed: () {
///     print('I am the one thing in life.');
///   }
/// )
/// ```
/// {@end-tool}
///
/// ## Material Design 3
///
/// [InputChip] can be used for Input chips from Material Design 3.
/// If [ThemeData.useMaterial3] is true, then [InputChip]
/// will be styled to match the Material Design 3 specification for Input
/// chips.
///
/// See also:
///
///  * [Chip], a chip that displays information and can be deleted.
///  * [ChoiceChip], allows a single selection from a set of options. Choice
///    chips contain related descriptive text or categories.
///  * [FilterChip], uses tags or descriptive words as a way to filter content.
///  * [ActionChip], represents an action related to primary content.
///  * [CircleAvatar], which shows images or initials of people.
///  * [Wrap], A widget that displays its children in multiple horizontal or
///    vertical runs.
///  * <https://material.io/design/components/chips.html>
class InputChip extends StatelessWidget
    implements
        ChipAttributes,
        DeletableChipAttributes,
        SelectableChipAttributes,
        CheckmarkableChipAttributes,
        DisabledChipAttributes,
        TappableChipAttributes {
  /// Creates an [InputChip].
  ///
  /// The [onPressed] and [onSelected] callbacks must not both be specified at
  /// the same time.
  ///
  /// The [label], [isEnabled], [selected], [autofocus], and [clipBehavior]
  /// arguments must not be null. The [pressElevation] and [elevation] must be
  /// null or non-negative. Typically, [pressElevation] is greater than
  /// [elevation].
  const InputChip({
    super.key,
    this.avatar,
    required this.label,
    this.labelStyle,
    this.labelPadding,
    this.selected = false,
    this.isEnabled = true,
    this.onSelected,
    this.deleteIcon,
    this.onDeleted,
    this.deleteIconColor,
    this.deleteButtonTooltipMessage,
    this.onPressed,
    this.pressElevation,
    this.disabledColor,
    this.selectedColor,
    this.tooltip,
    this.side,
    this.shape,
    this.clipBehavior = Clip.none,
    this.focusNode,
    this.autofocus = false,
    this.backgroundColor,
    this.padding,
    this.visualDensity,
    this.materialTapTargetSize,
    this.elevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.iconTheme,
    this.selectedShadowColor,
    this.showCheckmark,
    this.checkmarkColor,
    this.avatarBorder = const CircleBorder(),
    @Deprecated(
      'Migrate to deleteButtonTooltipMessage. '
      'This feature was deprecated after v2.10.0-0.3.pre.'
    )
    this.useDeleteButtonTooltip = true,
  }) : assert(selected != null),
       assert(isEnabled != null),
       assert(label != null),
       assert(clipBehavior != null),
       assert(autofocus != null),
       assert(pressElevation == null || pressElevation >= 0.0),
       assert(elevation == null || elevation >= 0.0);

  @override
  final Widget? avatar;
  @override
  final Widget label;
  @override
  final TextStyle? labelStyle;
  @override
  final EdgeInsetsGeometry? labelPadding;
  @override
  final bool selected;
  @override
  final bool isEnabled;
  @override
  final ValueChanged<bool>? onSelected;
  @override
  final Widget? deleteIcon;
  @override
  final VoidCallback? onDeleted;
  @override
  final Color? deleteIconColor;
  @override
  final String? deleteButtonTooltipMessage;
  @override
  final VoidCallback? onPressed;
  @override
  final double? pressElevation;
  @override
  final Color? disabledColor;
  @override
  final Color? selectedColor;
  @override
  final String? tooltip;
  @override
  final BorderSide? side;
  @override
  final OutlinedBorder? shape;
  @override
  final Clip clipBehavior;
  @override
  final FocusNode? focusNode;
  @override
  final bool autofocus;
  @override
  final Color? backgroundColor;
  @override
  final EdgeInsetsGeometry? padding;
  @override
  final VisualDensity? visualDensity;
  @override
  final MaterialTapTargetSize? materialTapTargetSize;
  @override
  final double? elevation;
  @override
  final Color? shadowColor;
  @override
  final Color? surfaceTintColor;
  @override
  final Color? selectedShadowColor;
  @override
  final bool? showCheckmark;
  @override
  final Color? checkmarkColor;
  @override
  final ShapeBorder avatarBorder;
  @override
  final IconThemeData? iconTheme;
  @override
  @Deprecated(
    'Migrate to deleteButtonTooltipMessage. '
    'This feature was deprecated after v2.10.0-0.3.pre.'
  )
  final bool useDeleteButtonTooltip;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    final ChipThemeData? defaults = Theme.of(context).useMaterial3
      ? _InputChipDefaultsM3(context, isEnabled)
      : null;
    final Widget? resolvedDeleteIcon = deleteIcon
      ?? (Theme.of(context).useMaterial3 ? const Icon(Icons.clear, size: 18) : null);
    return RawChip(
      defaultProperties: defaults,
      avatar: avatar,
      label: label,
      labelStyle: labelStyle,
      labelPadding: labelPadding,
      deleteIcon: resolvedDeleteIcon,
      onDeleted: onDeleted,
      deleteIconColor: deleteIconColor,
      useDeleteButtonTooltip: useDeleteButtonTooltip,
      deleteButtonTooltipMessage: deleteButtonTooltipMessage,
      onSelected: onSelected,
      onPressed: onPressed,
      pressElevation: pressElevation,
      selected: selected,
      disabledColor: disabledColor,
      selectedColor: selectedColor,
      tooltip: tooltip,
      side: side,
      shape: shape,
      clipBehavior: clipBehavior,
      focusNode: focusNode,
      autofocus: autofocus,
      backgroundColor: backgroundColor,
      padding: padding,
      visualDensity: visualDensity,
      materialTapTargetSize: materialTapTargetSize,
      elevation: elevation,
      shadowColor: shadowColor,
      surfaceTintColor: surfaceTintColor,
      selectedShadowColor: selectedShadowColor,
      showCheckmark: showCheckmark,
      checkmarkColor: checkmarkColor,
      isEnabled: isEnabled && (onSelected != null || onDeleted != null || onPressed != null),
      avatarBorder: avatarBorder,
    );
  }
}

// BEGIN GENERATED TOKEN PROPERTIES - InputChip

// Do not edit by hand. The code between the "BEGIN GENERATED" and
// "END GENERATED" comments are generated from data in the Material
// Design token database by the script:
//   dev/tools/gen_defaults/bin/gen_defaults.dart.

// Token database version: v0_101

class _InputChipDefaultsM3 extends ChipThemeData {
  const _InputChipDefaultsM3(this.context, this.isEnabled)
    : super(
        elevation: 0.0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(8.0), topRight: Radius.circular(8.0), bottomLeft: Radius.circular(8.0), bottomRight: Radius.circular(8.0))),
        showCheckmark: true,
      );

  final BuildContext context;
  final bool isEnabled;

  @override
  TextStyle? get labelStyle => Theme.of(context).textTheme.labelLarge;

  @override
  Color? get backgroundColor => null;

  @override
  Color? get shadowColor => null;

  @override
  @override Color? get surfaceTintColor => null;

  @override
  Color? get selectedColor => Theme.of(context).colorScheme.secondaryContainer;

  @override
  Color? get checkmarkColor => null;

  @override
  Color? get disabledColor => null;

  @override
  Color? get deleteIconColor => Theme.of(context).colorScheme.onSecondaryContainer;

  @override
  BorderSide? get side => isEnabled
    ? BorderSide(color: Theme.of(context).colorScheme.outline)
    : BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12));

  @override
  IconThemeData? get iconTheme => IconThemeData(
    color: isEnabled
      ? null
      : Theme.of(context).colorScheme.onSurface,
    size: 18.0,
  );

  @override
  EdgeInsetsGeometry? get padding => const EdgeInsets.all(8.0);

  /// The chip at text scale 1 starts with 8px on each side and as text scaling
  /// gets closer to 2 the label padding is linearly interpolated from 8px to 4px.
  /// Once the widget has a text scaling of 2 or higher than the label padding
  /// remains 4px.
  @override
  EdgeInsetsGeometry? get labelPadding => EdgeInsets.lerp(
    const EdgeInsets.symmetric(horizontal: 8.0),
    const EdgeInsets.symmetric(horizontal: 4.0),
    clampDouble(MediaQuery.of(context).textScaleFactor - 1.0, 0.0, 1.0),
  )!;
}

// END GENERATED TOKEN PROPERTIES - InputChip
