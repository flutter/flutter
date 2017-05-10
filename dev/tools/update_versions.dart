// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Updates the version numbers of the Flutter repo.
// Only tested on Linux.

import 'dart:io';

import 'package:args/args.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

const String kIncrement = 'increment';
const String kBrokeSdk = 'broke-sdk';
const String kBrokeFramework = 'broke-framework';
const String kBrokeTest = 'broke-test';
const String kBrokeDriver = 'broke-driver';
const String kMarkRelease = 'release';
const String kHelp = 'help';

const String kYamlVersionPrefix = 'version: ';
const String kDev = '-dev';

void main(List<String> args) {
  // If we're run from the `tools` dir, set the cwd to the repo root.
  if (path.basename(Directory.current.path) == 'tools')
    Directory.current = Directory.current.parent.parent;

  final ArgParser argParser = new ArgParser();
  argParser.addFlag(kIncrement, defaultsTo: false, help: 'Increment all the version numbers. Cannot be specified with --$kMarkRelease or with any --broke-* commands.');
  argParser.addFlag(kBrokeSdk, defaultsTo: false, negatable: false, help: 'Increment the Flutter SDK version number to indicate that there has been a breaking change to the SDK (for example, to the command line options).');
  argParser.addFlag(kBrokeFramework, defaultsTo: false, negatable: false, help: 'Increment the "flutter" package version number to indicate that there has been a breaking change to the Flutter framework.');
  argParser.addFlag(kBrokeTest, defaultsTo: false, negatable: false, help: 'Increment the "flutter_test" package version number to indicate that there has been a breaking change to the test API framework.');
  argParser.addFlag(kBrokeDriver, defaultsTo: false, negatable: false, help: 'Increment the "flutter_driver" package version number to indicate that there has been a breaking change to the driver API framework.');
  argParser.addFlag(kMarkRelease, defaultsTo: false, help: 'Remove "-dev" from each version number. This is used when releasing. When not present, "-dev" is added to each version number. Cannot be specified with --$kIncrement or with any --broke-* commands.');
  argParser.addFlag(kHelp, negatable: false, help: 'Show this help message.');
  final ArgResults argResults = argParser.parse(args);

  final bool increment = argResults[kIncrement];
  final bool brokeSdk = argResults[kBrokeSdk];
  final bool brokeFramework = argResults[kBrokeFramework];
  final bool brokeTest = argResults[kBrokeTest];
  final bool brokeDriver = argResults[kBrokeDriver];
  final bool brokeAnything = brokeSdk || brokeFramework || brokeTest || brokeDriver;
  final bool release = argResults[kMarkRelease];
  final bool help = argResults[kHelp];

  if (help) {
    print('update_versions.dart - update version numbers of Flutter packages and SDK');
    print(argParser.usage);
    exit(0);
  }

  if ((brokeAnything && release) || (brokeAnything && increment) || (release && increment)) {
    print('You can either increment all the version numbers (--$kIncrement), indicate that some packages have had breaking changes (--broke-*), or switch to release mode (--$kMarkRelease).');
    print('You cannot combine these, however.');
    exit(1);
  }

  final RawVersion sdk = new RawVersion('VERSION');
  final PubSpecVersion framework = new PubSpecVersion('packages/flutter/pubspec.yaml');
  final PubSpecVersion test = new PubSpecVersion('packages/flutter_test/pubspec.yaml');
  final PubSpecVersion driver = new PubSpecVersion('packages/flutter_driver/pubspec.yaml');

  if (increment || brokeAnything)
    sdk.increment(brokeAnything);
  sdk.setMode(release);

  if (increment || brokeFramework)
    framework.increment(brokeFramework);
  framework.setMode(release);

  if (increment || brokeTest)
    test.increment(brokeTest);
  test.setMode(release);

  if (increment || brokeDriver)
    driver.increment(brokeDriver);
  driver.setMode(release);

  sdk.write();
  framework.write();
  test.write();
  driver.write();

  print('Flutter SDK is now at version: $sdk');
  print('flutter package is now at version: $framework');
  print('flutter_test package is now at version: $test');
  print('flutter_driver package is now at version: $driver');
}

abstract class Version {
  Version() {
    read();
  }

  @protected
  final List<int> version = <int>[];

  @protected
  bool dev;

  @protected
  bool dirty = false;

  @protected
  void read();

  void interpret(String value) {
    dev = value.endsWith(kDev);
    if (dev)
      value = value.substring(0, value.length - kDev.length);
    version.addAll(value.split('.').map<int>(int.parse));
  }

  void increment(bool breaking) {
    assert(version.length == 3);
    if (breaking) {
      version[1] += 1;
      version[2] = 0;
    } else {
      version[2] += 1;
    }
    dirty = true;
  }

  void setMode(bool release) {
    if (release != !dev) {
      dev = !release;
      dirty = true;
    }
  }

  void write();

  @override
  String toString() => version.join('.') + (dev ? kDev : '');
}

class PubSpecVersion extends Version {
  PubSpecVersion(this.path);

  final String path;

  @override
  void read() {
    final List<String> lines = new File(path).readAsLinesSync();
    final String versionLine = lines.where((String line) => line.startsWith(kYamlVersionPrefix)).single;
    interpret(versionLine.substring(kYamlVersionPrefix.length));
  }

  @override
  void write() {
    if (!dirty)
      return;
    final List<String> lines = new File(path).readAsLinesSync();
    for (int index = 0; index < lines.length; index += 1) {
      final String line = lines[index];
      if (line.startsWith(kYamlVersionPrefix)) {
        lines[index] = '$kYamlVersionPrefix$this';
        break;
      }
    }
    new File(path).writeAsStringSync(lines.join('\n') + '\n');
  }
}

class RawVersion extends Version {
  RawVersion(this.path);

  final String path;

  @override
  void read() {
    final List<String> lines = new File(path).readAsLinesSync();
    interpret(lines.where((String line) => line.isNotEmpty && !line.startsWith('#')).single);
  }

  @override
  void write() {
    if (!dirty)
      return;
    final List<String> lines = new File(path).readAsLinesSync();
    for (int index = 0; index < lines.length; index += 1) {
      final String line = lines[index];
      if (line.isNotEmpty && !line.startsWith('#')) {
        lines[index] = '$this';
        break;
      }
    }
    new File(path).writeAsStringSync(lines.join('\n') + '\n');
  }
}
