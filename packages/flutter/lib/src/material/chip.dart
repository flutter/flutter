// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'debug.dart';
import 'icons.dart';
import 'ink_well.dart';
import 'material.dart';
import 'material_localizations.dart';
import 'theme.dart';
import 'tooltip.dart';

// Some design constants
const double _kChipHeight = 32.0;
const double _kDeleteIconSize = 18.0;
const int _kTextLabelAlpha = 0xde; // 87%
const double _kDeleteIconOpacity = 0.87;
const double _kEdgePadding = 4.0;
const int _kDisabledAlpha = 0x5e; // 36%
const double _kCheckmarkStrokeWidth = 2.0;
const double _kPressElevation = 8.0;
const Duration _kSelectDuration = const Duration(milliseconds: 195);
const Duration _kSelectReverseDuration = const Duration(milliseconds: 100);
const Duration _kCheckmarkDuration = const Duration(milliseconds: 150);
const Duration _kCheckmarkReverseDuration = const Duration(milliseconds: 75);
const Duration _kDrawerDuration = const Duration(milliseconds: 150);
const Duration _kDisableDuration = const Duration(milliseconds: 75);
const Color _kSelectScrimColor = const Color(0x60191919);
const Color _kSelectedColor = const Color(0x28000000);
const Color _kDefaultBackground = const Color(0x14000000);
const Color _kDefaultDisabledBackground = const Color(0x08000000);

/// A material design chip.
///
/// Chips are compact elements that represent an attribute, text, entity, or
/// action.
///
/// Supplying a non-null [onDeleted] callback will cause the chip to include a
/// button for deleting the chip.
///
/// Requires one of its ancestors to be a [Material] widget. The [label],
/// [deleteIcon] and [border] arguments must not be null.
///
/// ## Sample code
///
/// ```dart
/// new Chip(
///   avatar: new CircleAvatar(
///     backgroundColor: Colors.grey.shade800,
///     child: new Text('AB'),
///   ),
///   label: new Text('Aaron Burr'),
/// )
/// ```
///
/// See also:
///
///  * [CircleAvatar], which shows images or initials of entities.
///  * <https://material.google.com/components/chips.html>
class Chip extends StatelessWidget {
  /// Creates a material design chip.
  ///
  /// The [label] and [border] arguments may not be null.
  const Chip({
    Key key,
    this.avatar,
    @required this.label,
    this.labelStyle,
    this.labelPadding,
    this.deleteIcon,
    this.onDeleted,
    this.deleteIconColor,
    this.deleteButtonTooltipMessage,
    this.border: const StadiumBorder(),
    this.backgroundColor,
    this.padding,
  })  : assert(label != null),
        assert(border != null),
        super(key: key);

  /// A widget to display prior to the chip's label.
  ///
  /// Typically a [CircleAvatar] widget.
  final Widget avatar;

  /// The primary content of the chip.
  ///
  /// Typically a [Text] widget.
  final Widget label;

  /// The style to be applied to the chip's label.
  ///
  /// This only has effect on widgets that respect the [DefaultTextStyle],
  /// such as [Text].
  final TextStyle labelStyle;

  /// The padding around the [label] widget.
  final EdgeInsetsGeometry labelPadding;

  /// The icon displayed when [onDeleted] is non-null.
  ///
  /// This has no effect when [onDeleted] is null since no delete icon will be
  /// shown.
  ///
  /// Defaults to an [Icon] widget containing [Icons.cancel].
  ///
  /// May not be null.
  final Widget deleteIcon;

  /// Called when the user taps the delete button to delete the chip.
  ///
  /// If null, the delete button will not appear on the chip.
  final VoidCallback onDeleted;

  /// Color for delete icon, the default being black.
  ///
  /// This has no effect when [onDeleted] or [deleteIcon] are null since no
  /// delete icon will be shown.
  ///
  /// If [deleteIcon] is set to something other than its default, then this
  /// will have no effect, since the color specified in the [deleteIcon] widget
  /// will take precedence.
  final Color deleteIconColor;

  /// Message to be used for the chip delete button's tooltip.
  ///
  /// This has no effect when [onDeleted] or [deleteIcon] are null since no
  /// delete icon will be shown.
  final String deleteButtonTooltipMessage;

  /// The border to draw around the chip.
  ///
  /// Defaults to a [StadiumBorder]. May not be null.
  final ShapeBorder border;

  /// Color to be used for the chip's background, the default is based on the
  /// ambient [IconTheme].
  ///
  /// This color is used as the background of the container that will hold the
  /// widget's label.
  final Color backgroundColor;

  /// The padding between the contents of the chip and the outside [border].
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    return new RawChip(
      avatar: avatar,
      label: label,
      labelStyle: labelStyle,
      labelPadding: labelPadding,
      deleteIcon: deleteIcon,
      onDeleted: onDeleted,
      deleteIconColor: deleteIconColor,
      deleteButtonTooltipMessage: deleteButtonTooltipMessage,
      tapEnabled: false,
      border: border,
      backgroundColor: backgroundColor,
      padding: padding,
      isEnabled: true,
    );
  }
}

/// A material design input chip.
///
/// Input chips represent a complex piece of information, such as an entity
/// (person, place, or thing) or conversational text, in a compact form.
///
/// Input chips can be selected by setting [onSelected], deleted by setting
/// [onDeleted], and pushed like a button with [onPressed]. They have a [label],
/// and they can have a leading icon (see [avatar]) and a trailing icon
/// ([deleteIcon]). Colors and padding can be customized.
///
/// Requires one of its ancestors to be a [Material] widget. The [label],
/// [isEnabled], [selected], and [border] arguments must not be null.
///
/// Input chips work together with other UI elements. They can appear:
///
///  * In a [Wrap] widget.
///  * In a horizontally scrollable list
///
/// ## Sample code
///
/// ```dart
/// new InputChip(
///   avatar: new CircleAvatar(
///     backgroundColor: Colors.grey.shade800,
///     child: new Text('AB'),
///   ),
///   label: new Text('Aaron Burr'),
///   onPressed: () {
///     print("I am the one thing in life.");
///   }
/// )
/// ```
///
/// See also:
///
///  * [CircleAvatar], which shows images or initials of people.
///  * <https://material.google.com/components/chips.html>
class InputChip extends StatelessWidget {
  const InputChip({
    Key key,
    this.avatar,
    @required this.label,
    this.labelStyle,
    this.labelPadding,
    this.selected: false,
    this.isEnabled: true,
    this.onSelected,
    this.deleteIcon,
    this.onDeleted,
    this.deleteIconColor,
    this.deleteButtonTooltipMessage,
    this.onPressed,
    this.disabledColor,
    this.selectedColor,
    this.tooltip,
    this.border: const StadiumBorder(),
    this.backgroundColor,
    this.padding,
  })  : assert(selected != null),
        assert(isEnabled != null),
        assert(label != null),
        assert(border != null),
        super(key: key);

  /// A widget to display prior to the chip's label.
  ///
  /// Typically a [CircleAvatar] widget.
  final Widget avatar;

  /// The primary content of the chip.
  ///
  /// Typically a [Text] widget.
  final Widget label;

  /// The style to be applied to the chip's label.
  ///
  /// This only has an effect on widgets that respect the [DefaultTextStyle],
  /// such as [Text].
  final TextStyle labelStyle;

  /// The padding around the [label] widget.
  ///
  /// By default, this is 4 logical pixels at the beginning and the end of the
  /// label.
  final EdgeInsetsGeometry labelPadding;

  /// Whether or not this chip is selected.
  ///
  /// If [onSelected] is not null, this value will be used to determine if the
  /// [selectIcon] will be shown or not. Has no effect if [onSelected] is null.
  ///
  /// May not be null. Defaults to false.
  final bool selected;

  /// Whether or not this chip is enabled for input.
  ///
  /// If this is true, but all three of [onSelected], [onPressed], and
  /// [onDeleted] are null, then the control will still be shown as disabled.
  ///
  /// This is typically only used if you want the chip to be disabled, but also
  /// show a delete button.
  ///
  /// Defaults to true. Cannot be null.
  final bool isEnabled;

  /// Called when the chip should change between selected and deselected states.
  ///
  /// The chip passes the new value to the callback but does not actually
  /// change state until the parent widget rebuilds the chip with the new
  /// value.
  ///
  /// When the chip is tapped, then the [onSelected] callback, if set, will be
  /// applied to `!selected`.
  ///
  /// The callback provided to [onSelected] should update the state of the
  /// parent [StatefulWidget] using the [State.setState] method, so that the
  /// parent gets rebuilt.
  ///
  /// The [onSelected] and [onPressed] callbacks may not both be specified at
  /// the same time.
  ///
  /// ## Sample code
  ///
  /// ```dart
  /// class Marble extends StatefulWidget {
  ///   @override
  ///   State<StatefulWidget> createState() => new MarbleState();
  /// }
  ///
  /// class MarbleState extends State<Marble> {
  ///   bool _useChisel;
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     return new InputChip(
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
  final ValueChanged<bool> onSelected;

  /// The icon displayed when [onDeleted] is set.
  ///
  /// This has no effect when [onDeleted] is null since no delete icon will be
  /// shown.
  ///
  /// Defaults to an [Icon] widget set to use [Icons.cancel].
  final Widget deleteIcon;

  /// Called when the user taps the delete button to delete the chip.
  ///
  /// If null, the delete button will not appear on the chip.
  final VoidCallback onDeleted;

  /// Color for delete icon. The default is based on the ambient [IconTheme].
  final Color deleteIconColor;

  /// The message to be used for the chip's delete button tooltip.
  final String deleteButtonTooltipMessage;

  /// Called when the user taps the chip.
  ///
  /// If [onPressed] is set, then this callback will be called when the user
  /// taps on the label or avatar parts of the chip. If [onPressed] is null,
  /// then the chip will be disabled.
  ///
  /// The [onPressed] and [onSelected] callbacks may not both be specified at
  /// the same time.
  ///
  /// ## Sample code
  ///
  /// ```dart
  /// class Alabaster extends StatelessWidget {
  ///   void startHammering() {
  ///     print('bang bang bang');
  ///   }
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     return new InputChip(
  ///       label: const Text('Apply Hammer'),
  ///       onPressed: startHammering,
  ///     );
  ///   }
  /// }
  /// ```
  final VoidCallback onPressed;

  /// Color to be used for the chip's background indicating that it is disabled.
  ///
  /// The chip is disabled when [isEnabled] is false, or all three of
  /// [onDeleted], [onPressed] and [onSelected] are null.
  ///
  /// It defaults to dark grey.
  final Color disabledColor;

  /// Color to be used for the chip's background indicating that it is selected.
  ///
  /// The chip is selected when [selected] is true.
  final Color selectedColor;

  /// Tooltip string to be used for the label and avatar area of the chip.
  ///
  /// This has no effect when [onPressed] and [onSelected] are null, since no
  /// action will occur.
  final String tooltip;

  /// The border to draw around the chip.
  ///
  /// Defaults to a [StadiumBorder]. May not be null.
  final ShapeBorder border;

  /// Color to be used for the unselected, enabled chip's background.
  ///
  /// The default is light grey.
  final Color backgroundColor;

  /// The padding between the contents of the chip and the outside [border].
  ///
  /// Defaults to [EdgeInsets.zero].
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    return new RawChip(
      avatar: avatar,
      label: label,
      labelStyle: labelStyle,
      labelPadding: labelPadding,
      deleteIcon: deleteIcon,
      onDeleted: onDeleted,
      deleteIconColor: deleteIconColor,
      deleteButtonTooltipMessage: deleteButtonTooltipMessage,
      onSelected: onSelected,
      onPressed: onPressed,
      selected: selected,
      tapEnabled: true,
      disabledColor: disabledColor,
      selectedColor: selectedColor,
      tooltip: tooltip,
      border: border,
      backgroundColor: backgroundColor,
      padding: padding,
      isEnabled: isEnabled && (onSelected != null || onDeleted != null || onPressed != null),
    );
  }
}

/// A material design choice chip.
///
/// [ChoiceChip]s allow a single selection from a set of options. Choice chips
/// contain related descriptive text or categories.
///
/// Requires one of its ancestors to be a [Material] widget. The [selected],
/// [label] and [border] arguments must not be null.
///
/// ## Sample code
///
/// ```dart
/// bool _value = false;
///
/// new ChoiceChip(
///   avatar: new CircleAvatar(
///     backgroundColor: Colors.grey.shade800,
///     child: new Text('C'),
///   ),
///   selected: _value,
///   onSelected: (bool value) {
///     _value = value;
///     if (value)
///       print('Chosen!');
///     else
///       print('Not Chosen!');
///   },
///   label: new Text('Choose me!'),
/// )
/// ```
///
/// See also:
///
///  * [CircleAvatar], which shows images or initials of people.
///  * <https://material.google.com/components/chips.html>
class ChoiceChip extends StatelessWidget {
  const ChoiceChip({
    Key key,
    this.avatar,
    @required this.label,
    this.labelStyle,
    this.labelPadding,
    this.onSelected,
    @required this.selected,
    this.selectedColor,
    this.disabledColor,
    this.tooltip,
    this.border: const StadiumBorder(),
    this.backgroundColor,
    this.padding,
  })  : assert(selected != null),
        assert(label != null),
        assert(border != null),
        super(key: key);

  /// A widget to display prior to the chip's label.
  ///
  /// Typically a [CircleAvatar] widget.
  final Widget avatar;

  /// The primary content of the chip.
  ///
  /// Typically a [Text] widget.
  final Widget label;

  /// The style to be applied to the chip's label.
  ///
  /// This only has effect on widgets that respect the [DefaultTextStyle],
  /// such as [Text].
  final TextStyle labelStyle;

  /// The padding around the [label] widget.
  ///
  /// By default, this is 4 logical pixels at the beginning and the end of the
  /// label.
  final EdgeInsetsGeometry labelPadding;

  /// Called when the chip should change between selected and deselected states.
  ///
  /// The chip passes the new value to the callback but does not actually
  /// change state until the parent widget rebuilds the chip with the new
  /// value.
  ///
  /// If this callback is null, the chip will be displayed as disabled
  /// and will not respond to input gestures.
  ///
  /// When the chip is tapped, then the [onSelected] callback will be applied to
  /// `!selected`.
  ///
  /// The callback provided to [onSelected] should update the state of the
  /// parent [StatefulWidget] using the [State.setState] method, so that the
  /// parent gets rebuilt, for example:
  ///
  /// ## Sample code
  ///
  /// ```dart
  /// class Wood extends StatefulWidget {
  ///   @override
  ///   State<StatefulWidget> createState() => new WoodState();
  /// }
  ///
  /// class WoodState extends State<Wood> {
  ///   bool _useChisel;
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     return new ChoiceChip(
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
  final ValueChanged<bool> onSelected;

  /// Whether or not this chip has been selected.
  ///
  /// Cannot be null.
  final bool selected;

  /// Color to be used for the chip's background indicating that it is disabled.
  ///
  /// The chip is disabled when [onSelected] is null.
  final Color disabledColor;

  /// Color to be used for the chip's background indicating that it is selected.
  ///
  /// The chip is selected when [selected] is true.
  final Color selectedColor;

  /// Tooltip string to be used for the label and avatar area of the chip.
  ///
  /// This has no effect when [onSelected] is null, since no action will occur.
  final String tooltip;

  /// The border to draw around the chip.
  ///
  /// Defaults to a [StadiumBorder]. May not be null.
  final ShapeBorder border;

  /// Color to be used for the unselected, enabled chip's background.
  ///
  /// Defaults to light grey.
  final Color backgroundColor;

  /// The padding between the contents of the chip and the outside [border].
  ///
  /// Defaults to [EdgeInsets.zero].
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    return new RawChip(
      avatar: avatar,
      label: label,
      labelStyle: labelStyle,
      labelPadding: labelPadding,
      onSelected: onSelected,
      selected: selected,
      showCheckmark: false,
      onDeleted: null,
      tooltip: tooltip,
      border: border,
      disabledColor: disabledColor,
      selectedColor: selectedColor,
      backgroundColor: backgroundColor,
      padding: padding,
      isEnabled: onSelected != null,
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
/// Requires one of its ancestors to be a [Material] widget. The [label]
/// and [border] arguments must not be null.
///
/// ## Sample code
///
/// ```dart
/// new Chip(
///   avatar: new CircleAvatar(
///     backgroundColor: Colors.grey.shade800,
///     child: new Text('AB'),
///   ),
///   label: new Text('Aaron Burr'),
/// )
/// ```
///
/// See also:
///
///  * [CircleAvatar], which shows images or initials of people.
///  * <https://material.google.com/components/chips.html>
class FilterChip extends StatelessWidget {
  const FilterChip({
    Key key,
    this.avatar,
    @required this.label,
    this.labelStyle,
    this.labelPadding,
    this.selected: false,
    @required this.onSelected,
    this.disabledColor,
    this.selectedColor,
    this.tooltip,
    this.border: const StadiumBorder(),
    this.backgroundColor,
    this.padding,
  })  : assert(selected != null),
        assert(label != null),
        assert(border != null),
        super(key: key);

  /// A widget to display prior to the chip's label.
  ///
  /// Typically a [CircleAvatar] widget.
  final Widget avatar;

  /// The primary content of the chip.
  ///
  /// Typically a [Text] widget.
  final Widget label;

  /// The style to be applied to the chip's label.
  ///
  /// This only has effect on widgets that respect the [DefaultTextStyle],
  /// such as [Text].
  final TextStyle labelStyle;

  /// The padding around the [label] widget.
  ///
  /// By default, this is 4 logical pixels at the beginning and the end of the
  /// label.
  final EdgeInsetsGeometry labelPadding;

  /// Whether or not this chip is selected.
  ///
  /// If [onSelected] is not null, this value will be used to determine if the
  /// [selectIcon] will be shown or not. Has no effect if [onSelected] is null.
  ///
  /// May not be null.
  final bool selected;

  /// Called when the chip should change between selected and deselected states.
  ///
  /// The chip passes the new value to the callback but does not actually
  /// change state until the parent widget rebuilds the checkbox with the new
  /// value.
  ///
  /// If this callback is null, the chip will be displayed as disabled
  /// and will not respond to input gestures.
  ///
  /// When the chip is tapped, then the [onSelected] callback, if set, will be
  /// applied to `!value`.
  ///
  /// The callback provided to [onSelected] should update the state of the
  /// parent [StatefulWidget] using the [State.setState] method, so that the
  /// parent gets rebuilt, for example:
  ///
  /// ## Sample code
  ///
  /// ```dart
  /// class Ice extends StatefulWidget {
  ///   @override
  ///   State<StatefulWidget> createState() => new IceState();
  /// }
  ///
  /// class IceState extends State<Ice> {
  ///   bool _useChisel;
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     return new ChoiceChip(
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
  final ValueChanged<bool> onSelected;

  /// Color to be used for the chip's background indicating that it is disabled.
  ///
  /// The chip is disabled when [onSelected] is null.
  ///
  /// It defaults to dark grey.
  final Color disabledColor;

  /// Color to be used for the chip's background indicating that it is selected.
  ///
  /// The chip is selected when [selected] is true.
  final Color selectedColor;

  /// Tooltip string to be used for the label and avatar area of the chip.
  ///
  /// This has no effect when [onSelected] is null, since no action will occur.
  final String tooltip;

  /// The border to draw around the chip.
  ///
  /// Defaults to a [StadiumBorder]. May not be null.
  final ShapeBorder border;

  /// Color to be used for the unselected, enabled chip's background.
  ///
  /// The default is light grey.
  final Color backgroundColor;

  /// The padding between the contents of the chip and the outside [border].
  ///
  /// Defaults to [EdgeInsets.zero].
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    return new RawChip(
      avatar: avatar,
      label: label,
      labelStyle: labelStyle,
      labelPadding: labelPadding,
      onSelected: onSelected,
      selected: selected,
      tooltip: tooltip,
      border: border,
      backgroundColor: backgroundColor,
      disabledColor: disabledColor,
      selectedColor: selectedColor,
      padding: padding,
      isEnabled: onSelected != null,
    );
  }
}

/// A material design action chip.
///
/// Action chips are a set of options which trigger an action related to primary
/// content. Action chips should appear dynamically and contextually in a UI.
///
/// Action chips can be tapped to trigger an action or show progress and
/// confirmation.
///
/// Action chips are displayed after primary content, such as below a card or
/// persistently at the bottom of a screen.
///
/// [MaterialButton]s are an alternative to action chips, which should appear
/// statically and consistently in a UI.
///
/// Requires one of its ancestors to be a [Material] widget. The [onPressed],
/// [label] and [border] arguments must not be null.
///
/// ## Sample code
///
/// ```dart
/// new ActionChip(
///   avatar: new CircleAvatar(
///     backgroundColor: Colors.grey.shade800,
///     child: new Text('AB'),
///   ),
///   label: new Text('Aaron Burr'),
///   onPressed: () {
///     print("If you stand for nothing, Burr, what’ll you fall for?");
///   }
/// )
/// ```
///
/// See also:
///
///  * [MaterialButton] which offers another UI choice for similar situations.
///  * [CircleAvatar], which shows images or initials of people.
///  * <https://material.google.com/components/chips.html>
class ActionChip extends StatelessWidget {
  const ActionChip({
    Key key,
    this.avatar,
    @required this.label,
    this.labelStyle,
    this.labelPadding,
    @required this.onPressed,
    this.tooltip,
    this.border: const StadiumBorder(),
    this.backgroundColor,
    this.padding,
  })  : assert(label != null),
        assert(border != null),
        assert(onPressed != null),
        super(key: key);

  /// A widget to display prior to the chip's label.
  ///
  /// Typically a [CircleAvatar] widget.
  final Widget avatar;

  /// The primary content of the chip.
  ///
  /// Typically a [Text] widget.
  final Widget label;

  /// The style to be applied to the chip's label.
  ///
  /// This only has effect on widgets that respect the [DefaultTextStyle],
  /// such as [Text].
  final TextStyle labelStyle;

  /// The padding around the [label] widget.
  final EdgeInsetsGeometry labelPadding;

  /// Called when the user taps the chip.
  ///
  /// [onPressed] may not be null, and must be supplied.
  ///
  /// If [onPressed] is set, then this callback will be called when the user
  /// taps on the label or avatar parts of the chip. If [onPressed] is null,
  /// then the chip will be disabled.
  ///
  /// ## Sample code
  ///
  /// ```dart
  /// class Granite extends StatelessWidget {
  ///   void startHammering() {
  ///     print('bang bang bang');
  ///   }
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     return new ActionChip(
  ///       label: const Text('Apply Hammer'),
  ///       onPressed: startHammering,
  ///     );
  ///   }
  /// }
  /// ```
  final VoidCallback onPressed;

  /// The tooltip describing what will happen if the user taps the chip.
  final String tooltip;

  /// The border to draw around the chip.
  ///
  /// Defaults to a [StadiumBorder]. May not be null.
  final ShapeBorder border;

  /// Color to be used for the chip's background, the default being grey.
  ///
  /// This color is used as the background of the container that will hold the
  /// widget's label.
  final Color backgroundColor;

  /// The padding between the contents of the chip and the outside [border].
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    return new RawChip(
      avatar: avatar,
      label: label,
      onPressed: onPressed,
      tooltip: tooltip,
      labelStyle: labelStyle,
      backgroundColor: backgroundColor,
      border: border,
      padding: padding,
      labelPadding: labelPadding,
      isEnabled: true,
    );
  }
}

/// A raw material design chip.
///
/// This serves as the basis for all of the chip widget types to aggregate.
/// It is typically not created directly, one of the other chip types
/// that are appropriate for the use case are used instead. The more specific
/// chip types are:
///
///  * [Chip] a simple chip that can only display information and be deleted.
///  * [InputChip] represents a complex piece of information, such as an entity
///    (person, place, or thing) or conversational text, in a compact form.
///  * [ChoiceChip] allows a single selection from a set of options.
///  * [FilterChip] a chip that uses tags or descriptive words as a way to
///    filter content.
///  * [ActionChip] a set of options which trigger an action related to primary
///    content.
///
/// Raw chips are typically only used if you want to create your own custom chip
/// type.
///
/// Raw chips can be selected by setting [onSelected], deleted by setting
/// [onDeleted], and pushed like a button with [onPressed]. They have a [label],
/// and they can have a leading icon (see [avatar]) and a trailing icon
/// ([deleteIcon]). Colors and padding can be customized.
///
/// Requires one of its ancestors to be a [Material] widget. The [label],
/// [isEnabled], and [border] arguments must not be null.
///
/// See also:
///
///  * [CircleAvatar], which shows images or initials of people.
///  * <https://material.google.com/components/chips.html>
class RawChip extends StatefulWidget {
  const RawChip({
    Key key,
    this.avatar,
    @required this.label,
    this.labelStyle,
    EdgeInsetsGeometry labelPadding,
    this.deleteIcon,
    this.onDeleted,
    this.deleteIconColor,
    this.deleteButtonTooltipMessage,
    this.onPressed,
    this.onSelected,
    this.tapEnabled: true,
    this.selected,
    this.showCheckmark: true,
    this.isEnabled: true,
    this.disabledColor,
    this.selectedColor,
    this.tooltip,
    @required this.border,
    this.backgroundColor,
    this.padding: EdgeInsetsDirectional.zero,
  })  : assert(label != null),
        assert(border != null),
        assert(isEnabled != null),
        labelPadding = labelPadding ?? const EdgeInsets.symmetric(horizontal: _kEdgePadding),
        super(key: key);

  /// A widget to display prior to the chip's label.
  ///
  /// Typically a [CircleAvatar] widget.
  final Widget avatar;

  /// The primary content of the chip.
  ///
  /// Typically a [Text] widget.
  final Widget label;

  /// The style to be applied to the chip's label.
  ///
  /// This only has an effect on widgets that respect the [DefaultTextStyle],
  /// such as [Text].
  final TextStyle labelStyle;

  /// The padding around the [label] widget.
  ///
  /// By default, this is 4 logical pixels at the beginning and the end of the
  /// label.
  final EdgeInsetsGeometry labelPadding;

  /// Whether or not this chip is selected.
  ///
  /// If [onSelected] is not null, this value will be used to determine if the
  /// [selectIcon] will be shown or not. Has no effect if [onSelected] is null.
  ///
  /// May not be null.
  final Widget deleteIcon;

  /// Called when the user taps the delete button to delete the chip.
  ///
  /// If null, the delete button will not appear on the chip.
  final VoidCallback onDeleted;

  /// Color for delete icon. The default is based on the ambient [IconTheme].
  final Color deleteIconColor;

  /// The message to be used for the chip's delete button tooltip.
  final String deleteButtonTooltipMessage;

  /// Called when the chip should change between selected and deselected states.
  ///
  /// The chip passes the new value to the callback but does not actually
  /// change state until the parent widget rebuilds the chip with the new
  /// value.
  ///
  /// When the chip is tapped, then the [onSelected] callback, if set, will be
  /// applied to `!selected`.
  ///
  /// The callback provided to [onSelected] should update the state of the
  /// parent [StatefulWidget] using the [State.setState] method, so that the
  /// parent gets rebuilt.
  ///
  /// The [onSelected] and [onPressed] callbacks may not both be specified at
  /// the same time.
  final ValueChanged<bool> onSelected;

  /// Called when the user taps the chip.
  ///
  /// If [onPressed] is set, then this callback will be called when the user
  /// taps on the label or avatar parts of the chip. If [onPressed] is null,
  /// then the chip will be disabled.
  ///
  /// The [onPressed] and [onSelected] callbacks may not both be specified at
  /// the same time.
  final VoidCallback onPressed;

  /// If set, this indicates that the chip should be disabled if all of the
  /// tap callbacks ([onSelected], [onPressed]) are null.
  ///
  /// For example, the [Chip] class sets this to false because it can't be
  /// disabled, even if no callbacks are set on it, since it is used for
  /// displaying information only.
  ///
  /// Defaults to true.
  final bool tapEnabled;

  /// Whether or not this chip is selected.
  ///
  /// If [onSelected] is not null, this value will be used to determine if the
  /// [selectIcon] will be shown or not. Has no effect if [onSelected] is null.
  final bool selected;

  /// Whether or not to show a checkmark when [selected] is true.
  ///
  /// For instance, the [ChoiceChip] sets this to false so that it can be
  /// be selected without showing the checkmark.
  ///
  /// Defaults to true.
  final bool showCheckmark;

  /// Whether or not this chip is enabled for input.
  ///
  /// If this is true, but all three of [onSelected], [onPressed], and
  /// [onDeleted] are null, then the control will still be shown as disabled.
  ///
  /// This is typically only used if you want the chip to be disabled, but also
  /// show a delete button.
  ///
  /// Defaults to true. Cannot be null.
  final bool isEnabled;

  /// Color to be used for the chip's background indicating that it is disabled.
  ///
  /// The chip is disabled when [isEnabled] is false, or all three of
  /// [onDeleted], [onPressed] and [onSelected] are null.
  ///
  /// It defaults to dark grey.
  final Color disabledColor;

  /// Color to be used for the chip's background indicating that it is selected.
  ///
  /// The chip is selected when [selected] is true.
  final Color selectedColor;

  /// Tooltip string to be used for the label and avatar area of the chip.
  ///
  /// This has no effect when [onPressed] and [onSelected] are null, since no
  /// action will occur.
  final String tooltip;

  /// The border to draw around the chip.
  ///
  /// Defaults to a [StadiumBorder]. May not be null.
  final ShapeBorder border;

  /// Color to be used for the unselected, enabled chip's background.
  ///
  /// The default is light grey.
  final Color backgroundColor;

  /// The padding between the contents of the chip and the outside [border].
  ///
  /// Defaults to [EdgeInsets.zero].
  final EdgeInsetsGeometry padding;

  @override
  _RawChipState createState() => new _RawChipState();
}

class _RawChipState extends State<RawChip> with TickerProviderStateMixin<RawChip> {
  static const Duration pressedAnimationDuration = const Duration(milliseconds: 75);

  AnimationController selectController;
  AnimationController avatarDrawerController;
  AnimationController deleteDrawerController;
  AnimationController enableController;
  Animation<double> selectionFade;

  static final Tween<double> pressedShadowTween = new Tween<double>(
    begin: 0.0,
    end: _kPressElevation,
  );
  bool _hadDeleteButton;
  bool _hadAvatar;
  bool _wasEnabled;
  bool _wasSelected;
  bool get hasDeleteButton => widget.onDeleted != null;
  bool get hasAvatar => widget.avatar != null;
  bool get isSelected => widget.selected;

  @override
  void initState() {
    assert(widget.onSelected == null || widget.onPressed == null);
    super.initState();
    selectController = new AnimationController(
      duration: _kSelectDuration,
      value: widget.selected == true ? 1.0 : 0.0,
      vsync: this,
    );
    selectionFade = new CurvedAnimation(
      parent: selectController,
      curve: Curves.fastOutSlowIn,
    )..addListener(() {
        setState(() {});
      });
    avatarDrawerController = new AnimationController(
      duration: _kDrawerDuration,
      value: hasAvatar || isSelected ? 1.0 : 0.0,
      vsync: this,
    );
    deleteDrawerController = new AnimationController(
      duration: _kDrawerDuration,
      value: hasDeleteButton ? 1.0 : 0.0,
      vsync: this,
    );
    enableController = new AnimationController(
      duration: _kDisableDuration,
      value: isEnabled ? 1.0 : 0.0,
      vsync: this,
    );
    _hadDeleteButton = hasDeleteButton;
    _hadAvatar = hasAvatar;
    _wasSelected = isSelected;
  }

  @override
  void dispose() {
    selectController.dispose();
    avatarDrawerController.dispose();
    deleteDrawerController.dispose();
    enableController.dispose();
    super.dispose();
  }

  Widget _wrapWithTooltip(Widget child, String tooltip, VoidCallback callback) {
    if (child == null || callback == null || tooltip == null) {
      return child;
    }
    return new Tooltip(
      message: tooltip,
      child: child,
    );
  }

  bool get isEnabled => widget.isEnabled;
  bool get canTap {
    return isEnabled && widget.tapEnabled && (widget.onPressed != null || widget.onSelected != null);
  }

  bool _isTapping = false;
  bool get isTapping => !canTap ? false : _isTapping;

  void _handleTapDown(TapDownDetails details) {
    if (!canTap) {
      return;
    }
    setState(() {
      _isTapping = true;
    });
  }

  void _handleTapCancel() {
    if (!canTap) {
      return;
    }
    setState(() {
      _isTapping = false;
    });
  }

  void _handleTap() {
    if (!canTap) {
      return;
    }
    setState(() {
      _isTapping = false;
    });
    // Only one of these can be set, so only one will be called.
    widget.onSelected?.call(!widget.selected);
    widget.onPressed?.call();
  }

  Color getBackgroundColor(ThemeData theme) {
    final ColorTween backgroundTween = new ColorTween(
      begin: widget.disabledColor ?? _kDefaultDisabledBackground,
      end: widget.backgroundColor ?? _kDefaultBackground,
    );
    final ColorTween selectTween = new ColorTween(
      begin: backgroundTween.evaluate(enableController),
      end: widget.selectedColor ?? _kSelectedColor,
    );
    return selectTween.evaluate(selectionFade);
  }

  void _reactToChanges() {
    if (_wasEnabled != isEnabled) {
      setState(() {
        if (isEnabled) {
          enableController.forward();
        } else {
          enableController.reverse();
        }
        _wasEnabled = isEnabled;
      });
    }
    if (_hadAvatar != hasAvatar || _wasSelected != isSelected) {
      setState(() {
        if (hasAvatar || isSelected) {
          avatarDrawerController.forward();
        } else {
          avatarDrawerController.reverse();
        }
        _hadAvatar = hasAvatar;
      });
    }
    if (_wasSelected != isSelected) {
      setState(() {
        if (isSelected) {
          selectController.forward();
        } else {
          selectController.reverse();
        }
        _wasSelected = isSelected;
      });
    }
    if (_hadDeleteButton != hasDeleteButton) {
      setState(() {
        if (hasDeleteButton) {
          deleteDrawerController.forward();
        } else {
          deleteDrawerController.reverse();
        }
        _hadDeleteButton = hasDeleteButton;
      });
    }
  }

  Widget _buildDeleteIcon(BuildContext context, ThemeData theme) {
    if (!hasDeleteButton) {
      return null;
    }
    return _wrapWithTooltip(
      new InkResponse(
        onTap: widget.isEnabled ? widget.onDeleted : null,
        child: new Container(
          child: new IconTheme(
            data: theme.iconTheme.copyWith(
              color: widget.deleteIconColor ?? theme.iconTheme.color,
              opacity: _kDeleteIconOpacity,
            ),
            child: widget.deleteIcon ?? const Icon(Icons.cancel, size: _kDeleteIconSize),
          ),
        ),
      ),
      widget.deleteButtonTooltipMessage ?? MaterialLocalizations.of(context).deleteButtonTooltip,
      widget.onDeleted,
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    final ThemeData theme = Theme.of(context);
    final TextDirection textDirection = Directionality.of(context);
    _reactToChanges();
    return new DefaultTextStyle(
      overflow: TextOverflow.fade,
      textAlign: TextAlign.start,
      maxLines: 1,
      softWrap: false,
      style: widget.labelStyle ??
          theme.textTheme.body2.copyWith(
            color: Colors.black.withAlpha(_kTextLabelAlpha),
          ),
      child: new Material(
        elevation: isTapping ? _kPressElevation : 0.0,
        animationDuration: pressedAnimationDuration,
        shape: widget.border,
        child: new InkResponse(
          onTap: canTap ? _handleTap : null,
          onTapDown: canTap ? _handleTapDown : null,
          onTapCancel: canTap ? _handleTapCancel : null,
          child: new Container(
            decoration: new ShapeDecoration(
              shape: widget.border,
              color: getBackgroundColor(theme),
            ),
            child: _wrapWithTooltip(
                new _ChipRenderWidget(
                  theme: new _ChipRenderTheme(
                    label: widget.label,
                    avatar: new AutoFade(
                      child: widget.avatar,
                      duration: _kDrawerDuration,
                      curve: Curves.fastOutSlowIn,
                    ),
                    deleteIcon: new AutoFade(
                      child: _buildDeleteIcon(context, theme),
                      duration: _kDrawerDuration,
                      curve: Curves.fastOutSlowIn,
                    ),
                    padding: widget.padding?.resolve(textDirection) ?? EdgeInsets.zero,
                    labelPadding: widget.labelPadding?.resolve(textDirection) ?? EdgeInsets.zero,
                    showAvatar: hasAvatar,
                    showCheckmark: widget.showCheckmark,
                    canTapBody: canTap,
                  ),
                  value: widget.selected,
                  selectController: selectController,
                  enableController: enableController,
                  avatarDrawerController: avatarDrawerController,
                  deleteDrawerController: deleteDrawerController,
                  isEnabled: isEnabled,
                ),
                widget.tooltip,
                widget.onPressed),
          ),
        ),
      ),
    );
  }
}

class _ChipRenderWidget extends RenderObjectWidget {
  const _ChipRenderWidget({
    Key key,
    @required this.theme,
    this.value,
    this.isEnabled,
    this.selectController,
    this.avatarDrawerController,
    this.deleteDrawerController,
    this.enableController,
  })  : assert(theme != null),
        super(key: key);

  final _ChipRenderTheme theme;
  final bool value;
  final bool isEnabled;
  final AnimationController selectController;
  final AnimationController avatarDrawerController;
  final AnimationController deleteDrawerController;
  final AnimationController enableController;

  @override
  _RenderChipElement createElement() => new _RenderChipElement(this);

  @override
  void updateRenderObject(BuildContext context, _RenderChip renderObject) {
    renderObject
      ..theme = theme
      ..textDirection = Directionality.of(context)
      ..value = value
      ..isEnabled = isEnabled
      ..selectController = selectController
      ..avatarDrawerController = avatarDrawerController
      ..deleteDrawerController = deleteDrawerController
      ..enableController = enableController;
  }

  @override
  RenderObject createRenderObject(BuildContext context) {
    return new _RenderChip(
      theme: theme,
      textDirection: Directionality.of(context),
      value: value,
      isEnabled: isEnabled,
      selectController: selectController,
      avatarDrawerController: avatarDrawerController,
      deleteDrawerController: deleteDrawerController,
      enableController: enableController,
    );
  }
}

enum _ChipSlot {
  label,
  avatar,
  deleteIcon,
}

class _RenderChipElement extends RenderObjectElement {
  _RenderChipElement(_ChipRenderWidget chip) : super(chip);

  final Map<_ChipSlot, Element> slotToChild = <_ChipSlot, Element>{};
  final Map<Element, _ChipSlot> childToSlot = <Element, _ChipSlot>{};

  @override
  _ChipRenderWidget get widget => super.widget;

  @override
  _RenderChip get renderObject => super.renderObject;

  @override
  void visitChildren(ElementVisitor visitor) {
    slotToChild.values.forEach(visitor);
  }

  @override
  void forgetChild(Element child) {
    assert(slotToChild.values.contains(child));
    assert(childToSlot.keys.contains(child));
    final _ChipSlot slot = childToSlot[child];
    childToSlot.remove(child);
    slotToChild.remove(slot);
  }

  void _mountChild(Widget widget, _ChipSlot slot) {
    final Element oldChild = slotToChild[slot];
    final Element newChild = updateChild(oldChild, widget, slot);
    if (oldChild != null) {
      slotToChild.remove(slot);
      childToSlot.remove(oldChild);
    }
    if (newChild != null) {
      slotToChild[slot] = newChild;
      childToSlot[newChild] = slot;
    }
  }

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _mountChild(widget.theme.avatar, _ChipSlot.avatar);
    _mountChild(widget.theme.deleteIcon, _ChipSlot.deleteIcon);
    _mountChild(widget.theme.label, _ChipSlot.label);
  }

  void _updateChild(Widget widget, _ChipSlot slot) {
    final Element oldChild = slotToChild[slot];
    final Element newChild = updateChild(oldChild, widget, slot);
    if (oldChild != null) {
      childToSlot.remove(oldChild);
      slotToChild.remove(slot);
    }
    if (newChild != null) {
      slotToChild[slot] = newChild;
      childToSlot[newChild] = slot;
    }
  }

  @override
  void update(_ChipRenderWidget newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _updateChild(widget.theme.label, _ChipSlot.label);
    _updateChild(widget.theme.avatar, _ChipSlot.avatar);
    _updateChild(widget.theme.deleteIcon, _ChipSlot.deleteIcon);
  }

  void _updateRenderObject(RenderObject child, _ChipSlot slot) {
    switch (slot) {
      case _ChipSlot.avatar:
        renderObject.avatar = child;
        break;
      case _ChipSlot.label:
        renderObject.label = child;
        break;
      case _ChipSlot.deleteIcon:
        renderObject.deleteIcon = child;
        break;
    }
  }

  @override
  void insertChildRenderObject(RenderObject child, dynamic slotValue) {
    assert(child is RenderBox);
    assert(slotValue is _ChipSlot);
    final _ChipSlot slot = slotValue;
    _updateRenderObject(child, slot);
    assert(renderObject.childToSlot.keys.contains(child));
    assert(renderObject.slotToChild.keys.contains(slot));
  }

  @override
  void removeChildRenderObject(RenderObject child) {
    assert(child is RenderBox);
    assert(renderObject.childToSlot.keys.contains(child));
    _updateRenderObject(null, renderObject.childToSlot[child]);
    assert(!renderObject.childToSlot.keys.contains(child));
    assert(!renderObject.slotToChild.keys.contains(slot));
  }

  @override
  void moveChildRenderObject(RenderObject child, dynamic slotValue) {
    assert(false, 'not reachable');
  }
}

class _ChipRenderTheme {
  const _ChipRenderTheme({
    @required this.avatar,
    @required this.label,
    @required this.deleteIcon,
    @required this.padding,
    @required this.labelPadding,
    @required this.showAvatar,
    @required this.showCheckmark,
    @required this.canTapBody,
  });

  final Widget avatar;
  final Widget label;
  final Widget deleteIcon;
  final EdgeInsets padding;
  final EdgeInsets labelPadding;
  final bool showAvatar;
  final bool showCheckmark;
  final bool canTapBody;

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final _ChipRenderTheme typedOther = other;
    return typedOther.avatar == avatar &&
        typedOther.label == label &&
        typedOther.deleteIcon == deleteIcon &&
        typedOther.padding == padding &&
        typedOther.labelPadding == labelPadding &&
        typedOther.showAvatar == showAvatar &&
        typedOther.showCheckmark == showCheckmark &&
        typedOther.canTapBody == canTapBody;
  }

  @override
  int get hashCode {
    return hashValues(
      avatar,
      label,
      deleteIcon,
      padding,
      labelPadding,
      showAvatar,
      showCheckmark,
      canTapBody,
    );
  }
}

class _RenderChip extends RenderBox {
  _RenderChip({
    @required _ChipRenderTheme theme,
    @required TextDirection textDirection,
    this.value,
    this.isEnabled,
    this.selectController,
    this.avatarDrawerController,
    this.deleteDrawerController,
    this.enableController,
  })  : assert(theme != null),
        assert(textDirection != null),
        _theme = theme,
        _textDirection = textDirection {
    if (selectController != null) {
      // These will delay the start of some animations, and/or reduce their
      // length compared to the overall select animation, using Intervals.
      final double checkmarkPercentage =
          _kCheckmarkDuration.inMilliseconds / _kSelectDuration.inMilliseconds;
      final double checkmarkReversePercentage =
          _kCheckmarkReverseDuration.inMilliseconds / _kSelectDuration.inMilliseconds;
      final double selectReversePercentage =
          _kSelectReverseDuration.inMilliseconds / _kSelectDuration.inMilliseconds;
      selectAnimation = new CurvedAnimation(
        parent: selectController,
        curve: new Interval(
          0.0,
          checkmarkPercentage,
          curve: Curves.fastOutSlowIn,
        ),
        reverseCurve: new Interval(0.0, selectReversePercentage, curve: Curves.fastOutSlowIn),
      )..addListener(markNeedsPaint);
      checkmarkAnimation = new CurvedAnimation(
        parent: selectController,
        curve: new Interval(1.0 - checkmarkPercentage, 1.0, curve: Curves.fastOutSlowIn),
        reverseCurve: new Interval(
          1.0 - checkmarkReversePercentage,
          1.0,
          curve: Curves.fastOutSlowIn,
        ),
      )..addListener(markNeedsPaint);
    }
    if (deleteDrawerController != null) {
      deleteDrawerAnimation = new CurvedAnimation(
        parent: deleteDrawerController,
        curve: Curves.fastOutSlowIn,
      )..addListener(markNeedsLayout);
    }
    if (avatarDrawerController != null) {
      avatarDrawerAnimation = new CurvedAnimation(
        parent: avatarDrawerController,
        curve: Curves.fastOutSlowIn,
      )..addListener(markNeedsLayout);
    }
    if (enableController != null) {
      enableAnimation = new CurvedAnimation(
        parent: enableController,
        curve: Curves.fastOutSlowIn,
      )..addListener(markNeedsPaint);
    }
  }

  // Set this to true to have outlines of the tap targets drawn over
  // the chip.  This should never be checked in while set to 'true'.
  static const bool _debugShowTapTargetOutlines = false;
  static const EdgeInsets _iconPadding = const EdgeInsets.all(_kEdgePadding);

  final Map<_ChipSlot, RenderBox> slotToChild = <_ChipSlot, RenderBox>{};
  final Map<RenderBox, _ChipSlot> childToSlot = <RenderBox, _ChipSlot>{};

  bool value;
  bool isEnabled;
  Rect deleteButtonRect;
  Rect _pressRect;
  AnimationController selectController;
  AnimationController avatarDrawerController;
  AnimationController deleteDrawerController;
  AnimationController enableController;
  Animation<double> selectAnimation;
  Animation<double> checkmarkAnimation;
  Animation<double> avatarDrawerAnimation;
  Animation<double> deleteDrawerAnimation;
  Animation<double> enableAnimation;

  RenderBox _updateChild(RenderBox oldChild, RenderBox newChild, _ChipSlot slot) {
    if (oldChild != null) {
      dropChild(oldChild);
      childToSlot.remove(oldChild);
      slotToChild.remove(slot);
    }
    if (newChild != null) {
      childToSlot[newChild] = slot;
      slotToChild[slot] = newChild;
      adoptChild(newChild);
    }
    return newChild;
  }

  RenderBox _avatar;
  RenderBox get avatar => _avatar;
  set avatar(RenderBox value) {
    _avatar = _updateChild(_avatar, value, _ChipSlot.avatar);
  }

  RenderBox _deleteIcon;
  RenderBox get deleteIcon => _deleteIcon;
  set deleteIcon(RenderBox value) {
    _deleteIcon = _updateChild(_deleteIcon, value, _ChipSlot.deleteIcon);
  }

  RenderBox _label;
  RenderBox get label => _label;
  set label(RenderBox value) {
    _label = _updateChild(_label, value, _ChipSlot.label);
  }

  _ChipRenderTheme get theme => _theme;
  _ChipRenderTheme _theme;
  set theme(_ChipRenderTheme value) {
    if (_theme == value) {
      return;
    }
    _theme = value;
    markNeedsLayout();
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
    markNeedsLayout();
  }

  // The returned list is ordered for hit testing.
  Iterable<RenderBox> get _children sync* {
    if (avatar != null) {
      yield avatar;
    }
    if (label != null) {
      yield label;
    }
    if (deleteIcon != null) {
      yield deleteIcon;
    }
  }

  bool get isDrawingCheckmark => theme.showCheckmark && !(selectController?.isDismissed ?? !value);
  bool get deleteButtonShowing => !deleteDrawerAnimation.isDismissed;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    for (RenderBox child in _children) {
      child.attach(owner);
    }
  }

  @override
  void detach() {
    super.detach();
    for (RenderBox child in _children) {
      child.detach();
    }
  }

  @override
  void redepthChildren() {
    _children.forEach(redepthChild);
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    _children.forEach(visitor);
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final List<DiagnosticsNode> value = <DiagnosticsNode>[];
    void add(RenderBox child, String name) {
      if (child != null) {
        value.add(child.toDiagnosticsNode(name: name));
      }
    }

    add(avatar, 'avatar');
    add(label, 'label');
    add(deleteIcon, 'deleteIcon');
    return value;
  }

  @override
  bool get sizedByParent => false;

  static double _minWidth(RenderBox box, double height) {
    return box == null ? 0.0 : box.getMinIntrinsicWidth(height);
  }

  static double _maxWidth(RenderBox box, double height) {
    return box == null ? 0.0 : box.getMaxIntrinsicWidth(height);
  }

  static double _minHeight(RenderBox box, double width) {
    return box == null ? 0.0 : box.getMinIntrinsicWidth(width);
  }

  static Size _boxSize(RenderBox box) => box == null ? Size.zero : box.size;

  static Rect _boxRect(RenderBox box) => box == null ? Rect.zero : _boxParentData(box).offset & box.size;

  static BoxParentData _boxParentData(RenderBox box) => box.parentData;

  @override
  double computeMinIntrinsicWidth(double height) {
    // The overall padding isn't affected by missing avatar or delete icon
    // because we add the padding regardless to give extra padding for the label
    // when they're missing.
    final double overallPadding = theme.labelPadding.horizontal + _iconPadding.horizontal * 2.0;
    return overallPadding + _minWidth(avatar, height) + _minWidth(label, height) + _minWidth(deleteIcon, height);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    // The overall padding isn't affected by missing avatar or delete icon
    // because we add the padding regardless to give extra padding for the label
    // when they're missing.
    final double overallPadding = theme.labelPadding.horizontal + _iconPadding.horizontal * 2.0;
    return overallPadding + _maxWidth(avatar, height) + _maxWidth(label, height) + _maxWidth(deleteIcon, height);
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    // This widget is sized to the height of the label only, as long as it's
    // larger than _kChipHeight.  The other widgets are sized to match the
    // label.
    return math.max(_kChipHeight, theme.labelPadding.vertical + _minHeight(label, width));
  }

  @override
  double computeMaxIntrinsicHeight(double width) => computeMinIntrinsicHeight(width);

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    // The baseline of this widget is the baseline of the label.
    return label.computeDistanceToActualBaseline(baseline);
  }

  @override
  void performLayout() {
    double iconPlusPadding = _kChipHeight;
    double iconSize;
    label.layout(constraints.loosen(), parentUsesSize: true);
    // Now that we know the height, we can determine how much to shrink the
    // constraints by for the "real" layout. Ignored if the constraints are
    // infinite.
    iconPlusPadding = math.max(iconPlusPadding, _boxSize(label).height);
    iconSize = iconPlusPadding - _iconPadding.vertical;
    if (constraints.maxWidth.isFinite) {
      final double allPadding = _iconPadding.horizontal * 2.0 + theme.labelPadding.horizontal;
      final double iconSizes = (avatar != null ? iconSize : 0.0) + (deleteIcon != null ? iconSize : 0.0);
      label.layout(
        constraints.loosen().copyWith(
              maxWidth: math.max(0.0, constraints.maxWidth - iconSizes - allPadding),
            ),
        parentUsesSize: true,
      );
    }
    final double labelWidth = theme.labelPadding.horizontal + _boxSize(label).width;
    final BoxConstraints iconConstraints = new BoxConstraints.tightFor(
      width: iconSize,
      height: iconSize,
    );

    final double drawerScale = avatarDrawerAnimation.value;

    double avatarWidth = _iconPadding.horizontal;
    if (avatar != null) {
      avatar.layout(iconConstraints, parentUsesSize: true);
      if (theme.showCheckmark || theme.showAvatar) {
        avatarWidth += drawerScale * _boxSize(avatar).width;
      }
    } else if (theme.showCheckmark || theme.showAvatar) {
      avatarWidth += iconSize * drawerScale;
    }
    double deleteIconWidth = _iconPadding.horizontal;
    if (deleteIcon != null) {
      deleteIcon.layout(iconConstraints, parentUsesSize: true);
      deleteIconWidth += deleteDrawerAnimation.value * _boxSize(deleteIcon).width;
    } else {
      deleteIconWidth += iconSize * deleteDrawerAnimation.value;
    }
    final double overallWidth = avatarWidth + labelWidth + deleteIconWidth + theme.padding.horizontal;
    final double overallHeight = iconPlusPadding + theme.padding.vertical;

    // Now we have all of the dimensions. Place the children where they belong.

    double centerLayout(RenderBox box, double x) {
      _boxParentData(box).offset = new Offset(
        x,
        theme.padding.top + (iconPlusPadding - box.size.height) / 2.0,
      );
      return box.size.width;
    }

    const double left = 0.0;
    final double right = overallWidth;

    switch (textDirection) {
      case TextDirection.rtl:
        double start = right - theme.padding.right - _iconPadding.right;
        if (theme.showCheckmark || theme.showAvatar) {
          if (avatar != null) {
            start -= drawerScale * centerLayout(avatar, start - avatar.size.width);
          } else {
            start -= drawerScale * iconSize;
          }
        }
        start -= _iconPadding.left + theme.labelPadding.right;
        start -= centerLayout(label, start - label.size.width);
        start -= theme.labelPadding.left + _iconPadding.right;
        if (deleteButtonShowing && deleteIcon != null) {
          deleteButtonRect = new Rect.fromLTWH(
            0.0,
            0.0,
            iconSize + theme.padding.right + _iconPadding.horizontal,
            iconPlusPadding + theme.padding.vertical,
          );
          start -= deleteDrawerAnimation.value *
              centerLayout(
                deleteIcon,
                theme.padding.left + _iconPadding.left,
              );
        } else {
          deleteButtonRect = Rect.zero;
          start -= deleteDrawerAnimation.value * iconSize;
        }
        if (theme.canTapBody) {
          _pressRect = new Rect.fromLTWH(
            deleteButtonRect.width,
            0.0,
            overallWidth - deleteButtonRect.width,
            iconPlusPadding + theme.padding.vertical,
          );
        } else {
          _pressRect = Rect.zero;
        }
        break;
      case TextDirection.ltr:
        double start = left + theme.padding.left + _iconPadding.left;
        if (theme.showCheckmark || theme.showAvatar) {
          if (avatar != null) {
            start += drawerScale * centerLayout(avatar, start);
          } else {
            start += drawerScale * iconSize;
          }
        }
        start += _iconPadding.right + theme.labelPadding.left;
        start += centerLayout(label, start);
        start += theme.labelPadding.right;
        if (theme.canTapBody) {
          _pressRect = new Rect.fromLTWH(
            0.0,
            0.0,
            deleteButtonShowing ? start : overallWidth,
            iconPlusPadding + theme.padding.vertical,
          );
        } else {
          _pressRect = Rect.zero;
        }
        if (deleteButtonShowing && deleteIcon != null) {
          deleteButtonRect = new Rect.fromLTWH(
            start,
            0.0,
            iconSize + theme.padding.right + _iconPadding.horizontal,
            iconPlusPadding + theme.padding.vertical,
          );
          centerLayout(
            deleteIcon,
            overallWidth - theme.padding.right - _iconPadding.right - _boxSize(deleteIcon).width,
          );
        } else {
          deleteButtonRect = Rect.zero;
        }
        break;
    }

    size = constraints.constrain(new Size(overallWidth, overallHeight));
    assert(size.width == constraints.constrainWidth(overallWidth));
    assert(size.height == constraints.constrainHeight(overallHeight));
  }

  static final ColorTween enableTween = new ColorTween(
    begin: Colors.white.withAlpha(_kDisabledAlpha),
    end: Colors.white,
  );

  static final ColorTween selectionScrimTween = new ColorTween(
    begin: Colors.transparent,
    end: _kSelectScrimColor,
  );

  Color get _disabledColor {
    if (enableAnimation == null || enableAnimation.isCompleted) {
      return Colors.white;
    }
    return enableTween.evaluate(enableAnimation);
  }

  void _paintCheck(Canvas canvas, Offset origin, double size) {
    Color paintColor = theme.showAvatar ? Colors.white : Colors.black87;
    final ColorTween fadeTween = new ColorTween(begin: Colors.transparent, end: paintColor);

    paintColor = checkmarkAnimation.status == AnimationStatus.reverse
        ? fadeTween.evaluate(checkmarkAnimation)
        : paintColor;

    final Paint paint = new Paint()
      ..color = paintColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _kCheckmarkStrokeWidth * (avatar != null ? avatar.size.height / 24.0 : 1.0);
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
    final Path path = new Path();
    final Offset start = new Offset(size * 0.15, size * 0.45);
    final Offset mid = new Offset(size * 0.4, size * 0.7);
    final Offset end = new Offset(size * 0.85, size * 0.25);
    if (t < 0.5) {
      final double strokeT = t * 2.0;
      final Offset drawMid = Offset.lerp(start, mid, strokeT);
      path.moveTo(origin.dx + start.dx, origin.dy + start.dy);
      path.lineTo(origin.dx + drawMid.dx, origin.dy + drawMid.dy);
    } else {
      final double strokeT = (t - 0.5) * 2.0;
      final Offset drawEnd = Offset.lerp(mid, end, strokeT);
      path.moveTo(origin.dx + start.dx, origin.dy + start.dy);
      path.lineTo(origin.dx + mid.dx, origin.dy + mid.dy);
      path.lineTo(origin.dx + drawEnd.dx, origin.dy + drawEnd.dy);
    }
    canvas.drawPath(path, paint);
  }

  void _paintSelectionOverlay(PaintingContext context, Offset offset) {
    if (isDrawingCheckmark) {
      final Rect avatarRect = _boxRect(avatar).shift(offset);
      final Paint darkenPaint = new Paint()
        ..color = selectionScrimTween.evaluate(checkmarkAnimation)
        ..blendMode = BlendMode.srcATop;
      context.canvas.drawRect(avatarRect, darkenPaint);
      final double checkSize = avatar.size.height * 0.75;
      final Offset checkOffset = _boxParentData(avatar).offset +
          new Offset(avatar.size.height * 0.125, avatar.size.height * 0.125);
      _paintCheck(context.canvas, offset + checkOffset, checkSize);
    }
  }

  void _paintAvatar(PaintingContext context, Offset offset) {
    if (theme.showAvatar == false && avatarDrawerAnimation.isDismissed) {
      return;
    }
    if (needsCompositing) {
      context.pushLayer(
        new OpacityLayer(alpha: _disabledColor.alpha),
        (PaintingContext context, Offset offset) {
          context.paintChild(avatar, _boxParentData(avatar).offset + offset);
          _paintSelectionOverlay(context, offset);
        },
        offset,
      );
    } else {
      final Rect childRect = _boxRect(avatar).shift(offset);
      context.canvas.saveLayer(childRect.inflate(20.0), new Paint()..color = _disabledColor);
      context.paintChild(avatar, _boxParentData(avatar).offset + offset);
      _paintSelectionOverlay(context, offset);
      context.canvas.restore();
    }
  }

  void _paintChild(PaintingContext context, Offset offset, RenderBox child, bool isEnabled) {
    if (child == null) {
      return;
    }
    if (!enableAnimation.isCompleted) {
      if (needsCompositing) {
        context.pushLayer(
          new OpacityLayer(alpha: _disabledColor.alpha),
          (PaintingContext context, Offset offset) {
            context.paintChild(child, _boxParentData(child).offset + offset);
          },
          offset,
        );
      } else {
        final Rect childRect = _boxRect(child).shift(offset);
        context.canvas.saveLayer(childRect.inflate(20.0), new Paint()..color = _disabledColor);
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
    _paintChild(context, offset, deleteIcon, isEnabled);
    _paintChild(context, offset, label, isEnabled);
  }

  @override
  void debugPaint(PaintingContext context, Offset offset) {
    assert(!_debugShowTapTargetOutlines ||
        () {
          // Draws a rect around the tap targets to help with visualizing where
          // they really are.
          final Paint outlinePaint = new Paint()
            ..color = const Color(0xff800000)
            ..strokeWidth = 1.0
            ..style = PaintingStyle.stroke;
          if (deleteIcon != null) {
            context.canvas.drawRect(deleteButtonRect.shift(offset), outlinePaint);
          }
          context.canvas.drawRect(
            _pressRect.shift(offset),
            outlinePaint..color = const Color(0xff008000),
          );
          return true;
        }());
  }

  @override
  bool hitTestSelf(Offset position) => deleteButtonRect.contains(position) || _pressRect.contains(position);

  @override
  bool hitTestChildren(HitTestResult result, {@required Offset position}) {
    assert(position != null);
    if (deleteIcon != null && deleteButtonRect.contains(position)) {
      // This simulates a position at the center of the delete icon if the hit
      // on the chip is inside of the delete area.
      return deleteIcon.hitTest(result, position: (Offset.zero & _boxSize(deleteIcon)).center);
    }
    for (RenderBox child in _children) {
      if (child.hasSize &&
          child.hitTest(result, position: position - _boxParentData(child).offset)) {
        return true;
      }
    }
    return false;
  }
}
