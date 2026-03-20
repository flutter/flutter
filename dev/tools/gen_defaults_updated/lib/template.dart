// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import '../data/color_roles.dart';

/// Base class for code generation templates.
abstract class TokenTemplate {
  const TokenTemplate(
    this.blockName,
    this.fileName, {
    this.colorSchemePrefix = '_colors.',
    this.textThemePrefix = 'Theme.of(context).textTheme.',
  });

  /// Name of the code block that this template will generate.
  ///
  /// Used to identify an existing block when updating it.
  final String blockName;

  /// Name of the file that will be updated with the generated code.
  final String fileName;

  /// Optional prefix prepended to color definitions.
  ///
  /// Defaults to '_colors.'
  final String colorSchemePrefix;

  /// Optional prefix prepended to text style definitions.
  ///
  /// Defaults to 'Theme.of(context).textTheme.'
  final String textThemePrefix;

  static const String beginGeneratedComment = '''

// BEGIN GENERATED TOKEN PROPERTIES''';

  static const String headerComment = '''

// Do not edit by hand. The code between the "BEGIN GENERATED" and
// "END GENERATED" comments are generated from data in the Material
// Design token database by the script:
//   dev/tools/gen_defaults_updated/bin/gen_defaults_updated.dart.

// dart format off
''';

  static const String footerComment = '''
// dart format on
''';

  static const String endGeneratedComment = '''

// END GENERATED TOKEN PROPERTIES''';

  /// Replace or append the contents of the file with the text from [generate].
  ///
  /// If the file already contains a generated text block matching the
  /// [blockName], it will be replaced by the [generate] output. Otherwise
  /// the content will just be appended to the end of the file.
  void updateFile() {
    final File file = File(fileName);
    if (!file.existsSync()) {
      print('File $fileName does not exist. Skipping.');
      return;
    }
    final String contents = file.readAsStringSync();
    final beginComment = '$beginGeneratedComment - $blockName\n';
    final endComment = '$endGeneratedComment - $blockName\n';
    final int beginPreviousBlock = contents.indexOf(beginComment);
    final int endPreviousBlock = contents.indexOf(endComment);
    late String contentBeforeBlock;
    late String contentAfterBlock;
    if (beginPreviousBlock != -1) {
      if (endPreviousBlock < beginPreviousBlock) {
        print('Unable to find block named $blockName in $fileName, skipping code generation.');
        return;
      }
      // Found a valid block matching the name, so record the content before and after.
      contentBeforeBlock = contents.substring(0, beginPreviousBlock);
      contentAfterBlock = contents.substring(endPreviousBlock + endComment.length);
    } else {
      // Just append to the bottom.
      contentBeforeBlock = contents;
      contentAfterBlock = '';
    }

    final buffer = StringBuffer(contentBeforeBlock);
    buffer.write(beginComment);
    buffer.write(headerComment);
    buffer.write(generate());
    buffer.write(footerComment);
    buffer.write(endComment);
    buffer.write(contentAfterBlock);
    file.writeAsStringSync(buffer.toString());
  }

  /// Provide the generated content for the template.
  ///
  /// This abstract method needs to be implemented by subclasses
  /// to provide the content that [updateFile] will append to the
  /// bottom of the file.
  String generate();

  /// Generate a [ColorScheme] color name for the given token.
  String color(TokenColorRole role) {
    return '$colorSchemePrefix${role.name}';
  }

  /// Generate a [ColorScheme] color name for the given component's color
  /// with opacity if available.
  String componentColor(TokenColorRole role, [double? opacity]) {
    String value = color(role);
    if (opacity != null && opacity != 1.0) {
      value += '.withOpacity($opacity)';
    }
    return value;
  }
}
