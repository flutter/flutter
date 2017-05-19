// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
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
///
/// This will only work on UNIX systems, not Windows. It requires that 'git' be
/// in your path. It requires that 'flutter' has been run previously. It uses
/// the version of Dart downloaded by the 'flutter' tool in this repository and
/// will crash if that is absent.
Future<Null> main(List<String> args) async {
  // If we're run from the `tools` dir, set the cwd to the repo root.
  if (path.basename(Directory.current.path) == 'tools')
    Directory.current = Directory.current.parent.parent;

  // Create the pubspec.yaml file.
  final StringBuffer buf = new StringBuffer('''
name: Flutter
dependencies:
''');
  for (String package in findPackageNames()) {
    buf.writeln('  $package:');
    buf.writeln('    sdk: flutter');
  }
  buf.writeln('  platform_integration: 0.0.1');
  buf.writeln('dependency_overrides:');
  buf.writeln('  platform_integration:');
  buf.writeln('    path: platform_integration');
  new File('dev/docs/pubspec.yaml').writeAsStringSync(buf.toString());

  // Create the library file.
  final Directory libDir = new Directory('dev/docs/lib');
  libDir.createSync();

  final StringBuffer contents = new StringBuffer('library temp_doc;\n\n');
  for (String libraryRef in libraryRefs()) {
    contents.writeln('import \'package:$libraryRef\';');
  }
  new File('dev/docs/lib/temp_doc.dart').writeAsStringSync(contents.toString());

  // Run pub.
  Process process = await Process.start(
    '../../bin/cache/dart-sdk/bin/pub',
    <String>['get'],
    workingDirectory: 'dev/docs',
    environment: <String, String>{
      'FLUTTER_ROOT': Directory.current.path,
    },
  );
  printStream(process.stdout);
  printStream(process.stderr);
  final int code = await process.exitCode;
  if (code != 0)
    exit(code);

  createFooter('dev/docs/lib/footer.html');

  // Verify which version of dartdoc we're using.
  final ProcessResult result = Process.runSync(
    '../../bin/cache/dart-sdk/bin/pub',
    <String>['global', 'run', 'dartdoc', '--version'],
    workingDirectory: 'dev/docs',
  );
  print('\n${result.stdout}');

  // Generate the documentation.
  final List<String> args = <String>[
    'global', 'run', 'dartdoc',
    '--header', 'styles.html',
    '--header', 'analytics.html',
    '--footer', 'lib/footer.html',
    '--exclude', 'temp_doc',
    '--favicon=favicon.ico',
    '--use-categories',
    '--category-order', 'flutter,Dart Core,flutter_test,flutter_driver',
  ];

  for (String libraryRef in libraryRefs(diskPath: true)) {
    args.add('--include-external');
    args.add(libraryRef);
  }

  process = await Process.start(
    '../../bin/cache/dart-sdk/bin/pub',
    args,
    workingDirectory: 'dev/docs',
  );
  printStream(process.stdout);
  printStream(process.stderr);
  final int exitCode = await process.exitCode;

  if (exitCode != 0)
    exit(exitCode);

  sanityCheckDocs();

  createIndexAndCleanup();
}

void createFooter(String footerPath) {
  final ProcessResult gitResult = Process.runSync('git', <String>['rev-parse', 'HEAD']);
  final String gitHead = (gitResult.exitCode == 0) ? gitResult.stdout.trim() : 'unknown';

  final String timestamp = new DateFormat('yyyy-MM-dd HH:mm').format(new DateTime.now());

  new File(footerPath).writeAsStringSync(
    '<p class="text-center" style="font-size: 10px">'
    'Generated on $timestamp - Version $gitHead</p>'
  );
}

void sanityCheckDocs() {
  // TODO(jcollins-g): remove old_sdk_canaries for dartdoc >= 0.10.0
  final List<String> oldSdkCanaries = <String>[
    '$kDocRoot/api/dart.io/File-class.html',
    '$kDocRoot/api/dart.ui/Canvas-class.html',
    '$kDocRoot/api/dart.ui/Canvas/drawRect.html',
  ];
  final List<String> newSdkCanaries = <String>[
    '$kDocRoot/api/dart-io/File-class.html',
    '$kDocRoot/api/dart-ui/Canvas-class.html',
    '$kDocRoot/api/dart-ui/Canvas/drawRect.html',
  ];
  final List<String> canaries = <String>[
    '$kDocRoot/api/flutter_test/WidgetTester/pumpWidget.html',
    '$kDocRoot/api/material/Material-class.html',
    '$kDocRoot/api/material/Tooltip-class.html',
    '$kDocRoot/api/widgets/Widget-class.html',
  ];
  bool oldMissing = false;
  for (String canary in oldSdkCanaries) {
    if (!new File(canary).existsSync()) {
      oldMissing = true;
      break;
    }
  }
  if (oldMissing)
    canaries.addAll(newSdkCanaries);
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
  final File indexFile = new File('$kDocRoot/index.html');
  String indexContents = indexFile.readAsStringSync();
  indexContents = indexContents.replaceFirst('</title>\n',
    '</title>\n  <base href="./flutter/">\n');
  indexContents = indexContents.replaceAll(
    'href="Android/Android-library.html"',
    'href="https://docs.flutter.io/javadoc/"'
  );
  indexFile.writeAsStringSync(indexContents);
}

void putRedirectInOldIndexLocation() {
  final String metaTag = '<meta http-equiv="refresh" content="0;URL=../index.html">';
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
      final File pubspec = new File('${entity.path}/pubspec.yaml');
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
    final String dirName = path.basename(dir.path);
    for (FileSystemEntity file in new Directory('${dir.path}/lib').listSync()) {
      if (file is File && file.path.endsWith('.dart')) {
        if (diskPath)
          yield '$dirName/lib/${path.basename(file.path)}';
        else
          yield '$dirName/${path.basename(file.path)}';
       }
    }
  }

  // Add a fake package for platform integration APIs.
  if (diskPath)
    yield 'platform_integration/lib/android.dart';
  else
    yield 'platform_integration/android.dart';
}

void printStream(Stream<List<int>> stream) {
  stream
    .transform(UTF8.decoder)
    .transform(const LineSplitter())
    .listen(print);
}
