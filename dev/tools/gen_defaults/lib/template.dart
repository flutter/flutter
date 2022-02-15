// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

abstract class TokenTemplate {
  const TokenTemplate(this.fileName, this.tokens);

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

  /// Generate a [ColorScheme] color name for the given component token.
  ///
  /// If there is an opacity specified for the given component, it will
  /// apply that opacity to the component's color.
  String color(String componentToken) {
    final String tokenColor = '$componentToken.color';
    final String tokenOpacity = '$componentToken.opacity';
    String value = '${tokens[tokenColor]!}';
    if (tokens.containsKey(tokenOpacity)) {
      final String opacity = tokens[tokens[tokenOpacity]!]!.toString();
      value += '.withOpacity($opacity)';
    }
    return value;
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

  /// Generate a [TextTheme] text style name for the given component token.
  String textStyle(String componentToken) {
    return tokens['$componentToken.text-style']!.toString();
  }
}
