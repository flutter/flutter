// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mustache4dart/mustache4dart.dart' as mustache;
import 'package:path/path.dart' as path;

import '../android/android.dart' as android;
import '../artifacts.dart';
import '../dart/pub.dart';
import '../globals.dart';
import '../ios/setup_xcodeproj.dart';

class CreateCommand extends Command {
  final String name = 'create';
  final String description = 'Create a new Flutter project.';
  final List<String> aliases = <String>['init'];

  CreateCommand() {
    argParser.addOption('out',
      abbr: 'o',
      hide: true,
      help: 'The output directory.'
    );
    argParser.addFlag('pub',
      defaultsTo: true,
      help: 'Whether to run "pub get" after the project has been created.'
    );
  }

  String get invocation => "${runner.executableName} $name <output directory>";

  @override
  Future<int> run() async {
    if (!argResults.wasParsed('out') && argResults.rest.isEmpty) {
      printStatus('No option specified for the output directory.');
      printStatus(usage);
      return 2;
    }

    if (ArtifactStore.flutterRoot == null) {
      printError('Neither the --flutter-root command line flag nor the FLUTTER_ROOT environment');
      printError('variable was specified. Unable to find package:flutter.');
      return 2;
    }

    String flutterRoot = path.absolute(ArtifactStore.flutterRoot);

    String flutterPackagePath = path.join(flutterRoot, 'packages', 'flutter');
    if (!FileSystemEntity.isFileSync(path.join(flutterPackagePath, 'pubspec.yaml'))) {
      printError('Unable to find package:flutter in $flutterPackagePath');
      return 2;
    }

    Directory out;

    if (argResults.wasParsed('out')) {
      out = new Directory(argResults['out']);
    } else {
      out = new Directory(argResults.rest.first);
    }

    new FlutterSimpleTemplate().generateInto(out, flutterPackagePath);

    printStatus('');

    String message = '''
All done! To run your application:

  \$ cd ${out.path}
  \$ flutter run
''';

    if (argResults['pub']) {
      int code = await pubGet(directory: out.path);
      if (code != 0)
        return code;
    }

    printStatus('');
    printStatus(message);
    return 0;
  }
}

abstract class Template {
  final String name;
  final String description;

  Map<String, String> files = <String, String>{};

  Template(this.name, this.description);

  void generateInto(Directory dir, String flutterPackagePath) {
    String dirPath = path.normalize(dir.absolute.path);
    String projectName = _normalizeProjectName(path.basename(dirPath));
    String projectIdentifier = _createProjectIdentifier(path.basename(dirPath));
    printStatus('Creating ${path.basename(projectName)}...');
    dir.createSync(recursive: true);

    String relativeFlutterPackagePath = path.relative(flutterPackagePath, from: dirPath);
    Iterable<String> paths = files.keys.toList()..sort();

    for (String filePath in paths) {
      String contents = files[filePath];
      Map m = <String, String>{
        'projectName': projectName,
        'projectIdentifier': projectIdentifier,
        'description': description,
        'flutterPackagePath': relativeFlutterPackagePath
      };
      contents = mustache.render(contents, m);
      filePath = filePath.replaceAll('/', Platform.pathSeparator);
      File file = new File(path.join(dir.path, filePath));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(contents);
      printStatus('  ${file.path}');
    }
  }

  String toString() => name;
}

class FlutterSimpleTemplate extends Template {
  FlutterSimpleTemplate() : super('flutter-simple', 'A minimal Flutter project.') {
    files['.analysis_options'] = _analysis_options;
    files['.gitignore'] = _gitignore;
    files['flutter.yaml'] = _flutterYaml;
    files['pubspec.yaml'] = _pubspec;
    files['README.md'] = _readme;
    files['lib/main.dart'] = _libMain;

    // Android files.
    files['android/AndroidManifest.xml'] = _apkManifest;
    // Create a file here in order to create the res/ directory and ensure it gets committed to git.
    files['android/res/.empty'] = _androidEmptyFile;

    // iOS files.
    files.addAll(iosTemplateFiles);
  }
}

String _normalizeProjectName(String name) {
  name = name.replaceAll('-', '_').replaceAll(' ', '_');
  // Strip any extension (like .dart).
  if (name.contains('.'))
    name = name.substring(0, name.indexOf('.'));
  return name;
}

String _createProjectIdentifier(String name) {
  // Create a UTI (https://en.wikipedia.org/wiki/Uniform_Type_Identifier) from a base name
  RegExp disallowed = new RegExp(r"[^a-zA-Z0-9\-.\u0080-\uffff]+");
  name = name.replaceAll(disallowed, '');
  name = name.length == 0 ? 'untitled' : name;
  return 'com.yourcompany.$name';
}

const String _analysis_options = r'''
analyzer:
  exclude:
    - 'ios/.generated/**'
''';

const String _gitignore = r'''
.DS_Store
.atom/
.idea
.packages
.pub/
build/
ios/.generated/
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
      routes: <String, RouteBuilder>{
        '/': (RouteArguments args) => new FlutterDemo()
      }
    )
  );
}

class FlutterDemo extends StatefulComponent {
  @override
  State createState() => new FlutterDemoState();
}

class FlutterDemoState extends State {
  int counter = 0;

  void incrementCounter() {
    setState(() {
      counter++;
    });
  }

  Widget build(BuildContext context) {
    return new Scaffold(
      toolBar: new ToolBar(
        center: new Text("Flutter Demo")
      ),
      body: new Material(
        child: new Center(
          child: new Text("Button tapped $counter times.")
        )
      ),
      floatingActionButton: new FloatingActionButton(
        child: new Icon(
          icon: 'content/add'
        ),
        onPressed: incrementCounter
      )
    );
  }
}
''';

final String _apkManifest = '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="{{projectIdentifier}}"
    android:versionCode="1"
    android:versionName="0.0.1">

    <uses-sdk android:minSdkVersion="${android.minApiLevel}" android:targetSdkVersion="21" />
    <uses-permission android:name="android.permission.INTERNET"/>

    <application android:name="org.domokit.sky.shell.SkyApplication" android:label="{{projectName}}">
        <activity android:name="org.domokit.sky.shell.SkyActivity"
                  android:launchMode="singleTask"
                  android:theme="@android:style/Theme.Black.NoTitleBar"
                  android:configChanges="orientation|keyboardHidden|keyboard|screenSize|locale|layoutDirection"
                  android:hardwareAccelerated="true"
                  android:windowSoftInputMode="adjustResize">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
''';

final String _androidEmptyFile = '''
Place Android resources here (http://developer.android.com/guide/topics/resources/overview.html).
''';
