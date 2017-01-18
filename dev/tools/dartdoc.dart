// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

const String kDocRoot = 'dev/docs/doc';

/// This script expects to run with the cwd as the root of the flutter repo. It
/// will generate documentation for the packages in `//packages/` and write the
/// documentation to `//dev/docs/doc/api/`.
///
/// This script also updates the index.html file so that it can be placed
/// at the root of docs.flutter.io. We are keeping the files inside of
/// docs.flutter.io/flutter for now, so we need to manipulate paths
/// a bit. See https://github.com/flutter/flutter/issues/3900 for more info.
Future<Null> main(List<String> args) async {
  // If we're run from the `tools` dir, set the cwd to the repo root.
  if (path.basename(Directory.current.path) == 'tools')
    Directory.current = Directory.current.parent.parent;

  // Create the pubspec.yaml file.
  StringBuffer buf = new StringBuffer('''
name: Flutter
dependencies:
''');
  for (String package in findPackageNames()) {
    buf.writeln('  $package:');
    buf.writeln('    sdk: flutter');
  }
  new File('dev/docs/pubspec.yaml').writeAsStringSync(buf.toString());

  // Create the library file.
  Directory libDir = new Directory('dev/docs/lib');
  libDir.createSync();

  StringBuffer contents = new StringBuffer('library temp_doc;\n\n');
  for (String libraryRef in libraryRefs()) {
    contents.writeln('import \'package:$libraryRef\';');
  }
  new File('dev/docs/lib/temp_doc.dart').writeAsStringSync(contents.toString());

  // Run pub.
  Process process = await Process.start('pub', <String>['get'],
    workingDirectory: 'dev/docs',
    environment: <String, String>{
      'FLUTTER_ROOT': Directory.current.path
    }
  );
  printStream(process.stdout);
  printStream(process.stderr);
  int code = await process.exitCode;
  if (code != 0)
    exit(code);

  // Generate the documentation.
  List<String> args = <String>[
    'global', 'run', 'dartdoc',
    '--header', 'styles.html',
    '--header', 'analytics.html',
    '--exclude', 'temp_doc',
    '--favicon=favicon.ico',
    '--use-categories'
  ];

  for (String libraryRef in libraryRefs(diskPath: true)) {
    args.add('--include-external');
    args.add(libraryRef);
  }

  process = await Process.start('pub', args, workingDirectory: 'dev/docs');
  printStream(process.stdout);
  printStream(process.stderr);
  int exitCode = await process.exitCode;

  if (exitCode != 0)
    exit(exitCode);

  sanityCheckDocs();

  createIndexAndCleanup();
}

void sanityCheckDocs() {
  List<String> canaries = <String>[
    '$kDocRoot/api/dart-io/File-class.html',
    '$kDocRoot/api/dart-ui/Canvas-class.html',
    '$kDocRoot/api/dart-ui/Canvas/drawRect.html',
    '$kDocRoot/api/flutter_test/WidgetTester/pumpWidget.html',
    '$kDocRoot/api/material/Material-class.html',
    '$kDocRoot/api/material/Tooltip-class.html',
    '$kDocRoot/api/widgets/Widget-class.html',
  ];
  for (String canary in canaries) {
    if (!new File(canary).existsSync())
      throw new Exception('Missing "$canary", which probably means the documentation failed to build correctly.');
  }
}

/// Creates a custom index.html because we try to maintain old
/// paths. Cleanup unused index.html files no longer needed.
void createIndexAndCleanup() {
  print('\nCreating a custom index.html in $kDocRoot/index.html');
  removeOldFlutterDocsDir();
  renameApiDir();
  copyIndexToRootOfDocs();
  addHtmlBaseToIndex();
  putRedirectInOldIndexLocation();
  print('\nDocs ready to go!');
}

void removeOldFlutterDocsDir() {
  try {
    new Directory('$kDocRoot/flutter').deleteSync(recursive: true);
  } catch (e) {
    // If the directory does not exist, that's OK.
  }
}

void renameApiDir() {
  new Directory('$kDocRoot/api').renameSync('$kDocRoot/flutter');
}

void copyIndexToRootOfDocs() {
  new File('$kDocRoot/flutter/index.html').copySync('$kDocRoot/index.html');
}

void addHtmlBaseToIndex() {
  File indexFile = new File('$kDocRoot/index.html');
  String indexContents = indexFile.readAsStringSync();
  indexContents = indexContents.replaceFirst('</title>\n',
    '</title>\n  <base href="./flutter/">\n');
  indexFile.writeAsStringSync(indexContents);
}

void putRedirectInOldIndexLocation() {
  String metaTag = '<meta http-equiv="refresh" content="0;URL=../index.html">';
  new File('$kDocRoot/flutter/index.html').writeAsStringSync(metaTag);
}

List<String> findPackageNames() {
  return findPackages().map((Directory dir) => path.basename(dir.path)).toList();
}

/// Finds all packages in the Flutter SDK
List<Directory> findPackages() {
  return new Directory('packages')
    .listSync()
    .where((FileSystemEntity entity) {
      if (entity is! Directory)
        return false;
      File pubspec = new File('${entity.path}/pubspec.yaml');
      // TODO(ianh): Use a real YAML parser here
      return !pubspec.readAsStringSync().contains('nodoc: true');
    })
    .toList();
}

/// Returns import or on-disk paths for all libraries in the Flutter SDK.
///
/// diskPath toggles between import paths vs. disk paths.
Iterable<String> libraryRefs({ bool diskPath: false }) sync* {
  for (Directory dir in findPackages()) {
    String dirName = path.basename(dir.path);
    for (FileSystemEntity file in new Directory('${dir.path}/lib').listSync()) {
      if (file is File && file.path.endsWith('.dart')) {
        if (diskPath)
          yield '$dirName/lib/${path.basename(file.path)}';
        else
          yield '$dirName/${path.basename(file.path)}';
       }
    }
  }
}

void printStream(Stream<List<int>> stream) {
  stream
    .transform(UTF8.decoder)
    .transform(const LineSplitter())
    .listen(print);
}
