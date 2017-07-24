// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'print.dart';

/// Styles for displaying a node in a [DiagnosticsNode] tree.
///
/// See also:
///
///  * [DiagnosticsNode.toStringDeep], which dumps text art trees for these
///    styles.
enum DiagnosticsTreeStyle {
  /// Sparse style for displaying trees.
  ///
  /// See also:
  ///
  ///  * [RenderObject], which uses this style.
  sparse,

  /// Connects a node to its parent with a dashed line.
  ///
  /// See also:
  ///
  ///  * [RenderSliverMultiBoxAdaptor], which uses this style to distinguish
  ///    offstage children from onstage children.
  offstage,

  /// Slightly more compact version of the [sparse] style.
  ///
  /// See also:
  ///
  ///  * [Element], which uses this style.
  dense,

  /// Style that enables transitioning from nodes of one style to children of
  /// another.
  ///
  /// See also:
  ///
  ///  * [RenderParagraph], which uses this style for
  transition,

  /// Render the tree just using whitespace without connecting parents to
  /// children using lines.
  ///
  /// See also:
  ///
  ///  * [SliverGeometry], which uses this style.
  whitespace,

  /// Render the tree on a single line without showing children.
  singleLine,
}

/// Configuration specifying how a particular [DiagnosticsTreeStyle] should be
/// rendered as text art.
///
/// See also:
///
///  * [sparseTextConfiguration], which is a typical style.
///  * [leafTextConfiguration], which is an example of a complex tree style.
///  * [DiagnosticsNode.toStringDeep], for code using [TextTreeConfiguration]
///    to render text art for arbitrary trees of [DiagnosticsNode] objects.
class TextTreeConfiguration {
  TextTreeConfiguration({
    @required this.prefixLineOne,
    @required this.prefixOtherLines,
    @required this.prefixLastChildLineOne,
    @required this.prefixOtherLinesRootNode,
    @required this.linkCharacter,
    @required this.propertyPrefixIfChildren,
    @required this.propertyPrefixNoChildren,
    this.lineBreak: '\n',
    this.afterName: ':',
    this.afterDescriptionIfBody: '',
    this.beforeProperties: '',
    this.afterProperties: '',
    this.propertySeparator: '',
    this.bodyIndent: '',
    this.footer: '',
    this.showChildren: true,
    this.addBlankLineIfNoChildren: true,
    this.isNameOnOwnLine: false,
    this.isBlankLineBetweenPropertiesAndChildren: true,
  }) : childLinkSpace = ' ' * linkCharacter.length;

  /// Prefix to add to the first line to display a child with this style.
  final String prefixLineOne;

  /// Prefix to add to other lines to display a child with this style.
  ///
  /// [prefixOtherLines] should typically be one character shorter than
  /// [prefixLineOne] as
  final String prefixOtherLines;

  /// Prefix to add to the first line to display the last child of a node with
  /// this style.
  final String prefixLastChildLineOne;

  /// Additional prefix to add to other lines of a node if this is the root node
  /// of the tree.
  final String prefixOtherLinesRootNode;

  /// Prefix to add before each property if the node as children.
  ///
  /// Plays a similar role to [linkCharacter] except that some configurations
  /// intentionally use a different line style than the [linkCharacter].
  final String propertyPrefixIfChildren;

  /// Prefix to add before each property if the node does not have children.
  ///
  /// This string is typically a whitespace string the same length as
  /// [propertyPrefixIfChildren] but can have a different length.
  final String propertyPrefixNoChildren;

  /// Character to use to draw line linking parent to child.
  ///
  /// The first child does not require a line but all subsequent children do
  /// with the line drawn immediately before the left edge of the previous
  /// sibling.
  final String linkCharacter;

  /// Whitespace to draw instead of the childLink character if this node is the
  /// last child of its parent so no link line is required.
  final String childLinkSpace;

  /// Character(s) to use to separate lines.
  ///
  /// Typically leave set at the default value of '\n' unless this style needs
  /// to treat lines differently as is the case for
  /// [singleLineTextConfiguration].
  final String lineBreak;

  /// Text added immediately after the name of the node.
  ///
  /// See [leafTextConfiguration] for an example of using a value other than ':'
  /// to achieve a custom line art style.
  final String afterName;

  /// Text to add immediately after the description line of a node with
  /// properties and/or children.
  final String afterDescriptionIfBody;

  /// Optional string to add before the properties of a node.
  ///
  /// Only displayed if the node has properties.
  /// See [singleLineTextConfiguration] for an example of using this field
  /// to enclose the property list with parenthesis.
  final String beforeProperties;

  /// Optional string to add after the properties of a node.
  ///
  /// See documentation for [beforeProperties].
  final String afterProperties;

  /// Property separator to add between properties.
  ///
  /// See [singleLineTextConfiguration] for an example of using this field
  /// to render properties as a comma separated list.
  final String propertySeparator;

  /// Prefix to add to all lines of the body of the tree node.
  ///
  /// The body is all content in the node other than the name and description.
  final String bodyIndent;

  /// Whether the children of a node should be shown.
  ///
  /// See [singleLineTextConfiguration] for an example of using this field to
  /// hide all children of a node.
  final bool showChildren;

  /// Whether to add a blank line at the end of the output for a node if it has
  /// no children.
  ///
  /// See [denseTextConfiguration] for an example of setting this to false.
  final bool addBlankLineIfNoChildren;

  /// Whether the name should be displayed on the same line as the description.
  final bool isNameOnOwnLine;

  /// Footer to add as its own line at the end of a non-root node.
  ///
  /// See [leafTextConfiguration] for an example of using footer to draw a box around
  /// the node.  [footer] is indented the same amount as [prefixOtherLines].
  final String footer;

  /// Add a blank line between properties and children if both are present.
  final bool isBlankLineBetweenPropertiesAndChildren;

  /// Whether all text should be added to a single line.
  bool get isSingleLine => lineBreak.isEmpty;
}

/// Default text tree configuration.
///
/// Example:
/// ```
/// <root_name>: <root_description>
///  │ <property1>
///  │ <property2>
///  │ ...
///  │ <propertyN>
///  ├─<child_name>: <child_description>
///  │ │ <property1>
///  │ │ <property2>
///  │ │ ...
///  │ │ <propertyN>
///  │ │
///  │ └─<child_name>: <child_description>
///  │     <property1>
///  │     <property2>
///  │     ...
///  │     <propertyN>
///  │
///  └─<child_name>: <child_description>'
///    <property1>
///    <property2>
///    ...
///    <propertyN>
/// ```
///
/// See also:
///
///  * [DiagnosticsTreeStyle.sparse]
final TextTreeConfiguration sparseTextConfiguration = new TextTreeConfiguration(
  prefixLineOne:            '├─',
  prefixOtherLines:         ' ',
  prefixLastChildLineOne:   '└─',
  linkCharacter:            '│',
  propertyPrefixIfChildren: '│ ',
  propertyPrefixNoChildren: '  ',
  prefixOtherLinesRootNode: ' ',
);

/// Identical to [sparseTextConfiguration] except that the lines connecting
/// parent to children are dashed.
///
/// Example:
/// ```
/// <root_name>: <root_description>
///  │ <property1>
///  │ <property2>
///  │ ...
///  │ <propertyN>
///  ├─<normal_child_name>: <child_description>
///  ╎ │ <property1>
///  ╎ │ <property2>
///  ╎ │ ...
///  ╎ │ <propertyN>
///  ╎ │
///  ╎ └─<child_name>: <child_description>
///  ╎     <property1>
///  ╎     <property2>
///  ╎     ...
///  ╎     <propertyN>
///  ╎
///  ╎╌<dashed_child_name>: <child_description>
///  ╎ │ <property1>
///  ╎ │ <property2>
///  ╎ │ ...
///  ╎ │ <propertyN>
///  ╎ │
///  ╎ └─<child_name>: <child_description>
///  ╎     <property1>
///  ╎     <property2>
///  ╎     ...
///  ╎     <propertyN>
///  ╎
///  └╌<dashed_child_name>: <child_description>'
///    <property1>
///    <property2>
///    ...
///    <propertyN>
/// ```
///
/// See also:
///
///  * [DiagnosticsTreeStyle.offstage], uses this style for ascii art display.
final TextTreeConfiguration dashedTextConfiguration = new TextTreeConfiguration(
  prefixLineOne:            '╎╌',
  prefixLastChildLineOne:   '└╌',
  prefixOtherLines:         ' ',
  linkCharacter:            '╎',
  // Intentionally not set as a dashed line as that would make the properties
  // look like they were disabled.
  propertyPrefixIfChildren: '│ ',
  propertyPrefixNoChildren: '  ',
  prefixOtherLinesRootNode: ' ',
);

/// Dense text tree configuration that minimizes horizontal whitespace.
///
/// Example:
/// ```
/// <root_name>: <root_description>
/// │ <property1>
/// │ <property2>
/// │ ...
/// │ <propertyN>
/// │
/// ├<child_name>: <child_description>
/// │ <property1>
/// │ <property2>
/// │ ...
/// │ <propertyN>
/// │
/// └<child_name>: <child_description>'
///   <property1>
///   <property2>
///   ...
///   <propertyN>
/// ```
///
/// See also:
///
///  * [DiagnosticsTreeStyle.dense]
final TextTreeConfiguration denseTextConfiguration = new TextTreeConfiguration(
  prefixLineOne:            '├',
  prefixOtherLines:         '',
  prefixLastChildLineOne:   '└',
  linkCharacter:            '│',
  propertyPrefixIfChildren: '│',
  propertyPrefixNoChildren: ' ',
  prefixOtherLinesRootNode: '',
  addBlankLineIfNoChildren: false,
);

/// Configuration that draws a box around a leaf node.
///
/// Used by leaf nodes such as [TextSpan] to draw a clear border around the
/// contents of a node.
///
/// Example:
/// ```
///  <parent_node>
///  ╞═╦══ <name> ═══
///  │ ║  <description>:
///  │ ║    <body>
///  │ ║    ...
///  │ ╚═══════════
///  ╘═╦══ <name> ═══
///    ║  <description>:
///    ║    <body>
///    ║    ...
///    ╚═══════════
/// ```
///
/// /// See also:
///
///  * [DiagnosticsTreeStyle.transition]
final TextTreeConfiguration leafTextConfiguration = new TextTreeConfiguration(
  prefixLineOne:           '╞═╦══ ',
  prefixLastChildLineOne:  '╘═╦══ ',
  prefixOtherLines:         ' ║ ',
  footer:                   ' ╚═══════════\n',
  linkCharacter:            '│',
  // Subtree boundaries are clear due to the border around the node so omit the
  // property prefix.
  propertyPrefixIfChildren: '',
  propertyPrefixNoChildren: '',
  prefixOtherLinesRootNode: '',
  afterName:                ' ═══',
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

/// Whitespace only configuration where children are consistently indented
/// two spaces.
///
/// Use this style for displaying properties with structured values or for
/// displaying children within a [leafTextConfiguration] as using a style that
/// draws line art would be visually distracting for those cases.
///
/// Example:
/// ```
/// <parent_node>
///   <name>: <description>:
///     <properties>
///     <children>
///   <name>: <description>:
///     <properties>
///     <children>
///```
///
/// See also:
///
///  * [DiagnosticsTreeStyle.whitespace]
final TextTreeConfiguration whitespaceTextConfiguration = new TextTreeConfiguration(
  prefixLineOne: '',
  prefixLastChildLineOne: '',
  prefixOtherLines: ' ',
  prefixOtherLinesRootNode: '  ',
  bodyIndent: '',
  propertyPrefixIfChildren: '',
  propertyPrefixNoChildren: '',
  linkCharacter: ' ',
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
///   * [DiagnosticsTreeStyle.singleLine]
final TextTreeConfiguration singleLineTextConfiguration = new TextTreeConfiguration(
  propertySeparator: ', ',
  beforeProperties: '(',
  afterProperties: ')',
  prefixLineOne: '',
  prefixOtherLines: '',
  prefixLastChildLineOne: '',
  lineBreak: '',
  addBlankLineIfNoChildren: false,
  showChildren: false,
  propertyPrefixIfChildren: '',
  propertyPrefixNoChildren: '',
  linkCharacter: '',
  prefixOtherLinesRootNode: '',
);

/// Builder that builds a String with specified prefixes for the first and
/// subsequent lines.
///
/// Allows for the incremental building of strings using `write*()` methods.
/// The strings are concatenated into a single string with the first line
/// prefixed by [prefixLineOne] and subsequent lines prefixed by
/// [prefixOtherLines].
class _PrefixedStringBuilder {
  _PrefixedStringBuilder(this.prefixLineOne, this.prefixOtherLines);

  /// Prefix to add to the first line.
  final String prefixLineOne;

  /// Prefix to add to subsequent lines.
  ///
  /// The prefix can be modified while the string is being built in which case
  /// subsequent lines will be added with the modified prefix.
  String prefixOtherLines;

  final StringBuffer _buffer = new StringBuffer();
  bool _atLineStart = true;
  bool _hasMultipleLines = false;

  /// Whether the string being built already has more than 1 line.
  bool get hasMultipleLines => _hasMultipleLines;

  /// Write text ensuring the specified prefixes for the first and subsequent
  /// lines.
  void write(String s) {
    if (s.isEmpty)
      return;

    if (s == '\n') {
      // Edge case to avoid adding trailing whitespace when the caller did
      // not explicitly add trailing trailing whitespace.
      if (_buffer.isEmpty) {
        _buffer.write(prefixLineOne.trimRight());
      } else if (_atLineStart) {
        _buffer.write(prefixOtherLines.trimRight());
        _hasMultipleLines = true;
      }
      _buffer.write('\n');
      _atLineStart = true;
      return;
    }

    if (_buffer.isEmpty) {
      _buffer.write(prefixLineOne);
    } else if (_atLineStart) {
      _buffer.write(prefixOtherLines);
      _hasMultipleLines = true;
    }
    bool lineTerminated = false;

    if (s.endsWith('\n')) {
      s = s.substring(0, s.length - 1);
      lineTerminated = true;
    }
    final List<String> parts = s.split('\n');
    _buffer.write(parts[0]);
    for (int i = 1; i < parts.length; ++i) {
      _buffer
        ..write('\n')
        ..write(prefixOtherLines)
        ..write(parts[i]);
    }

    if (lineTerminated)
      _buffer.write('\n');

    _atLineStart = lineTerminated;
  }

  /// Write text assuming the text already obeys the specified prefixes for the
  /// first and subsequent lines.
  void writeRaw(String text) {
    if (text.isEmpty)
      return;
    _buffer.write(text);
    _atLineStart = text.endsWith('\n');
  }


  /// Write a line assuming the line obeys the specified prefixes. Ensures that
  /// a newline is added if one is not present.
  /// The same as [writeRaw] except a newline is added at the end of [line] if
  /// one is not already present.
  ///
  /// A new line is not added if the input string already contains a newline.
  void writeRawLine(String line) {
    if (line.isEmpty)
      return;
    _buffer.write(line);
    if (!line.endsWith('\n'))
      _buffer.write('\n');
    _atLineStart = true;
  }

  @override
  String toString() => _buffer.toString();
}

class _NoDefaultValue {
  const _NoDefaultValue();
}

/// Marker object indicating that a DiagnosticNode has no default value.
const _NoDefaultValue kNoDefaultValue = const _NoDefaultValue();

/// Defines diagnostics data for an [Object].
///
/// DiagnosticsNode provides a high quality multi-line string dump via
/// [toStringDeep]. The core members are the [name], [description], [getProperties],
/// [object], and [getChildren]. All other members exist typically to provide
/// hints for how [toStringDeep] and debugging tools should format output.
abstract class DiagnosticsNode {
  DiagnosticsNode({
    @required this.name,
    this.style: DiagnosticsTreeStyle.sparse,
    this.showName: true,
    this.showSeparator: true,
    this.emptyBodyDescription,
  }) {
    // A name ending with ':' indicates that the user forgot that the ':' will
    // be automatically added for them when generating descriptions of the
    // property.
    assert(name == null || !name.endsWith(':'));
  }

  /// Constructor that creates a [DiagnosticsNode] where properties and children
  /// are computed lazily.
  factory DiagnosticsNode.lazy({
    String name,
    Object object,
    String description,
    FillPropertiesCallback fillProperties,
    GetChildrenCallback getChildren,
    String emptyBodyDescription,
    DiagnosticsTreeStyle style: DiagnosticsTreeStyle.sparse,
  }) {
    return new _LazyMembersDiagnosticsNode(
      name: name,
      object: object,
      description: description,
      fillProperties: fillProperties,
      getChildren: getChildren,
      style: style,
      emptyBodyDescription: emptyBodyDescription,
    );
  }


  /// Diagnostics containing just a string `message` and not a concrete name or
  /// value.
  ///
  /// See also:
  ///
  ///  * [PropertyMessage], which should be used if the message should be
  ///    formatted like a property with a separate name and message.
  factory DiagnosticsNode.message(
    String message, {
    DiagnosticsTreeStyle style: DiagnosticsTreeStyle.singleLine,
  }) {
    return new DiagnosticsProperty<Null>(
      '',
      null,
      description: message,
      style: style,
      showName: false,
    );
  }

  /// Label describing the Diagnostics node.
  final String name;

  /// Description with a short summary of the node itself not including children
  /// or properties.
  String get description;

  /// Whether to show a separator between [name] and [description].
  ///
  /// If false, name and description should be shown with no separation.
  /// `:` is typically used as a separator when displaying as text.
  final bool showSeparator;

  /// Whether the diagnostics should be hidden when showing the default
  /// view of a tree.
  bool get hidden;

  final bool showName;

  /// Description to show if the node has no displayed properties or children.
  final String emptyBodyDescription;

  /// Dart object this is diagnostics data for.
  Object get object;

  /// Hint for how the node should be displayed.
  final DiagnosticsTreeStyle style;

  /// Properties of this DiagnosticsNode.
  ///
  /// Properties and children are kept distinct even though they are both
  /// [List<DiagnosticNode>] because they should be grouped differently.
  List<DiagnosticsNode> getProperties();

  /// Children of this DiagnosticsNode.
  ///
  /// See also:
  ///
  ///  * [getProperties]
  List<DiagnosticsNode> getChildren();

  String get _separator => showSeparator ? ':' : '';

  @override
  String toString() {
    if (style == DiagnosticsTreeStyle.singleLine)
      return toStringDeep();

    if (name == null || name.isEmpty || showName == false)
      return description;

    return description.contains('\n') ?
        '$name$_separator\n$description' : '$name$_separator $description';
  }

  TextTreeConfiguration get textTreeConfiguration {
    switch (style) {
      case DiagnosticsTreeStyle.dense:
        return denseTextConfiguration;
      case DiagnosticsTreeStyle.sparse:
        return sparseTextConfiguration;
      case DiagnosticsTreeStyle.offstage:
        return dashedTextConfiguration;
      case DiagnosticsTreeStyle.whitespace:
        return whitespaceTextConfiguration;
      case DiagnosticsTreeStyle.transition:
        return leafTextConfiguration;
      case DiagnosticsTreeStyle.singleLine:
        return singleLineTextConfiguration;
    }
    return sparseTextConfiguration;
  }

  /// Text configuration to use to connect this node to a `child`.
  ///
  /// The singleLine style is special cased because the connection from the
  /// parent to the child should be consistent with the parent's style as the
  /// single line style does not provide any meaningful style for how children
  /// should be connected to their parents.
  TextTreeConfiguration _childTextConfiguration(
    DiagnosticsNode child,
    TextTreeConfiguration textStyle,
  ) {
    return (child != null && child.style != DiagnosticsTreeStyle.singleLine) ?
        child.textTreeConfiguration : textStyle;
  }

  /// Returns a string representation of this node and its descendants.
  ///
  /// The [toStringDeep] method takes arguments, but those are intended for
  /// internal use when recursing to the descendants, and so can be ignored.
  ///
  /// See also:
  ///
  ///  * [toString], for a brief description of the object but not its children.
  ///  * [toStringShallow], for a detailed description of the object but not its
  ///    children.
  String toStringDeep([String prefixLineOne = '', String prefixOtherLines = '']) {
    prefixOtherLines ??= prefixLineOne;

    final List<DiagnosticsNode> children = getChildren();
    final TextTreeConfiguration config = textTreeConfiguration;
    if (prefixOtherLines.isEmpty)
      prefixOtherLines += config.prefixOtherLinesRootNode;

    final _PrefixedStringBuilder builder =  new _PrefixedStringBuilder(
        prefixLineOne, prefixOtherLines);

    if (description == null || description.isEmpty) {
      if (showName && name != null)
        builder.write(name);
    } else {
      if (name != null && name.isNotEmpty && showName) {
        builder.write(name);
        if (showSeparator)
          builder.write(config.afterName);

        builder.write(
            config.isNameOnOwnLine || description.contains('\n') ? '\n' : ' ');
      }
      builder.prefixOtherLines += children.isEmpty ?
          config.propertyPrefixNoChildren : config.propertyPrefixIfChildren;
      builder.write(description);
    }

    final List<DiagnosticsNode> properties =
        getProperties().where((DiagnosticsNode n) => !n.hidden).toList();
    if (properties.isNotEmpty || children.isNotEmpty || emptyBodyDescription != null)
      builder.write(config.afterDescriptionIfBody);

    if (properties.isNotEmpty)
      builder.write(config.beforeProperties);
    builder.write(config.lineBreak);

    builder.prefixOtherLines += config.bodyIndent;

    if (emptyBodyDescription != null &&
        properties.isEmpty &&
        children.isEmpty &&
        prefixLineOne.isNotEmpty) {
      builder..write(emptyBodyDescription)..write(config.lineBreak);
    }

    for (int i = 0; i < properties.length; ++i) {
      final DiagnosticsNode property = properties[i];
      if (i > 0)
        builder.write(config.propertySeparator);

      final int kWrapWidth = 65;
      if (property.style != DiagnosticsTreeStyle.singleLine) {
        final TextTreeConfiguration propertyStyle = property.textTreeConfiguration;
        builder.writeRaw(property.toStringDeep(
            '${builder.prefixOtherLines}${propertyStyle.prefixLineOne}',
            '${builder.prefixOtherLines}${propertyStyle.linkCharacter}${propertyStyle.prefixOtherLines}',
        ));
        continue;
      }
      assert (property.style == null ||
          property.style == DiagnosticsTreeStyle.singleLine);
      final String message = property == null ? '<null>' : property.toString();
      if (config.isSingleLine || message.length < kWrapWidth) {
        builder.write(message);
      } else {
        // debugWordWrap doesn't handle line breaks within the text being
        // wrapped so we must call it on each line.
        final List<String> lines = message.split('\n');
        for (int j = 0; j < lines.length; ++j) {
          final String line = lines[j];
          if (j > 0)
            builder.write(config.lineBreak);
          builder.write(debugWordWrap(line, kWrapWidth, wrapIndent: '  ').join('\n'));
        }
      }
      builder.write(config.lineBreak);
    }
    if (properties.isNotEmpty)
      builder.write(config.afterProperties);

    final String prefixChildren = '$prefixOtherLines${config.bodyIndent}';

    if (children.isEmpty &&
        config.addBlankLineIfNoChildren &&
        builder.hasMultipleLines) {
      final String prefix = prefixChildren.trimRight();
      if (prefix.isNotEmpty)
        builder.writeRaw('$prefix${config.lineBreak}');
    }

    if (children.isNotEmpty && config.showChildren) {
      if (config.isBlankLineBetweenPropertiesAndChildren &&
          properties.isNotEmpty &&
          children.first.textTreeConfiguration.isBlankLineBetweenPropertiesAndChildren) {
        builder.write(config.lineBreak);
      }

      for (int i = 0; i < children.length; i++) {
        final DiagnosticsNode child = children[i];

        final TextTreeConfiguration childConfig = _childTextConfiguration(child, config);
        if (i == children.length - 1) {
          final String lastChildPrefixLineOne = '$prefixChildren${childConfig.prefixLastChildLineOne}';
          if (child == null) {
            builder.writeRawLine('$lastChildPrefixLineOne<null>');
            continue;
          }
          builder.writeRawLine(child.toStringDeep(
            lastChildPrefixLineOne,
            '$prefixChildren${childConfig.childLinkSpace}${childConfig.prefixOtherLines}',
          ));
          if (childConfig.footer.isNotEmpty)
            builder.writeRaw('$prefixChildren${childConfig.childLinkSpace}${childConfig.footer}');

        } else {
          final TextTreeConfiguration nextChildStyle = _childTextConfiguration(children[i + 1], config);

          final String childPrefixLineOne = '$prefixChildren${childConfig.prefixLineOne}';
          final String childPrefixOtherLines ='$prefixChildren${nextChildStyle.linkCharacter}${childConfig.prefixOtherLines}';

          if (child == null) {
            builder.writeRawLine('$childPrefixLineOne<null>');
            continue;
          }
          builder.writeRawLine(child.toStringDeep(childPrefixLineOne, childPrefixOtherLines));
          if (childConfig.footer.isNotEmpty)
            builder.writeRaw('$prefixChildren${nextChildStyle.linkCharacter}${childConfig.footer}');
        }
      }
    }
    return builder.toString();
  }
}

/// Debugging message displayed like a property.
///
/// The following two properties should be a [MessageProperty] not
/// [StringProperty] as the intent is to show a message with property style
/// display not to describe the value of an actual property of the object.
///
/// ```dart
/// new MessageProperty('table size', '$columns\u00D7$rows'));
/// new MessageProperty('usefulness ratio', 'no metrics collected yet (never painted)');
/// ```
///
/// StringProperty should be used if the property has a concrete value that is
/// a string.
/// ```dart
/// new StringProperty('fontFamily', fontFamily);
/// new StringProperty('title', title):
/// ```
///
/// See also:
///
///  * [DiagnosticsProperty.message], which serves the same role for messages
///    without a clear property name.
///  * [StringProperty], which should be used instead for properties with string
///    values.
class MessageProperty extends DiagnosticsProperty<Null> {
  MessageProperty(String name, String message) : super(name, null, description: message);
}

/// Property which encloses its string [value] in quotes.
///
/// See also:
///
///  * [MessageProperty], which should be used instead if showing a message
///    instead of describing a property with a string value.
class StringProperty extends DiagnosticsProperty<String> {
  StringProperty(String name, String value, {
    String description,
    bool showName: true,
    Object defaultValue: kNoDefaultValue,
    bool hidden: false,
    this.quoted: true,
    String ifEmpty,
  }) : super(
    name,
    value,
    description: description,
    defaultValue: defaultValue,
    showName: showName,
    hidden: hidden,
    ifEmpty: ifEmpty,
  );

  /// Whether the description is enclosed in double quotes.
  final bool quoted;

  @override
  String valueToString() {
    final String text = _description ?? value;
    if (quoted && text != null) {
      // An empty value would not appear empty after being surrounded with
      // quotes so we have to handle this case separately.
      if (ifEmpty != null && text.isEmpty)
        return ifEmpty;
      return '"$text"';
    }
    return text.toString();
  }
}

abstract class _NumProperty<T extends num> extends DiagnosticsProperty<T> {
  _NumProperty(String name,
    T value, {
    bool hidden: false,
    String ifNull,
    this.unit,
    bool showName: true,
    Object defaultValue: kNoDefaultValue,
    String tooltip,
  }) : super(
    name,
    value,
    hidden: hidden,
    ifNull: ifNull,
    showName: showName,
    defaultValue: defaultValue,
    tooltip: tooltip,
  );

  _NumProperty.lazy(String name,
    ComputePropertyValueCallback<T> computeValue, {
    bool hidden: false,
    String ifNull,
    this.unit,
    bool showName: true,
    Object defaultValue: kNoDefaultValue,
    String tooltip,
  }) : super.lazy(
    name,
    computeValue,
    hidden: hidden,
    ifNull: ifNull,
    showName: showName,
    defaultValue: defaultValue,
    tooltip: tooltip,
  );


  /// Optional unit the [value] is measured in.
  ///
  /// Unit must be acceptable to display immediately after a number with no
  /// spaces. For example: 'physical pixels per logical pixel' should be a
  /// [tooltip] not a [unit].
  final String unit;

  /// String describing just the numeric [value] without a unit suffix.
  String numberToString();

  @override
  String valueToString() {
    if (value == null)
      return value.toString();

    return unit != null ?  '${numberToString()}$unit' : numberToString();
  }
}
/// Property describing a [double] [value] with an option [unit] of measurement.
///
/// Numeric formatting is optimized for debug message readability.
class DoubleProperty extends _NumProperty<double> {

  /// If specified, `unit` describes the unit for the [value] (e.g. px).
  DoubleProperty(String name, double value, {
    bool hidden: false,
    String ifNull,
    String unit,
    String tooltip,
    Object defaultValue: kNoDefaultValue,
    bool showName : true,
  }) : super(
    name,
    value,
    hidden: hidden,
    ifNull: ifNull,
    unit: unit,
    tooltip: tooltip,
    defaultValue: defaultValue,
    showName: showName,
  );

  /// Property with a [value] that is computed only when needed.
  ///
  /// Use if computing the property [value] may throw an exception or is
  /// expensive.
  DoubleProperty.lazy(
    String name,
    ComputePropertyValueCallback<double> computeValue, {
    bool hidden: false,
    String ifNull,
    String unit,
    String tooltip,
    Object defaultValue: kNoDefaultValue,
  }) : super.lazy(
    name,
    computeValue,
    hidden: hidden,
    ifNull: ifNull,
    unit: unit,
    tooltip: tooltip,
    defaultValue: defaultValue,
  );

  @override
  String numberToString() => object?.toStringAsFixed(1);
}

/// An int valued property with an optional unit the value is measured in.
///
/// Examples of units include 'px' and 'ms'.
class IntProperty extends _NumProperty<int> {
  IntProperty(String name, int value, {
    String ifNull,
    bool showName: true,
    String unit,
    Object defaultValue: kNoDefaultValue,
    bool hidden: false,
  }) : super(
    name,
    value,
    ifNull: ifNull,
    showName: showName,
    unit: unit,
    defaultValue: defaultValue,
    hidden: hidden,
  );

  @override
  String numberToString() => object.toString();
}

/// Property which clamps a [double] to between 0 and 1 and formats it as a
/// percentage.
class PercentProperty extends DoubleProperty {
  PercentProperty(String name, double fraction, {
    String ifNull,
    bool showName: true,
    String tooltip,
    String unit,
  }) : super(
    name,
    fraction,
    ifNull: ifNull,
    showName: showName,
    tooltip: tooltip,
    unit: unit,
  );

  @override
  String valueToString() {
    if (value == null)
      return value.toString();

    return unit != null ?  '${numberToString()} $unit' : numberToString();
  }

  @override
  String numberToString() {
    if (value == null)
      return value.toString();

    return '${(value.clamp(0.0, 1.0) * 100.0).toStringAsFixed(1)}%';
  }
}

/// Property where the description is either [ifTrue] or [ifFalse] depending on
/// whether [value] is `true` or `false`.
///
/// Using FlagProperty instead of `DiagnosticsProperty<bool>` can make
/// diagnostics display more polished. For example, Given a property named
/// `visible` that is typically true, the following code will return 'hidden'
/// when `visible` is false and the empty string in contrast to `visible: true`
/// or `visible: false`.
///
/// ## Sample code
///
/// ```dart
/// new FlagProperty(
///   'visible',
///   value: visible,
///   ifFalse: 'hidden',
/// )).toString()
/// `
///
/// [FlagProperty] should also be used instead of `DiagnosticsProperty<bool>`
/// if showing the bool value would not clearly indicate the meaning of the
/// property value.
///
/// ## Sample code
///
/// ```dart
/// new FlagProperty(
///   'inherit',
///   value: inherit,
///   ifTrue: '<all styles inherited>',
///   ifFalse: '<no style specified>',
/// );
/// ```
///
/// See also:
///
///  * [ObjectFlagProperty], which provides similar behavior describing whether
///    a `value` is `null`.
class FlagProperty extends DiagnosticsProperty<bool> {
  /// Constructs a FlagProperty with the given descriptions  with the specified descriptions.
  ///
  /// [showName] defaults to false as typically [ifTrue] and [ifFalse] should
  /// be descriptions that make the property name redundant.
  FlagProperty(String name, {
    @required bool value,
    this.ifTrue,
    this.ifFalse,
    bool showName: false,
    bool hidden: false,
    Object defaultValue: null,
  }) : super(
    name,
    value,
    showName: showName,
    hidden: hidden,
    defaultValue: defaultValue,
  ) {
    assert(ifTrue != null || ifFalse != null);
  }

  /// Description to use if the property [value] is `true`.
  ///
  /// If not specified and [value] equals `true`, the description is set to the
  /// empty string and the property is [hidden].
  final String ifTrue;

  /// Description to use if the property value is `false`.
  ///
  /// If not specified and [value] equals `false`, the description is set to the
  /// empty string and the property is [hidden].
  final String ifFalse;

  @override
  String valueToString() {
    if (value == true)
      return ifTrue ?? '';
    if (value == false)
      return ifFalse ?? '';
    return '';
  }

  @override
  bool get hidden {
    if (_hidden || object == defaultValue)
      return true;
    if (object == true)
      return ifTrue == null;
    if (object == false)
      return ifFalse == null;

    return true;
  }
}

/// Property with an `Iterable<T>` [value] that can be displayed with
/// different [DiagnosticsTreeStyle] for custom rendering.
///
/// If `style` is [DiagnosticsTreeStyle.singleLine], the iterable is described
/// as a comma separated list, otherwise the iterable is described as a line
/// break separated list.
class IterableProperty<T> extends DiagnosticsProperty<Iterable<T>> {
  IterableProperty(String name, Iterable<T> value, {
    Object defaultValue: kNoDefaultValue,
    String ifNull,
    String ifEmpty = '[]',
    DiagnosticsTreeStyle style: DiagnosticsTreeStyle.singleLine,
  }) : super(
    name,
    value,
    defaultValue: defaultValue,
    ifNull: ifNull,
    ifEmpty: ifEmpty,
    style: style,
  );

  @override
  String valueToString() {
    if (value == null)
      return value.toString();

    return style == DiagnosticsTreeStyle.singleLine ?
        value.join(', ') : object.join('\n');
  }
}

/// An property than displays enum values tersely.
///
/// The enum value is converted to a hyphen-separated string. For example:
/// [HitTestBehavior.deferToChild] is shown as `defer-to-child`.
///
/// See also:
///
///  * [DiagnosticsProperty] which documents named parameters common to all
///    [DiagnosticsProperty]
class EnumProperty<T> extends DiagnosticsProperty<T> {
  EnumProperty(String name, T value, {
    Object defaultValue: kNoDefaultValue,
    bool hidden: false,
  }) : super (
    name,
    value,
    defaultValue: defaultValue,
    hidden: hidden,
  );

  @override
  String valueToString() {
    if (value == null)
      return value.toString();

    return camelCaseToHyphenatedName(describeEnum(value));
  }
}

/// Flag describing whether a [value] is `null` or not.
///
/// [ifPresent] and [ifNull] describe the property [value]
/// when it is present and `null` respectively. If [ifPresent] or [ifNull] is
/// omitted, that is taken to mean that [hidden] should be `true`when [value] is
/// present and null respectively.
///
/// See also:
///
///  * [FlagProperty], which provides similar functionality describing whether
///    a `value` is `true` or `false`.
class ObjectFlagProperty<T> extends DiagnosticsProperty<T> {
  ObjectFlagProperty(String name, T value, {
    this.ifPresent,
    String ifNull,
    bool showName: false,
    bool hidden: false,
  }) : super(
    name,
    value,
    showName: showName,
    hidden: hidden,
    ifNull: ifNull,
  ) {
    assert(ifPresent != null || ifNull != null);
  }

  /// Shorthand constructor to describe whether the property has a value.
  ///
  /// Only use if prefixing the property name with the word 'has' is a good
  /// flag name.
  ObjectFlagProperty.has(
    String name,
    T value,
  ) : ifPresent = 'has $name',
      super(
        name,
        value,
        showName: false,
      );

  /// Description to use if the property [value] is not `null`.
  ///
  /// If the property [value] is not `null` and [ifPresent] is null, the
  /// [description] is the  empty string and the property is [hidden].
  final String ifPresent;

  @override
  String valueToString() {
    if (value != null)
      return ifPresent ?? '';

    return ifNull ?? '';
  }

  @override
  bool get hidden {
    if (super.hidden)
      return true;

    if (object != null)
      return ifPresent == null;

    return ifNull == null;
  }
}

/// Signature for computing the value of a property.
///
/// May throw exception if accessing the property would throw an exception
/// and callers must handle that case gracefully. For example, accessing a
/// property may trigger an assert that layout constraints were violated.
typedef T ComputePropertyValueCallback<T>();

/// Property with a [value] of type [T].
///
/// If the default `object.toString()` does not provide an adequate description
/// of the object, specify `description` defining a custom description.
/// * `hidden` specifies whether the property should be hidden.
/// * `showSeparator` indicates whether a separator should be placed
///   between the property `name` and `object`.
class DiagnosticsProperty<T> extends DiagnosticsNode {
  DiagnosticsProperty(
    String name,
    T value, {
    String description,
    bool hidden: false,
    this.ifNull,
    this.ifEmpty,
    bool showName: true,
    bool showSeparator: true,
    this.defaultValue: kNoDefaultValue,
    this.tooltip,
    DiagnosticsTreeStyle style : DiagnosticsTreeStyle.singleLine,
  }) : _description = description,
       _valueComputed = true,
       _value = value,
       _computeValue = null,
       _hidden = hidden,
       super(
         name: name,
         showName: showName,
         showSeparator: showSeparator,
         style: style,
      );

  /// Property with a [value] that is computed only when needed.
  ///
  /// Use if computing the property [value] may throw an exception or is
  /// expensive.
  DiagnosticsProperty.lazy(
    String name,
    ComputePropertyValueCallback<T> computeValue, {
    String description,
    bool hidden: false,
    this.ifNull,
    this.ifEmpty,
    bool showName: true,
    bool showSeparator: true,
    this.defaultValue: kNoDefaultValue,
    this.tooltip,
    DiagnosticsTreeStyle style : DiagnosticsTreeStyle.singleLine,
  }) : _description = description,
       _valueComputed = false,
       _value = null,
       _computeValue = computeValue,
       _hidden = hidden,
       super(
         name: name,
         showName: showName,
         showSeparator: showSeparator,
         style: style,
       );

  final String _description;

  /// Returns a string representation of the property value.
  ///
  /// Subclasses should override this method instead of [description] to
  /// customize how property values are converted to strings.
  ///
  /// Overriding this method ensures that behavior controlling how property
  /// values are decorated to generate a nice description are consistent across
  /// all implementations. Debugging tools may also choose to use
  /// [valueToString] directly instead of [description].
  String valueToString() => value.toString();

  @override
  String get description {
    if (_description != null)
      return addTooltip(_description);

    if (exception != null)
      return 'EXCEPTION (${exception.runtimeType})';

    if (ifNull != null && object == null)
      return addTooltip(ifNull);

    String result = valueToString();
    if (result.isEmpty && ifEmpty != null)
      result = ifEmpty;
    return addTooltip(result);
  }

  String addTooltip(String text) {
    return tooltip == null ? text : '$text ($tooltip)';
  }

  /// Description if the property [value] is null.
  final String ifNull;

  /// Description if the property description would otherwise be empty.
  final String ifEmpty;

  /// Optional tooltip typically describing the property.
  ///
  /// Example tooltip: 'physical pixels per logical pixel'
  ///
  /// If present, the tooltip is added in parenthesis after the raw value when
  /// generating the string description.
  final String tooltip;

  Type get propertyType => T;

  /// Returns the value of the property either from cache or by invoking a
  /// [ComputePropertyValueCallback].
  ///
  /// If an exception is thrown invoking the [ComputePropertyValueCallback],
  /// [value] returns `null` and the exception thrown can be found via the
  /// [exception] property.
  ///
  /// See also:
  ///
  ///  * [valueToString], which converts the property value to a string.
  T get value {
    _maybeCacheValue();
    return _value;
  }

  T _value;

  bool _valueComputed;

  @override
  T get object => value;

  Object _exception;

  /// Exception thrown if accessing the property [value] threw an exception.
  ///
  /// Returns null if computing the property value did not throw an exception.
  Object get exception {
    _maybeCacheValue();
    return _exception;
  }

  void _maybeCacheValue() {
    if (_valueComputed)
      return;

    _valueComputed = true;
    assert(_computeValue != null);
    try {
      _value = _computeValue();
    } catch (exception) {
      _exception = exception;
      _value = null;
    }
  }

  final Object defaultValue;

  final bool _hidden;

  @override
  bool get hidden {
    if (_hidden)
      return true;

    if (defaultValue != kNoDefaultValue) {
      if (exception != null)
        return false;

      return object == defaultValue;
    }
    return false;
  }

  final ComputePropertyValueCallback<T> _computeValue;

  @override
  List<DiagnosticsNode> getProperties() => <DiagnosticsNode>[];

  @override
  List<DiagnosticsNode> getChildren() => <DiagnosticsNode>[];
}

/// Add additional properties describing an object.
///
/// See also:
///
///  * [TreeDiagnosticsMixin.debugFillProperties], which lists best practices
///    for specifying properties.
typedef void FillPropertiesCallback(List<DiagnosticsNode> properties);

/// Returns a list of [DiagnosticsNode] objects describing an object's children.
///
/// See also:
///
///  * [TreeDiagnosticsMixin.debugDescribeChildren], which lists best practices
///    for describing children.
typedef List<DiagnosticsNode> GetChildrenCallback();

class _LazyMembersDiagnosticsNode extends DiagnosticsNode {
  _LazyMembersDiagnosticsNode({
    @required String name,
    @required String description,
    @required this.object,
    GetChildrenCallback getChildren,
    FillPropertiesCallback fillProperties,
    String emptyBodyDescription,
    DiagnosticsTreeStyle style: DiagnosticsTreeStyle.sparse,
  }) : _description = description,
       _getChildren = getChildren,
       _fillProperties = fillProperties,
       super(
         name: name,
         style: style,
         emptyBodyDescription: emptyBodyDescription,
       );

  @override
  final Object object;

  final GetChildrenCallback _getChildren;
  final FillPropertiesCallback _fillProperties;

  final String _description;

  @override
  bool get hidden => false;

  @override
  String get description => _description ?? object.toString();

  @override
  List<DiagnosticsNode> getProperties() {
    final List<DiagnosticsNode> properties = <DiagnosticsNode>[];
    if (_fillProperties != null)
      _fillProperties(properties);
    return properties;
  }

  @override
  List<DiagnosticsNode> getChildren() {
    return _getChildren != null ? _getChildren() :  <DiagnosticsNode>[];
  }
}

/// [DiagnosticsNode] for an instance of [TreeDiagnosticsMixin].
class _TreeDiagnosticsMixinNode extends DiagnosticsNode {
  @override
  final TreeDiagnosticsMixin object;

  _TreeDiagnosticsMixinNode({
    String name,
    this.object,
    DiagnosticsTreeStyle style,
  }) : super(
    name: name,
    style: style,
  );

  @override
  List<DiagnosticsNode> getProperties() {
    final List<DiagnosticsNode> description = <DiagnosticsNode>[];
    if (object != null)
      object.debugFillProperties(description);
    return description;
  }

  @override
  List<DiagnosticsNode> getChildren() {
    if (object != null)
      return object.debugDescribeChildren();
    return <DiagnosticsNode>[];
  }

  @override
  String get description => object.toString();

  @override bool get hidden => false;
}

/// Returns a 5 character long hexadecimal string generated from
/// Object.hashCode's 20 least-significant bits.
String shortHash(Object object) {
  return object.hashCode.toUnsigned(20).toRadixString(16).padLeft(5, '0');
}

/// Returns a summary of the runtime type and hash code of `object`.
String describeIdentity(Object object) =>
    '${object.runtimeType}#${shortHash(object)}';

// This method exists as a workaround for https://github.com/dart-lang/sdk/issues/30021
/// Returns a short description of an enum value.
///
/// Strips off the enum class name from the `enumEntry.toString()`.
///
/// ## Sample code
///
/// ```dart
/// enum Day {
///   monday, tuesday, wednesday, thursday, friday, saturday, sunday
/// }
///
/// main() {
///   assert(Day.monday.toString() == 'Day.monday');
///   assert(describeEnum(Day.monday) == 'monday');
/// }
/// ```
String describeEnum(Object enumEntry) {
  final String description = enumEntry.toString();
  final int indexOfDot = description.indexOf('.');
  assert(indexOfDot != -1 && indexOfDot < description.length - 1);
  return description.substring(indexOfDot + 1);
}

/// Returns a lowercase hyphen-separated version of a camel case name.
///
/// ## Sample code
///
/// ```dart
/// main() {
///   assert(toHyphenedName('deferToChild') == 'defer-to-child');
///   assert(toHyphenedName('Monday') == 'monday');
///   assert(toHyphenedName('monday') == 'monday');
/// }
/// ```
String camelCaseToHyphenatedName(String word) {
  final String lowerWord = word.toLowerCase();
  if (word == lowerWord)
    return word;

  final StringBuffer buffer = new StringBuffer();
  for (int i = 0; i < word.length; i++) {
    final String lower = lowerWord[i];
    if (word[i] != lower && i > 0)
      buffer.write('-');
    buffer.write(lower);
  }
  return buffer.toString();
}

/// An interface providing string and [DiagnosticNode] debug representations.
///
/// The string debug representation is generated from the intermediate
/// [DiagnosticNode] representation. The [DiagnosticNode] representation is
/// also used by debugging tools displaying interactive trees of objects and
/// properties.
///
/// See also:
///
///  * [TreeDiagnosticsMixin], which should be used to implement this interface
///    in all contexts where a mixin can be used.
///  * [TreeDiagnosticsMixin.debugFillProperties], which lists best practices
///    for specifying the properties of a [DiagnosticNode]. The most common use
///    case is to override [debugFillProperties] defining custom properties for
///    a subclass of [TreeDiagnosticsMixin] using the existing
///    [DiagnosticsProperty] subclasses.
///  * [TreeDiagnosticsMixin.debugDescribeChildren], which lists best practices
///    for describing the children of a [DiagnosticNode]. Typically the base
///    class already describes the children of a node properly or a node has
///    no children.
///  * [DiagnosticsProperty], which should be used to create leaf diagnostic
///    nodes without properties or children. There are many [DiagnosticProperty]
///    subclasses to handle common use cases.
///  * [DiagnosticsNode.lazy], which should be used to create a DiagnosticNode
///    with children and properties where [TreeDiagnosticsMixin] cannot be used.
abstract class TreeDiagnostics {
  const TreeDiagnostics();

  /// The [toStringDeep] method takes arguments, but those are intended for
  /// internal use when recursing to the descendants, and so can be ignored.
  ///
  /// See also:
  ///
  ///  * [toString], for a brief description of the object but not its children.
  ///  * [TreeDiagnosticsMixin.toStringShallow], for a detailed description of
  ///    the object but not its children.
  String toStringDeep([String prefixLineOne = '', String prefixOtherLines = '']) {
    return toDiagnosticsNode().toStringDeep(prefixLineOne, prefixOtherLines);
  }

  DiagnosticsNode toDiagnosticsNode({ String name, DiagnosticsTreeStyle style });
}

/// A mixin that helps dump string and [DiagnosticsNode] representations of
/// trees.
///
/// Use this class to implement [TreeDiagnostics] any time it is possible to use
/// mixins.
abstract class TreeDiagnosticsMixin implements TreeDiagnostics {
  // This class is intended to be used as a mixin, and should not be
  // extended directly.
  factory TreeDiagnosticsMixin._() => null;

  /// A brief description of this object, usually just the [runtimeType] and the
  /// [hashCode].
  ///
  /// See also:
  ///
  ///  * [toStringShallow], for a detailed description of the object.
  ///  * [toStringDeep], for a description of the subtree rooted at this object.
  @override
  String toString() => describeIdentity(this);

  /// Returns a one-line detailed description of the object.
  ///
  /// This description is often somewhat long. This includes the same
  /// information given by [toStringDeep], but does not recurse to any children.
  ///
  /// The [toStringShallow] method can take an argument, which is the string to
  /// place between each part obtained from [debugFillProperties]. Passing a
  /// string such as `'\n '` will result in a multiline string that indents the
  /// properties of the object below its name (as per [toString]).
  ///
  /// See also:
  ///
  ///  * [toString], for a brief description of the object.
  ///  * [toStringDeep], for a description of the subtree rooted at this object.
  String toStringShallow([String joiner = '; ']) {
    final StringBuffer result = new StringBuffer();
    result.write(toString());
    result.write(joiner);
    final List<DiagnosticsNode> properties = <DiagnosticsNode>[];
    debugFillProperties(properties);
    result.write(
      properties.where((DiagnosticsNode n) => !n.hidden).join(joiner),
    );
    return result.toString();
  }

  /// Returns a string representation of this node and its descendants.
  ///
  /// The [toStringDeep] method takes arguments, but those are intended for
  /// internal use when recursing to the descendants, and so can be ignored.
  ///
  /// See also:
  ///
  ///  * [toString], for a brief description of the object but not its children.
  ///  * [toStringShallow], for a detailed description of the object but not its
  ///    children.
  @override
  String toStringDeep([String prefixLineOne = '', String prefixOtherLines = '']) {
    return toDiagnosticsNode().toStringDeep(prefixLineOne, prefixOtherLines);
  }

  @override
  DiagnosticsNode toDiagnosticsNode({ String name, DiagnosticsTreeStyle style }) {
    return new _TreeDiagnosticsMixinNode(
      name: name,
      object: this,
      style: style,
    );
  }

  /// Add additional properties associated with the node.
  ///
  /// Use the most specific [DiagnosticsProperty] existing subclass to describe
  /// each property instead of the [DiagnosticsProperty] base class. There are
  /// only a small number of [DiagnosticProperty] subclasses each covering a
  /// common use case. Consider what values a property is relevant for users
  /// debugging as users debugging large trees are overloaded with information.
  /// Common named parameters in [DiagnosticNode] subclasses help filter when
  /// and how properties are displayed.
  ///
  /// `defaultValue`, `showName`, `showSeparator`, and `hidden` keep string
  /// representations of diagnostics terse and hide properties when they are not
  /// very useful.
  ///
  ///  * Use `defaultValue` any time the default value of a property is
  ///    uninteresting. For example, specify a default value of `null` any time
  ///    a property being `null` does not indicate an error.
  ///  * Avoid specifying the `hidden` parameter unless the result you want
  ///    cannot be be achieved by using the `defaultValue` parameter or using
  ///    the [ObjectFlagProperty] class to conditionally display the property
  ///    as a flag.
  ///  * Specify `showName` and `showSeparator` in rare cases where the string
  ///    output would look clumsy if they were not set.
  ///    ```dart
  ///    new DiagnosticsProperty<Object>('child(3, 4)', null, ifNull: 'is null', showSeparator: false).toString()
  ///    ```
  ///    Shows using `showSeparator` to get output `child(3, 4) is null` which
  ///    is more polished than `child(3, 4): is null`.
  ///    ```dart
  ///    new DiagnosticsProperty<IconData>('icon', icon, ifNull: '<empty>', showName: false)).toString()
  ///    ```
  ///    Shows using `showName` to omit the property name as in this context the
  ///    property name does not add useful information.
  ///
  /// `ifNull`, `ifEmpty`, `unit`, and `tooltip` make property
  /// descriptions clearer. The examples in the code sample below illustrate
  /// good uses of all of these parameters.
  ///
  /// ## DiagnosticProperty subclasses for primitive types
  ///
  ///  * [StringProperty], which supports automatically enclosing a [String]
  ///    value in quotes.
  ///  * [DoubleProperty], which supports specifying a unit of measurement for
  ///    a [double] value.
  ///  * [PercentProperty], which clamps a [double] to between 0 and 1 and
  ///    formats it as a percentage.
  ///  * [IntProperty], which supports specifying a unit of measurement for an
  ///    [int] value.
  ///  * [FlagProperty], which formats a [bool] value as one or more flags.
  ///    Depending on the use case it is better to format a bool as
  ///    `DiagnosticProperty<bool>` instead of using [FlagProperty] as the
  ///    output is more verbose but unambiguous.
  ///
  /// ## Other important [DiagnosticProperty] subclasses
  ///
  ///  * [EnumProperty], which provides terse descriptions of enum values
  ///    working around limitations of the `toString` implementation for Dart
  ///    enum types.
  ///  * [IterableProperty], which handles iterable values with display
  ///    customizable depending on the [DiagnosticsTreeStyle] used.
  ///  * [LazyDiagnosticsProperty], which handles properties where computing the
  ///    value could throw an exception.
  ///  * [ObjectFlagProperty], which provides terse descriptions of whether a
  ///    property value is present or not. For example, whether an `onClick`
  ///    callback is specified or an animation is in progress.
  ///
  /// If none of these subclasses apply, use the [DiagnosticProperty]
  /// constructor or in rare cases create your own [DiagnosticsProperty]
  /// subclass as in the case for [TransformProperty] which handles [Matrix4]
  /// that represent transforms. Generally any property value with a good
  /// `toString` method implementation works fine using [DiagnosticProperty]
  /// directly.
  ///
  /// ## Sample code
  ///
  /// This example shows best practices for implementing [debugFillProperties]
  /// illustrating use of all common [DiagnosticProperty] subclasses and all
  /// common [DiagnosticsProperty] parameters.
  ///
  /// ```dart
  /// @override
  /// void debugFillProperties(List<DiagnosticsNode> properties) {
  ///   // Always add properties from the base class first.
  ///   super.debugFillProperties(properties);
  ///
  ///   // Omit the property name 'message' when displaying this String property
  ///   // as it would just add visual noise.
  ///   description.add(new StringProperty('message', message, showName: false));
  ///
  ///   description.add(new DoubleProperty('stepWidth', stepWidth));
  ///
  ///   // A scale of 1.0 does nothing so should be hidden.
  ///   description.add(new DoubleProperty('scale', scale, defaultValue: 1.0));
  ///
  ///   // If the hitTestExtent matches the paintExtent, it is just set to its
  ///   // default value so is not relevant.
  ///   properties.add(new DoubleProperty('hitTestExtent', hitTestExtent, defaultValue: paintExtent));
  ///
  ///   // maxWidth of double.INFINITY indicates the width is unconstrained and
  ///   // so maxWidth has no impact.,
  ///   description.add(new DoubleProperty('maxWidth', maxWidth, defaultValue: double.INFINITY));
  ///
  ///   // Progress is a value between 0 and 1 or null. Showing it as a
  ///   // percentage makes the meaning clear enough that the name can be
  ///   // hidden.
  ///   description.add(new PercentProperty(
  ///     'progress',
  ///     progress,
  ///     showName: false,
  ///     ifNull: '<indeterminate>',
  ///   ));
  ///
  ///   // Most text fields have maxLines set to 1.
  ///   description.add(new IntProperty('maxLines', maxLines, defaultValue: 1));
  ///
  ///   // Specify the unit as otherwise it would be unclear that time is in
  ///   // milliseconds.
  ///   description.add(new IntProperty('duration', duration.inMilliseconds, unit: 'ms'));
  ///
  ///   // Tooltip is used instead of unit for this case as a unit should be a
  ///   // terse description appropriate to display directly after a number
  ///   // without a space.
  ///   description.add(new DoubleProperty(
  ///     'device pixel ratio',
  ///     ui.window.devicePixelRatio,
  ///     tooltip: 'physical pixels per logical pixel',
  ///   ));
  ///
  ///   // Displaying the depth value would be distracting. Instead only display
  ///   // if the depth value is missing.
  ///   description.add(new ObjectFlagProperty<int>('depth', depth, ifNull: 'no depth'));
  ///
  ///   // bool flag that is only shown when the value is true.
  ///   description.add(new FlagProperty('using primary controller', value: primary));
  ///
  ///   description.add(new FlagProperty.describe(
  ///     'isCurrent',
  ///     value: isCurrent,
  ///     ifTrue: 'active',
  ///     ifFalse: 'inactive',
  ///     showName: false,
  ///   ));
  ///
  ///   description.add(new DiagnosticsProperty<bool>('keepAlive', keepAlive));
  ///
  ///   // FlagProperty could have also been used in this case.
  ///   // This option results in the text "obscureText: true" instead
  ///   // of "obscureText" which is a bit more verbose but a bit clearer.
  ///   description.add(new DiagnosticsProperty<bool>('obscureText', obscureText, defaultValue: false));
  ///
  ///   description.add(new EnumProperty<TextAlign>('textAlign', textAlign, defaultValue: null));
  ///   description.add(new EnumProperty<ImageRepeat>('repeat', repeat, defaultValue: ImageRepeat.noRepeat));
  ///
  ///   // Warn users when the widget is missing but do not show the value.
  ///   description.add(new ObjectFlagProperty<Widget>('widget', widget, ifNull: 'no widget'));
  ///
  ///   description.add(new IterableProperty<BoxShadow>(
  ///     'boxShadow',
  ///     boxShadow,
  ///     defaultValue: null,
  ///     style: style,
  ///   ));
  ///
  ///   // Getting the value of size throws an exception unless hasSize is true.
  ///   description.add(new DiagnosticsProperty<Size>.lazy(
  ///     'size',
  ///     () => size,
  ///     description: '${ hasSize ? size : "MISSING" }',
  ///   ));
  ///
  ///   // If the `toString` method for the property value does not provide a
  ///   // good terse description, write a DiagnosticsProperty subclass as in
  ///   // the case of TransformProperty which displays a nice debugging view
  ///   // of a Matrix4 that represents a transform.
  ///   description.add(new TransformProperty('transform', transform));
  ///
  ///   // If the value class has a good `toString` method, use
  ///   // DiagnosticsProperty<YourValueType>. Specifying the value type ensures
  ///   // that debugging tools always know the type of the field and so can
  ///   // provide the right UI affordances. For example, in this case even
  ///   // if color is null, a debugging tool still knows the value is a Color
  ///   // and can display relevant color related UI.
  ///   description.add(new DiagnosticsProperty<Color>('color', color));
  ///
  ///   // Use a custom description to generate a more terse summary than the
  ///   // `toString` method on the map class.
  ///   description.add(new DiagnosticsProperty<Map<Listenable, VoidCallback>>(
  ///     'handles',
  ///     handles,
  ///     description: handles != null ?
  ///     '${handles.length} active client${ handles.length == 1 ? "" : "s" }' :
  ///     null,
  ///     ifNull: 'no notifications ever received',
  ///     showName: false,
  ///   ));
  /// }
  /// ```
  ///
  /// Used by [toStringDeep], [toDiagnosticsNode] and [toStringShallow].
  @protected
  @mustCallSuper
  void debugFillProperties(List<DiagnosticsNode> properties) { }

  /// Returns a list of [DiagnosticsNode] objects describing this node's
  /// children.
  ///
  /// Children that are offstage should added with `style`
  /// [DiagnosticsTreeStyle.offstage] to indicate that they are offstage.
  ///
  /// See also:
  ///
  ///  * [RenderTable.debugDescribeChildren], which provides high quality custom
  ///    descriptions for child nodes.
  ///
  /// Used by [toStringDeep], [toDiagnosticsNode] and [toStringShallow].
  @protected
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[];
  }
}