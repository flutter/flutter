// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

abstract class TokenTemplate {
  TokenTemplate(this.fileName, this.tokens);

  static const String headerComment = '''

// Generated code to the end of this file. Do not edit by hand.
// These defaults are generated from the Material Design Token
// database by the script dev/tools/tokens/bin/gen_defaults.dart.

// BEGIN GENERATED TOKEN PROPERTIES

''';

  static const String endGeneratedComment = '''
// END GENERATED TOKEN PROPERTIES
''';

  final String fileName;
  final Map<String, dynamic> tokens;

  Future<void> updateFile() async {
    String contents = File(fileName).readAsStringSync();
    final int previousHeaderIndex = contents.indexOf(headerComment);
    if (previousHeaderIndex != -1) {
      contents = contents.substring(0, previousHeaderIndex);
    }
    final StringBuffer buffer = StringBuffer(contents);
    buffer.write(headerComment);
    buffer.write(generate());
    buffer.write(endGeneratedComment);
    File(fileName).writeAsStringSync(buffer.toString());
  }

  String generate();

  String color(String tokenName) {
    final String tokenColor = '$tokenName.color';
    final String tokenOpacity = '$tokenName.opacity';
    String value = '${tokens[tokenColor]!}';
    if (tokens.containsKey(tokenOpacity)) {
      final String opacity = tokens[tokens[tokenOpacity]!]!.toString();
      value += '.withOpacity($opacity)';
    }
    return value;
  }

  String elevation(String tokenName) {
    final String elevationName = '$tokenName.elevation';
    final Map<String, dynamic> elevationValue = tokens[tokens[elevationName]!]! as Map<String, dynamic>;
    return elevationValue['value']!.toString();
  }

  String shape(String tokenName) {
    // TODO(darrenaustin): handle more than just rounded rectangle shapes
    final String shapeToken = tokens[tokenName]! as String;
    final Map<String, dynamic> shape = tokens[shapeToken]! as Map<String, dynamic>;
    final Map<String, dynamic> shapeValue = shape['value']! as Map<String, dynamic>;
    return 'const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(${shapeValue['value']!})))';
  }

  String value(String tokenName) {
    final Map<String, dynamic> value = tokens[tokenName]! as Map<String, dynamic>;
    return value['value'].toString();
  }

  String textStyle(String tokenName) {
    final String fontName = '$tokenName.font';
    return tokens[fontName]!.toString();
  }
}
