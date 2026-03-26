// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'dart:developer';
///
/// @docImport 'package:flutter/rendering.dart';
/// @docImport 'package:flutter/widgets.dart';
library;

import 'dart:ui' show clampDouble;

import 'package:meta/meta.dart';

import 'debug.dart';
import 'object.dart';
import 'ui_primitives.dart';

// Examples can assume:
// late int rows, columns;
// late String _name;
// late bool inherit;
// abstract class ExampleSuperclass with Diagnosticable { }
// late String message;
// late double stepWidth;
// late double scale;
// late double hitTestExtent;
// late double paintExtent;
// late double maxWidth;
// late double progress;
// late int maxLines;
// late Duration duration;
// late int depth;
// late bool primary;
// late bool isCurrent;
// late bool keepAlive;
// late bool obscureText;
// late TextAlign textAlign;
// late ImageRepeat repeat;
// late Widget widget;
// late List<BoxShadow> boxShadow;
// late Size size;
// late bool hasSize;
// late Matrix4 transform;
// late Color color;
// late Map<Listenable, VoidCallback>? handles;
// late DiagnosticsTreeStyle style;
// late IconData icon;
// late double devicePixelRatio;

/// Default text tree configuration.
///
/// Example:
///
///     <root_name>: <root_description>
///      │ <property1>
///      │ <property2>
///      │ ...
///      │ <propertyN>
///      ├─<child_name>: <child_description>
///      │ │ <property1>
///      │ │ <property2>
///      │ │ ...
///      │ │ <propertyN>
///      │ │
///      │ └─<child_name>: <child_description>
///      │     <property1>
///      │     <property2>
///      │     ...
///      │     <propertyN>
///      │
///      └─<child_name>: <child_description>'
///        <property1>
///        <property2>
///        ...
///        <propertyN>
///
/// See also:
///
///  * [DiagnosticsTreeStyle.sparse], uses this style for ASCII art display.
final TextTreeConfiguration sparseTextConfiguration = TextTreeConfiguration(
  prefixLineOne: '├─',
  prefixOtherLines: ' ',
  prefixLastChildLineOne: '└─',
  linkCharacter: '│',
  propertyPrefixIfChildren: '│ ',
  propertyPrefixNoChildren: '  ',
  prefixOtherLinesRootNode: ' ',
);

/// Identical to [sparseTextConfiguration] except that the lines connecting
/// parent to children are dashed.
///
/// Example:
///
///     <root_name>: <root_description>
///      │ <property1>
///      │ <property2>
///      │ ...
///      │ <propertyN>
///      ├─<normal_child_name>: <child_description>
///      ╎ │ <property1>
///      ╎ │ <property2>
///      ╎ │ ...
///      ╎ │ <propertyN>
///      ╎ │
///      ╎ └─<child_name>: <child_description>
///      ╎     <property1>
///      ╎     <property2>
///      ╎     ...
///      ╎     <propertyN>
///      ╎
///      ╎╌<dashed_child_name>: <child_description>
///      ╎ │ <property1>
///      ╎ │ <property2>
///      ╎ │ ...
///      ╎ │ <propertyN>
///      ╎ │
///      ╎ └─<child_name>: <child_description>
///      ╎     <property1>
///      ╎     <property2>
///      ╎     ...
///      ╎     <propertyN>
///      ╎
///      └╌<dashed_child_name>: <child_description>'
///        <property1>
///        <property2>
///        ...
///        <propertyN>
///
/// See also:
///
///  * [DiagnosticsTreeStyle.offstage], uses this style for ASCII art display.
final TextTreeConfiguration dashedTextConfiguration = TextTreeConfiguration(
  prefixLineOne: '╎╌',
  prefixLastChildLineOne: '└╌',
  prefixOtherLines: ' ',
  linkCharacter: '╎',
  // Intentionally not set as a dashed line as that would make the properties
  // look like they were disabled.
  propertyPrefixIfChildren: '│ ',
  propertyPrefixNoChildren: '  ',
  prefixOtherLinesRootNode: ' ',
);

/// Dense text tree configuration that minimizes horizontal whitespace.
///
/// Example:
///
///     <root_name>: <root_description>(<property1>; <property2> <propertyN>)
///     ├<child_name>: <child_description>(<property1>, <property2>, <propertyN>)
///     └<child_name>: <child_description>(<property1>, <property2>, <propertyN>)
///
/// See also:
///
///  * [DiagnosticsTreeStyle.dense], uses this style for ASCII art display.
final TextTreeConfiguration denseTextConfiguration = TextTreeConfiguration(
  propertySeparator: ', ',
  beforeProperties: '(',
  afterProperties: ')',
  lineBreakProperties: false,
  prefixLineOne: '├',
  prefixOtherLines: '',
  prefixLastChildLineOne: '└',
  linkCharacter: '│',
  propertyPrefixIfChildren: '│',
  propertyPrefixNoChildren: ' ',
  prefixOtherLinesRootNode: '',
  addBlankLineIfNoChildren: false,
  isBlankLineBetweenPropertiesAndChildren: false,
);

/// Configuration that draws a box around a leaf node.
///
/// Used by leaf nodes such as [TextSpan] to draw a clear border around the
/// contents of a node.
///
/// Example:
///
///     <parent_node>
///     ╞═╦══ <name> ═══
///     │ ║  <description>:
///     │ ║    <body>
///     │ ║    ...
///     │ ╚═══════════
///     ╘═╦══ <name> ═══
///       ║  <description>:
///       ║    <body>
///       ║    ...
///       ╚═══════════
///
/// See also:
///
///  * [DiagnosticsTreeStyle.transition], uses this style for ASCII art display.
final TextTreeConfiguration transitionTextConfiguration = TextTreeConfiguration(
  prefixLineOne: '╞═╦══ ',
  prefixLastChildLineOne: '╘═╦══ ',
  prefixOtherLines: ' ║ ',
  footer: ' ╚═══════════',
  linkCharacter: '│',
  // Subtree boundaries are clear due to the border around the node so omit the
  // property prefix.
  propertyPrefixIfChildren: '',
  propertyPrefixNoChildren: '',
  prefixOtherLinesRootNode: '',
  afterName: ' ═══',
  // Add a colon after the description if the node has a body to make the
  // connection between the description and the body clearer.
  afterDescriptionIfBody: ':',
  // Members are indented an extra two spaces to disambiguate as the description
  // is placed within the box instead of along side the name as is the case for
  // other styles.
  bodyIndent: '  ',
  isNameOnOwnLine: true,
  // No need to add a blank line as the footer makes the boundary of this
  // subtree unambiguous.
  addBlankLineIfNoChildren: false,
  isBlankLineBetweenPropertiesAndChildren: false,
);

/// Configuration that draws a box around a node ignoring the connection to the
/// parents.
///
/// If nested in a tree, this node is best displayed in the property box rather
/// than as a traditional child.
///
/// Used to draw a decorative box around detailed descriptions of an exception.
///
/// Example:
///
///     ══╡ <name>: <description> ╞═════════════════════════════════════
///     <body>
///     ...
///     ├─<normal_child_name>: <child_description>
///     ╎ │ <property1>
///     ╎ │ <property2>
///     ╎ │ ...
///     ╎ │ <propertyN>
///     ╎ │
///     ╎ └─<child_name>: <child_description>
///     ╎     <property1>
///     ╎     <property2>
///     ╎     ...
///     ╎     <propertyN>
///     ╎
///     ╎╌<dashed_child_name>: <child_description>
///     ╎ │ <property1>
///     ╎ │ <property2>
///     ╎ │ ...
///     ╎ │ <propertyN>
///     ╎ │
///     ╎ └─<child_name>: <child_description>
///     ╎     <property1>
///     ╎     <property2>
///     ╎     ...
///     ╎     <propertyN>
///     ╎
///     └╌<dashed_child_name>: <child_description>'
///     ════════════════════════════════════════════════════════════════
///
/// See also:
///
///  * [DiagnosticsTreeStyle.error], uses this style for ASCII art display.
final TextTreeConfiguration errorTextConfiguration = TextTreeConfiguration(
  prefixLineOne: '╞═╦',
  prefixLastChildLineOne: '╘═╦',
  prefixOtherLines: ' ║ ',
  footer: ' ╚═══════════',
  linkCharacter: '│',
  // Subtree boundaries are clear due to the border around the node so omit the
  // property prefix.
  propertyPrefixIfChildren: '',
  propertyPrefixNoChildren: '',
  prefixOtherLinesRootNode: '',
  beforeName: '══╡ ',
  suffixLineOne: ' ╞══',
  mandatoryFooter: '═════',
  // No need to add a blank line as the footer makes the boundary of this
  // subtree unambiguous.
  addBlankLineIfNoChildren: false,
  isBlankLineBetweenPropertiesAndChildren: false,
);

/// Whitespace only configuration where children are consistently indented
/// two spaces.
///
/// Use this style for displaying properties with structured values or for
/// displaying children within a [transitionTextConfiguration] as using a style that
/// draws line art would be visually distracting for those cases.
///
/// Example:
///
///     <parent_node>
///       <name>: <description>:
///         <properties>
///         <children>
///       <name>: <description>:
///         <properties>
///         <children>
///
/// See also:
///
///  * [DiagnosticsTreeStyle.whitespace], uses this style for ASCII art display.
final TextTreeConfiguration whitespaceTextConfiguration = TextTreeConfiguration(
  prefixLineOne: '',
  prefixLastChildLineOne: '',
  prefixOtherLines: ' ',
  prefixOtherLinesRootNode: '  ',
  propertyPrefixIfChildren: '',
  propertyPrefixNoChildren: '',
  linkCharacter: ' ',
  addBlankLineIfNoChildren: false,
  // Add a colon after the description and before the properties to link the
  // properties to the description line.
  afterDescriptionIfBody: ':',
  isBlankLineBetweenPropertiesAndChildren: false,
);

/// Whitespace only configuration where children are not indented.
///
/// Use this style when indentation is not needed to disambiguate parents from
/// children as in the case of a [DiagnosticsStackTrace].
///
/// Example:
///
///     <parent_node>
///     <name>: <description>:
///     <properties>
///     <children>
///     <name>: <description>:
///     <properties>
///     <children>
///
/// See also:
///
///  * [DiagnosticsTreeStyle.flat], uses this style for ASCII art display.
final TextTreeConfiguration flatTextConfiguration = TextTreeConfiguration(
  prefixLineOne: '',
  prefixLastChildLineOne: '',
  prefixOtherLines: '',
  prefixOtherLinesRootNode: '',
  propertyPrefixIfChildren: '',
  propertyPrefixNoChildren: '',
  linkCharacter: '',
  addBlankLineIfNoChildren: false,
  // Add a colon after the description and before the properties to link the
  // properties to the description line.
  afterDescriptionIfBody: ':',
  isBlankLineBetweenPropertiesAndChildren: false,
);

/// Render a node as a single line omitting children.
///
/// Example:
/// `<name>: <description>(<property1>, <property2>, ..., <propertyN>)`
///
/// See also:
///
///  * [DiagnosticsTreeStyle.singleLine], uses this style for ASCII art display.
final TextTreeConfiguration singleLineTextConfiguration = TextTreeConfiguration(
  propertySeparator: ', ',
  beforeProperties: '(',
  afterProperties: ')',
  prefixLineOne: '',
  prefixOtherLines: '',
  prefixLastChildLineOne: '',
  lineBreak: '',
  lineBreakProperties: false,
  addBlankLineIfNoChildren: false,
  showChildren: false,
  propertyPrefixIfChildren: '  ',
  propertyPrefixNoChildren: '  ',
  linkCharacter: '',
  prefixOtherLinesRootNode: '',
);

/// Render the name on a line followed by the body and properties on the next
/// line omitting the children.
///
/// Example:
///
///     <name>:
///       <description>(<property1>, <property2>, ..., <propertyN>)
///
/// See also:
///
///  * [DiagnosticsTreeStyle.errorProperty], uses this style for ASCII art
///    display.
final TextTreeConfiguration errorPropertyTextConfiguration = TextTreeConfiguration(
  propertySeparator: ', ',
  beforeProperties: '(',
  afterProperties: ')',
  prefixLineOne: '',
  prefixOtherLines: '',
  prefixLastChildLineOne: '',
  lineBreakProperties: false,
  addBlankLineIfNoChildren: false,
  showChildren: false,
  propertyPrefixIfChildren: '  ',
  propertyPrefixNoChildren: '  ',
  linkCharacter: '',
  prefixOtherLinesRootNode: '',
  isNameOnOwnLine: true,
);

/// Render a node on multiple lines omitting children.
///
/// Example:
/// `<name>: <description>
///   <property1>
///   <property2>
///   <propertyN>`
///
/// See also:
///
///  * [DiagnosticsTreeStyle.shallow]
final TextTreeConfiguration shallowTextConfiguration = TextTreeConfiguration(
  prefixLineOne: '',
  prefixLastChildLineOne: '',
  prefixOtherLines: ' ',
  prefixOtherLinesRootNode: '  ',
  propertyPrefixIfChildren: '',
  propertyPrefixNoChildren: '',
  linkCharacter: ' ',
  addBlankLineIfNoChildren: false,
  // Add a colon after the description and before the properties to link the
  // properties to the description line.
  afterDescriptionIfBody: ':',
  isBlankLineBetweenPropertiesAndChildren: false,
  showChildren: false,
);

class _NoDefaultValue {
  const _NoDefaultValue();
}

/// Marker object indicating that a [DiagnosticsNode] has no default value.
const Object kNoDefaultValue = _NoDefaultValue();

bool _isSingleLine(DiagnosticsTreeStyle? style) {
  return style == DiagnosticsTreeStyle.singleLine;
}

/// Debugging message displayed like a property.
///
/// {@tool snippet}
///
/// The following two properties are better expressed using this
/// [MessageProperty] class, rather than [StringProperty], as the intent is to
/// show a message with property style display rather than to describe the value
/// of an actual property of the object:
///
/// ```dart
/// MessageProperty table = MessageProperty('table size', '$columns\u00D7$rows');
/// MessageProperty usefulness = MessageProperty('usefulness ratio', 'no metrics collected yet (never painted)');
/// ```
/// {@end-tool}
/// {@tool snippet}
///
/// On the other hand, [StringProperty] is better suited when the property has a
/// concrete value that is a string:
///
/// ```dart
/// StringProperty name = StringProperty('name', _name);
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [DiagnosticsNode.message], which serves the same role for messages
///    without a clear property name.
///  * [StringProperty], which is a better fit for properties with string values.
class MessageProperty extends DiagnosticsProperty<void> {
  /// Create a diagnostics property that displays a message.
  ///
  /// Messages have no concrete [value] (so [value] will return null). The
  /// message is stored as the description.
  MessageProperty(
    String name,
    String message, {
    super.style = DiagnosticsTreeStyle.singleLine,
    super.level = DiagnosticLevel.info,
  }) : super(name, null, description: message);
}

/// Property which encloses its string [value] in quotes.
///
/// See also:
///
///  * [MessageProperty], which is a better fit for showing a message
///    instead of describing a property with a string value.
class StringProperty extends DiagnosticsProperty<String> {
  /// Create a diagnostics property for strings.
  StringProperty(
    String super.name,
    super.value, {
    super.description,
    super.tooltip,
    super.showName,
    super.defaultValue,
    this.quoted = true,
    super.ifEmpty,
    super.style,
    super.level,
  });

  /// Whether the value is enclosed in double quotes.
  final bool quoted;

  @override
  Map<String, Object?> toJsonMap(DiagnosticsSerializationDelegate delegate) {
    final Map<String, Object?> json = super.toJsonMap(delegate);
    json['quoted'] = quoted;
    return json;
  }

  @override
  String valueToString({TextTreeConfiguration? parentConfiguration}) {
    String? text = _description ?? value;
    if (parentConfiguration != null && !parentConfiguration.lineBreakProperties && text != null) {
      // Escape linebreaks in multiline strings to avoid confusing output when
      // the parent of this node is trying to display all properties on the same
      // line.
      text = text.replaceAll('\n', r'\n');
    }

    if (quoted && text != null) {
      // An empty value would not appear empty after being surrounded with
      // quotes so we have to handle this case separately.
      if (ifEmpty != null && text.isEmpty) {
        return ifEmpty!;
      }
      return '"$text"';
    }
    return text.toString();
  }
}

abstract class _NumProperty<T extends num> extends DiagnosticsProperty<T> {
  _NumProperty(
    String super.name,
    super.value, {
    super.ifNull,
    this.unit,
    super.showName,
    super.defaultValue,
    super.tooltip,
    super.style,
    super.level,
  });

  _NumProperty.lazy(
    String super.name,
    super.computeValue, {
    super.ifNull,
    this.unit,
    super.showName,
    super.defaultValue,
    super.tooltip,
    super.style,
    super.level,
  }) : super.lazy();

  @override
  Map<String, Object?> toJsonMap(DiagnosticsSerializationDelegate delegate) {
    final Map<String, Object?> json = super.toJsonMap(delegate);
    if (unit != null) {
      json['unit'] = unit;
    }

    json['numberToString'] = numberToString();
    return json;
  }

  /// Optional unit the [value] is measured in.
  ///
  /// Unit must be acceptable to display immediately after a number with no
  /// spaces. For example: 'physical pixels per logical pixel' should be a
  /// [tooltip] not a [unit].
  final String? unit;

  /// String describing just the numeric [value] without a unit suffix.
  String numberToString();

  @override
  String valueToString({TextTreeConfiguration? parentConfiguration}) {
    if (value == null) {
      return value.toString();
    }

    return unit != null ? '${numberToString()}$unit' : numberToString();
  }
}

/// Property describing a [double] [value] with an optional [unit] of measurement.
///
/// Numeric formatting is optimized for debug message readability.
class DoubleProperty extends _NumProperty<double> {
  /// If specified, [unit] describes the unit for the [value] (e.g. px).
  DoubleProperty(
    super.name,
    super.value, {
    super.ifNull,
    super.unit,
    super.tooltip,
    super.defaultValue,
    super.showName,
    super.style,
    super.level,
  });

  /// Property with a [value] that is computed only when needed.
  ///
  /// Use if computing the property [value] may throw an exception or is
  /// expensive.
  DoubleProperty.lazy(
    super.name,
    super.computeValue, {
    super.ifNull,
    super.showName,
    super.unit,
    super.tooltip,
    super.defaultValue,
    super.level,
  }) : super.lazy();

  @override
  String numberToString() => debugFormatDouble(value);
}

/// An int valued property with an optional unit the value is measured in.
///
/// Examples of units include 'px' and 'ms'.
class IntProperty extends _NumProperty<int> {
  /// Create a diagnostics property for integers.
  IntProperty(
    super.name,
    super.value, {
    super.ifNull,
    super.showName,
    super.unit,
    super.defaultValue,
    super.style,
    super.level,
  });

  @override
  String numberToString() => value.toString();
}

/// Property which clamps a [double] to between 0 and 1 and formats it as a
/// percentage.
class PercentProperty extends DoubleProperty {
  /// Create a diagnostics property for doubles that represent percentages or
  /// fractions.
  ///
  /// Setting [showName] to false is often reasonable for [PercentProperty]
  /// objects, as the fact that the property is shown as a percentage tends to
  /// be sufficient to disambiguate its meaning.
  PercentProperty(
    super.name,
    super.fraction, {
    super.ifNull,
    super.showName,
    super.tooltip,
    super.unit,
    super.level,
  });

  @override
  String valueToString({TextTreeConfiguration? parentConfiguration}) {
    if (value == null) {
      return value.toString();
    }
    return unit != null ? '${numberToString()} $unit' : numberToString();
  }

  @override
  String numberToString() {
    final double? v = value;
    if (v == null) {
      return value.toString();
    }
    return '${(clampDouble(v, 0.0, 1.0) * 100.0).toStringAsFixed(1)}%';
  }
}

/// Property where the description is either [ifTrue] or [ifFalse] depending on
/// whether [value] is true or false.
///
/// Using [FlagProperty] instead of [DiagnosticsProperty<bool>] can make
/// diagnostics display more polished. For example, given a property named
/// `visible` that is typically true, the following code will return 'hidden'
/// when `visible` is false and nothing when visible is true, in contrast to
/// `visible: true` or `visible: false`.
///
/// {@tool snippet}
///
/// ```dart
/// FlagProperty(
///   'visible',
///   value: true,
///   ifFalse: 'hidden',
/// )
/// ```
/// {@end-tool}
/// {@tool snippet}
///
/// [FlagProperty] should also be used instead of [DiagnosticsProperty<bool>]
/// if showing the bool value would not clearly indicate the meaning of the
/// property value.
///
/// ```dart
/// FlagProperty(
///   'inherit',
///   value: inherit,
///   ifTrue: '<all styles inherited>',
///   ifFalse: '<no style specified>',
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [ObjectFlagProperty], which provides similar behavior describing whether
///    a [value] is null.
class FlagProperty extends DiagnosticsProperty<bool> {
  /// Constructs a FlagProperty with the given descriptions with the specified descriptions.
  ///
  /// [showName] defaults to false as typically [ifTrue] and [ifFalse] should
  /// be descriptions that make the property name redundant.
  FlagProperty(
    String name, {
    required bool? value,
    this.ifTrue,
    this.ifFalse,
    bool showName = false,
    Object? defaultValue,
    DiagnosticLevel level = DiagnosticLevel.info,
  }) : assert(ifTrue != null || ifFalse != null),
       super(name, value, showName: showName, defaultValue: defaultValue, level: level);

  @override
  Map<String, Object?> toJsonMap(DiagnosticsSerializationDelegate delegate) {
    final Map<String, Object?> json = super.toJsonMap(delegate);
    if (ifTrue != null) {
      json['ifTrue'] = ifTrue;
    }
    if (ifFalse != null) {
      json['ifFalse'] = ifFalse;
    }

    return json;
  }

  /// Description to use if the property [value] is true.
  ///
  /// If not specified and [value] equals true the property's priority [level]
  /// will be [DiagnosticLevel.hidden].
  final String? ifTrue;

  /// Description to use if the property value is false.
  ///
  /// If not specified and [value] equals false, the property's priority [level]
  /// will be [DiagnosticLevel.hidden].
  final String? ifFalse;

  @override
  String valueToString({TextTreeConfiguration? parentConfiguration}) {
    return switch (value) {
      true when ifTrue != null => ifTrue!,
      false when ifFalse != null => ifFalse!,
      _ => super.valueToString(parentConfiguration: parentConfiguration),
    };
  }

  @override
  bool get showName {
    if (value == null ||
        ((value ?? false) && ifTrue == null) ||
        (!(value ?? true) && ifFalse == null)) {
      // We are missing a description for the flag value so we need to show the
      // flag name. The property will have DiagnosticLevel.hidden for this case
      // so users will not see this property in this case unless they are
      // displaying hidden properties.
      return true;
    }
    return super.showName;
  }

  @override
  DiagnosticLevel get level => switch (value) {
    true when ifTrue == null => DiagnosticLevel.hidden,
    false when ifFalse == null => DiagnosticLevel.hidden,
    _ => super.level,
  };
}

/// Property with an `Iterable<T>` [value] that can be displayed with
/// different [DiagnosticsTreeStyle] for custom rendering.
///
/// If [style] is [DiagnosticsTreeStyle.singleLine], the iterable is described
/// as a comma separated list, otherwise the iterable is described as a line
/// break separated list.
class IterableProperty<T> extends DiagnosticsProperty<Iterable<T>> {
  /// Create a diagnostics property for iterables (e.g. lists).
  ///
  /// The [ifEmpty] argument is used to indicate how an iterable [value] with 0
  /// elements is displayed. If [ifEmpty] equals null that indicates that an
  /// empty iterable [value] is not interesting to display similar to how
  /// [defaultValue] is used to indicate that a specific concrete value is not
  /// interesting to display.
  IterableProperty(
    String super.name,
    super.value, {
    super.defaultValue,
    super.ifNull,
    super.ifEmpty = '[]',
    super.style,
    super.showName,
    super.showSeparator,
    super.level,
  });

  @override
  String valueToString({TextTreeConfiguration? parentConfiguration}) {
    if (value == null) {
      return value.toString();
    }

    if (value!.isEmpty) {
      return ifEmpty ?? '[]';
    }

    final Iterable<String> formattedValues = value!.map((T v) {
      if (T == double && v is double) {
        return debugFormatDouble(v);
      } else {
        return v.toString();
      }
    });

    if (parentConfiguration != null && !parentConfiguration.lineBreakProperties) {
      // Always display the value as a single line and enclose the iterable
      // value in brackets to avoid ambiguity.
      return '[${formattedValues.join(', ')}]';
    }

    return formattedValues.join(_isSingleLine(style) ? ', ' : '\n');
  }

  /// Priority level of the diagnostic used to control which diagnostics should
  /// be shown and filtered.
  ///
  /// If [ifEmpty] is null and the [value] is an empty [Iterable] then level
  /// [DiagnosticLevel.fine] is returned in a similar way to how an
  /// [ObjectFlagProperty] handles when [ifNull] is null and the [value] is
  /// null.
  @override
  DiagnosticLevel get level {
    if (ifEmpty == null &&
        value != null &&
        value!.isEmpty &&
        super.level != DiagnosticLevel.hidden) {
      return DiagnosticLevel.fine;
    }
    return super.level;
  }

  @override
  Map<String, Object?> toJsonMap(DiagnosticsSerializationDelegate delegate) {
    final Map<String, Object?> json = super.toJsonMap(delegate);
    if (value != null) {
      json['values'] = value!.map<String>((T value) => value.toString()).toList();
    }
    return json;
  }
}

/// [DiagnosticsProperty] that has an [Enum] as value.
///
/// The enum value is displayed with the enum name stripped. For example:
/// [HitTestBehavior.deferToChild] is shown as `deferToChild`.
///
/// This class can be used with enums and returns the enum's name getter. It
/// can also be used with nullable properties; the null value is represented as
/// `null`.
///
/// See also:
///
///  * [DiagnosticsProperty] which documents named parameters common to all
///    [DiagnosticsProperty].
class EnumProperty<T extends Enum?> extends DiagnosticsProperty<T> {
  /// Create a diagnostics property that displays an enum.
  ///
  /// The [level] argument must also not be null.
  EnumProperty(String super.name, super.value, {super.defaultValue, super.level});

  @override
  String valueToString({TextTreeConfiguration? parentConfiguration}) {
    return value?.name ?? 'null';
  }
}

/// A property where the important diagnostic information is primarily whether
/// the [value] is present (non-null) or absent (null), rather than the actual
/// value of the property itself.
///
/// The [ifPresent] and [ifNull] strings describe the property [value] when it
/// is non-null and null respectively. If one of [ifPresent] or [ifNull] is
/// omitted, that is taken to mean that [level] should be
/// [DiagnosticLevel.hidden] when [value] is non-null or null respectively.
///
/// This kind of diagnostics property is typically used for opaque
/// values, like closures, where presenting the actual object is of dubious
/// value but where reporting the presence or absence of the value is much more
/// useful.
///
/// See also:
///
///
///  * [FlagsSummary], which provides similar functionality but accepts multiple
///    flags under the same name, and is preferred if there are multiple such
///    values that can fit into a same category (such as "listeners").
///  * [FlagProperty], which provides similar functionality describing whether
///    a [value] is true or false.
class ObjectFlagProperty<T> extends DiagnosticsProperty<T> {
  /// Create a diagnostics property for values that can be present (non-null) or
  /// absent (null), but for which the exact value's [Object.toString]
  /// representation is not very transparent (e.g. a callback).
  ///
  /// At least one of [ifPresent] or [ifNull] must be non-null.
  ObjectFlagProperty(
    String super.name,
    super.value, {
    this.ifPresent,
    super.ifNull,
    super.showName = false,
    super.level,
  }) : assert(ifPresent != null || ifNull != null);

  /// Shorthand constructor to describe whether the property has a value.
  ///
  /// Only use if prefixing the property name with the word 'has' is a good
  /// flag name.
  ObjectFlagProperty.has(String super.name, super.value, {super.level})
    : ifPresent = 'has $name',
      super(showName: false);

  /// Description to use if the property [value] is not null.
  ///
  /// If the property [value] is not null and [ifPresent] is null, the
  /// [level] for the property is [DiagnosticLevel.hidden] and the description
  /// from superclass is used.
  final String? ifPresent;

  @override
  String valueToString({TextTreeConfiguration? parentConfiguration}) {
    if (value != null) {
      if (ifPresent != null) {
        return ifPresent!;
      }
    } else {
      if (ifNull != null) {
        return ifNull!;
      }
    }
    return super.valueToString(parentConfiguration: parentConfiguration);
  }

  @override
  bool get showName {
    if ((value != null && ifPresent == null) || (value == null && ifNull == null)) {
      // We are missing a description for the flag value so we need to show the
      // flag name. The property will have DiagnosticLevel.hidden for this case
      // so users will not see this property in this case unless they are
      // displaying hidden properties.
      return true;
    }
    return super.showName;
  }

  @override
  DiagnosticLevel get level {
    if (value != null) {
      if (ifPresent == null) {
        return DiagnosticLevel.hidden;
      }
    } else {
      if (ifNull == null) {
        return DiagnosticLevel.hidden;
      }
    }

    return super.level;
  }

  @override
  Map<String, Object?> toJsonMap(DiagnosticsSerializationDelegate delegate) {
    final Map<String, Object?> json = super.toJsonMap(delegate);
    if (ifPresent != null) {
      json['ifPresent'] = ifPresent;
    }
    return json;
  }
}

/// A summary of multiple properties, indicating whether each of them is present
/// (non-null) or absent (null).
///
/// Each entry of [value] is described by its key. The eventual description will
/// be a list of keys of non-null entries.
///
/// The [ifEmpty] describes the entire collection of [value] when it contains no
/// non-null entries. If [ifEmpty] is omitted, [level] will be
/// [DiagnosticLevel.hidden] when [value] contains no non-null entries.
///
/// This kind of diagnostics property is typically used for opaque
/// values, like closures, where presenting the actual object is of dubious
/// value but where reporting the presence or absence of the value is much more
/// useful.
///
/// See also:
///
///  * [ObjectFlagProperty], which provides similar functionality but accepts
///    only one flag, and is preferred if there is only one entry.
///  * [IterableProperty], which provides similar functionality describing
///    the values a collection of objects.
class FlagsSummary<T> extends DiagnosticsProperty<Map<String, T?>> {
  /// Create a summary for multiple properties, indicating whether each of them
  /// is present (non-null) or absent (null).
  ///
  /// The [value], [showName], [showSeparator] and [level] arguments must not be
  /// null.
  FlagsSummary(
    String super.name,
    Map<String, T?> super.value, {
    super.ifEmpty,
    super.showName,
    super.showSeparator,
    super.level,
  });

  @override
  Map<String, T?> get value => super.value!;

  @override
  String valueToString({TextTreeConfiguration? parentConfiguration}) {
    if (!_hasNonNullEntry() && ifEmpty != null) {
      return ifEmpty!;
    }

    final Iterable<String> formattedValues = _formattedValues();
    if (parentConfiguration != null && !parentConfiguration.lineBreakProperties) {
      // Always display the value as a single line and enclose the iterable
      // value in brackets to avoid ambiguity.
      return '[${formattedValues.join(', ')}]';
    }

    return formattedValues.join(_isSingleLine(style) ? ', ' : '\n');
  }

  /// Priority level of the diagnostic used to control which diagnostics should
  /// be shown and filtered.
  ///
  /// If [ifEmpty] is null and the [value] contains no non-null entries, then
  /// level [DiagnosticLevel.hidden] is returned.
  @override
  DiagnosticLevel get level {
    if (!_hasNonNullEntry() && ifEmpty == null) {
      return DiagnosticLevel.hidden;
    }
    return super.level;
  }

  @override
  Map<String, Object?> toJsonMap(DiagnosticsSerializationDelegate delegate) {
    final Map<String, Object?> json = super.toJsonMap(delegate);
    if (value.isNotEmpty) {
      json['values'] = _formattedValues().toList();
    }
    return json;
  }

  bool _hasNonNullEntry() => value.values.any((T? o) => o != null);

  // An iterable of each entry's description in [value].
  //
  // For a non-null value, its description is its key.
  //
  // For a null value, it is omitted unless `includeEmpty` is true and
  // [ifEntryNull] contains a corresponding description.
  Iterable<String> _formattedValues() {
    return value.entries
        .where((MapEntry<String, T?> entry) => entry.value != null)
        .map((MapEntry<String, T?> entry) => entry.key);
  }
}

/// Signature for computing the value of a property.
///
/// May throw exception if accessing the property would throw an exception
/// and callers must handle that case gracefully. For example, accessing a
/// property may trigger an assert that layout constraints were violated.
typedef ComputePropertyValueCallback<T> = T? Function();

/// Property with a [value] of type [T].
///
/// If the default `value.toString()` does not provide an adequate description
/// of the value, specify `description` defining a custom description.
///
/// The [showSeparator] property indicates whether a separator should be placed
/// between the property [name] and its [value].
class DiagnosticsProperty<T> extends DiagnosticsNode {
  /// Create a diagnostics property.
  ///
  /// The [level] argument is just a suggestion and can be overridden if
  /// something else about the property causes it to have a lower or higher
  /// level. For example, if the property value is null and [missingIfNull] is
  /// true, [level] is raised to [DiagnosticLevel.warning].
  DiagnosticsProperty(
    String? name,
    T? value, {
    String? description,
    String? ifNull,
    this.ifEmpty,
    super.showName,
    super.showSeparator,
    this.defaultValue = kNoDefaultValue,
    this.tooltip,
    this.missingIfNull = false,
    super.linePrefix,
    this.expandableValue = false,
    this.allowWrap = true,
    this.allowNameWrap = true,
    DiagnosticsTreeStyle super.style = DiagnosticsTreeStyle.singleLine,
    DiagnosticLevel level = DiagnosticLevel.info,
  }) : _description = description,
       _valueComputed = true,
       _value = value,
       _computeValue = null,
       ifNull = ifNull ?? (missingIfNull ? 'MISSING' : null),
       _defaultLevel = level,
       super(name: name);

  /// Property with a [value] that is computed only when needed.
  ///
  /// Use if computing the property [value] may throw an exception or is
  /// expensive.
  ///
  /// The [level] argument is just a suggestion and can be overridden
  /// if something else about the property causes it to have a lower or higher
  /// level. For example, if calling `computeValue` throws an exception, [level]
  /// will always return [DiagnosticLevel.error].
  DiagnosticsProperty.lazy(
    String? name,
    ComputePropertyValueCallback<T> computeValue, {
    String? description,
    String? ifNull,
    this.ifEmpty,
    super.showName,
    super.showSeparator,
    this.defaultValue = kNoDefaultValue,
    this.tooltip,
    this.missingIfNull = false,
    this.expandableValue = false,
    this.allowWrap = true,
    this.allowNameWrap = true,
    DiagnosticsTreeStyle super.style = DiagnosticsTreeStyle.singleLine,
    DiagnosticLevel level = DiagnosticLevel.info,
  }) : assert(defaultValue == kNoDefaultValue || defaultValue is T?),
       _description = description,
       _valueComputed = false,
       _value = null,
       _computeValue = computeValue,
       _defaultLevel = level,
       ifNull = ifNull ?? (missingIfNull ? 'MISSING' : null),
       super(name: name);

  final String? _description;

  /// Whether to expose properties and children of the value as properties and
  /// children.
  final bool expandableValue;

  @override
  final bool allowWrap;

  @override
  final bool allowNameWrap;

  @override
  Map<String, Object?> toJsonMap(DiagnosticsSerializationDelegate delegate) {
    final T? v = value;
    List<Map<String, Object?>>? properties;
    if (delegate.expandPropertyValues &&
        delegate.includeProperties &&
        v is Diagnosticable &&
        getProperties().isEmpty) {
      // Exclude children for expanded nodes to avoid cycles.
      delegate = delegate.copyWith(subtreeDepth: 0, includeProperties: false);
      properties = DiagnosticsNode.toJsonList(
        delegate.filterProperties(v.toDiagnosticsNode().getProperties(), this),
        this,
        delegate,
      );
    }
    final Map<String, Object?> json = super.toJsonMap(delegate);
    if (properties != null) {
      json['properties'] = properties;
    }
    if (defaultValue != kNoDefaultValue) {
      json['defaultValue'] = defaultValue.toString();
    }
    if (ifEmpty != null) {
      json['ifEmpty'] = ifEmpty;
    }
    if (ifNull != null) {
      json['ifNull'] = ifNull;
    }
    if (tooltip != null) {
      json['tooltip'] = tooltip;
    }
    json['missingIfNull'] = missingIfNull;
    if (exception != null) {
      json['exception'] = exception.toString();
    }
    json['propertyType'] = propertyType.toString();
    json['defaultLevel'] = _defaultLevel.name;
    if (value is Diagnosticable || value is DiagnosticsNode) {
      json['isDiagnosticableValue'] = true;
    }
    if (v is num) {
      // TODO(jacob314): Workaround, since JSON.stringify replaces infinity and NaN with null,
      // https://github.com/flutter/flutter/issues/39937#issuecomment-529558033)
      json['value'] = v.isFinite ? v : v.toString();
    }
    if (value is String || value is bool || value == null) {
      json['value'] = value;
    }
    return json;
  }

  /// Returns a string representation of the property value.
  ///
  /// Subclasses should override this method instead of [toDescription] to
  /// customize how property values are converted to strings.
  ///
  /// Overriding this method ensures that behavior controlling how property
  /// values are decorated to generate a nice [toDescription] are consistent
  /// across all implementations. Debugging tools may also choose to use
  /// [valueToString] directly instead of [toDescription].
  ///
  /// `parentConfiguration` specifies how the parent is rendered as text art.
  /// For example, if the parent places all properties on one line, the value
  /// of the property should be displayed without line breaks if possible.
  String valueToString({TextTreeConfiguration? parentConfiguration}) {
    final T? v = value;
    // DiagnosticableTree values are shown using the shorter toStringShort()
    // instead of the longer toString() because the toString() for a
    // DiagnosticableTree value is likely too large to be useful.
    return v is DiagnosticableTree ? v.toStringShort() : v.toString();
  }

  @override
  String toDescription({TextTreeConfiguration? parentConfiguration}) {
    if (_description != null) {
      return _addTooltip(_description);
    }

    if (exception != null) {
      return 'EXCEPTION (${exception.runtimeType})';
    }

    if (ifNull != null && value == null) {
      return _addTooltip(ifNull!);
    }

    String result = valueToString(parentConfiguration: parentConfiguration);
    if (result.isEmpty && ifEmpty != null) {
      result = ifEmpty!;
    }
    return _addTooltip(result);
  }

  /// If a [tooltip] is specified, add the tooltip it to the end of `text`
  /// enclosing it parenthesis to disambiguate the tooltip from the rest of
  /// the text.
  String _addTooltip(String text) {
    return tooltip == null ? text : '$text ($tooltip)';
  }

  /// Description if the property [value] is null.
  final String? ifNull;

  /// Description if the property description would otherwise be empty.
  final String? ifEmpty;

  /// Optional tooltip typically describing the property.
  ///
  /// Example tooltip: 'physical pixels per logical pixel'
  ///
  /// If present, the tooltip is added in parenthesis after the raw value when
  /// generating the string description.
  final String? tooltip;

  /// Whether a [value] of null causes the property to have [level]
  /// [DiagnosticLevel.warning] warning that the property is missing a [value].
  final bool missingIfNull;

  /// The type of the property [value].
  ///
  /// This is determined from the type argument `T` used to instantiate the
  /// [DiagnosticsProperty] class. This means that the type is available even if
  /// [value] is null, but it also means that the [propertyType] is only as
  /// accurate as the type provided when invoking the constructor.
  ///
  /// Generally, this is only useful for diagnostic tools that should display
  /// null values in a manner consistent with the property type. For example, a
  /// tool might display a null [Color] value as an empty rectangle instead of
  /// the word "null".
  Type get propertyType => T;

  /// Returns the value of the property either from cache or by invoking a
  /// [ComputePropertyValueCallback].
  ///
  /// If an exception is thrown invoking the [ComputePropertyValueCallback],
  /// [value] returns null and the exception thrown can be found via the
  /// [exception] property.
  ///
  /// See also:
  ///
  ///  * [valueToString], which converts the property value to a string.
  @override
  T? get value {
    _maybeCacheValue();
    return _value;
  }

  T? _value;

  bool _valueComputed;

  Object? _exception;

  /// Exception thrown if accessing the property [value] threw an exception.
  ///
  /// Returns null if computing the property value did not throw an exception.
  Object? get exception {
    _maybeCacheValue();
    return _exception;
  }

  void _maybeCacheValue() {
    if (_valueComputed) {
      return;
    }

    _valueComputed = true;
    assert(_computeValue != null);
    try {
      _value = _computeValue!();
    } catch (exception) {
      // The error is reported to inspector; rethrowing would destroy the
      // debugging experience.
      _exception = exception;
      _value = null;
    }
  }

  /// The default value of this property, when it has not been set to a specific
  /// value.
  ///
  /// For most [DiagnosticsProperty] classes, if the [value] of the property
  /// equals [defaultValue], then the priority [level] of the property is
  /// downgraded to [DiagnosticLevel.fine] on the basis that the property value
  /// is uninteresting. This is implemented by [isInteresting].
  ///
  /// The [defaultValue] is [kNoDefaultValue] by default. Otherwise it must be of
  /// type `T?`.
  final Object? defaultValue;

  /// Whether to consider the property's value interesting. When a property is
  /// uninteresting, its [level] is downgraded to [DiagnosticLevel.fine]
  /// regardless of the value provided as the constructor's `level` argument.
  bool get isInteresting => defaultValue == kNoDefaultValue || value != defaultValue;

  final DiagnosticLevel _defaultLevel;

  /// Priority level of the diagnostic used to control which diagnostics should
  /// be shown and filtered.
  ///
  /// The property level defaults to the value specified by the [level]
  /// constructor argument. The level is raised to [DiagnosticLevel.error] if
  /// an [exception] was thrown getting the property [value]. The level is
  /// raised to [DiagnosticLevel.warning] if the property [value] is null and
  /// the property is not allowed to be null due to [missingIfNull]. The
  /// priority level is lowered to [DiagnosticLevel.fine] if the property
  /// [value] equals [defaultValue].
  @override
  DiagnosticLevel get level {
    if (_defaultLevel == DiagnosticLevel.hidden) {
      return _defaultLevel;
    }

    if (exception != null) {
      return DiagnosticLevel.error;
    }

    if (value == null && missingIfNull) {
      return DiagnosticLevel.warning;
    }

    if (!isInteresting) {
      return DiagnosticLevel.fine;
    }

    return _defaultLevel;
  }

  final ComputePropertyValueCallback<T>? _computeValue;

  @override
  List<DiagnosticsNode> getProperties() {
    if (expandableValue) {
      final T? object = value;
      if (object is DiagnosticsNode) {
        return object.getProperties();
      }
      if (object is Diagnosticable) {
        return object.toDiagnosticsNode(style: style).getProperties();
      }
    }
    return const <DiagnosticsNode>[];
  }

  @override
  List<DiagnosticsNode> getChildren() {
    if (expandableValue) {
      final T? object = value;
      if (object is DiagnosticsNode) {
        return object.getChildren();
      }
      if (object is Diagnosticable) {
        return object.toDiagnosticsNode(style: style).getChildren();
      }
    }
    return const <DiagnosticsNode>[];
  }
}

/// [DiagnosticsNode] for an instance of [DiagnosticableTree].
class DiagnosticableTreeNode extends DiagnosticableNode<DiagnosticableTree> {
  /// Creates a [DiagnosticableTreeNode].
  DiagnosticableTreeNode({super.name, required super.value, required super.style});

  @override
  List<DiagnosticsNode> getChildren() => value.debugDescribeChildren();
}

/// Returns a 5 character long hexadecimal string generated from
/// [Object.hashCode]'s 20 least-significant bits.
String shortHash(Object? object) {
  return object.hashCode.toUnsigned(20).toRadixString(16).padLeft(5, '0');
}

/// Returns a short description of an enum value.
///
/// Strips off the enum class name from the `enumEntry.toString()`.
///
/// For real enums, this is redundant with calling the `name` getter on the enum
/// value (see [EnumName.name]), a feature that was added to Dart 2.15.
///
/// This function can also be used with classes whose `toString` return a value
/// in the same form as an enum (the class name, a dot, then the value name).
/// For example, it's used with [SemanticsAction], which is written to appear to
/// be an enum but is actually a bespoke class so that the index values can be
/// set as powers of two instead of as sequential integers.
///
/// {@tool snippet}
///
/// ```dart
/// enum Day {
///   monday, tuesday, wednesday, thursday, friday, saturday, sunday
/// }
///
/// void validateDescribeEnum() {
///   assert(Day.monday.toString() == 'Day.monday');
///   // ignore: deprecated_member_use
///   assert(describeEnum(Day.monday) == 'monday');
///   assert(Day.monday.name == 'monday'); // preferred for real enums
/// }
/// ```
/// {@end-tool}
@Deprecated(
  'Use the `name` getter on enums instead. '
  'This feature was deprecated after v3.14.0-2.0.pre.',
)
String describeEnum(Object enumEntry) {
  if (enumEntry is Enum) {
    return enumEntry.name;
  }
  final description = enumEntry.toString();
  final int indexOfDot = description.indexOf('.');
  assert(
    indexOfDot != -1 && indexOfDot < description.length - 1,
    'The provided object "$enumEntry" is not an enum.',
  );
  return description.substring(indexOfDot + 1);
}

// Examples can assume:
// class ExampleSuperclass with Diagnosticable { late String message; late double stepWidth; late double scale; late double paintExtent; late double hitTestExtent; late double paintExtend; late double maxWidth; late bool primary; late double progress; late int maxLines; late Duration duration; late int depth; Iterable<BoxShadow>? boxShadow; late DiagnosticsTreeStyle style; late bool hasSize; late Matrix4 transform; Map<Listenable, VoidCallback>? handles; late Color color; late bool obscureText; late ImageRepeat repeat; late Size size; late Widget widget; late bool isCurrent; late bool keepAlive; late TextAlign textAlign; }
/// A base class for providing string and [DiagnosticsNode] debug
/// representations describing the properties and children of an object.
///
/// The string debug representation is generated from the intermediate
/// [DiagnosticsNode] representation. The [DiagnosticsNode] representation is
/// also used by debugging tools displaying interactive trees of objects and
/// properties.
///
/// See also:
///
///  * [DiagnosticableTreeMixin], a mixin that implements this class.
///  * [Diagnosticable], which should be used instead of this class to
///    provide diagnostics for objects without children.
abstract class DiagnosticableTree with Diagnosticable {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const DiagnosticableTree();

  /// Returns a one-line detailed description of the object.
  ///
  /// This description is often somewhat long. This includes the same
  /// information given by [toStringDeep], but does not recurse to any children.
  ///
  /// `joiner` specifies the string which is place between each part obtained
  /// from [debugFillProperties]. Passing a string such as `'\n '` will result
  /// in a multiline string that indents the properties of the object below its
  /// name (as per [toString]).
  ///
  /// `minLevel` specifies the minimum [DiagnosticLevel] for properties included
  /// in the output.
  ///
  /// See also:
  ///
  ///  * [toString], for a brief description of the object.
  ///  * [toStringDeep], for a description of the subtree rooted at this object.
  String toStringShallow({String joiner = ', ', DiagnosticLevel minLevel = DiagnosticLevel.debug}) {
    String? shallowString;
    assert(() {
      final result = StringBuffer();
      result.write(toString());
      result.write(joiner);
      final builder = DiagnosticPropertiesBuilder();
      debugFillProperties(builder);
      result.write(
        builder.properties.where((DiagnosticsNode n) => !n.isFiltered(minLevel)).join(joiner),
      );
      shallowString = result.toString();
      return true;
    }());
    return shallowString ?? toString();
  }

  /// Returns a string representation of this node and its descendants.
  ///
  /// `prefixLineOne` will be added to the front of the first line of the
  /// output. `prefixOtherLines` will be added to the front of each other line.
  /// If `prefixOtherLines` is null, the `prefixLineOne` is used for every line.
  /// By default, there is no prefix.
  ///
  /// `minLevel` specifies the minimum [DiagnosticLevel] for properties included
  /// in the output.
  ///
  /// `wrapWidth` specifies the column number where word wrapping will be
  /// applied.
  ///
  /// The [toStringDeep] method takes other arguments, but those are intended
  /// for internal use when recursing to the descendants, and so can be ignored.
  ///
  /// See also:
  ///
  ///  * [toString], for a brief description of the object but not its children.
  ///  * [toStringShallow], for a detailed description of the object but not its
  ///    children.
  String toStringDeep({
    String prefixLineOne = '',
    String? prefixOtherLines,
    DiagnosticLevel minLevel = DiagnosticLevel.debug,
    int wrapWidth = 65,
  }) {
    return toDiagnosticsNode().toStringDeep(
      prefixLineOne: prefixLineOne,
      prefixOtherLines: prefixOtherLines,
      minLevel: minLevel,
      wrapWidth: wrapWidth,
    );
  }

  @override
  String toStringShort() => describeIdentity(this);

  @override
  DiagnosticsNode toDiagnosticsNode({String? name, DiagnosticsTreeStyle? style}) {
    return DiagnosticableTreeNode(name: name, value: this, style: style);
  }

  /// Returns a list of [DiagnosticsNode] objects describing this node's
  /// children.
  ///
  /// Children that are offstage should be added with `style` set to
  /// [DiagnosticsTreeStyle.offstage] to indicate that they are offstage.
  ///
  /// The list must not contain any null entries. If there are explicit null
  /// children to report, consider [DiagnosticsNode.message] or
  /// [DiagnosticsProperty<Object>] as possible [DiagnosticsNode] objects to
  /// provide.
  ///
  /// Used by [toStringDeep], [toDiagnosticsNode] and [toStringShallow].
  ///
  /// See also:
  ///
  ///  * [RenderTable.debugDescribeChildren], which provides high quality custom
  ///    descriptions for its child nodes.
  @protected
  List<DiagnosticsNode> debugDescribeChildren() => const <DiagnosticsNode>[];
}

/// A mixin that helps dump string and [DiagnosticsNode] representations of trees.
///
/// This mixin is identical to class [DiagnosticableTree].
mixin DiagnosticableTreeMixin implements DiagnosticableTree {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return toDiagnosticsNode(style: DiagnosticsTreeStyle.singleLine).toString(minLevel: minLevel);
  }

  @override
  String toStringShallow({String joiner = ', ', DiagnosticLevel minLevel = DiagnosticLevel.debug}) {
    String? shallowString;
    assert(() {
      final result = StringBuffer();
      result.write(toStringShort());
      result.write(joiner);
      final builder = DiagnosticPropertiesBuilder();
      debugFillProperties(builder);
      result.write(
        builder.properties.where((DiagnosticsNode n) => !n.isFiltered(minLevel)).join(joiner),
      );
      shallowString = result.toString();
      return true;
    }());
    return shallowString ?? toString();
  }

  @override
  String toStringDeep({
    String prefixLineOne = '',
    String? prefixOtherLines,
    DiagnosticLevel minLevel = DiagnosticLevel.debug,
    int wrapWidth = 65,
  }) {
    return toDiagnosticsNode().toStringDeep(
      prefixLineOne: prefixLineOne,
      prefixOtherLines: prefixOtherLines,
      minLevel: minLevel,
      wrapWidth: wrapWidth,
    );
  }

  @override
  String toStringShort() => describeIdentity(this);

  @override
  DiagnosticsNode toDiagnosticsNode({String? name, DiagnosticsTreeStyle? style}) {
    return DiagnosticableTreeNode(name: name, value: this, style: style);
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() => const <DiagnosticsNode>[];

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {}
}

/// [DiagnosticsNode] that exists mainly to provide a container for other
/// diagnostics that typically lacks a meaningful value of its own.
///
/// This class is typically used for displaying complex nested error messages.
class DiagnosticsBlock extends DiagnosticsNode {
  /// Creates a diagnostic with properties specified by [properties] and
  /// children specified by [children].
  DiagnosticsBlock({
    super.name,
    DiagnosticsTreeStyle super.style = DiagnosticsTreeStyle.whitespace,
    bool showName = true,
    super.showSeparator,
    super.linePrefix,
    this.value,
    String? description,
    this.level = DiagnosticLevel.info,
    this.allowTruncate = false,
    List<DiagnosticsNode> children = const <DiagnosticsNode>[],
    List<DiagnosticsNode> properties = const <DiagnosticsNode>[],
  }) : _description = description ?? '',
       _children = children,
       _properties = properties,
       super(showName: showName && name != null);

  final List<DiagnosticsNode> _children;
  final List<DiagnosticsNode> _properties;

  @override
  final DiagnosticLevel level;

  final String _description;

  @override
  final Object? value;

  @override
  final bool allowTruncate;

  @override
  List<DiagnosticsNode> getChildren() => _children;

  @override
  List<DiagnosticsNode> getProperties() => _properties;

  @override
  String toDescription({TextTreeConfiguration? parentConfiguration}) => _description;
}
