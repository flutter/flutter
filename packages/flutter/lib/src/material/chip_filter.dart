// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'chip.dart';
import 'debug.dart';
import 'theme_data.dart';

/// A Material Design filter chip.
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
    super.key,
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
