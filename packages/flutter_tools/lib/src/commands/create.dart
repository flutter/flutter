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
    argParser.addFlag(
      'with-driver-test',
      negatable: true,
      defaultsTo: false,
      help: 'Also add Flutter Driver dependencies and generate a sample driver test.'
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

    String flutterPackagesDirectory = path.join(flutterRoot, 'packages');
    String flutterPackagePath = path.join(flutterPackagesDirectory, 'flutter');
    if (!FileSystemEntity.isFileSync(path.join(flutterPackagePath, 'pubspec.yaml'))) {
      printError('Unable to find package:flutter in $flutterPackagePath');
      return 2;
    }

    String flutterDriverPackagePath = path.join(flutterRoot, 'packages', 'flutter_driver');
    if (!FileSystemEntity.isFileSync(path.join(flutterDriverPackagePath, 'pubspec.yaml'))) {
      printError('Unable to find package:flutter_driver in $flutterDriverPackagePath');
      return 2;
    }

    Directory out;

    if (argResults.wasParsed('out')) {
      out = new Directory(argResults['out']);
    } else {
      out = new Directory(argResults.rest.first);
    }

    FlutterSimpleTemplate template = new FlutterSimpleTemplate();

    if (argResults['with-driver-test'])
      template.withDriverTest();

    template.generateInto(
      dir: out,
      flutterPackagesDirectory: flutterPackagesDirectory
    );

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
  final Map<String, String> files = <String, String>{};
  final Map<String, dynamic> additionalTemplateVariables = <String, dynamic>{};

  Template(this.name, this.description);

  void generateInto({
    Directory dir,
    String flutterPackagesDirectory
  }) {
    String dirPath = path.normalize(dir.absolute.path);
    String projectName = _normalizeProjectName(path.basename(dirPath));
    String projectIdentifier = _createProjectIdentifier(path.basename(dirPath));
    printStatus('Creating ${path.basename(projectName)}...');
    dir.createSync(recursive: true);

    String relativeFlutterPackagesDirectory =
        path.relative(flutterPackagesDirectory, from: dirPath);
    Iterable<String> paths = files.keys.toList()..sort();

    for (String filePath in paths) {
      String contents = files[filePath];
      Map m = <String, String>{
        'projectName': projectName,
        'projectIdentifier': projectIdentifier,
        'description': description,
        'flutterPackagesDirectory': relativeFlutterPackagesDirectory,
      };
      m.addAll(additionalTemplateVariables);
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
  FlutterSimpleTemplate() : super('flutter-simple', 'A simple Flutter app.') {
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

  void withDriverTest() {
    additionalTemplateVariables['withDriverTest?'] = {};
    files['test_driver/e2e.dart'] = _e2eApp;
    files['test_driver/e2e_test.dart'] = _e2eTest;
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
    path: {{flutterPackagesDirectory}}/flutter
{{#withDriverTest?}}
dev_dependencies:
  flutter_driver:
    path: {{flutterPackagesDirectory}}/flutter_driver
{{/withDriverTest?}}
''';

const String _flutterYaml = r'''
name: {{projectName}}
material-design-icons:
  - name: content/add
  - name: navigation/arrow_back
  - name: navigation/menu
  - name: navigation/more_vert
''';

const String _libMain = r'''
import 'package:flutter/material.dart';

void main() {
  runApp(
    new MaterialApp(
      title: 'Flutter Demo',
      routes: <String, RouteBuilder>{
        '/': (RouteArguments args) => new FlutterDemo()
      }
    )
  );
}

class FlutterDemo extends StatefulComponent {
  State createState() => new _FlutterDemoState();
}

class _FlutterDemoState extends State<FlutterDemo> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  Widget build(BuildContext context) {
    return new Scaffold(
      toolBar: new ToolBar(
        center: new Text('Flutter Demo')
      ),
      body: new Material(
        child: new Center(
          child: new Text(
            'Button tapped $_counter times.',
            key: const ValueKey('counter')
          )
        )
      ),
      floatingActionButton: new FloatingActionButton(
        key: const ValueKey('fab'),
        child: new Icon(
          icon: 'content/add'
        ),
        onPressed: _incrementCounter
      )
    );
  }
}
''';

const String _e2eApp = '''
// Starts the app with Flutter Driver extension enabled to allow Flutter Driver
// to test the app.
import 'package:{{projectName}}/main.dart' as app;
import 'package:flutter_driver/driver_extension.dart';

main() {
  enableFlutterDriverExtension();
  app.main();
}
''';

const String _e2eTest = '''
// This is a basic Flutter Driver test for the application. A Flutter Driver
// test is an end-to-end test that "drives" your application from another
// process or even from another computer. If you are familiar with
// Selenium/WebDriver for web, Espresso for Android or UI Automation for iOS,
// this is simply Flutter's version of that.
//
// To start the test run the following command from the root of your application
// package:
//
//     flutter drive --target=test_driver/e2e.dart
//
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

main() {
  group('end-to-end test', () {
    FlutterDriver driver;

    setUpAll(() async {
      // Connect to a running Flutter application instance.
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      if (driver != null) driver.close();
    });

    test('find the floating action button by value key', () async {
      ObjectRef elem = await driver.findByValueKey('fab');
      expect(elem, isNotNull);
      expect(elem.objectReferenceKey, isNotNull);
    });

    test('tap on the floating action button; verify counter', () async {
      ObjectRef fab = await driver.findByValueKey('fab');
      expect(fab, isNotNull);
      await driver.tap(fab);
      ObjectRef counter = await driver.findByValueKey('counter');
      expect(counter, isNotNull);
      String text = await driver.getText(counter);
      expect(text, contains("Button tapped 1 times."));
    });
  });
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
