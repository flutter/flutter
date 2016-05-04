// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Make `n` copies of material_gallery.

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

/// If no `copies` param is passed in, we scale the generated app up to 60k lines.
const int kTargetLineCount = 60 * 1024;

void main(List<String> args) {
  // If we're run from the `tools` dir, set the cwd to the repo root.
  if (path.basename(Directory.current.path) == 'tools')
    Directory.current = Directory.current.parent.parent;

  ArgParser argParser = new ArgParser();
  // ../mega_gallery? dev/benchmarks/mega_gallery?
  argParser.addOption('out', defaultsTo: _normalize('dev/benchmarks/mega_gallery'));
  argParser.addOption('copies');
  argParser.addFlag('delete', negatable: false);
  argParser.addFlag('help', abbr: 'h', negatable: false);

  ArgResults results = argParser.parse(args);

  if (results['help']) {
    print('Generate n copies of material_gallery.\n');
    print('usage: dart mega_gallery.dart <options>');
    print(argParser.usage);
    exit(0);
  }

  Directory source = new Directory(_normalize('examples/material_gallery'));
  Directory out = new Directory(_normalize(results['out']));

  if (results['delete']) {
    if (out.existsSync()) {
      print('Deleting ${out.path}');
      out.deleteSync(recursive: true);
    }

    exit(0);
  }

  int copies;
  if (!results.wasParsed('copies')) {
    SourceStats stats = getStatsFor(_dir(source, 'lib'));
    copies = (kTargetLineCount / stats.lines).round();
  } else {
    copies = int.parse(results['copies']);
  }

  print('Stats:');
  print('  packages/flutter           : ${getStatsFor(new Directory("packages/flutter"))}');
  print('  examples/material_gallery  : ${getStatsFor(new Directory("examples/material_gallery"))}');
  print('');

  print('Making $copies copies of material_gallery:');

  Directory lib = _dir(out, 'lib');
  if (lib.existsSync())
    lib.deleteSync(recursive: true);

  // Copy everything that's not a symlink, dot directory, or build/.
  _copy(source, out);

  // Make n - 1 copies.
  for (int i = 1; i < copies; i++)
    _copyGallery(out, i);

  // Create a new entry-point.
  _createEntry(_file(out, 'lib/main.dart'), copies);

  // Update the pubspec.
  String pubspec = _file(out, 'pubspec.yaml').readAsStringSync();
  pubspec = pubspec.replaceAll('../../packages/flutter', '../../../packages/flutter');
  _file(out, 'pubspec.yaml').writeAsStringSync(pubspec);

  _file(out, '.dartignore').writeAsStringSync('');

  // Count source lines and number of files; tell how to run it.
  print('  ${path.relative(results["out"])}: ${getStatsFor(out)}');
}

// TODO(devoncarew): Create an entry-point that builds a UI with all `n` copies.
void _createEntry(File mainFile, int copies) {
  StringBuffer imports = new StringBuffer();
  StringBuffer importRefs = new StringBuffer();

  for (int i = 1; i < copies; i++) {
    imports.writeln("import 'gallery_$i/main.dart' as main_$i;");
    importRefs.writeln("  main_$i.main;");
  }

  String contents = '''
// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'gallery/app.dart';
${imports.toString().trim()}

void main() {
  // Make sure the imports are not marked as unused.
  ${importRefs.toString().trim()}

  runApp(new GalleryApp());
}
''';

  mainFile.writeAsStringSync(contents);
}

void _copyGallery(Directory galleryDir, int index) {
  Directory lib = _dir(galleryDir, 'lib');
  Directory dest = _dir(lib, 'gallery_$index');
  dest.createSync();

  // Copy demo/, gallery/, and main.dart.
  _copy(_dir(lib, 'demo'), _dir(dest, 'demo'));
  _copy(_dir(lib, 'gallery'), _dir(dest, 'gallery'));
  _file(dest, 'main.dart').writeAsBytesSync(_file(lib, 'main.dart').readAsBytesSync());
}

void _copy(Directory source, Directory target) {
  if (!target.existsSync())
    target.createSync();

  for (FileSystemEntity entity in source.listSync(followLinks: false)) {
    String name = path.basename(entity.path);

    if (entity is Directory) {
      if (name == 'build' || name.startsWith('.'))
        continue;
      _copy(entity, new Directory(path.join(target.path, name)));
    } else if (entity is File) {
      if (name == '.packages' || name == 'pubspec.lock')
        continue;
      File dest = new File(path.join(target.path, name));
      dest.writeAsBytesSync(entity.readAsBytesSync());
    }
  }
}

Directory _dir(Directory parent, String name) => new Directory(path.join(parent.path, name));
File _file(Directory parent, String name) => new File(path.join(parent.path, name));
String _normalize(String filePath) => path.normalize(path.absolute(filePath));

class SourceStats {
  int files = 0;
  int lines = 0;

  @override
  String toString() => '${_comma(files)} files, ${_comma(lines)} lines';
}

SourceStats getStatsFor(Directory dir, [SourceStats stats]) {
  stats ??= new SourceStats();

  for (FileSystemEntity entity in dir.listSync(recursive: false, followLinks: false)) {
    String name = path.basename(entity.path);
    if (entity is File && name.endsWith('.dart')) {
      stats.files += 1;
      stats.lines += _lineCount(entity);
    } else if (entity is Directory && !name.startsWith('.')) {
      getStatsFor(entity, stats);
    }
  }

  return stats;
}

int _lineCount(File file) {
  return file.readAsLinesSync().where((String line) {
    line = line.trim();
    if (line.isEmpty || line.startsWith('//'))
      return false;
    return true;
  }).length;
}

String _comma(int count) {
  String str = count.toString();
  if (str.length > 3)
    return str.substring(0, str.length - 3) + ',' + str.substring(str.length - 3);
  return str;
}
