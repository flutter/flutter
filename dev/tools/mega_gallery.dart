// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Make `n` copies of material_gallery.

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

const int kTargetLineCount = 100 * 1024;

// TODO: Copy this into the ../benchmarks directory?

void main(List<String> args) {
  // If we're run from the `tools` dir, set the cwd to the repo root.
  if (path.basename(Directory.current.path) == 'tools')
    Directory.current = Directory.current.parent.parent;

  ArgParser argParser = new ArgParser();
  // ../mega_gallery? dev/benchmarks/mega_gallery?
  argParser.addOption('out', defaultsTo: path.normalize(path.absolute('dev/benchmarks/mega_gallery')));
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

  Directory source = new Directory(path.normalize(path.absolute('examples/material_gallery')));
  int copies;

  Directory out = new Directory(path.normalize(path.absolute(results['out'])));

  if (results['delete']) {
    if (out.existsSync()) {
      print('Deleting ${out.path}');
      out.deleteSync(recursive: true);
    }

    exit(0);
  }

  if (!results.wasParsed('copies')) {
    SourceStats stats = getStatsFor(_dir(source, 'lib'));
    copies = (kTargetLineCount / stats.lines).round();
  } else {
    copies = int.parse(results['copies']);
  }

  print('Making $copies copies of material_gallery to ${out.path}/');

  Directory lib = _dir(out, 'lib');
  if (lib.existsSync())
    lib.deleteSync(recursive: true);

  // Copy everything that's not a symlink, dot directory, or build/.
  _copy(source, out);

  // Make n - 1 copies.
  for (int i = 1; i < copies; i++)
    _copyGallery(out, i);

  // Create a new entry-point.
  // TODO:

  // Update the pubspec.
  String pubspec = _file(out, 'pubspec.yaml').readAsStringSync();
  pubspec = pubspec.replaceAll('../../packages/flutter', '../../../packages/flutter');
  _file(out, 'pubspec.yaml').writeAsStringSync(pubspec);

  // Count source lines and number of files; tell how to run it.
  SourceStats stats = getStatsFor(out);
  print('material_gallery copied $copies times ($stats).');
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

class SourceStats {
  int files = 0;
  int lines = 0;

  String toString() => '${_comma(files)} files, ${_comma(lines)} lines';
}

SourceStats getStatsFor(Directory dir) {
  SourceStats stats = new SourceStats();

  for (FileSystemEntity entity in dir.listSync(recursive: true, followLinks: false)) {
    if (entity is File && path.basename(entity.path).endsWith('.dart')) {
      stats.files += 1;
      stats.lines += _lineCount(entity);
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
