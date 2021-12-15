// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'chip_theme.dart';
import 'colors.dart';
import 'constants.dart';
import 'debug.dart';
import 'icons.dart';
import 'ink_well.dart';
import 'material.dart';
import 'material_localizations.dart';
import 'material_state.dart';
import 'material_state_mixin.dart';
import 'theme.dart';
import 'theme_data.dart';
import 'tooltip.dart';

// Some design constants
const double _kChipHeight = 32.0;
const double _kDeleteIconSize = 18.0;

const int _kCheckmarkAlpha = 0xde; // 87%
const int _kDisabledAlpha = 0x61; // 38%
const double _kCheckmarkStrokeWidth = 2.0;

const Duration _kSelectDuration = Duration(milliseconds: 195);
const Duration _kCheckmarkDuration = Duration(milliseconds: 150);
const Duration _kCheckmarkReverseDuration = Duration(milliseconds: 50);
const Duration _kDrawerDuration = Duration(milliseconds: 150);
const Duration _kReverseDrawerDuration = Duration(milliseconds: 100);
const Duration _kDisableDuration = Duration(milliseconds: 75);

const Color _kSelectScrimColor = Color(0x60191919);
const Icon _kDefaultDeleteIcon = Icon(Icons.cancel, size: _kDeleteIconSize);

/// An interface defining the base attributes for a material design chip.
///
/// Chips are compact elements that represent an attribute, text, entity, or
/// action.
///
/// The defaults mentioned in the documentation for each attribute are what
/// the implementing classes typically use for defaults (but this class doesn't
/// provide or enforce them).
///
/// See also:
///
///  * [Chip], a chip that displays information and can be deleted.
///  * [InputChip], a chip that represents a complex piece of information, such
///    as an entity (person, place, or thing) or conversational text, in a
///    compact form.
///  * [ChoiceChip], allows a single selection from a set of options. Choice
///    chips contain related descriptive text or categories.
///  * [FilterChip], uses tags or descriptive words as a way to filter content.
///  * [ActionChip], represents an action related to primary content.
///  * <https://material.io/design/components/chips.html>
abstract class ChipAttributes {
  // This class is intended to be used as an interface, and should not be
  // extended directly; this constructor prevents instantiation and extension.
  ChipAttributes._();

  /// The primary content of the chip.
  ///
  /// Typically a [Text] widget.
  Widget get label;

  /// A widget to display prior to the chip's label.
  ///
  /// Typically a [CircleAvatar] widget.
  Widget? get avatar;

  /// The style to be applied to the chip's label.
  ///
  /// The default label style is [TextTheme.bodyText1] from the overall
  /// theme's [ThemeData.textTheme].
  //
  /// This only has an effect on widgets that respect the [DefaultTextStyle],
  /// such as [Text].
  ///
  /// If [TextStyle.color] is a [MaterialStateProperty<Color>], [MaterialStateProperty.resolve]
  /// is used for the following [MaterialState]s:
  ///
  ///  * [MaterialState.disabled].
  ///  * [MaterialState.selected].
  ///  * [MaterialState.hovered].
  ///  * [MaterialState.focused].
  ///  * [MaterialState.pressed].
  TextStyle? get labelStyle;

  /// The color and weight of the chip's outline.
  ///
  /// Defaults to the border side in the ambient [ChipThemeData]. If the theme
  /// border side resolves to null, the default is the border side of [shape].
  ///
  /// This value is combined with [shape] to create a shape decorated with an
  /// outline. If it is a [MaterialStateBorderSide],
  /// [MaterialStateProperty.resolve] is used for the following
  /// [MaterialState]s:
  ///
  ///  * [MaterialState.disabled].
  ///  * [MaterialState.selected].
  ///  * [MaterialState.hovered].
  ///  * [MaterialState.focused].
  ///  * [MaterialState.pressed].
  BorderSide? get side;

  /// The [OutlinedBorder] to draw around the chip.
  ///
  /// Defaults to the shape in the ambient [ChipThemeData]. If the theme
  /// shape resolves to null, the default is [StadiumBorder].
  ///
  /// This shape is combined with [side] to create a shape decorated with an
  /// outline. If it is a [MaterialStateOutlinedBorder],
  /// [MaterialStateProperty.resolve] is used for the following
  /// [MaterialState]s:
  ///
  ///  * [MaterialState.disabled].
  ///  * [MaterialState.selected].
  ///  * [MaterialState.hovered].
  ///  * [MaterialState.focused].
  ///  * [MaterialState.pressed].
  OutlinedBorder? get shape;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none], and must not be null.
  Clip get clipBehavior;

  /// {@macro flutter.widgets.Focus.focusNode}
  FocusNode? get focusNode;

  /// {@macro flutter.widgets.Focus.autofocus}
  bool get autofocus;

  /// Color to be used for the unselected, enabled chip's background.
  ///
  /// The default is light grey.
  Color? get backgroundColor;

  /// The padding between the contents of the chip and the outside [shape].
  ///
  /// Defaults to 4 logical pixels on all sides.
  EdgeInsetsGeometry? get padding;

  /// Defines how compact the chip's layout will be.
  ///
  /// Chips are unaffected by horizontal density changes.
  ///
  /// {@macro flutter.material.themedata.visualDensity}
  ///
  /// See also:
  ///
  ///  * [ThemeData.visualDensity], which specifies the [visualDensity] for all
  ///    widgets within a [Theme].
  VisualDensity? get visualDensity;

  /// The padding around the [label] widget.
  ///
  /// By default, this is 4 logical pixels at the beginning and the end of the
  /// label, and zero on top and bottom.
  EdgeInsetsGeometry? get labelPadding;

  /// Configures the minimum size of the tap target.
  ///
  /// Defaults to [ThemeData.materialTapTargetSize].
  ///
  /// See also:
  ///
  ///  * [MaterialTapTargetSize], for a description of how this affects tap targets.
  MaterialTapTargetSize? get materialTapTargetSize;

  /// Elevation to be applied on the chip relative to its parent.
  ///
  /// This controls the size of the shadow below the chip.
  ///
  /// Defaults to 0. The value is always non-negative.
  double? get elevation;

  /// Color of the chip's shadow when the elevation is greater than 0.
  ///
  /// The default is [Colors.black].
  Color? get shadowColor;
}

/// An interface for material design chips that can be deleted.
///
/// The defaults mentioned in the documentation for each attribute are what
/// the implementing classes typically use for defaults (but this class doesn't
/// provide or enforce them).
///
/// See also:
///
///  * [Chip], a chip that displays information and can be deleted.
///  * [InputChip], a chip that represents a complex piece of information, such
///    as an entity (person, place, or thing) or conversational text, in a
///    compact form.
///  * <https://material.io/design/components/chips.html>
abstract class DeletableChipAttributes {
  // This class is intended to be used as an interface, and should not be
  // extended directly; this constructor prevents instantiation and extension.
  DeletableChipAttributes._();

  /// The icon displayed when [onDeleted] is set.
  ///
  /// Defaults to an [Icon] widget set to use [Icons.cancel].
  Widget? get deleteIcon;

  /// Called when the user taps the [deleteIcon] to delete the chip.
  ///
  /// If null, the delete button will not appear on the chip.
  ///
  /// The chip will not automatically remove itself: this just tells the app
  /// that the user tapped the delete button. In order to delete the chip, you
  /// have to do something similar to the following sample:
  ///
  /// {@tool dartpad}
  /// This sample shows how to use [onDeleted] to remove an entry when the
  /// delete button is tapped.
  ///
  /// ** See code in examples/api/lib/material/chip/deletable_chip_attributes.on_deleted.0.dart **
  /// {@end-tool}
  VoidCallback? get onDeleted;

  /// Used to define the delete icon's color with an [IconTheme] that
  /// contains the icon.
  ///
  /// The default is `Color(0xde000000)`
  /// (slightly transparent black) for light themes, and `Color(0xdeffffff)`
  /// (slightly transparent white) for dark themes.
  ///
  /// The delete icon appears if [DeletableChipAttributes.onDeleted] is
  /// non-null.
  Color? get deleteIconColor;

  /// Whether to use a tooltip on the chip's delete button showing the
  /// [deleteButtonTooltipMessage].
  ///
  /// Must not be null. Defaults to true.
  bool get useDeleteButtonTooltip;

  /// The message to be used for the chip's delete button tooltip.
  ///
  /// This will be shown only if [useDeleteButtonTooltip] is true.
  ///
  /// If not specified, the default [MaterialLocalizations.deleteButtonTooltip] will
  /// be used.
  String? get deleteButtonTooltipMessage;
}

/// An interface for material design chips that can have check marks.
///
/// The defaults mentioned in the documentation for each attribute are what
/// the implementing classes typically use for defaults (but this class doesn't
/// provide or enforce them).
///
/// See also:
///
///  * [InputChip], a chip that represents a complex piece of information, such
///    as an entity (person, place, or thing) or conversational text, in a
///    compact form.
///  * [FilterChip], uses tags or descriptive words as a way to filter content.
///  * <https://material.io/design/components/chips.html>
abstract class CheckmarkableChipAttributes {
  // This class is intended to be used as an interface, and should not be
  // extended directly; this constructor prevents instantiation and extension.
  CheckmarkableChipAttributes._();

  /// Whether or not to show a check mark when
  /// [SelectableChipAttributes.selected] is true.
  ///
  /// Defaults to true.
  bool? get showCheckmark;

  /// [Color] of the chip's check mark when a check mark is visible.
  ///
  /// This will override the color set by the platform's brightness setting.
  ///
  /// If null, it will defer to a color selected by the platform's brightness
  /// setting.
  Color? get checkmarkColor;
}

/// An interface for material design chips that can be selected.
///
/// The defaults mentioned in the documentation for each attribute are what
/// the implementing classes typically use for defaults (but this class doesn't
/// provide or enforce them).
///
/// See also:
///
///  * [InputChip], a chip that represents a complex piece of information, such
///    as an entity (person, place, or thing) or conversational text, in a
///    compact form.
///  * [ChoiceChip], allows a single selection from a set of options. Choice
///    chips contain related descriptive text or categories.
///  * [FilterChip], uses tags or descriptive words as a way to filter content.
///  * <https://material.io/design/components/chips.html>
abstract class SelectableChipAttributes {
  // This class is intended to be used as an interface, and should not be
  // extended directly; this constructor prevents instantiation and extension.
  SelectableChipAttributes._();

  /// Whether or not this chip is selected.
  ///
  /// If [onSelected] is not null, this value will be used to determine if the
  /// select check mark will be shown or not.
  ///
  /// Must not be null. Defaults to false.
  bool get selected;

  /// Called when the chip should change between selected and de-selected
  /// states.
  ///
  /// When the chip is tapped, then the [onSelected] callback, if set, will be
  /// applied to `!selected` (see [selected]).
  ///
  /// The chip passes the new value to the callback but does not actually
  /// change state until the parent widget rebuilds the chip with the new
  /// value.
  ///
  /// The callback provided to [onSelected] should update the state of the
  /// parent [StatefulWidget] using the [State.setState] method, so that the
  /// parent gets rebuilt.
  ///
  /// The [onSelected] and [TappableChipAttributes.onPressed] callbacks must not
  /// both be specified at the same time.
  ///
  /// {@tool snippet}
  ///
  /// A [StatefulWidget] that illustrates use of onSelected in an [InputChip].
  ///
  /// ```dart
  /// class Wood extends StatefulWidget {
  ///   const Wood({Key? key}) : super(key: key);
  ///
  ///   @override
  ///   State<StatefulWidget> createState() => WoodState();
  /// }
  ///
  /// class WoodState extends State<Wood> {
  ///   bool _useChisel = false;
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     return InputChip(
  ///       label: const Text('Use Chisel'),
  ///       selected: _useChisel,
  ///       onSelected: (bool newValue) {
  ///         setState(() {
  ///           _useChisel = newValue;
  ///         });
  ///       },
  ///     );
  ///   }
  /// }
  /// ```
  /// {@end-tool}
  ValueChanged<bool>? get onSelected;

  /// Elevation to be applied on the chip relative to its parent during the
  /// press motion.
  ///
  /// This controls the size of the shadow below the chip.
  ///
  /// Defaults to 8. The value is always non-negative.
  double? get pressElevation;

  /// Color to be used for the chip's background, indicating that it is
  /// selected.
  ///
  /// The chip is selected when [selected] is true.
  Color? get selectedColor;

  /// Color of the chip's shadow when the elevation is greater than 0 and the
  /// chip is selected.
  ///
  /// The default is [Colors.black].
  Color? get selectedShadowColor;

  /// Tooltip string to be used for the body area (where the label and avatar
  /// are) of the chip.
  String? get tooltip;

  /// The shape of the translucent highlight painted over the avatar when the
  /// [selected] property is true.
  ///
  /// Only the outer path of the shape is used.
  ///
  /// Defaults to [CircleBorder].
  ShapeBorder get avatarBorder;
}

/// An interface for material design chips that can be enabled and disabled.
///
/// The defaults mentioned in the documentation for each attribute are what
/// the implementing classes typically use for defaults (but this class doesn't
/// provide or enforce them).
///
/// See also:
///
///  * [InputChip], a chip that represents a complex piece of information, such
///    as an entity (person, place, or thing) or conversational text, in a
///    compact form.
///  * [ChoiceChip], allows a single selection from a set of options. Choice
///    chips contain related descriptive text or categories.
///  * [FilterChip], uses tags or descriptive words as a way to filter content.
///  * <https://material.io/design/components/chips.html>
abstract class DisabledChipAttributes {
  // This class is intended to be used as an interface, and should not be
  // extended directly; this constructor prevents instantiation and extension.
  DisabledChipAttributes._();

  /// Whether or not this chip is enabled for input.
  ///
  /// If this is true, but all of the user action callbacks are null (i.e.
  /// [SelectableChipAttributes.onSelected], [TappableChipAttributes.onPressed],
  /// and [DeletableChipAttributes.onDeleted]), then the
  /// control will still be shown as disabled.
  ///
  /// This is typically used if you want the chip to be disabled, but also show
  /// a delete button.
  ///
  /// For classes which don't have this as a constructor argument, [isEnabled]
  /// returns true if their user action callback is set.
  ///
  /// Defaults to true. Cannot be null.
  bool get isEnabled;

  /// The color used for the chip's background to indicate that it is not
  /// enabled.
  ///
  /// The chip is disabled when [isEnabled] is false, or all three of
  /// [SelectableChipAttributes.onSelected], [TappableChipAttributes.onPressed],
  /// and [DeletableChipAttributes.onDeleted] are null.
  ///
  /// It defaults to [Colors.black38].
  Color? get disabledColor;
}

/// An interface for material design chips that can be tapped.
///
/// The defaults mentioned in the documentation for each attribute are what
/// the implementing classes typically use for defaults (but this class doesn't
/// provide or enforce them).
///
/// See also:
///
///  * [InputChip], a chip that represents a complex piece of information, such
///    as an entity (person, place, or thing) or conversational text, in a
///    compact form.
///  * [ChoiceChip], allows a single selection from a set of options. Choice
///    chips contain related descriptive text or categories.
///  * [FilterChip], uses tags or descriptive words as a way to filter content.
///  * [ActionChip], represents an action related to primary content.
///  * <https://material.io/design/components/chips.html>
abstract class TappableChipAttributes {
  // This class is intended to be used as an interface, and should not be
  // extended directly; this constructor prevents instantiation and extension.
  TappableChipAttributes._();

  /// Called when the user taps the chip.
  ///
  /// If [onPressed] is set, then this callback will be called when the user
  /// taps on the label or avatar parts of the chip. If [onPressed] is null,
  /// then the chip will be disabled.
  ///
  /// {@tool snippet}
  ///
  /// ```dart
  /// class Blacksmith extends StatelessWidget {
  ///   const Blacksmith({Key? key}) : super(key: key);
  ///
  ///   void startHammering() {
  ///     print('bang bang bang');
  ///   }
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     return InputChip(
  ///       label: const Text('Apply Hammer'),
  ///       onPressed: startHammering,
  ///     );
  ///   }
  /// }
  /// ```
  /// {@end-tool}
  VoidCallback? get onPressed;

  /// Elevation to be applied on the chip relative to its parent during the
  /// press motion.
  ///
  /// This controls the size of the shadow below the chip.
  ///
  /// Defaults to 8. The value is always non-negative.
  double? get pressElevation;

  /// Tooltip string to be used for the body area (where the label and avatar
  /// are) of the chip.
  String? get tooltip;
}

/// A material design chip.
///
/// Chips are compact elements that represent an attribute, text, entity, or
/// action.
///
/// Supplying a non-null [onDeleted] callback will cause the chip to include a
/// button for deleting the chip.
///
/// Its ancestors must include [Material], [MediaQuery], [Directionality], and
/// [MaterialLocalizations]. Typically all of these widgets are provided by
/// [MaterialApp] and [Scaffold]. The [label] and [clipBehavior] arguments must
/// not be null.
///
/// {@tool snippet}
///
/// ```dart
/// Chip(
///   avatar: CircleAvatar(
///     backgroundColor: Colors.grey.shade800,
///     child: const Text('AB'),
///   ),
///   label: const Text('Aaron Burr'),
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [InputChip], a chip that represents a complex piece of information, such
///    as an entity (person, place, or thing) or conversational text, in a
///    compact form.
///  * [ChoiceChip], allows a single selection from a set of options. Choice
///    chips contain related descriptive text or categories.
///  * [FilterChip], uses tags or descriptive words as a way to filter content.
///  * [ActionChip], represents an action related to primary content.
///  * [CircleAvatar], which shows images or initials of entities.
///  * [Wrap], A widget that displays its children in multiple horizontal or
///    vertical runs.
///  * <https://material.io/design/components/chips.html>
class Chip extends StatelessWidget implements ChipAttributes, DeletableChipAttributes {
  /// Creates a material design chip.
  ///
  /// The [label], [autofocus], and [clipBehavior] arguments must not be null.
  /// The [elevation] must be null or non-negative.
  const Chip({
    Key? key,
    this.avatar,
    required this.label,
    this.labelStyle,
    this.labelPadding,
    this.deleteIcon,
    this.onDeleted,
    this.deleteIconColor,
    this.useDeleteButtonTooltip = true,
    this.deleteButtonTooltipMessage,
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
  }) : assert(label != null),
       assert(autofocus != null),
       assert(clipBehavior != null),
       assert(elevation == null || elevation >= 0.0),
       assert(useDeleteButtonTooltip != null),
       super(key: key);

  @override
  final Widget? avatar;
  @override
  final Widget label;
  @override
  final TextStyle? labelStyle;
  @override
  final EdgeInsetsGeometry? labelPadding;
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
  final Widget? deleteIcon;
  @override
  final VoidCallback? onDeleted;
  @override
  final Color? deleteIconColor;
  @override
  final bool useDeleteButtonTooltip;
  @override
  final String? deleteButtonTooltipMessage;
  @override
  final MaterialTapTargetSize? materialTapTargetSize;
  @override
  final double? elevation;
  @override
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    return RawChip(
      avatar: avatar,
      label: label,
      labelStyle: labelStyle,
      labelPadding: labelPadding,
      deleteIcon: deleteIcon,
      onDeleted: onDeleted,
      deleteIconColor: deleteIconColor,
      useDeleteButtonTooltip: useDeleteButtonTooltip,
      deleteButtonTooltipMessage: deleteButtonTooltipMessage,
      tapEnabled: false,
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
    );
  }
}

/// A material design input chip.
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
    Key? key,
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
    this.useDeleteButtonTooltip = true,
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
    this.selectedShadowColor,
    this.showCheckmark,
    this.checkmarkColor,
    this.avatarBorder = const CircleBorder(),
  }) : assert(selected != null),
       assert(isEnabled != null),
       assert(label != null),
       assert(clipBehavior != null),
       assert(autofocus != null),
       assert(pressElevation == null || pressElevation >= 0.0),
       assert(elevation == null || elevation >= 0.0),
       assert(useDeleteButtonTooltip != null),
       super(key: key);

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
  final bool useDeleteButtonTooltip;
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
  final Color? selectedShadowColor;
  @override
  final bool? showCheckmark;
  @override
  final Color? checkmarkColor;
  @override
  final ShapeBorder avatarBorder;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    return RawChip(
      avatar: avatar,
      label: label,
      labelStyle: labelStyle,
      labelPadding: labelPadding,
      deleteIcon: deleteIcon,
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
      selectedShadowColor: selectedShadowColor,
      showCheckmark: showCheckmark,
      checkmarkColor: checkmarkColor,
      isEnabled: isEnabled && (onSelected != null || onDeleted != null || onPressed != null),
      avatarBorder: avatarBorder,
    );
  }
}

/// A material design choice chip.
///
/// [ChoiceChip]s represent a single choice from a set. Choice chips contain
/// related descriptive text or categories.
///
/// Requires one of its ancestors to be a [Material] widget. The [selected] and
/// [label] arguments must not be null.
///
/// {@tool snippet}
///
/// ```dart
/// class MyThreeOptions extends StatefulWidget {
///   const MyThreeOptions({Key? key}) : super(key: key);
///
///   @override
///   State<MyThreeOptions> createState() => _MyThreeOptionsState();
/// }
///
/// class _MyThreeOptionsState extends State<MyThreeOptions> {
///   int? _value = 1;
///
///   @override
///   Widget build(BuildContext context) {
///     return Wrap(
///       children: List<Widget>.generate(
///         3,
///         (int index) {
///           return ChoiceChip(
///             label: Text('Item $index'),
///             selected: _value == index,
///             onSelected: (bool selected) {
///               setState(() {
///                 _value = selected ? index : null;
///               });
///             },
///           );
///         },
///       ).toList(),
///     );
///   }
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [Chip], a chip that displays information and can be deleted.
///  * [InputChip], a chip that represents a complex piece of information, such
///    as an entity (person, place, or thing) or conversational text, in a
///    compact form.
///  * [FilterChip], uses tags or descriptive words as a way to filter content.
///  * [ActionChip], represents an action related to primary content.
///  * [CircleAvatar], which shows images or initials of people.
///  * [Wrap], A widget that displays its children in multiple horizontal or
///    vertical runs.
///  * <https://material.io/design/components/chips.html>
class ChoiceChip extends StatelessWidget
    implements
        ChipAttributes,
        SelectableChipAttributes,
        DisabledChipAttributes {
  /// Create a chip that acts like a radio button.
  ///
  /// The [label], [selected], [autofocus], and [clipBehavior] arguments must
  /// not be null. The [pressElevation] and [elevation] must be null or
  /// non-negative. Typically, [pressElevation] is greater than [elevation].
  const ChoiceChip({
    Key? key,
    this.avatar,
    required this.label,
    this.labelStyle,
    this.labelPadding,
    this.onSelected,
    this.pressElevation,
    required this.selected,
    this.selectedColor,
    this.disabledColor,
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
    this.selectedShadowColor,
    this.avatarBorder = const CircleBorder(),
  }) : assert(selected != null),
       assert(label != null),
       assert(clipBehavior != null),
       assert(autofocus != null),
       assert(pressElevation == null || pressElevation >= 0.0),
       assert(elevation == null || elevation >= 0.0),
       super(key: key);

  @override
  final Widget? avatar;
  @override
  final Widget label;
  @override
  final TextStyle? labelStyle;
  @override
  final EdgeInsetsGeometry? labelPadding;
  @override
  final ValueChanged<bool>? onSelected;
  @override
  final double? pressElevation;
  @override
  final bool selected;
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
  final Color? selectedShadowColor;
  @override
  final ShapeBorder avatarBorder;

  @override
  bool get isEnabled => onSelected != null;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    final ChipThemeData chipTheme = ChipTheme.of(context);
    return RawChip(
      avatar: avatar,
      label: label,
      labelStyle: labelStyle ?? (selected ? chipTheme.secondaryLabelStyle : null),
      labelPadding: labelPadding,
      onSelected: onSelected,
      pressElevation: pressElevation,
      selected: selected,
      showCheckmark: false,
      tooltip: tooltip,
      side: side,
      shape: shape,
      clipBehavior: clipBehavior,
      focusNode: focusNode,
      autofocus: autofocus,
      disabledColor: disabledColor,
      selectedColor: selectedColor ?? chipTheme.secondarySelectedColor,
      backgroundColor: backgroundColor,
      padding: padding,
      visualDensity: visualDensity,
      isEnabled: isEnabled,
      materialTapTargetSize: materialTapTargetSize,
      elevation: elevation,
      shadowColor: shadowColor,
      selectedShadowColor: selectedShadowColor,
      avatarBorder: avatarBorder,
    );
  }
}

/// A material design filter chip.
///
/// Filter chips use tags or descriptive words as a way to filter content.
///
/// Filter chips are a good alternative to [Checkbox] or [Switch] widgets.
/// Unlike these alternatives, filter chips allow for clearly delineated and
/// exposed options in a compact area.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// {@tool snippet}
///
/// ```dart
/// class ActorFilterEntry {
///   const ActorFilterEntry(this.name, this.initials);
///   final String name;
///   final String initials;
/// }
///
/// class CastFilter extends StatefulWidget {
///   const CastFilter({Key? key}) : super(key: key);
///
///   @override
///   State createState() => CastFilterState();
/// }
///
/// class CastFilterState extends State<CastFilter> {
///   final List<ActorFilterEntry> _cast = <ActorFilterEntry>[
///     const ActorFilterEntry('Aaron Burr', 'AB'),
///     const ActorFilterEntry('Alexander Hamilton', 'AH'),
///     const ActorFilterEntry('Eliza Hamilton', 'EH'),
///     const ActorFilterEntry('James Madison', 'JM'),
///   ];
///   final List<String> _filters = <String>[];
///
///   Iterable<Widget> get actorWidgets {
///     return _cast.map((ActorFilterEntry actor) {
///       return Padding(
///         padding: const EdgeInsets.all(4.0),
///         child: FilterChip(
///           avatar: CircleAvatar(child: Text(actor.initials)),
///           label: Text(actor.name),
///           selected: _filters.contains(actor.name),
///           onSelected: (bool value) {
///             setState(() {
///               if (value) {
///                 _filters.add(actor.name);
///               } else {
///                 _filters.removeWhere((String name) {
///                   return name == actor.name;
///                 });
///               }
///             });
///           },
///         ),
///       );
///     });
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Column(
///       mainAxisAlignment: MainAxisAlignment.center,
///       children: <Widget>[
///         Wrap(
///           children: actorWidgets.toList(),
///         ),
///         Text('Look for: ${_filters.join(', ')}'),
///       ],
///     );
///   }
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [Chip], a chip that displays information and can be deleted.
///  * [InputChip], a chip that represents a complex piece of information, such
///    as an entity (person, place, or thing) or conversational text, in a
///    compact form.
///  * [ChoiceChip], allows a single selection from a set of options. Choice
///    chips contain related descriptive text or categories.
///  * [ActionChip], represents an action related to primary content.
///  * [CircleAvatar], which shows images or initials of people.
///  * [Wrap], A widget that displays its children in multiple horizontal or
///    vertical runs.
///  * <https://material.io/design/components/chips.html>
class FilterChip extends StatelessWidget
    implements
        ChipAttributes,
        SelectableChipAttributes,
        CheckmarkableChipAttributes,
        DisabledChipAttributes {
  /// Create a chip that acts like a checkbox.
  ///
  /// The [selected], [label], [autofocus], and [clipBehavior] arguments must
  /// not be null. The [pressElevation] and [elevation] must be null or
  /// non-negative. Typically, [pressElevation] is greater than [elevation].
  const FilterChip({
    Key? key,
    this.avatar,
    required this.label,
    this.labelStyle,
    this.labelPadding,
    this.selected = false,
    required this.onSelected,
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
    this.selectedShadowColor,
    this.showCheckmark,
    this.checkmarkColor,
    this.avatarBorder = const CircleBorder(),
  }) : assert(selected != null),
       assert(label != null),
       assert(clipBehavior != null),
       assert(autofocus != null),
       assert(pressElevation == null || pressElevation >= 0.0),
       assert(elevation == null || elevation >= 0.0),
       super(key: key);

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
  final ValueChanged<bool>? onSelected;
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
  final Color? selectedShadowColor;
  @override
  final bool? showCheckmark;
  @override
  final Color? checkmarkColor;
  @override
  final ShapeBorder avatarBorder;

  @override
  bool get isEnabled => onSelected != null;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    return RawChip(
      avatar: avatar,
      label: label,
      labelStyle: labelStyle,
      labelPadding: labelPadding,
      onSelected: onSelected,
      pressElevation: pressElevation,
      selected: selected,
      tooltip: tooltip,
      side: side,
      shape: shape,
      clipBehavior: clipBehavior,
      focusNode: focusNode,
      autofocus: autofocus,
      backgroundColor: backgroundColor,
      disabledColor: disabledColor,
      selectedColor: selectedColor,
      padding: padding,
      visualDensity: visualDensity,
      isEnabled: isEnabled,
      materialTapTargetSize: materialTapTargetSize,
      elevation: elevation,
      shadowColor: shadowColor,
      selectedShadowColor: selectedShadowColor,
      showCheckmark: showCheckmark,
      checkmarkColor: checkmarkColor,
      avatarBorder: avatarBorder,
    );
  }
}

/// A material design action chip.
///
/// Action chips are a set of options which trigger an action related to primary
/// content. Action chips should appear dynamically and contextually in a UI.
///
/// Action chips can be tapped to trigger an action or show progress and
/// confirmation. They cannot be disabled; if the action is not applicable, the
/// chip should not be included in the interface. (This contrasts with buttons,
/// where unavailable choices are usually represented as disabled controls.)
///
/// Action chips are displayed after primary content, such as below a card or
/// persistently at the bottom of a screen.
///
/// The material button widgets, [ElevatedButton], [TextButton], and
/// [OutlinedButton], are an alternative to action chips, which should appear
/// statically and consistently in a UI.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// {@tool snippet}
///
/// ```dart
/// ActionChip(
///   avatar: CircleAvatar(
///     backgroundColor: Colors.grey.shade800,
///     child: const Text('AB'),
///   ),
///   label: const Text('Aaron Burr'),
///   onPressed: () {
///     print('If you stand for nothing, Burr, what’ll you fall for?');
///   }
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [Chip], a chip that displays information and can be deleted.
///  * [InputChip], a chip that represents a complex piece of information, such
///    as an entity (person, place, or thing) or conversational text, in a
///    compact form.
///  * [ChoiceChip], allows a single selection from a set of options. Choice
///    chips contain related descriptive text or categories.
///  * [CircleAvatar], which shows images or initials of people.
///  * [Wrap], A widget that displays its children in multiple horizontal or
///    vertical runs.
///  * <https://material.io/design/components/chips.html>
class ActionChip extends StatelessWidget implements ChipAttributes, TappableChipAttributes {
  /// Create a chip that acts like a button.
  ///
  /// The [label], [onPressed], [autofocus], and [clipBehavior] arguments must
  /// not be null. The [pressElevation] and [elevation] must be null or
  /// non-negative. Typically, [pressElevation] is greater than [elevation].
  const ActionChip({
    Key? key,
    this.avatar,
    required this.label,
    this.labelStyle,
    this.labelPadding,
    required this.onPressed,
    this.pressElevation,
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
  }) : assert(label != null),
       assert(clipBehavior != null),
       assert(autofocus != null),
       assert(
         onPressed != null,
         'Rather than disabling an ActionChip by setting onPressed to null, '
         'remove it from the interface entirely.',
       ),
       assert(pressElevation == null || pressElevation >= 0.0),
       assert(elevation == null || elevation >= 0.0),
       super(key: key);

  @override
  final Widget? avatar;
  @override
  final Widget label;
  @override
  final TextStyle? labelStyle;
  @override
  final EdgeInsetsGeometry? labelPadding;
  @override
  final VoidCallback onPressed;
  @override
  final double? pressElevation;
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
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    return RawChip(
      avatar: avatar,
      label: label,
      onPressed: onPressed,
      pressElevation: pressElevation,
      tooltip: tooltip,
      labelStyle: labelStyle,
      backgroundColor: backgroundColor,
      side: side,
      shape: shape,
      clipBehavior: clipBehavior,
      focusNode: focusNode,
      autofocus: autofocus,
      padding: padding,
      visualDensity: visualDensity,
      labelPadding: labelPadding,
      materialTapTargetSize: materialTapTargetSize,
      elevation: elevation,
      shadowColor: shadowColor,
    );
  }
}

/// A raw material design chip.
///
/// This serves as the basis for all of the chip widget types to aggregate.
/// It is typically not created directly, one of the other chip types
/// that are appropriate for the use case are used instead:
///
///  * [Chip] a simple chip that can only display information and be deleted.
///  * [InputChip] represents a complex piece of information, such as an entity
///    (person, place, or thing) or conversational text, in a compact form.
///  * [ChoiceChip] allows a single selection from a set of options.
///  * [FilterChip] a chip that uses tags or descriptive words as a way to
///    filter content.
///  * [ActionChip]s display a set of actions related to primary content.
///
/// Raw chips are typically only used if you want to create your own custom chip
/// type.
///
/// Raw chips can be selected by setting [onSelected], deleted by setting
/// [onDeleted], and pushed like a button with [onPressed]. They have a [label],
/// and they can have a leading icon (see [avatar]) and a trailing icon
/// ([deleteIcon]). Colors and padding can be customized.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// See also:
///
///  * [CircleAvatar], which shows images or initials of people.
///  * [Wrap], A widget that displays its children in multiple horizontal or
///    vertical runs.
///  * <https://material.io/design/components/chips.html>
class RawChip extends StatefulWidget
    implements
        ChipAttributes,
        DeletableChipAttributes,
        SelectableChipAttributes,
        CheckmarkableChipAttributes,
        DisabledChipAttributes,
        TappableChipAttributes {
  /// Creates a RawChip.
  ///
  /// The [onPressed] and [onSelected] callbacks must not both be specified at
  /// the same time.
  ///
  /// The [label], [isEnabled], [selected], [autofocus], and [clipBehavior]
  /// arguments must not be null. The [pressElevation] and [elevation] must be
  /// null or non-negative. Typically, [pressElevation] is greater than
  /// [elevation].
  const RawChip({
    Key? key,
    this.avatar,
    required this.label,
    this.labelStyle,
    this.padding,
    this.visualDensity,
    this.labelPadding,
    Widget? deleteIcon,
    this.onDeleted,
    this.deleteIconColor,
    this.useDeleteButtonTooltip = true,
    this.deleteButtonTooltipMessage,
    this.onPressed,
    this.onSelected,
    this.pressElevation,
    this.tapEnabled = true,
    this.selected = false,
    this.isEnabled = true,
    this.disabledColor,
    this.selectedColor,
    this.tooltip,
    this.side,
    this.shape,
    this.clipBehavior = Clip.none,
    this.focusNode,
    this.autofocus = false,
    this.backgroundColor,
    this.materialTapTargetSize,
    this.elevation,
    this.shadowColor,
    this.selectedShadowColor,
    this.showCheckmark = true,
    this.checkmarkColor,
    this.avatarBorder = const CircleBorder(),
  }) : assert(label != null),
       assert(isEnabled != null),
       assert(selected != null),
       assert(clipBehavior != null),
       assert(autofocus != null),
       assert(pressElevation == null || pressElevation >= 0.0),
       assert(elevation == null || elevation >= 0.0),
       assert(useDeleteButtonTooltip != null),
       deleteIcon = deleteIcon ?? _kDefaultDeleteIcon,
       super(key: key);

  @override
  final Widget? avatar;
  @override
  final Widget label;
  @override
  final TextStyle? labelStyle;
  @override
  final EdgeInsetsGeometry? labelPadding;
  @override
  final Widget deleteIcon;
  @override
  final VoidCallback? onDeleted;
  @override
  final Color? deleteIconColor;
  @override
  final bool useDeleteButtonTooltip;
  @override
  final String? deleteButtonTooltipMessage;
  @override
  final ValueChanged<bool>? onSelected;
  @override
  final VoidCallback? onPressed;
  @override
  final double? pressElevation;
  @override
  final bool selected;
  @override
  final bool isEnabled;
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
  final Color? selectedShadowColor;
  @override
  final bool? showCheckmark;
  @override
  final Color? checkmarkColor;
  @override
  final ShapeBorder avatarBorder;

  /// If set, this indicates that the chip should be disabled if all of the
  /// tap callbacks ([onSelected], [onPressed]) are null.
  ///
  /// For example, the [Chip] class sets this to false because it can't be
  /// disabled, even if no callbacks are set on it, since it is used for
  /// displaying information only.
  ///
  /// Defaults to true.
  final bool tapEnabled;

  @override
  State<RawChip> createState() => _RawChipState();
}

class _RawChipState extends State<RawChip> with MaterialStateMixin, TickerProviderStateMixin<RawChip> {
  static const Duration pressedAnimationDuration = Duration(milliseconds: 75);

  late AnimationController selectController;
  late AnimationController avatarDrawerController;
  late AnimationController deleteDrawerController;
  late AnimationController enableController;
  late Animation<double> checkmarkAnimation;
  late Animation<double> avatarDrawerAnimation;
  late Animation<double> deleteDrawerAnimation;
  late Animation<double> enableAnimation;
  late Animation<double> selectionFade;

  bool get hasDeleteButton => widget.onDeleted != null;
  bool get hasAvatar => widget.avatar != null;

  bool get canTap {
    return widget.isEnabled
        && widget.tapEnabled
        && (widget.onPressed != null || widget.onSelected != null);
  }

  bool _isTapping = false;
  bool get isTapping => canTap && _isTapping;

  @override
  void initState() {
    assert(widget.onSelected == null || widget.onPressed == null);
    super.initState();
    setMaterialState(MaterialState.disabled, !widget.isEnabled);
    setMaterialState(MaterialState.selected, widget.selected);
    selectController = AnimationController(
      duration: _kSelectDuration,
      value: widget.selected == true ? 1.0 : 0.0,
      vsync: this,
    );
    selectionFade = CurvedAnimation(
      parent: selectController,
      curve: Curves.fastOutSlowIn,
    );
    avatarDrawerController = AnimationController(
      duration: _kDrawerDuration,
      value: hasAvatar || widget.selected == true ? 1.0 : 0.0,
      vsync: this,
    );
    deleteDrawerController = AnimationController(
      duration: _kDrawerDuration,
      value: hasDeleteButton ? 1.0 : 0.0,
      vsync: this,
    );
    enableController = AnimationController(
      duration: _kDisableDuration,
      value: widget.isEnabled ? 1.0 : 0.0,
      vsync: this,
    );

    // These will delay the start of some animations, and/or reduce their
    // length compared to the overall select animation, using Intervals.
    final double checkmarkPercentage = _kCheckmarkDuration.inMilliseconds /
        _kSelectDuration.inMilliseconds;
    final double checkmarkReversePercentage = _kCheckmarkReverseDuration.inMilliseconds /
        _kSelectDuration.inMilliseconds;
    final double avatarDrawerReversePercentage = _kReverseDrawerDuration.inMilliseconds /
        _kSelectDuration.inMilliseconds;
    checkmarkAnimation = CurvedAnimation(
      parent: selectController,
      curve: Interval(1.0 - checkmarkPercentage, 1.0, curve: Curves.fastOutSlowIn),
      reverseCurve: Interval(
        1.0 - checkmarkReversePercentage,
        1.0,
        curve: Curves.fastOutSlowIn,
      ),
    );
    deleteDrawerAnimation = CurvedAnimation(
      parent: deleteDrawerController,
      curve: Curves.fastOutSlowIn,
    );
    avatarDrawerAnimation = CurvedAnimation(
      parent: avatarDrawerController,
      curve: Curves.fastOutSlowIn,
      reverseCurve: Interval(
        1.0 - avatarDrawerReversePercentage,
        1.0,
        curve: Curves.fastOutSlowIn,
      ),
    );
    enableAnimation = CurvedAnimation(
      parent: enableController,
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  void dispose() {
    selectController.dispose();
    avatarDrawerController.dispose();
    deleteDrawerController.dispose();
    enableController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!canTap) {
      return;
    }
    setMaterialState(MaterialState.pressed, true);
    setState(() {
      _isTapping = true;
    });
  }

  void _handleTapCancel() {
    if (!canTap) {
      return;
    }
    setMaterialState(MaterialState.pressed, false);
    setState(() {
      _isTapping = false;
    });
  }

  void _handleTap() {
    if (!canTap) {
      return;
    }
    setMaterialState(MaterialState.pressed, false);
    setState(() {
      _isTapping = false;
    });
    // Only one of these can be set, so only one will be called.
    widget.onSelected?.call(!widget.selected);
    widget.onPressed?.call();
  }

  OutlinedBorder _getShape(ThemeData theme, ChipThemeData chipTheme, ChipThemeData chipDefaults) {
    final BorderSide? resolvedSide = MaterialStateProperty.resolveAs<BorderSide?>(widget.side, materialStates)
      ?? MaterialStateProperty.resolveAs<BorderSide?>(chipTheme.side, materialStates)
      ?? MaterialStateProperty.resolveAs<BorderSide?>(chipDefaults.side, materialStates);
    final OutlinedBorder resolvedShape = MaterialStateProperty.resolveAs<OutlinedBorder?>(widget.shape, materialStates)
      ?? MaterialStateProperty.resolveAs<OutlinedBorder?>(chipTheme.shape, materialStates)
      ?? MaterialStateProperty.resolveAs<OutlinedBorder?>(chipDefaults.shape, materialStates)
      ?? const StadiumBorder();
    return resolvedShape.copyWith(side: resolvedSide);
  }

  /// Picks between three different colors, depending upon the state of two
  /// different animations.
  Color? _getBackgroundColor(ThemeData theme, ChipThemeData chipTheme, ChipThemeData chipDefaults) {
    final ColorTween backgroundTween = ColorTween(
      begin: widget.disabledColor
        ?? chipTheme.disabledColor
        ?? theme.disabledColor,
      end: widget.backgroundColor
        ?? chipTheme.backgroundColor
        ?? theme.chipTheme.backgroundColor
        ?? chipDefaults.backgroundColor,
    );
    final ColorTween selectTween = ColorTween(
      begin: backgroundTween.evaluate(enableController),
      end: widget.selectedColor
        ?? chipTheme.selectedColor
        ?? theme.chipTheme.selectedColor
        ?? chipDefaults.selectedColor,
    );
    return selectTween.evaluate(selectionFade);
  }

  @override
  void didUpdateWidget(RawChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isEnabled != widget.isEnabled) {
      setState(() {
        setMaterialState(MaterialState.disabled, !widget.isEnabled);
        if (widget.isEnabled) {
          enableController.forward();
        } else {
          enableController.reverse();
        }
      });
    }
    if (oldWidget.avatar != widget.avatar || oldWidget.selected != widget.selected) {
      setState(() {
        if (hasAvatar || widget.selected == true) {
          avatarDrawerController.forward();
        } else {
          avatarDrawerController.reverse();
        }
      });
    }
    if (oldWidget.selected != widget.selected) {
      setState(() {
        setMaterialState(MaterialState.selected, widget.selected);
        if (widget.selected == true) {
          selectController.forward();
        } else {
          selectController.reverse();
        }
      });
    }
    if (oldWidget.onDeleted != widget.onDeleted) {
      setState(() {
        if (hasDeleteButton) {
          deleteDrawerController.forward();
        } else {
          deleteDrawerController.reverse();
        }
      });
    }
  }

  Widget? _wrapWithTooltip({String? tooltip, bool enabled = true, Widget? child}) {
    if (child == null || !enabled || tooltip == null) {
      return child;
    }
    return Tooltip(
      message: tooltip,
      child: child,
    );
  }

  Widget? _buildDeleteIcon(
    BuildContext context,
    ThemeData theme,
    ChipThemeData chipTheme,
    ChipThemeData chipDefaults,
  ) {
    if (!hasDeleteButton) {
      return null;
    }
    return Semantics(
      container: true,
      button: true,
      child: _wrapWithTooltip(
        tooltip: widget.useDeleteButtonTooltip
          ? widget.deleteButtonTooltipMessage ?? MaterialLocalizations.of(context).deleteButtonTooltip
          : null,
        enabled: widget.onDeleted != null,
        child: InkWell(
          // Radius should be slightly less than the full size of the chip.
          radius: (_kChipHeight + (widget.padding?.vertical ?? 0.0)) * .45,
          // Keeps the splash from being constrained to the icon alone.
          splashFactory: _UnconstrainedInkSplashFactory(Theme.of(context).splashFactory),
          onTap: widget.isEnabled ? widget.onDeleted : null,
          child: IconTheme(
            data: theme.iconTheme.copyWith(
              color: widget.deleteIconColor
                ?? chipTheme.deleteIconColor
                ?? theme.chipTheme.deleteIconColor
                ?? chipDefaults.deleteIconColor,
            ),
            child: widget.deleteIcon,
          ),
        ),
      ),
    );
  }

  static const double _defaultElevation = 0.0;
  static const double _defaultPressElevation = 8.0;
  static const Color _defaultShadowColor = Colors.black;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    assert(debugCheckHasMediaQuery(context));
    assert(debugCheckHasDirectionality(context));
    assert(debugCheckHasMaterialLocalizations(context));

    /// The chip at text scale 1 starts with 8px on each side and as text scaling
    /// gets closer to 2 the label padding is linearly interpolated from 8px to 4px.
    /// Once the widget has a text scaling of 2 or higher than the label padding
    /// remains 4px.
    final EdgeInsetsGeometry _defaultLabelPadding = EdgeInsets.lerp(
      const EdgeInsets.symmetric(horizontal: 8.0),
      const EdgeInsets.symmetric(horizontal: 4.0),
      (MediaQuery.of(context).textScaleFactor - 1.0).clamp(0.0, 1.0),
    )!;

    final ThemeData theme = Theme.of(context);
    final ChipThemeData chipTheme = ChipTheme.of(context);
    final Brightness brightness = chipTheme.brightness ?? theme.brightness;
    final ChipThemeData chipDefaults = ChipThemeData.fromDefaults(
      brightness: brightness,
      secondaryColor: brightness == Brightness.dark ? Colors.tealAccent[200]! : theme.primaryColor,
      labelStyle: theme.textTheme.bodyText1!,
    );
    final TextDirection? textDirection = Directionality.maybeOf(context);
    final OutlinedBorder resolvedShape = _getShape(theme, chipTheme, chipDefaults);

    final double elevation = widget.elevation
      ?? chipTheme.elevation
      ?? theme.chipTheme.elevation
      ?? _defaultElevation;
    final double pressElevation = widget.pressElevation
      ?? chipTheme.pressElevation
      ?? theme.chipTheme.pressElevation
      ?? _defaultPressElevation;
    final Color shadowColor = widget.shadowColor
      ?? chipTheme.shadowColor
      ?? theme.chipTheme.shadowColor
      ?? _defaultShadowColor;
    final Color selectedShadowColor = widget.selectedShadowColor
      ?? chipTheme.selectedShadowColor
      ?? theme.chipTheme.selectedShadowColor
      ?? _defaultShadowColor;
    final Color? checkmarkColor = widget.checkmarkColor
      ?? chipTheme.checkmarkColor
      ?? theme.chipTheme.checkmarkColor;
    final bool showCheckmark = widget.showCheckmark
      ?? chipTheme.showCheckmark
      ?? theme.chipTheme.showCheckmark
      ?? true;
    final EdgeInsetsGeometry padding = widget.padding
      ?? chipTheme.padding
      ?? theme.chipTheme.padding
      ?? chipDefaults.padding!;
    final TextStyle labelStyle = chipTheme.labelStyle
      ?? theme.chipTheme.labelStyle
      ?? chipDefaults.labelStyle!;
    final EdgeInsetsGeometry labelPadding = widget.labelPadding
      ?? chipTheme.labelPadding
      ?? theme.chipTheme.labelPadding
      ?? _defaultLabelPadding;

    final TextStyle effectiveLabelStyle = labelStyle.merge(widget.labelStyle);
    final Color? resolvedLabelColor = MaterialStateProperty.resolveAs<Color?>(effectiveLabelStyle.color, materialStates);
    final TextStyle resolvedLabelStyle = effectiveLabelStyle.copyWith(color: resolvedLabelColor);

    Widget result = Material(
      elevation: isTapping ? pressElevation : elevation,
      shadowColor: widget.selected ? selectedShadowColor : shadowColor,
      animationDuration: pressedAnimationDuration,
      shape: resolvedShape,
      clipBehavior: widget.clipBehavior,
      child: InkWell(
        onFocusChange: updateMaterialState(MaterialState.focused),
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        canRequestFocus: widget.isEnabled,
        onTap: canTap ? _handleTap : null,
        onTapDown: canTap ? _handleTapDown : null,
        onTapCancel: canTap ? _handleTapCancel : null,
        onHover: canTap ? updateMaterialState(MaterialState.hovered) : null,
        customBorder: resolvedShape,
        child: AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[selectController, enableController]),
          builder: (BuildContext context, Widget? child) {
            return Container(
              decoration: ShapeDecoration(
                shape: resolvedShape,
                color: _getBackgroundColor(theme, chipTheme, chipDefaults),
              ),
              child: child,
            );
          },
          child: _wrapWithTooltip(
            tooltip: widget.tooltip,
            enabled: widget.onPressed != null || widget.onSelected != null,
            child: _ChipRenderWidget(
              theme: _ChipRenderTheme(
                label: DefaultTextStyle(
                  overflow: TextOverflow.fade,
                  textAlign: TextAlign.start,
                  maxLines: 1,
                  softWrap: false,
                  style: resolvedLabelStyle,
                  child: widget.label,
                ),
                avatar: AnimatedSwitcher(
                  duration: _kDrawerDuration,
                  switchInCurve: Curves.fastOutSlowIn,
                  child: widget.avatar,
                ),
                deleteIcon: AnimatedSwitcher(
                  duration: _kDrawerDuration,
                  switchInCurve: Curves.fastOutSlowIn,
                  child: _buildDeleteIcon(context, theme, chipTheme, chipDefaults),
                ),
                brightness: brightness,
                padding: padding.resolve(textDirection),
                visualDensity: widget.visualDensity ?? theme.visualDensity,
                labelPadding: labelPadding.resolve(textDirection),
                showAvatar: hasAvatar,
                showCheckmark: showCheckmark,
                checkmarkColor: checkmarkColor,
                canTapBody: canTap,
              ),
              value: widget.selected,
              checkmarkAnimation: checkmarkAnimation,
              enableAnimation: enableAnimation,
              avatarDrawerAnimation: avatarDrawerAnimation,
              deleteDrawerAnimation: deleteDrawerAnimation,
              isEnabled: widget.isEnabled,
              avatarBorder: widget.avatarBorder,
            ),
          ),
        ),
      ),
    );
    final BoxConstraints constraints;
    final Offset densityAdjustment = (widget.visualDensity ?? theme.visualDensity).baseSizeAdjustment;
    switch (widget.materialTapTargetSize ?? theme.materialTapTargetSize) {
      case MaterialTapTargetSize.padded:
        constraints = BoxConstraints(
          minWidth: kMinInteractiveDimension + densityAdjustment.dx,
          minHeight: kMinInteractiveDimension + densityAdjustment.dy,
        );
        break;
      case MaterialTapTargetSize.shrinkWrap:
        constraints = const BoxConstraints();
        break;
    }
    result = _ChipRedirectingHitDetectionWidget(
      constraints: constraints,
      child: Center(
        widthFactor: 1.0,
        heightFactor: 1.0,
        child: result,
      ),
    );
    return Semantics(
      button: widget.tapEnabled,
      container: true,
      selected: widget.selected,
      enabled: widget.tapEnabled ? canTap : null,
      child: result,
    );
  }
}

/// Redirects the [position.dy] passed to [RenderBox.hitTest] to the vertical
/// center of the widget.
///
/// The primary purpose of this widget is to allow padding around the [RawChip]
/// to trigger the child ink feature without increasing the size of the material.
class _ChipRedirectingHitDetectionWidget extends SingleChildRenderObjectWidget {
  const _ChipRedirectingHitDetectionWidget({
    Key? key,
    Widget? child,
    required this.constraints,
  }) : super(key: key, child: child);

  final BoxConstraints constraints;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderChipRedirectingHitDetection(constraints);
  }

  @override
  void updateRenderObject(BuildContext context, covariant _RenderChipRedirectingHitDetection renderObject) {
    renderObject.additionalConstraints = constraints;
  }
}

class _RenderChipRedirectingHitDetection extends RenderConstrainedBox {
  _RenderChipRedirectingHitDetection(BoxConstraints additionalConstraints) : super(additionalConstraints: additionalConstraints);

  @override
  bool hitTest(BoxHitTestResult result, { required Offset position }) {
    if (!size.contains(position))
      return false;
    // Only redirects hit detection which occurs above and below the render object.
    // In order to make this assumption true, I have removed the minimum width
    // constraints, since any reasonable chip would be at least that wide.
    final Offset offset = Offset(position.dx, size.height / 2);
    return result.addWithRawTransform(
      transform: MatrixUtils.forceToPoint(offset),
      position: position,
      hitTest: (BoxHitTestResult result, Offset position) {
        assert(position == offset);
        return child!.hitTest(result, position: offset);
      },
    );
  }
}

class _ChipRenderWidget extends RenderObjectWidget with SlottedMultiChildRenderObjectWidgetMixin<_ChipSlot> {
  const _ChipRenderWidget({
    Key? key,
    required this.theme,
    this.value,
    this.isEnabled,
    required this.checkmarkAnimation,
    required this.avatarDrawerAnimation,
    required this.deleteDrawerAnimation,
    required this.enableAnimation,
    this.avatarBorder,
  }) : assert(theme != null),
       super(key: key);

  final _ChipRenderTheme theme;
  final bool? value;
  final bool? isEnabled;
  final Animation<double> checkmarkAnimation;
  final Animation<double> avatarDrawerAnimation;
  final Animation<double> deleteDrawerAnimation;
  final Animation<double> enableAnimation;
  final ShapeBorder? avatarBorder;

  @override
  Iterable<_ChipSlot> get slots => _ChipSlot.values;

  @override
  Widget? childForSlot(_ChipSlot slot) {
    switch (slot) {
      case _ChipSlot.label:
        return theme.label;
      case _ChipSlot.avatar:
        return theme.avatar;
      case _ChipSlot.deleteIcon:
        return theme.deleteIcon;
    }
  }

  @override
  void updateRenderObject(BuildContext context, _RenderChip renderObject) {
    renderObject
      ..theme = theme
      ..textDirection = Directionality.of(context)
      ..value = value
      ..isEnabled = isEnabled
      ..checkmarkAnimation = checkmarkAnimation
      ..avatarDrawerAnimation = avatarDrawerAnimation
      ..deleteDrawerAnimation = deleteDrawerAnimation
      ..enableAnimation = enableAnimation
      ..avatarBorder = avatarBorder;
  }

  @override
  SlottedContainerRenderObjectMixin<_ChipSlot> createRenderObject(BuildContext context) {
    return _RenderChip(
      theme: theme,
      textDirection: Directionality.of(context),
      value: value,
      isEnabled: isEnabled,
      checkmarkAnimation: checkmarkAnimation,
      avatarDrawerAnimation: avatarDrawerAnimation,
      deleteDrawerAnimation: deleteDrawerAnimation,
      enableAnimation: enableAnimation,
      avatarBorder: avatarBorder,
    );
  }
}

enum _ChipSlot {
  label,
  avatar,
  deleteIcon,
}

@immutable
class _ChipRenderTheme {
  const _ChipRenderTheme({
    required this.avatar,
    required this.label,
    required this.deleteIcon,
    required this.brightness,
    required this.padding,
    required this.visualDensity,
    required this.labelPadding,
    required this.showAvatar,
    required this.showCheckmark,
    required this.checkmarkColor,
    required this.canTapBody,
  });

  final Widget avatar;
  final Widget label;
  final Widget deleteIcon;
  final Brightness brightness;
  final EdgeInsets padding;
  final VisualDensity visualDensity;
  final EdgeInsets labelPadding;
  final bool showAvatar;
  final bool showCheckmark;
  final Color? checkmarkColor;
  final bool canTapBody;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is _ChipRenderTheme
        && other.avatar == avatar
        && other.label == label
        && other.deleteIcon == deleteIcon
        && other.brightness == brightness
        && other.padding == padding
        && other.labelPadding == labelPadding
        && other.showAvatar == showAvatar
        && other.showCheckmark == showCheckmark
        && other.checkmarkColor == checkmarkColor
        && other.canTapBody == canTapBody;
  }

  @override
  int get hashCode {
    return hashValues(
      avatar,
      label,
      deleteIcon,
      brightness,
      padding,
      labelPadding,
      showAvatar,
      showCheckmark,
      checkmarkColor,
      canTapBody,
    );
  }
}

class _RenderChip extends RenderBox with SlottedContainerRenderObjectMixin<_ChipSlot> {
  _RenderChip({
    required _ChipRenderTheme theme,
    required TextDirection textDirection,
    this.value,
    this.isEnabled,
    required this.checkmarkAnimation,
    required this.avatarDrawerAnimation,
    required this.deleteDrawerAnimation,
    required this.enableAnimation,
    this.avatarBorder,
  }) : assert(theme != null),
       assert(textDirection != null),
       _theme = theme,
       _textDirection = textDirection {
    checkmarkAnimation.addListener(markNeedsPaint);
    avatarDrawerAnimation.addListener(markNeedsLayout);
    deleteDrawerAnimation.addListener(markNeedsLayout);
    enableAnimation.addListener(markNeedsPaint);
  }

  bool? value;
  bool? isEnabled;
  late Rect _deleteButtonRect;
  late Rect _pressRect;
  Animation<double> checkmarkAnimation;
  Animation<double> avatarDrawerAnimation;
  Animation<double> deleteDrawerAnimation;
  Animation<double> enableAnimation;
  ShapeBorder? avatarBorder;

  RenderBox? get avatar => childForSlot(_ChipSlot.avatar);
  RenderBox? get deleteIcon => childForSlot(_ChipSlot.deleteIcon);
  RenderBox? get label => childForSlot(_ChipSlot.label);

  _ChipRenderTheme get theme => _theme;
  _ChipRenderTheme _theme;
  set theme(_ChipRenderTheme value) {
    if (_theme == value) {
      return;
    }
    _theme = value;
    markNeedsLayout();
  }

  TextDirection? get textDirection => _textDirection;
  TextDirection? _textDirection;
  set textDirection(TextDirection? value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
    markNeedsLayout();
  }

  // The returned list is ordered for hit testing.
  @override
  Iterable<RenderBox> get children {
    return <RenderBox>[
      if (avatar != null)
        avatar!,
      if (label != null)
        label!,
      if (deleteIcon != null)
        deleteIcon!,
    ];
  }

  bool get isDrawingCheckmark => theme.showCheckmark && !checkmarkAnimation.isDismissed;
  bool get deleteIconShowing => !deleteDrawerAnimation.isDismissed;

  @override
  bool get sizedByParent => false;

  static double _minWidth(RenderBox? box, double height) {
    return box == null ? 0.0 : box.getMinIntrinsicWidth(height);
  }

  static double _maxWidth(RenderBox? box, double height) {
    return box == null ? 0.0 : box.getMaxIntrinsicWidth(height);
  }

  static double _minHeight(RenderBox? box, double width) {
    return box == null ? 0.0 : box.getMinIntrinsicHeight(width);
  }

  static Size _boxSize(RenderBox? box) => box == null ? Size.zero : box.size;

  static Rect _boxRect(RenderBox? box) => box == null ? Rect.zero : _boxParentData(box).offset & box.size;

  static BoxParentData _boxParentData(RenderBox box) => box.parentData! as BoxParentData;

  @override
  double computeMinIntrinsicWidth(double height) {
    // The overall padding isn't affected by missing avatar or delete icon
    // because we add the padding regardless to give extra padding for the label
    // when they're missing.
    final double overallPadding = theme.padding.horizontal +
        theme.labelPadding.horizontal;
    return overallPadding +
        _minWidth(avatar, height) +
        _minWidth(label, height) +
        _minWidth(deleteIcon, height);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final double overallPadding = theme.padding.horizontal +
        theme.labelPadding.horizontal;
    return overallPadding +
        _maxWidth(avatar, height) +
        _maxWidth(label, height) +
        _maxWidth(deleteIcon, height);
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return math.max(
      _kChipHeight,
      theme.padding.vertical + theme.labelPadding.vertical + _minHeight(label, width),
    );
  }

  @override
  double computeMaxIntrinsicHeight(double width) => computeMinIntrinsicHeight(width);

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    // The baseline of this widget is the baseline of the label.
    return label!.getDistanceToActualBaseline(baseline);
  }

  Size _layoutLabel(BoxConstraints contentConstraints, double iconSizes, Size size, Size rawSize, [ChildLayouter layoutChild = ChildLayoutHelper.layoutChild]) {
    // Now that we know the label height and the width of the icons, we can
    // determine how much to shrink the width constraints for the "real" layout.
    if (contentConstraints.maxWidth.isFinite) {
      final double maxWidth = math.max(
        0.0,
        contentConstraints.maxWidth
        - iconSizes
        - theme.labelPadding.horizontal
        - theme.padding.horizontal,
      );
      final Size updatedSize = layoutChild(
        label!,
        BoxConstraints(
          maxWidth: maxWidth,
          minHeight: rawSize.height,
          maxHeight: size.height,
        ),
      );

      return Size(
        updatedSize.width + theme.labelPadding.horizontal,
        updatedSize.height + theme.labelPadding.vertical,
      );
    }

    final Size updatedSize = layoutChild(
      label!,
      BoxConstraints(
        minHeight: rawSize.height,
        maxHeight: size.height,
        maxWidth: size.width,
      ),
    );

    return Size(
      updatedSize.width + theme.labelPadding.horizontal,
      updatedSize.height + theme.labelPadding.vertical,
    );
  }

  Size _layoutAvatar(BoxConstraints contentConstraints, double contentSize, [ChildLayouter layoutChild = ChildLayoutHelper.layoutChild]) {
    final double requestedSize = math.max(0.0, contentSize);
    final BoxConstraints avatarConstraints = BoxConstraints.tightFor(
      width: requestedSize,
      height: requestedSize,
    );
    final Size avatarBoxSize = layoutChild(avatar!, avatarConstraints);
    if (!theme.showCheckmark && !theme.showAvatar) {
      return Size(0.0, contentSize);
    }
    double avatarWidth = 0.0;
    double avatarHeight = 0.0;
    if (theme.showAvatar) {
      avatarWidth += avatarDrawerAnimation.value * avatarBoxSize.width;
    } else {
      avatarWidth += avatarDrawerAnimation.value * contentSize;
    }
    avatarHeight += avatarBoxSize.height;
    return Size(avatarWidth, avatarHeight);
  }

  Size _layoutDeleteIcon(BoxConstraints contentConstraints, double contentSize, [ChildLayouter layoutChild = ChildLayoutHelper.layoutChild]) {
    final double requestedSize = math.max(0.0, contentSize);
    final BoxConstraints deleteIconConstraints = BoxConstraints.tightFor(
      width: requestedSize,
      height: requestedSize,
    );
    final Size boxSize = layoutChild(deleteIcon!, deleteIconConstraints);
    if (!deleteIconShowing) {
      return Size(0.0, contentSize);
    }
    double deleteIconWidth = 0.0;
    double deleteIconHeight = 0.0;
    deleteIconWidth += deleteDrawerAnimation.value * boxSize.width;
    deleteIconHeight += boxSize.height;
    return Size(deleteIconWidth, deleteIconHeight);
  }

  @override
  bool hitTest(BoxHitTestResult result, { required Offset position }) {
    if (!size.contains(position)) {
      return false;
    }
    final bool hitIsOnDeleteIcon = deleteIcon != null && _hitIsOnDeleteIcon(
      padding: theme.padding,
      tapPosition: position,
      chipSize: size,
      deleteButtonSize: deleteIcon!.size,
      textDirection: textDirection!,
    );
    final RenderBox? hitTestChild = hitIsOnDeleteIcon
        ? (deleteIcon ?? label ?? avatar)
        : (label ?? avatar);

    if (hitTestChild != null) {
      final Offset center = hitTestChild.size.center(Offset.zero);
      return result.addWithRawTransform(
        transform: MatrixUtils.forceToPoint(center),
        position: position,
        hitTest: (BoxHitTestResult result, Offset position) {
          assert(position == center);
          return hitTestChild.hitTest(result, position: center);
        },
      );
    }
    return false;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return _computeSizes(constraints, ChildLayoutHelper.dryLayoutChild).size;
  }

  _ChipSizes _computeSizes(BoxConstraints constraints, ChildLayouter layoutChild) {
    final BoxConstraints contentConstraints = constraints.loosen();
    // Find out the height of the label within the constraints.
    final Offset densityAdjustment = Offset(0.0, theme.visualDensity.baseSizeAdjustment.dy / 2.0);
    final Size rawLabelSize = layoutChild(label!, contentConstraints);
    final double contentSize = math.max(
      _kChipHeight - theme.padding.vertical + theme.labelPadding.vertical,
      rawLabelSize.height + theme.labelPadding.vertical,
    );
    final Size avatarSize = _layoutAvatar(contentConstraints, contentSize, layoutChild);
    final Size deleteIconSize = _layoutDeleteIcon(contentConstraints, contentSize, layoutChild);
    final Size labelSize = _layoutLabel(
      contentConstraints,
      avatarSize.width + deleteIconSize.width,
      Size(rawLabelSize.width, contentSize),
      rawLabelSize,
      layoutChild,
    );

    // This is the overall size of the content: it doesn't include
    // theme.padding, that is added in at the end.
    final Size overallSize = Size(
      avatarSize.width + labelSize.width + deleteIconSize.width,
      contentSize,
    ) + densityAdjustment;
    final Size paddedSize = Size(
      overallSize.width + theme.padding.horizontal,
      overallSize.height + theme.padding.vertical,
    );

    return _ChipSizes(
      size: constraints.constrain(paddedSize),
      overall: overallSize,
      content: contentSize,
      densityAdjustment: densityAdjustment,
      avatar: avatarSize,
      label: labelSize,
      deleteIcon: deleteIconSize,
    );
  }

  @override
  void performLayout() {
    final _ChipSizes sizes = _computeSizes(constraints, ChildLayoutHelper.layoutChild);

    // Now we have all of the dimensions. Place the children where they belong.

    const double left = 0.0;
    final double right = sizes.overall.width;

    Offset centerLayout(Size boxSize, double x) {
      assert(sizes.content >= boxSize.height);
      switch (textDirection!) {
        case TextDirection.rtl:
          return Offset(x - boxSize.width, (sizes.content - boxSize.height + sizes.densityAdjustment.dy) / 2.0);
        case TextDirection.ltr:
          return Offset(x, (sizes.content - boxSize.height + sizes.densityAdjustment.dy) / 2.0);
      }
    }

    // These are the offsets to the upper left corners of the boxes (including
    // the child's padding) containing the children, for each child, but not
    // including the overall padding.
    Offset avatarOffset = Offset.zero;
    Offset labelOffset = Offset.zero;
    Offset deleteIconOffset = Offset.zero;
    switch (textDirection!) {
      case TextDirection.rtl:
        double start = right;
        if (theme.showCheckmark || theme.showAvatar) {
          avatarOffset = centerLayout(sizes.avatar, start);
          start -= sizes.avatar.width;
        }
        labelOffset = centerLayout(sizes.label, start);
        start -= sizes.label.width;
        if (deleteIconShowing) {
          _deleteButtonRect = Rect.fromLTWH(
            0.0,
            0.0,
            sizes.deleteIcon.width + theme.padding.right,
            sizes.overall.height + theme.padding.vertical,
          );
          deleteIconOffset = centerLayout(sizes.deleteIcon, start);
        } else {
          _deleteButtonRect = Rect.zero;
        }
        start -= sizes.deleteIcon.width;
        if (theme.canTapBody) {
          _pressRect = Rect.fromLTWH(
            _deleteButtonRect.width,
            0.0,
            sizes.overall.width - _deleteButtonRect.width + theme.padding.horizontal,
            sizes.overall.height + theme.padding.vertical,
          );
        } else {
          _pressRect = Rect.zero;
        }
        break;
      case TextDirection.ltr:
        double start = left;
        if (theme.showCheckmark || theme.showAvatar) {
          avatarOffset = centerLayout(sizes.avatar, start - _boxSize(avatar).width + sizes.avatar.width);
          start += sizes.avatar.width;
        }
        labelOffset = centerLayout(sizes.label, start);
        start += sizes.label.width;
        if (theme.canTapBody) {
          _pressRect = Rect.fromLTWH(
            0.0,
            0.0,
            deleteIconShowing
                ? start + theme.padding.left
                : sizes.overall.width + theme.padding.horizontal,
            sizes.overall.height + theme.padding.vertical,
          );
        } else {
          _pressRect = Rect.zero;
        }
        start -= _boxSize(deleteIcon).width - sizes.deleteIcon.width;
        if (deleteIconShowing) {
          deleteIconOffset = centerLayout(sizes.deleteIcon, start);
          _deleteButtonRect = Rect.fromLTWH(
            start + theme.padding.left,
            0.0,
            sizes.deleteIcon.width + theme.padding.right,
            sizes.overall.height + theme.padding.vertical,
          );
        } else {
          _deleteButtonRect = Rect.zero;
        }
        break;
    }
    // Center the label vertically.
    labelOffset = labelOffset +
        Offset(
          0.0,
          ((sizes.label.height - theme.labelPadding.vertical) - _boxSize(label).height) / 2.0,
        );
    _boxParentData(avatar!).offset = theme.padding.topLeft + avatarOffset;
    _boxParentData(label!).offset = theme.padding.topLeft + labelOffset + theme.labelPadding.topLeft;
    _boxParentData(deleteIcon!).offset = theme.padding.topLeft + deleteIconOffset;
    final Size paddedSize = Size(
      sizes.overall.width + theme.padding.horizontal,
      sizes.overall.height + theme.padding.vertical,
    );
    size = constraints.constrain(paddedSize);
    assert(
      size.height == constraints.constrainHeight(paddedSize.height),
      "Constrained height ${size.height} doesn't match expected height "
      '${constraints.constrainWidth(paddedSize.height)}',
    );
    assert(
      size.width == constraints.constrainWidth(paddedSize.width),
      "Constrained width ${size.width} doesn't match expected width "
      '${constraints.constrainWidth(paddedSize.width)}',
    );
  }

  static final ColorTween selectionScrimTween = ColorTween(
    begin: Colors.transparent,
    end: _kSelectScrimColor,
  );

  Color get _disabledColor {
    if (enableAnimation == null || enableAnimation.isCompleted) {
      return Colors.white;
    }
    final ColorTween enableTween;
    switch (theme.brightness) {
      case Brightness.light:
        enableTween = ColorTween(
          begin: Colors.white.withAlpha(_kDisabledAlpha),
          end: Colors.white,
        );
        break;
      case Brightness.dark:
        enableTween = ColorTween(
          begin: Colors.black.withAlpha(_kDisabledAlpha),
          end: Colors.black,
        );
        break;
    }
    return enableTween.evaluate(enableAnimation)!;
  }

  void _paintCheck(Canvas canvas, Offset origin, double size) {
    Color? paintColor;
    if (theme.checkmarkColor != null) {
      paintColor = theme.checkmarkColor;
    } else {
      switch (theme.brightness) {
        case Brightness.light:
          paintColor = theme.showAvatar ? Colors.white : Colors.black.withAlpha(_kCheckmarkAlpha);
          break;
        case Brightness.dark:
          paintColor = theme.showAvatar ? Colors.black : Colors.white.withAlpha(_kCheckmarkAlpha);
          break;
      }
    }

    final ColorTween fadeTween = ColorTween(begin: Colors.transparent, end: paintColor);

    paintColor = checkmarkAnimation.status == AnimationStatus.reverse
        ? fadeTween.evaluate(checkmarkAnimation)
        : paintColor;

    final Paint paint = Paint()
      ..color = paintColor!
      ..style = PaintingStyle.stroke
      ..strokeWidth = _kCheckmarkStrokeWidth * (avatar != null ? avatar!.size.height / 24.0 : 1.0);
    final double t = checkmarkAnimation.status == AnimationStatus.reverse
        ? 1.0
        : checkmarkAnimation.value;
    if (t == 0.0) {
      // Nothing to draw.
      return;
    }
    assert(t > 0.0 && t <= 1.0);
    // As t goes from 0.0 to 1.0, animate the two check mark strokes from the
    // short side to the long side.
    final Path path = Path();
    final Offset start = Offset(size * 0.15, size * 0.45);
    final Offset mid = Offset(size * 0.4, size * 0.7);
    final Offset end = Offset(size * 0.85, size * 0.25);
    if (t < 0.5) {
      final double strokeT = t * 2.0;
      final Offset drawMid = Offset.lerp(start, mid, strokeT)!;
      path.moveTo(origin.dx + start.dx, origin.dy + start.dy);
      path.lineTo(origin.dx + drawMid.dx, origin.dy + drawMid.dy);
    } else {
      final double strokeT = (t - 0.5) * 2.0;
      final Offset drawEnd = Offset.lerp(mid, end, strokeT)!;
      path.moveTo(origin.dx + start.dx, origin.dy + start.dy);
      path.lineTo(origin.dx + mid.dx, origin.dy + mid.dy);
      path.lineTo(origin.dx + drawEnd.dx, origin.dy + drawEnd.dy);
    }
    canvas.drawPath(path, paint);
  }

  void _paintSelectionOverlay(PaintingContext context, Offset offset) {
    if (isDrawingCheckmark) {
      if (theme.showAvatar) {
        final Rect avatarRect = _boxRect(avatar).shift(offset);
        final Paint darkenPaint = Paint()
          ..color = selectionScrimTween.evaluate(checkmarkAnimation)!
          ..blendMode = BlendMode.srcATop;
        final Path path =  avatarBorder!.getOuterPath(avatarRect);
        context.canvas.drawPath(path, darkenPaint);
      }
      // Need to make the check mark be a little smaller than the avatar.
      final double checkSize = avatar!.size.height * 0.75;
      final Offset checkOffset = _boxParentData(avatar!).offset +
          Offset(avatar!.size.height * 0.125, avatar!.size.height * 0.125);
      _paintCheck(context.canvas, offset + checkOffset, checkSize);
    }
  }

  void _paintAvatar(PaintingContext context, Offset offset) {
    void paintWithOverlay(PaintingContext context, Offset offset) {
      context.paintChild(avatar!, _boxParentData(avatar!).offset + offset);
      _paintSelectionOverlay(context, offset);
    }

    if (theme.showAvatar == false && avatarDrawerAnimation.isDismissed) {
      return;
    }
    final Color disabledColor = _disabledColor;
    final int disabledColorAlpha = disabledColor.alpha;
    if (needsCompositing) {
      context.pushLayer(OpacityLayer(alpha: disabledColorAlpha), paintWithOverlay, offset);
    } else {
      if (disabledColorAlpha != 0xff) {
        context.canvas.saveLayer(
          _boxRect(avatar).shift(offset).inflate(20.0),
          Paint()..color = disabledColor,
        );
      }
      paintWithOverlay(context, offset);
      if (disabledColorAlpha != 0xff) {
        context.canvas.restore();
      }
    }
  }

  void _paintChild(PaintingContext context, Offset offset, RenderBox? child, bool? isEnabled) {
    if (child == null) {
      return;
    }
    final int disabledColorAlpha = _disabledColor.alpha;
    if (!enableAnimation.isCompleted) {
      if (needsCompositing) {
        context.pushLayer(
          OpacityLayer(alpha: disabledColorAlpha),
          (PaintingContext context, Offset offset) {
            context.paintChild(child, _boxParentData(child).offset + offset);
          },
          offset,
        );
      } else {
        final Rect childRect = _boxRect(child).shift(offset);
        context.canvas.saveLayer(childRect.inflate(20.0), Paint()..color = _disabledColor);
        context.paintChild(child, _boxParentData(child).offset + offset);
        context.canvas.restore();
      }
    } else {
      context.paintChild(child, _boxParentData(child).offset + offset);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _paintAvatar(context, offset);
    if (deleteIconShowing) {
      _paintChild(context, offset, deleteIcon, isEnabled);
    }
    _paintChild(context, offset, label, isEnabled);
  }

  // Set this to true to have outlines of the tap targets drawn over
  // the chip.  This should never be checked in while set to 'true'.
  static const bool _debugShowTapTargetOutlines = false;

  @override
  void debugPaint(PaintingContext context, Offset offset) {
    assert(!_debugShowTapTargetOutlines || () {
      // Draws a rect around the tap targets to help with visualizing where
      // they really are.
      final Paint outlinePaint = Paint()
        ..color = const Color(0xff800000)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      if (deleteIconShowing) {
        context.canvas.drawRect(_deleteButtonRect.shift(offset), outlinePaint);
      }
      context.canvas.drawRect(
        _pressRect.shift(offset),
        outlinePaint..color = const Color(0xff008000),
      );
      return true;
    }());
  }

  @override
  bool hitTestSelf(Offset position) => _deleteButtonRect.contains(position) || _pressRect.contains(position);
}

class _ChipSizes {
  _ChipSizes({
    required this.size,
    required this.overall,
    required this.content,
    required this.avatar,
    required this.label,
    required this.deleteIcon,
    required this.densityAdjustment,
});
  final Size size;
  final Size overall;
  final double content;
  final Size avatar;
  final Size label;
  final Size deleteIcon;
  final Offset densityAdjustment;
}

class _UnconstrainedInkSplashFactory extends InteractiveInkFeatureFactory {
  const _UnconstrainedInkSplashFactory(this.parentFactory);

  final InteractiveInkFeatureFactory parentFactory;

  @override
  InteractiveInkFeature create({
    required MaterialInkController controller,
    required RenderBox referenceBox,
    required Offset position,
    required Color color,
    required TextDirection textDirection,
    bool containedInkWell = false,
    RectCallback? rectCallback,
    BorderRadius? borderRadius,
    ShapeBorder? customBorder,
    double? radius,
    VoidCallback? onRemoved,
  }) {
    return parentFactory.create(
      controller: controller,
      referenceBox: referenceBox,
      position: position,
      color: color,
      rectCallback: rectCallback,
      borderRadius: borderRadius,
      customBorder: customBorder,
      radius: radius,
      onRemoved: onRemoved,
      textDirection: textDirection,
    );
  }
}

bool _hitIsOnDeleteIcon({
  required EdgeInsetsGeometry padding,
  required Offset tapPosition,
  required Size chipSize,
  required Size deleteButtonSize,
  required TextDirection textDirection,
}) {
  // The chipSize includes the padding, so we need to deflate the size and adjust the
  // tap position to account for the padding.
  final EdgeInsets resolvedPadding = padding.resolve(textDirection);
  final Size deflatedSize = resolvedPadding.deflateSize(chipSize);
  final Offset adjustedPosition = tapPosition - Offset(resolvedPadding.left, resolvedPadding.top);
  // The delete button hit area should be at least the width of the delete
  // button, but, if there's room, up to 24 pixels from the center of the delete
  // icon (corresponding to part of a 48x48 square that Material would prefer
  // for touch targets), but no more than approximately half of the overall size
  // of the chip when the chip is small.
  //
  // This isn't affected by materialTapTargetSize because it only applies to the
  // width of the tappable region within the chip, not outside of the chip,
  // which is handled elsewhere. Also because delete buttons aren't specified to
  // be used on touch devices, only desktop devices.

  // Max out at not quite half, so that tests that tap on the center of a small
  // chip will still hit the chip, not the delete button.
  final double accessibleDeleteButtonWidth = math.min(
    deflatedSize.width * 0.499,
    math.max(deleteButtonSize.width, 24.0 + deleteButtonSize.width / 2.0),
  );
  switch (textDirection) {
    case TextDirection.ltr:
      return adjustedPosition.dx >= deflatedSize.width - accessibleDeleteButtonWidth;
    case TextDirection.rtl:
      return adjustedPosition.dx <= accessibleDeleteButtonWidth;
  }
}
