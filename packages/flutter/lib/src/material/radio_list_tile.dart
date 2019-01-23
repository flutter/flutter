// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'list_tile.dart';
import 'radio.dart';
import 'theme.dart';
import 'theme_data.dart';

// Examples can assume:
// void setState(VoidCallback fn) { }

/// A [ListTile] with a [Radio]. In other words, a radio button with a label.
///
/// The entire list tile is interactive: tapping anywhere in the tile selects
/// the radio button.
///
/// The [value], [groupValue], [onChanged], and [activeColor] properties of this
/// widget are identical to the similarly-named properties on the [Radio]
/// widget. The type parameter `T` serves the same purpose as that of the
/// [Radio] class' type parameter.
///
/// The [title], [subtitle], [isThreeLine], and [dense] properties are like
/// those of the same name on [ListTile].
///
/// The [selected] property on this widget is similar to the [ListTile.selected]
/// property, but the color used is that described by [activeColor], if any,
/// defaulting to the accent color of the current [Theme]. No effort is made to
/// coordinate the [selected] state and the [checked] state; to have the list
/// tile appear selected when the radio button is the selected radio button, set
/// [selected] to true when [value] matches [groupValue].
///
/// The radio button is shown on the left by default in left-to-right languages
/// (i.e. the leading edge). This can be changed using [controlAffinity]. The
/// [secondary] widget is placed on the opposite side. This maps to the
/// [ListTile.leading] and [ListTile.trailing] properties of [ListTile].
///
/// To show the [RadioListTile] as disabled, pass null as the [onChanged]
/// callback.
///
/// {@tool sample}
///
/// This widget shows a pair of radio buttons that control the `_character`
/// field. The field is of the type `SingingCharacter`, an enum.
///
/// ```dart
/// // At the top level:
/// enum SingingCharacter { lafayette, jefferson }
///
/// // In the State of a stateful widget:
/// SingingCharacter _character = SingingCharacter.lafayette;
///
/// // In the build function of that State:
/// Column(
///   children: <Widget>[
///     RadioListTile<SingingCharacter>(
///       title: const Text('Lafayette'),
///       value: SingingCharacter.lafayette,
///       groupValue: _character,
///       onChanged: (SingingCharacter value) { setState(() { _character = value; }); },
///     ),
///     RadioListTile<SingingCharacter>(
///       title: const Text('Thomas Jefferson'),
///       value: SingingCharacter.jefferson,
///       groupValue: _character,
///       onChanged: (SingingCharacter value) { setState(() { _character = value; }); },
///     ),
///   ],
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [ListTileTheme], which can be used to affect the style of list tiles,
///    including radio list tiles.
///  * [CheckboxListTile], a similar widget for checkboxes.
///  * [SwitchListTile], a similar widget for switches.
///  * [ListTile] and [Radio], the widgets from which this widget is made.
class RadioListTile<T> extends StatelessWidget {
  /// Creates a combination of a list tile and a radio button.
  ///
  /// The radio tile itself does not maintain any state. Instead, when the radio
  /// button is selected, the widget calls the [onChanged] callback. Most
  /// widgets that use a radio button will listen for the [onChanged] callback
  /// and rebuild the radio tile with a new [groupValue] to update the visual
  /// appearance of the radio button.
  ///
  /// The following arguments are required:
  ///
  /// * [value] and [groupValue] together determine whether the radio button is
  ///   selected.
  /// * [onChanged] is called when the user selects this radio button.
  const RadioListTile({
    Key key,
    @required this.value,
    @required this.groupValue,
    @required this.onChanged,
    this.activeColor,
    this.title,
    this.subtitle,
    this.isThreeLine = false,
    this.dense,
    this.secondary,
    this.selected = false,
    this.controlAffinity = ListTileControlAffinity.platform,
  }) : assert(isThreeLine != null),
       assert(!isThreeLine || subtitle != null),
       assert(selected != null),
       assert(controlAffinity != null),
       super(key: key);

  /// The value represented by this radio button.
  final T value;

  /// The currently selected value for this group of radio buttons.
  ///
  /// This radio button is considered selected if its [value] matches the
  /// [groupValue].
  final T groupValue;

  /// Called when the user selects this radio button.
  ///
  /// The radio button passes [value] as a parameter to this callback. The radio
  /// button does not actually change state until the parent widget rebuilds the
  /// radio tile with the new [groupValue].
  ///
  /// If null, the radio button will be displayed as disabled.
  ///
  /// The callback provided to [onChanged] should update the state of the parent
  /// [StatefulWidget] using the [State.setState] method, so that the parent
  /// gets rebuilt; for example:
  ///
  /// ```dart
  /// RadioListTile<SingingCharacter>(
  ///   title: const Text('Lafayette'),
  ///   value: SingingCharacter.lafayette,
  ///   groupValue: _character,
  ///   onChanged: (SingingCharacter newValue) {
  ///     setState(() {
  ///       _character = newValue;
  ///     });
  ///   },
  /// )
  /// ```
  final ValueChanged<T> onChanged;

  /// The color to use when this radio button is selected.
  ///
  /// Defaults to accent color of the current [Theme].
  final Color activeColor;

  /// The primary content of the list tile.
  ///
  /// Typically a [Text] widget.
  final Widget title;

  /// Additional content displayed below the title.
  ///
  /// Typically a [Text] widget.
  final Widget subtitle;

  /// A widget to display on the opposite side of the tile from the radio button.
  ///
  /// Typically an [Icon] widget.
  final Widget secondary;

  /// Whether this list tile is intended to display three lines of text.
  ///
  /// If false, the list tile is treated as having one line if the subtitle is
  /// null and treated as having two lines if the subtitle is non-null.
  final bool isThreeLine;

  /// Whether this list tile is part of a vertically dense list.
  ///
  /// If this property is null then its value is based on [ListTileTheme.dense].
  final bool dense;

  /// Whether to render icons and text in the [activeColor].
  ///
  /// No effort is made to automatically coordinate the [selected] state and the
  /// [checked] state. To have the list tile appear selected when the radio
  /// button is the selected radio button, set [selected] to true when [value]
  /// matches [groupValue].
  ///
  /// Normally, this property is left to its default value, false.
  final bool selected;

  /// Where to place the control relative to the text.
  final ListTileControlAffinity controlAffinity;

  /// Whether this radio button is checked.
  ///
  /// To control this value, set [value] and [groupValue] appropriately.
  bool get checked => value == groupValue;

  @override
  Widget build(BuildContext context) {
    final Widget control = Radio<T>(
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: activeColor,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    Widget leading, trailing;
    switch (controlAffinity) {
      case ListTileControlAffinity.leading:
      case ListTileControlAffinity.platform:
        leading = control;
        trailing = secondary;
        break;
      case ListTileControlAffinity.trailing:
        leading = secondary;
        trailing = control;
        break;
    }
    return MergeSemantics(
      child: ListTileTheme.merge(
        selectedColor: activeColor ?? Theme.of(context).accentColor,
        child: ListTile(
          leading: leading,
          title: title,
          subtitle: subtitle,
          trailing: trailing,
          isThreeLine: isThreeLine,
          dense: dense,
          enabled: onChanged != null,
          onTap: onChanged != null ? () { onChanged(value); } : null,
          selected: selected,
        ),
      ),
    );
  }
}
