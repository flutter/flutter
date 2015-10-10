// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library sky_tools.init;

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mustache4dart/mustache4dart.dart' as mustache;
import 'package:path/path.dart' as p;

class InitCommand extends Command {
  final name = 'init';
  final description = 'Create a new Flutter project.';

  InitCommand() {
    argParser.addOption('out', abbr: 'o', help: 'The output directory.');
    argParser.addFlag('pub',
        defaultsTo: true,
        help: 'Whether to run pub after the project has been created.');
  }

  @override
  Future<int> run() async {
    if (!argResults.wasParsed('out')) {
      print('No option specified for the output directory.');
      print(argParser.getUsage());
      return 2;
    }

    // TODO: Confirm overwrite of an existing directory with the user.
    Directory out = new Directory(argResults['out']);

    new FlutterSimpleTemplate().generateInto(out);

    print('');

    String message = '''All done! To run your application:

  cd ${out.path}
  ./packages/sky/sky_tool start

Or if the Sky APK is not already on your device, run:

  ./packages/sky/sky_tool start --install

  ''';

    if (argResults['pub']) {
      print("Running pub get...");
      Process process =
          await Process.start('pub', ['get'], workingDirectory: out.path);
      stdout.addStream(process.stdout);
      stderr.addStream(process.stderr);
      int code = await process.exitCode;
      if (code != 0) return code;
    }

    print(message);
    return 0;
  }
}

abstract class Template {
  final String name;
  final String description;

  Map<String, String> files = {};

  Template(this.name, this.description);

  void generateInto(Directory dir) {
    String projectName = _normalizeProjectName(p.basename(dir.path));
    print('Creating ${p.basename(projectName)}...');
    dir.createSync(recursive: true);

    files.forEach((String path, String contents) {
      Map m = {'projectName': projectName, 'description': description};
      contents = mustache.render(contents, m);
      path = path.replaceAll('/', Platform.pathSeparator);
      File file = new File(p.join(dir.path, path));
      file.parent.createSync();
      file.writeAsStringSync(contents);
      print(file.path);
    });
  }

  String toString() => name;
}

class FlutterSimpleTemplate extends Template {
  FlutterSimpleTemplate() : super('flutter-simple', 'A minimal Flutter project.') {
    files['.gitignore'] = _gitignore;
    files['pubspec.yaml'] = _pubspec;
    files['README.md'] = _readme;
    files['lib/main.dart'] = _libMain;
  }
}

String _normalizeProjectName(String name) {
  name = name.replaceAll('-', '_').replaceAll(' ', '_');
  // Strip any extension (like .dart).
  if (name.contains('.')) {
    name = name.substring(0, name.indexOf('.'));
  }
  return name;
}

const _gitignore = r'''
.DS_Store
.idea
.packages
.pub/
build/
packages
pubspec.lock
''';

const _readme = r'''
# {{projectName}}

{{description}}

## Getting Started

For help getting started with Flutter, view our online
[documentation](http://flutter.io/).
''';

const _pubspec = r'''
name: {{projectName}}
description: {{description}}
dependencies:
  sky: any
dev_dependencies:
  sky_tools: any
''';

const _libMain = r'''
import 'package:sky/material.dart';

void main() {
  runApp(
    new MaterialApp(
      title: "Flutter Demo",
      routes: <String, RouteBuilder>{
        '/': (RouteArguments args) => new HelloWorldComponent()
      }
    )
  );
}

class HelloWorldComponent extends StatelessComponent {
  Widget build(BuildContext context)  {
    return new Scaffold(
      toolBar: new ToolBar(center: new Text("Flutter Demo")),
      body: new Material(child: new Center(child: new Text("Hello world!"))),
      floatingActionButton: new FloatingActionButton(
        child: new Icon(type: 'content/add', size: 24)
      )
    );
  }
}
''';
