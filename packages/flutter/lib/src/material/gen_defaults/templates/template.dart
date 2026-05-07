// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import '../data/color_role.dart';
import '../data/shape_struct.dart';

/// Base class for code generation templates.
abstract class TokenTemplate {
  const TokenTemplate(
    this.blockName,
    this.fileName, {
    this.colorSchemePrefix = '_colors.',
    this.textThemePrefix = 'Theme.of(context).textTheme.',
  });

  final String blockName;
  final String fileName;
  final String colorSchemePrefix;
  final String textThemePrefix;

  static const String beginGeneratedComment = '// BEGIN GENERATED TOKEN PROPERTIES';

  static const String headerComment = '''

// Do not edit by hand. The code between the "BEGIN GENERATED" and
// "END GENERATED" comments are generated from data in the Material
// Design token database by the script:
//   packages/flutter/lib/src/material/gen_defaults/bin/gen_defaults.dart.

// dart format off
''';

  static const String footerComment = '''
// dart format on
''';

  static const String endGeneratedComment = '// END GENERATED TOKEN PROPERTIES';

  void updateFile() {
    final file = File(fileName);
    if (!file.existsSync()) {
      stdout.writeln('File $fileName does not exist. Skipping.');
      return;
    }
    final String contents = file.readAsStringSync();
    final beginComment = '$beginGeneratedComment - ${blockName}M3E\n';
    final endComment = '$endGeneratedComment - ${blockName}M3E\n';
    final int beginPreviousBlock = contents.indexOf(beginComment);
    final int endPreviousBlock = contents.indexOf(endComment);
    late String contentBeforeBlock;
    late String contentAfterBlock;
    if (beginPreviousBlock != -1) {
      if (endPreviousBlock < beginPreviousBlock) {
        stdout.writeln(
          'Unable to find block named ${blockName}M3E in $fileName, skipping code generation.',
        );
        return;
      }
      contentBeforeBlock = contents.substring(0, beginPreviousBlock);
      contentAfterBlock = contents.substring(endPreviousBlock + endComment.length);
    } else {
      contentBeforeBlock = contents;
      contentAfterBlock = '';
    }

    final buffer = StringBuffer(contentBeforeBlock);
    buffer.write('\n');
    buffer.write(beginComment);
    buffer.write(headerComment);
    buffer.write(generate());
    buffer.write(footerComment);
    buffer.write(endComment);
    buffer.write(contentAfterBlock);
    file.writeAsStringSync(buffer.toString());
  }

  String generate();

  String color(TokenColorRole role) {
    return '$colorSchemePrefix${_colorSchemeName(role)}';
  }

  String componentColor(TokenColorRole role, [double? opacity]) {
    String value = color(role);
    if (opacity != null && opacity != 1.0) {
      value += '.withOpacity($opacity)';
    }
    return value;
  }

  String _colorSchemeName(TokenColorRole role) {
    return switch (role) {
      TokenColorRole.inverseOnSurface => 'onInverseSurface',
      _ => role.name,
    };
  }

  String shape(ShapeStruct token, {double? circularRadius}) {
    final isCircular = token.family == 'SHAPE_FAMILY_CIRCULAR';
    final bool hasUniformCorners =
        token.topLeft == token.topRight &&
        token.topLeft == token.bottomLeft &&
        token.topLeft == token.bottomRight;

    if (isCircular) {
      return 'const StadiumBorder()';
    }

    if (hasUniformCorners) {
      return 'const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(${token.topLeft})))';
    }

    return '''
const RoundedRectangleBorder(
  borderRadius: BorderRadius.only(
    topLeft: Radius.circular(${token.topLeft}),
    topRight: Radius.circular(${token.topRight}),
    bottomLeft: Radius.circular(${token.bottomLeft}),
    bottomRight: Radius.circular(${token.bottomRight}),
  ),
)''';
  }
}
