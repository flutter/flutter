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
    return tokens[tokens[tokenName]!]!.toString();
  }

  String shape(String tokenName) {
    // TODO(darrenaustin): handle more than just rounded rectangle shapes
    final Map<String, dynamic> shape = tokens[tokens[tokenName]!]! as Map<String, dynamic>;
    return 'const RoundedRectangleBorder(borderRadius: '
        'BorderRadius.only('
          'topLeft: Radius.circular(${shape['topLeft']}), '
          'topRight: Radius.circular(${shape['topRight']}), '
          'bottomLeft: Radius.circular(${shape['bottomLeft']}), '
          'bottomRight: Radius.circular(${shape['bottomRight']})))';
  }

  String value(String tokenName) {
    final Map<String, dynamic> value = tokens[tokenName]! as Map<String, dynamic>;
    return value['value'].toString();
  }

  String textStyle(String tokenName) {
    return tokens['$tokenName.text-style']!.toString();
  }
}
