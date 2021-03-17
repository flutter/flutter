// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:io' as io;
import 'package:flutter_tools/src/runner/flutter_command.dart';

class MakeCommand extends FlutterCommand {
  @override
  String get description =>
      'Make Flutter classes such as Stateless & Stateful.\n\n'
      'Passing the <class type> and the <file name or path>\n'
      'example: stless home.dart';

  @override
  String get name => 'make';

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (argResults.rest.isNotEmpty) {
      await make();
    } else {
      print(
        'please make you sure you have passed the class Type then the files path or name.\n\n'
        'class types:\n'
        'class to make simple dart class.\n'
        'stful to make StatefulWidget.\n'
        'stless to make stful to make StatelessWidget.\n',
      );
    }

    return const FlutterCommandResult(ExitStatus.success);
  }

  String upperCamelCase(String str) {
    str = str.replaceAllMapped(
      RegExp('[a-z]+/*'),
      (Match match) => match[0][0].toUpperCase() + match[0].substring(1),
    );
    return str[0].toUpperCase() + str.substring(1);
  }

  String getClassName(String className) {
    className = className.replaceAll('.dart', '');
    className = upperCamelCase(className);
    className = className.replaceAll('_', '');
    return className;
  }

  Map<String, String> _snippetCode(String fileName) {
    return <String, String>{
      'class': '''
class ${getClassName(fileName)} {}
      ''',
      'stless': '''
import 'package:flutter/material.dart';

class ${getClassName(fileName)} extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
      ''',
      'stful': '''
import 'package:flutter/material.dart';

class ${getClassName(fileName)} extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<${getClassName(fileName)}> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
      '''
    };
  }

  String redColor(String text) {
    return '\x1B[31m$text\x1B[0m';
  }

  String greenColor(String text) {
    return '\x1B[32m$text\x1B[0m';
  }

  Future<void> make() async {
    final String classType = argResults.rest[0].toLowerCase();

    for (int i = 1; i < argResults.rest.length; i++) {
      final String fileName = argResults.rest[i].toLowerCase();
      final io.File file = io.File(fileName);
      final bool alreadyExists = file.existsSync();

      if (alreadyExists) {
        print(redColor('<$fileName> already exists!'));
      } else if (fileName.endsWith('.dart')) {
        await file.create().then(
              (_) => file.writeAsString(_snippetCode(fileName)[classType]).then(
                    (_) => print(
                      greenColor('Making <$fileName> has been successfully!'),
                    ),
                  ),
            );
      } else {
        print(redColor('$fileName is not a dart file!'));
      }
    }
  }
}
