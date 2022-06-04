// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

abstract class TokenTemplate {
  const TokenTemplate(this.fileName, this.tokens, {
    this.colorSchemePrefix = 'Theme.of(context).colorScheme.',
    this.textThemePrefix = 'Theme.of(context).textTheme.'
  });

  static const String beginGeneratedComment = '''

// BEGIN GENERATED TOKEN PROPERTIES
''';

  static const String headerComment = '''

// Generated code to the end of this file. Do not edit by hand.
// These defaults are generated from the Material Design Token
// database by the script dev/tools/gen_defaults/bin/gen_defaults.dart.

''';

  static const String endGeneratedComment = '''

// END GENERATED TOKEN PROPERTIES
''';

  final String fileName;
  final Map<String, dynamic> tokens;
  final String colorSchemePrefix;
  final String textThemePrefix;

  /// Replace or append the contents of the file with the text from [generate].
  ///
  /// If the file already contains generated block at the end, it will
  /// be replaced by the [generate] output. Otherwise the content will
  /// just be appended to the end of the file.
  Future<void> updateFile() async {
    String contents = File(fileName).readAsStringSync();
    final int previousGeneratedIndex = contents.indexOf(beginGeneratedComment);
    if (previousGeneratedIndex != -1) {
      contents = contents.substring(0, previousGeneratedIndex);
    }
    final StringBuffer buffer = StringBuffer(contents);
    buffer.write(beginGeneratedComment);
    buffer.write(headerComment);
    buffer.write(generate());
    buffer.write(endGeneratedComment);
    File(fileName).writeAsStringSync(buffer.toString());
  }

  /// Provide the generated content for the template.
  ///
  /// This abstract method needs to be implemented by subclasses
  /// to provide the content that [updateFile] will append to the
  /// bottom of the file.
  String generate();

  /// Generate a [ColorScheme] color name for the given token.
  ///
  /// If there is a value for the given token, this will return
  /// the value prepended with [colorSchemePrefix].
  ///
  /// Otherwise it will return 'null'.
  ///
  /// See also:
  ///   * [componentColor], that provides support for an optional opacity.
  String color(String colorToken) {
    return tokens.containsKey(colorToken)
      ? '$colorSchemePrefix${tokens[colorToken]}'
      : 'null';
  }

  /// Generate a [ColorScheme] color name for the given component's color
  /// with opacity if available.
  ///
  /// If there is a value for the given component's color, this will return
  /// the value prepended with [colorSchemePrefix]. If there is also
  /// an opacity specified for the component, then the returned value
  /// will include this opacity calculation.
  ///
  /// If there is no value for the component's color, 'null' will be returned.
  ///
  /// See also:
  ///   * [color], that provides support for looking up a raw color token.
  String componentColor(String componentToken) {
    final String colorToken = '$componentToken.color';
    if (!tokens.containsKey(colorToken))
      return 'null';
    String value = color(colorToken);
    final String opacityToken = '$componentToken.opacity';
    if (tokens.containsKey(opacityToken)) {
      value += '.withOpacity(${opacity(opacityToken)})';
    }
    return value;
  }

  /// Generate the opacity value for the given token.
  String? opacity(String token) {
    final dynamic value = tokens[token];
    if (value == null) {
      return null;
    }
    if (value is double) {
      return value.toString();
    }
    return tokens[value].toString();
  }

  /// Generate an elevation value for the given component token.
  String elevation(String componentToken) {
    return tokens[tokens['$componentToken.elevation']!]!.toString();
  }

  /// Generate a shape constant for the given component token.
  ///
  /// Currently supports family:
  ///   - "SHAPE_FAMILY_ROUNDED_CORNERS" which maps to [RoundedRectangleBorder].
  ///   - "SHAPE_FAMILY_CIRCULAR" which maps to a [StadiumBorder].
  String shape(String componentToken) {
    final Map<String, dynamic> shape = tokens[tokens['$componentToken.shape']!]! as Map<String, dynamic>;
    switch (shape['family']) {
      case 'SHAPE_FAMILY_ROUNDED_CORNERS':
        return 'const RoundedRectangleBorder(borderRadius: '
            'BorderRadius.only('
            'topLeft: Radius.circular(${shape['topLeft']}), '
            'topRight: Radius.circular(${shape['topRight']}), '
            'bottomLeft: Radius.circular(${shape['bottomLeft']}), '
            'bottomRight: Radius.circular(${shape['bottomRight']})))';
      case 'SHAPE_FAMILY_CIRCULAR':
        return 'const StadiumBorder()';
    }
    print('Unsupported shape family type: ${shape['family']} for $componentToken');
    return '';
  }

  /// Generate a [BorderSide] for the given component.
  String border(String componentToken) {
    if (!tokens.containsKey('$componentToken.color')) {
      return 'null';
    }
    final String borderColor = componentColor(componentToken);
    final double width = (tokens['$componentToken.width'] ?? 1.0) as double;
    return 'BorderSide(color: $borderColor${width != 1.0 ? ", width: $width" : ""})';
  }

  /// Generate a [TextTheme] text style name for the given component token.
  String textStyle(String componentToken) {
    return '$textThemePrefix${tokens["$componentToken.text-style"]!.toString()}';
  }
}
