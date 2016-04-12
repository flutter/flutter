#!/usr/bin/env dart

// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// This script expects to run with the cwd as the root of the flutter repo. It
/// will generate documentation for the packages in `packages/`, and leave the
/// documentation in `dev/docs/doc/api/`.
main(List<String> args) async {
  // Create the pubspec.yaml file.
  StringBuffer buf = new StringBuffer('''
name: Flutter
dependencies:
''');
  for (String package in _findPackageNames()) {
    buf.writeln('  $package:');
    buf.writeln('    path: ../../packages/$package');
  }
  new File('dev/docs/pubspec.yaml').writeAsStringSync(buf.toString());

  // Create the library file.
  Directory libDir = new Directory('dev/docs/lib');
  libDir.createSync();

  StringBuffer contents = new StringBuffer('library temp_doc;\n\n');
  for (String libraryRef in _libraryRefs()) {
    contents.writeln('import \'package:$libraryRef\';');
  }
  new File('dev/docs/lib/temp_doc.dart').writeAsStringSync(contents.toString());

  // Run pub.
  Process process = await Process.start('pub', <String>['get'], workingDirectory: 'dev/docs');
  _print(process.stdout);
  _print(process.stderr);
  int code = await process.exitCode;
  if (code != 0)
    exit(code);

  // Generate the documentation; we require dartdoc >= 0.9.4.
  List<String> args = <String>[
    'global', 'run', 'dartdoc',
    '--header', 'styles.html',
    '--header', 'analytics.html',
    '--dart-sdk', '../../bin/cache/dart-sdk',
    '--exclude', 'temp_doc',
    '--favicon=favicon.ico',
    '--use-categories'
  ];
  for (String libraryRef in _libraryRefs()) {
    String name = _entityName(libraryRef);

    args.add('--include-external');
    args.add(name.substring(0, name.length - 5));
  }

  _findSkyServicesLibraryNames().forEach((String libName) {
    args.add('--include-external');
    args.add(libName);
  });

  process = await Process.start('pub', args, workingDirectory: 'dev/docs');
  _print(process.stdout);
  _print(process.stderr);
  exit(await process.exitCode);
}

List<String> _findSkyServicesLibraryNames() {
  Directory skyServicesLocation = new Directory('bin/cache/pkg/sky_services/lib');
  if (!skyServicesLocation.existsSync()) {
    throw 'Did not find sky_services package location in '
          '${skyServicesLocation.path}.';
  }
  return skyServicesLocation.listSync(followLinks: false, recursive: true)
      .where((FileSystemEntity entity) {
    return entity is File && entity.path.endsWith('.mojom.dart');
  }).map((FileSystemEntity entity) {
    String basename = _entityName(entity.path);
    basename = basename.substring(0, basename.length-('.dart'.length));
    return basename.replaceAll('.', '_');
  });
}

List<String> _findPackageNames() {
  return _findPackages().map((Directory dir) => _entityName(dir.path)).toList();
}

List<Directory> _findPackages() {
  return new Directory('packages')
    .listSync()
    .where((FileSystemEntity entity) => entity is Directory)
    .where((Directory dir) {
      File pubspec = new File('${dir.path}/pubspec.yaml');
      bool nodoc = pubspec.readAsStringSync().contains('nodoc: true');
      return !nodoc;
    })
    .toList();
}

List<String> _libraryRefs() sync* {
  for (Directory dir in _findPackages()) {
    String dirName = _entityName(dir.path);

    for (FileSystemEntity file in new Directory('${dir.path}/lib').listSync()) {
      if (file is File && file.path.endsWith('.dart'))
        yield '$dirName/${_entityName(file.path)}';
    }
  }
}

String _entityName(String path) {
  return path.indexOf('/') == -1 ? path : path.substring(path.lastIndexOf('/') + 1);
}

void _print(Stream<List<int>> stream) {
  stream
    .transform(UTF8.decoder)
    .transform(const LineSplitter())
    .listen(print);
}
