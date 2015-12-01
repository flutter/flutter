// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mustache4dart/mustache4dart.dart' as mustache;
import 'package:path/path.dart' as path;

import '../artifacts.dart';
import '../base/logging.dart';
import '../base/process.dart';

class InitCommand extends Command {
  final String name = 'init';
  final String description = 'Create a new Flutter project.';

  InitCommand() {
    argParser.addOption('out', abbr: 'o', help: 'The output directory.');
    argParser.addFlag('pub',
        defaultsTo: true,
        help: 'Whether to run "pub get" after the project has been created.');
  }

  @override
  Future<int> run() async {
    if (!argResults.wasParsed('out')) {
      print('No option specified for the output directory.');
      print(argParser.usage);
      return 2;
    }

    if (ArtifactStore.flutterRoot == null) {
      stderr.writeln('Neither the --flutter-root command line flag nor the FLUTTER_ROOT environment');
      stderr.writeln('variable was specified. Unable to find package:flutter.');
      return 2;
    }
    String flutterRoot = path.absolute(ArtifactStore.flutterRoot);

    String flutterPackagePath = path.join(flutterRoot, 'packages', 'flutter');
    if (!FileSystemEntity.isFileSync(path.join(flutterPackagePath, 'pubspec.yaml'))) {
      print('Unable to find package:flutter in $flutterPackagePath');
      return 2;
    }

    // TODO: Confirm overwrite of an existing directory with the user.
    Directory out = new Directory(argResults['out']);

    new FlutterSimpleTemplate().generateInto(out, flutterPackagePath);

    print('');

    String message = '''All done! To run your application:

  \$ cd ${out.path}
  \$ flutter start
''';

    if (argResults['pub']) {
      int code = await pubGet(directory: out.path);
      if (code != 0)
        return code;
    }

    print(message);
    return 0;
  }

  Future<int> pubGet({
    String directory: '',
    bool skipIfAbsent: false,
    bool verbose: true
  }) async {
    File pubSpecYaml = new File(path.join(directory, 'pubspec.yaml'));
    File pubSpecLock = new File(path.join(directory, 'pubspec.lock'));
    File dotPackages = new File(path.join(directory, '.packages'));

    if (!pubSpecYaml.existsSync()) {
      if (skipIfAbsent)
        return 0;
      logging.severe('$directory: no pubspec.yaml found');
      return 1;
    }

    if (!pubSpecLock.existsSync() || pubSpecYaml.lastModifiedSync().isAfter(pubSpecLock.lastModifiedSync())) {
      if (verbose)
        print("Running pub get in $directory...");
      int code = await runCommandAndStreamOutput(
        [sdkBinaryName('pub'), 'get'],
        workingDirectory: directory
      );
      if (code != 0)
        return code;
    }

    if ((pubSpecLock.existsSync() && pubSpecLock.lastModifiedSync().isAfter(pubSpecYaml.lastModifiedSync())) &&
        (dotPackages.existsSync() && dotPackages.lastModifiedSync().isAfter(pubSpecYaml.lastModifiedSync())))
      return 0;

    logging.severe('$directory: pubspec.yaml, pubspec.lock, and .packages are in an inconsistent state');
    return 1;
  }
}

abstract class Template {
  final String name;
  final String description;

  Map<String, String> files = {};

  Template(this.name, this.description);

  void generateInto(Directory dir, String flutterPackagePath) {
    String dirPath = path.normalize(dir.absolute.path);
    String projectName = _normalizeProjectName(path.basename(dirPath));
    print('Creating ${path.basename(projectName)}...');
    dir.createSync(recursive: true);

    String relativeFlutterPackagePath = path.relative(flutterPackagePath, from: dirPath);

    files.forEach((String filePath, String contents) {
      Map m = {'projectName': projectName, 'description': description, 'flutterPackagePath': relativeFlutterPackagePath};
      contents = mustache.render(contents, m);
      filePath = filePath.replaceAll('/', Platform.pathSeparator);
      File file = new File(path.join(dir.path, filePath));
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
    files['flutter.yaml'] = _flutterYaml;
    files['pubspec.yaml'] = _pubspec;
    files['README.md'] = _readme;
    files['lib/main.dart'] = _libMain;
    files['apk/AndroidManifest.xml'] = _apkManifest;
  }
}

String _normalizeProjectName(String name) {
  name = name.replaceAll('-', '_').replaceAll(' ', '_');
  // Strip any extension (like .dart).
  if (name.contains('.'))
    name = name.substring(0, name.indexOf('.'));
  return name;
}

const String _gitignore = r'''
.DS_Store
.idea
.packages
.pub/
build/
packages
pubspec.lock
''';

const String _readme = r'''
# {{projectName}}

{{description}}

## Getting Started

For help getting started with Flutter, view our online
[documentation](http://flutter.io/).
''';

const String _pubspec = r'''
name: {{projectName}}
description: {{description}}
dependencies:
  flutter:
    path: {{flutterPackagePath}}
''';

const String _flutterYaml = r'''
name: {{projectName}}
material-design-icons:
  - name: content/add
''';

const String _libMain = r'''
import 'package:flutter/material.dart';

void main() {
  runApp(
    new MaterialApp(
      title: "Flutter Demo",
      routes: {
        '/': (RouteArguments args) => new FlutterDemo()
      }
    )
  );
}

class FlutterDemo extends StatelessComponent {
  Widget build(BuildContext context) {
    return new Scaffold(
      toolBar: new ToolBar(
        center: new Text("Flutter Demo")
      ),
      body: new Material(
        child: new Center(
          child: new Text("Hello world!")
        )
      ),
      floatingActionButton: new FloatingActionButton(
        child: new Icon(
          icon: 'content/add'
        )
      )
    );
  }
}
''';

const String _apkManifest = r'''
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.{{projectName}}">

    <uses-sdk android:minSdkVersion="14" android:targetSdkVersion="21" />
    <uses-permission android:name="android.permission.INTERNET"/>

    <application android:name="org.domokit.sky.shell.SkyApplication" android:label="{{projectName}}">
        <activity android:name="org.domokit.sky.shell.SkyActivity"
                  android:launchMode="singleTask"
                  android:theme="@android:style/Theme.Black.NoTitleBar"
                  android:configChanges="orientation|keyboardHidden|keyboard|screenSize"
                  android:hardwareAccelerated="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
''';
