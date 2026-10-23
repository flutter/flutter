// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Lists every place a platform channel is sent or handled, grouped by layer.
//
// Usage: dart find_channel_usages.dart flutter/<channel>
//
// Read-only. Searches the engine (excluding third_party) and the flutter and
// flutter_test packages for the channel name and for any constants or getters
// that hold it.

import 'dart:io';

const List<String> _extensions = <String>[
  '.dart',
  '.cc',
  '.h',
  '.mm',
  '.m',
  '.java',
  '.kt',
  '.swift',
];

const Set<String> _skipDirs = <String>{
  '.git',
  '.dart_tool',
  'third_party',
  'out',
  'build',
  'buildtools',
  'node_modules',
};

void main(List<String> args) {
  if (args.length != 1 || !args.first.contains('/')) {
    stderr.writeln('Usage: dart find_channel_usages.dart flutter/<channel>');
    exit(64);
  }
  final String channel = args.first;
  final Directory root = _findRepoRoot();
  final roots = <String, Directory>{
    'engine': Directory('${root.path}/engine/src/flutter'),
    'framework': Directory('${root.path}/packages/flutter'),
    'flutter_test': Directory('${root.path}/packages/flutter_test'),
  };

  final files = <File>[for (final Directory dir in roots.values) ..._listSources(dir)];

  // Pass 1: literal channel name, and identifiers that are assigned it.
  final literal = RegExp('${RegExp.escape('"$channel"')}|${RegExp.escape("'$channel'")}');
  // C, C++, Objective-C and Java constants, e.g. `kLifecycleChannel[] = "flutter/lifecycle"`.
  final String escaped = RegExp.escape(channel);
  final nativeConstant = RegExp('(\\w+)\\s*(?:\\[\\])?\\s*=\\s*@?"$escaped"');
  // Dart `static const Foo name = Foo(` with the channel name on the same or next lines.
  final dartDeclaration = RegExp(r'static\s+const\s+[\w<>?, ]+?\s+(\w+)\s*=');
  // Identifier -> files that define it. Identifiers such as `kChannelName` are
  // reused by many files for different channels, so they are only searched in
  // their defining file unless they are defined once and not file-private.
  final nativeIds = <String, Set<File>>{};
  final privateIds = <String>{};
  final dartIds = <String>{};
  final hits = <_Hit>[];
  final contents = <File, List<String>>{};

  for (final file in files) {
    final List<String> lines;
    try {
      lines = file.readAsLinesSync();
    } on FileSystemException {
      continue;
    }
    contents[file] = lines;
    final bool isDart = file.path.endsWith('.dart');
    for (var i = 0; i < lines.length; i++) {
      if (!literal.hasMatch(lines[i])) {
        continue;
      }
      hits.add(_Hit(file, i + 1, lines[i].trim()));
      if (isDart) {
        for (var j = i; j >= 0 && j >= i - 3; j--) {
          final RegExpMatch? m = dartDeclaration.firstMatch(lines[j]);
          if (m != null) {
            dartIds.add(m.group(1)!);
            break;
          }
        }
      } else {
        final RegExpMatch? m = nativeConstant.firstMatch(lines[i]);
        if (m != null) {
          nativeIds.putIfAbsent(m.group(1)!, () => <File>{}).add(file);
          if (RegExp(r'\b(static|private)\b').hasMatch(lines[i]) || !lines[i].contains('const')) {
            privateIds.add(m.group(1)!);
          }
        }
      }
    }
  }

  // Pass 2: uses of those identifiers.
  final globalPatterns = <RegExp>[
    for (final String id in dartIds) RegExp(r'SystemChannels\.' + id + r'\b'),
    for (final MapEntry<String, Set<File>> e in nativeIds.entries)
      if (e.value.length == 1 && !privateIds.contains(e.key)) RegExp(r'\b' + e.key + r'\b'),
  ];
  final localPatterns = <File, List<RegExp>>{};
  for (final MapEntry<String, Set<File>> e in nativeIds.entries) {
    for (final File f in e.value) {
      localPatterns.putIfAbsent(f, () => <RegExp>[]).add(RegExp(r'\b' + e.key + r'\b'));
    }
  }
  for (final MapEntry<File, List<String>> entry in contents.entries) {
    final patterns = <RegExp>[...globalPatterns, ...?localPatterns[entry.key]];
    if (patterns.isEmpty) {
      continue;
    }
    final List<String> lines = entry.value;
    for (var i = 0; i < lines.length; i++) {
      if (literal.hasMatch(lines[i])) {
        continue;
      }
      if (patterns.any((p) => p.hasMatch(lines[i]))) {
        hits.add(_Hit(entry.key, i + 1, lines[i].trim()));
      }
    }
  }

  final groups = <String, List<_Hit>>{};
  for (final hit in hits) {
    final String rel = hit.file.path.substring(root.path.length + 1);
    groups.putIfAbsent(_layer(rel), () => <_Hit>[]).add(hit);
  }

  stdout.writeln('Channel: $channel');
  final ids = <String>[for (final id in dartIds) 'SystemChannels.$id', ...nativeIds.keys];
  stdout.writeln(
    'Identifiers holding the channel name: ${ids.isEmpty ? '(none)' : ids.join(', ')}',
  );
  stdout.writeln();
  for (final String layer in _layerOrder) {
    final List<_Hit>? layerHits = groups[layer];
    if (layerHits == null) {
      continue;
    }
    stdout.writeln('== $layer (${layerHits.length})');
    layerHits.sort((a, b) {
      final int c = a.file.path.compareTo(b.file.path);
      return c != 0 ? c : a.line.compareTo(b.line);
    });
    for (final _Hit hit in layerHits) {
      final String rel = hit.file.path.substring(root.path.length + 1);
      stdout.writeln('  $rel:${hit.line}: ${hit.text}');
    }
    stdout.writeln();
  }
  if (hits.isEmpty) {
    stdout.writeln('No usages found.');
    exit(1);
  }
  if (!groups.containsKey('framework')) {
    stdout.writeln(
      'Note: the framework does not reference this channel. If shell/common '
      'handles it, the engine intercepts it and only dart:ui needs a new API.',
    );
  }
}

const List<String> _layerOrder = <String>[
  'framework',
  'framework tests',
  'flutter_test',
  'engine core (lib/ui, runtime, shell/common)',
  'embedder API',
  'platform: common',
  'platform: linux',
  'platform: windows',
  'platform: macos',
  'platform: ios',
  'platform: darwin (shared)',
  'platform: android',
  'platform: fuchsia',
  'web',
  'engine tests and fixtures',
  'other',
];

String _layer(String rel) {
  final bool isTest = RegExp(r'(_test|_unittests?|Test|Tests)\.\w+$|/test/|/testing/|/fixtures/')
      .hasMatch(rel);
  if (rel.startsWith('packages/flutter_test/')) {
    return 'flutter_test';
  }
  if (rel.startsWith('packages/flutter/')) {
    return isTest ? 'framework tests' : 'framework';
  }
  const prefix = 'engine/src/flutter/';
  final String e = rel.startsWith(prefix) ? rel.substring(prefix.length) : rel;
  if (e.startsWith('lib/web_ui/')) {
    return 'web';
  }
  if (isTest) {
    return 'engine tests and fixtures';
  }
  if (e.startsWith('lib/ui/') || e.startsWith('runtime/') || e.startsWith('shell/common/')) {
    return 'engine core (lib/ui, runtime, shell/common)';
  }
  const platforms = <String, String>{
    'shell/platform/embedder/': 'embedder API',
    'shell/platform/common/': 'platform: common',
    'shell/platform/linux/': 'platform: linux',
    'shell/platform/windows/': 'platform: windows',
    'shell/platform/darwin/macos/': 'platform: macos',
    'shell/platform/darwin/ios/': 'platform: ios',
    'shell/platform/darwin/': 'platform: darwin (shared)',
    'shell/platform/android/': 'platform: android',
    'shell/platform/fuchsia/': 'platform: fuchsia',
  };
  for (final MapEntry<String, String> p in platforms.entries) {
    if (e.startsWith(p.key)) {
      return p.value;
    }
  }
  return 'other';
}

Iterable<File> _listSources(Directory dir) sync* {
  if (!dir.existsSync()) {
    return;
  }
  for (final FileSystemEntity entity in dir.listSync(followLinks: false)) {
    final String name = entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
    if (entity is Directory) {
      if (!_skipDirs.contains(name)) {
        yield* _listSources(entity);
      }
    } else if (entity is File && _extensions.any(name.endsWith)) {
      yield entity;
    }
  }
}

Directory _findRepoRoot() {
  for (final start in <Directory>[Directory.current, File.fromUri(Platform.script).parent]) {
    Directory dir = start.absolute;
    while (true) {
      if (Directory('${dir.path}/engine/src/flutter').existsSync() &&
          Directory('${dir.path}/packages/flutter').existsSync()) {
        return dir;
      }
      if (dir.parent.path == dir.path) {
        break;
      }
      dir = dir.parent;
    }
  }
  stderr.writeln('Could not find the flutter repository root.');
  exit(2);
}

class _Hit {
  _Hit(this.file, this.line, this.text);
  final File file;
  final int line;
  final String text;
}
