// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Checks that every hop of a channel → embedder API migration is present.
//
// Usage:
//   dart check_hops.dart --direction in|out --name <Name> [--api <Api>]
//       [--kind state|event] [--channel <SystemChannels getter>] [--skip id,id]
//       [--base <git ref>]
//
// Read-only. Prints one line per hop: OK, MISSING, WARN or SKIP. Exits 1 if any
// hop is MISSING. Hop IDs match the headings in references/inbound-hops.md,
// references/outbound-hops.md and references/platform-adoption.md.

import 'dart:io';

late final String _root;
late final String _engine;

void main(List<String> argv) {
  final Map<String, String> args = _parseArgs(argv);
  final String? direction = args['direction'];
  final String? name = args['name'];
  if ((direction != 'in' && direction != 'out') ||
      name == null ||
      !RegExp(r'^[A-Z]\w*$').hasMatch(name)) {
    _usage();
  }
  final String kind = args['kind'] ?? 'state';
  if (kind != 'state' && kind != 'event') {
    _usage();
  }
  final String api =
      args['api'] ?? (direction == 'in' && kind == 'event' ? 'Send$name' : 'Set$name');
  final skip = <String>{
    ...?args['skip']?.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty),
  };

  _root = _findRepoRoot();
  _engine = '$_root/engine/src/flutter';

  final n = _Names(name, api);
  stdout.writeln(
    'Checking ${direction == 'in' ? 'inbound ($kind)' : 'outbound'} hops for '
    '{Name}=${n.name} {name}=${n.lower} {name_snake}=${n.snake} {Api}=${n.api} {api}=${n.apiLower}',
  );
  stdout.writeln();

  final List<_Hop> hops = direction == 'in'
      ? _inboundHops(n, kind == 'state', args['channel'])
      : _outboundHops(n);
  hops.addAll(_commonHops(n, args['base']));

  var missing = 0;
  final seen = <String>{};
  for (final hop in hops) {
    seen.add(hop.id);
    if (skip.contains(hop.id)) {
      _print('SKIP', hop.id, 'skipped with --skip');
      continue;
    }
    final _Result result = hop.check();
    _print(result.status, hop.id, result.detail);
    if (result.status == 'MISSING') {
      missing++;
    }
  }
  for (final String id in skip.difference(seen)) {
    _print('WARN', id, 'unknown hop ID passed to --skip');
  }
  stdout.writeln();
  if (missing > 0) {
    stdout.writeln('$missing hop(s) missing.');
    exit(1);
  }
  stdout.writeln('All hops present.');
}

// ---------------------------------------------------------------------------
// Hop definitions.

List<_Hop> _inboundHops(_Names n, bool state, String? channelGetter) {
  final String update = state ? 'Update${n.name}' : n.api;
  final hook = state ? '_update${n.name}' : '_${n.apiLower}';
  final callback = state ? 'on${n.name}Changed' : 'on${n.name}';
  const embedderH = 'shell/platform/embedder/embedder.h';
  const embedderCc = 'shell/platform/embedder/embedder.cc';
  return <_Hop>[
    _Hop(
      'embedder-h-function',
      () => _has(embedderH, r'FlutterEngineResult\s+FlutterEngine' + n.api + r'\s*\('),
    ),
    _Hop(
      'embedder-h-fnptr',
      () => _has(embedderH, r'\(\s*\*\s*FlutterEngine' + n.api + r'FnPtr\s*\)'),
    ),
    _Hop(
      'embedder-h-proctable',
      () => _inBlock(
        embedderH,
        'FlutterEngineProcTable',
        r'FlutterEngine' + n.api + r'FnPtr\s+' + n.api + r'\s*;',
        last: true,
      ),
    ),
    _Hop(
      'embedder-cc-function',
      () => _has(embedderCc, r'FlutterEngineResult\s+FlutterEngine' + n.api + r'\s*\('),
    ),
    _Hop(
      'embedder-cc-setproc',
      () => _has(embedderCc, r'SET_PROC\(\s*' + n.api + r'\s*,\s*FlutterEngine' + n.api + r'\s*\)'),
    ),
    _Hop(
      'embedder-engine',
      () => _all(<_Result>[
        _has('shell/platform/embedder/embedder_engine.h', r'\b' + n.api + r'\s*\('),
        _has('shell/platform/embedder/embedder_engine.cc', r'EmbedderEngine::' + n.api + r'\s*\('),
      ]),
    ),
    _Hop(
      'platform-view',
      () => _all(<_Result>[
        _has('shell/common/platform_view.h', r'void\s+' + n.api + r'\s*\('),
        _has('shell/common/platform_view.cc', r'PlatformView::' + n.api + r'\s*\('),
      ]),
    ),
    _Hop(
      'platform-view-delegate',
      () => _has(
        'shell/common/platform_view.h',
        r'virtual\s+void\s+OnPlatformView' + n.api + r'\s*\(',
      ),
    ),
    _Hop(
      'delegate-implementors',
      () => _implementors(
        r'(?:flutter::)?PlatformView::Delegate',
        'OnPlatformViewCreated',
        'OnPlatformView${n.api}',
      ),
    ),
    _Hop(
      'shell',
      () => _all(<_Result>[
        _has('shell/common/shell.h', r'\bOnPlatformView' + n.api + r'\s*\('),
        _has('shell/common/shell.cc', r'Shell::OnPlatformView' + n.api + r'\s*\('),
      ]),
    ),
    _Hop(
      'engine',
      () => _all(<_Result>[
        _has('shell/common/engine.h', r'\b' + n.api + r'\s*\('),
        _has('shell/common/engine.cc', r'Engine::' + n.api + r'\s*\('),
      ]),
    ),
    _Hop(
      'runtime-controller',
      () => _all(<_Result>[
        _has('runtime/runtime_controller.h', r'\b' + n.api + r'\s*\('),
        _has('runtime/runtime_controller.cc', r'RuntimeController::' + n.api + r'\s*\('),
      ]),
    ),
    if (state) ...<_Hop>[
      _Hop('platform-data', () => _has('runtime/platform_data.h', r'\b' + n.snake + r'\b')),
      _Hop(
        'flush',
        () => _inFunction(
          'runtime/runtime_controller.cc',
          'RuntimeController::FlushRuntimeStateToIsolate',
          r'\b' + n.api + r'\s*\(',
        ),
      ),
    ],
    _Hop(
      'platform-configuration',
      () => _all(<_Result>[
        _has('lib/ui/window/platform_configuration.h', r'\b' + update + r'\s*\('),
        _has(
          'lib/ui/window/platform_configuration.cc',
          r'PlatformConfiguration::' + update + r'\s*\(',
        ),
        _has('lib/ui/window/platform_configuration.cc', '"$hook"'),
      ]),
    ),
    _Hop('hooks', () => _has('lib/ui/hooks.dart', r'void\s+' + hook + r'\s*\(')),
    _Hop(
      'dart-ui-dispatcher',
      () => _all(<_Result>[
        if (state) _has('lib/ui/platform_dispatcher.dart', r'\bget\s+' + n.lower + r'\b'),
        _has('lib/ui/platform_dispatcher.dart', r'\b' + callback + r'\b'),
        _has('lib/ui/platform_dispatcher.dart', r'void\s+' + hook + r'\s*\('),
      ]),
    ),
    _Hop(
      'web-ui-abstract',
      () => _has('lib/web_ui/lib/platform_dispatcher.dart', r'\b' + callback + r'\b'),
    ),
    _Hop(
      'web-ui-impl',
      () => _has('lib/web_ui/lib/src/engine/platform_dispatcher.dart', r'\b' + callback + r'\b'),
    ),
    _Hop(
      'test-dispatcher',
      () => _hasRoot('packages/flutter_test/lib/src/window.dart', r'\b' + callback + r'\b'),
    ),
    _Hop(
      'deprecation-warning',
      () => _all(<_Result>[
        _has('shell/common/engine.cc', r'FlutterEngine' + n.api + r'\b'),
        _has('shell/common/engine.cc', r'std::call_once'),
      ]),
    ),
    _Hop('framework', () => _anyUnder('$_root/packages/flutter/lib', r'\b' + callback + r'\b')),
    if (state)
      _Hop(
        'framework-fallback',
        () => _anyUnder(
          '$_root/packages/flutter/lib',
          r'channelBuffers\.push\(\s*SystemChannels\.' + (channelGetter ?? r'\w+') + r'\b',
          warnOnly: true,
        ),
      ),
    // Platform adoption.
    _Hop(
      'platform-linux',
      () => _anyUnder('$_engine/shell/platform/linux', r'embedder_api\.' + n.api + r'\s*\('),
    ),
    _Hop('platform-linux-mock-engine', () {
      final _Result r = _has(
        'shell/platform/linux/testing/mock_engine.cc',
        r'table->' + n.api + r'\s*=',
      );
      return r.status == 'OK'
          ? r
          : _Result(
              'WARN',
              '${r.detail}. Add the proc if a Linux test reaches the new call without '
                  'overriding it with MOCK_ENGINE_PROC (it would call a null pointer).',
            );
    }),
    _Hop(
      'platform-windows',
      () => _anyUnder('$_engine/shell/platform/windows', r'embedder_api_\.' + n.api + r'\s*\('),
    ),
    _Hop(
      'platform-macos',
      () => _anyUnder('$_engine/shell/platform/darwin/macos', r'_embedderAPI\.' + n.api + r'\s*\('),
    ),
    _Hop(
      'platform-ios',
      () => _anyUnder('$_engine/shell/platform/darwin/ios', r'->' + n.api + r'\s*\('),
    ),
    _Hop(
      'platform-android',
      () => _all(<_Result>[
        _anyUnder(
          '$_engine/shell/platform/android',
          r'\bnative\b[^;(]*\bnative' + n.api + r'\s*\(',
        ),
        _has('shell/platform/android/platform_view_android_jni_impl.cc', '"native${n.api}"'),
      ]),
    ),
  ];
}

List<_Hop> _outboundHops(_Names n) {
  const embedderH = 'shell/platform/embedder/embedder.h';
  final cb = '${n.snake}_callback';
  return <_Hop>[
    _Hop(
      'dart-ui-native',
      () => _all(<_Result>[
        _has(
          'lib/ui/platform_dispatcher.dart',
          "symbol:\\s*'PlatformConfigurationNativeApi::${n.api}'",
        ),
        _has('lib/ui/platform_dispatcher.dart', r'\b' + n.apiLower + r'\s*\('),
      ]),
    ),
    _Hop(
      'dart-ui-native-registration',
      () => _has('lib/ui/dart_ui.cc', r'PlatformConfigurationNativeApi::' + n.api + r'\b'),
    ),
    _Hop(
      'platform-configuration-native',
      () => _all(<_Result>[
        _has(
          'lib/ui/window/platform_configuration.h',
          r'static\s+[\w:<>&\s]+\b' + n.api + r'\s*\(',
        ),
        _has(
          'lib/ui/window/platform_configuration.cc',
          r'PlatformConfigurationNativeApi::' + n.api + r'\s*\(',
        ),
      ]),
    ),
    _Hop(
      'platform-configuration-client',
      () => _has(
        'lib/ui/window/platform_configuration.h',
        r'virtual\s+[\w:<>&\s]+\b' + n.api + r'\s*\(',
      ),
    ),
    _Hop(
      'client-implementors',
      () => _implementors(r'(?:flutter::)?PlatformConfigurationClient', 'DefaultRouteName', n.api),
    ),
    _Hop(
      'runtime-controller',
      () => _has('runtime/runtime_controller.cc', r'RuntimeController::' + n.api + r'\s*\('),
    ),
    _Hop(
      'runtime-delegate',
      () => _has('runtime/runtime_delegate.h', r'virtual\s+[\w:<>&\s]+\b' + n.api + r'\s*\('),
    ),
    _Hop(
      'runtime-delegate-implementors',
      () => _implementors(r'(?:flutter::)?RuntimeDelegate', 'OnRootIsolateCreated', n.api),
    ),
    _Hop('engine', () => _has('shell/common/engine.cc', r'Engine::' + n.api + r'\s*\(')),
    _Hop(
      'engine-delegate',
      () => _has('shell/common/engine.h', r'virtual\s+void\s+OnEngine' + n.api + r'\s*\('),
    ),
    _Hop(
      'engine-delegate-implementors',
      () => _implementors(
        r'(?:flutter::)?Engine::Delegate',
        'OnEngineHandlePlatformMessage',
        'OnEngine${n.api}',
      ),
    ),
    _Hop('shell', () => _has('shell/common/shell.cc', r'Shell::OnEngine' + n.api + r'\s*\(')),
    _Hop(
      'platform-view',
      () => _all(<_Result>[
        _has('shell/common/platform_view.h', r'virtual\s+void\s+' + n.api + r'\s*\('),
        _has('shell/common/platform_view.cc', r'PlatformView::' + n.api + r'\s*\('),
      ]),
    ),
    _Hop(
      'embedder-h-callback',
      () => _inBlock(embedderH, 'FlutterProjectArgs', r'\b' + cb + r'\s*;', last: true),
    ),
    _Hop(
      'embedder-cc-callback',
      () =>
          _has('shell/platform/embedder/embedder.cc', r'SAFE_ACCESS\(\s*args\s*,\s*' + cb + r'\b'),
    ),
    _Hop(
      'embedder-platform-view',
      () => _all(<_Result>[
        _has('shell/platform/embedder/platform_view_embedder.h', r'\b' + cb + r'\b'),
        _has(
          'shell/platform/embedder/platform_view_embedder.cc',
          r'PlatformViewEmbedder::' + n.api + r'\s*\(',
        ),
      ]),
    ),
    _Hop(
      'web-ui-abstract',
      () => _has('lib/web_ui/lib/platform_dispatcher.dart', r'\b' + n.apiLower + r'\s*\('),
    ),
    _Hop(
      'test-dispatcher',
      () => _hasRoot('packages/flutter_test/lib/src/window.dart', r'\b' + n.apiLower + r'\s*\('),
    ),
    _Hop(
      'framework',
      () => _anyUnder('$_root/packages/flutter/lib', r'\.' + n.apiLower + r'\s*\('),
    ),
    // Platform adoption.
    _Hop('platform-linux', () => _anyUnder('$_engine/shell/platform/linux', r'\.' + cb + r'\s*=')),
    _Hop(
      'platform-windows',
      () => _anyUnder('$_engine/shell/platform/windows', r'\.' + cb + r'\s*='),
    ),
    _Hop(
      'platform-macos',
      () => _anyUnder('$_engine/shell/platform/darwin/macos', r'\.' + cb + r'\s*='),
    ),
    _Hop(
      'platform-ios',
      () => _has('shell/platform/darwin/ios/platform_view_ios.h', r'\b' + n.api + r'\s*\('),
    ),
    _Hop(
      'platform-android',
      () => _has('shell/platform/android/platform_view_android.h', r'\b' + n.api + r'\s*\('),
    ),
  ];
}

List<_Hop> _commonHops(_Names n, String? base) {
  return <_Hop>[
    _Hop('api-check', () => _apiCheck(n)),
    _Hop('abi-append-only', () => _abiAppendOnly(base)),
  ];
}

// ---------------------------------------------------------------------------
// Checks.

final Map<String, String?> _cache = <String, String?>{};

String? _read(String path) => _cache.putIfAbsent(path, () {
  final file = File(path);
  return file.existsSync() ? file.readAsStringSync() : null;
});

String _rel(String path) => path.startsWith('$_engine/')
    ? '\$ENGINE/${path.substring(_engine.length + 1)}'
    : path.startsWith('$_root/')
    ? path.substring(_root.length + 1)
    : path;

_Result _hasAt(String path, String pattern) {
  final String? text = _read(path);
  if (text == null) {
    return _Result('MISSING', '${_rel(path)} does not exist');
  }
  return RegExp(pattern).hasMatch(text)
      ? _Result('OK', _rel(path))
      : _Result('MISSING', '${_rel(path)}: no match for /$pattern/');
}

_Result _has(String engineRelative, String pattern) => _hasAt('$_engine/$engineRelative', pattern);

_Result _hasRoot(String rootRelative, String pattern) => _hasAt('$_root/$rootRelative', pattern);

_Result _all(List<_Result> results) {
  final List<_Result> bad = results.where((r) => r.status != 'OK').toList();
  if (bad.isEmpty) {
    return _Result('OK', results.map((r) => r.detail).toSet().join(', '));
  }
  final status = bad.any((r) => r.status == 'MISSING') ? 'MISSING' : 'WARN';
  return _Result(status, bad.map((r) => r.detail).join('; '));
}

_Result _anyUnder(String dir, String pattern, {bool warnOnly = false}) {
  final re = RegExp(pattern);
  final found = <String>[];
  for (final File file in _sources(Directory(dir))) {
    final String? text = _read(file.path);
    if (text != null && re.hasMatch(text)) {
      found.add(_rel(file.path));
    }
  }
  if (found.isNotEmpty) {
    return _Result(
      'OK',
      found.take(3).join(', ') + (found.length > 3 ? ' (+${found.length - 3} more)' : ''),
    );
  }
  return _Result(warnOnly ? 'WARN' : 'MISSING', 'no match for /$pattern/ under ${_rel(dir)}');
}

/// Checks [pattern] appears inside `typedef struct { ... } [structName];`.
/// With [last], warns if it is not the last field.
_Result _inBlock(String engineRelative, String structName, String pattern, {bool last = false}) {
  final path = '$_engine/$engineRelative';
  final String? text = _read(path);
  if (text == null) {
    return _Result('MISSING', '${_rel(path)} does not exist');
  }
  final int end = text.indexOf(RegExp(r'\}\s*' + structName + r'\s*;'));
  if (end < 0) {
    return _Result('MISSING', 'struct $structName not found in ${_rel(path)}');
  }
  final int start = text.lastIndexOf('typedef struct', end);
  final String block = text.substring(start, end);
  final List<RegExpMatch> matches = RegExp(pattern).allMatches(block).toList();
  if (matches.isEmpty) {
    return _Result('MISSING', '$structName in ${_rel(path)}: no match for /$pattern/');
  }
  if (last) {
    final String after = block
        .substring(matches.last.end)
        .replaceAll(RegExp(r'//[^\n]*'), '')
        .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
        .trim();
    if (after.isNotEmpty) {
      return _Result(
        'WARN',
        '$structName: field is not last; fields after it: ${after.split('\n').first.trim()}',
      );
    }
  }
  return _Result('OK', '$structName in ${_rel(path)}');
}

_Result _inFunction(String engineRelative, String function, String pattern) {
  final path = '$_engine/$engineRelative';
  final String? text = _read(path);
  if (text == null) {
    return _Result('MISSING', '${_rel(path)} does not exist');
  }
  final int start = text.indexOf(RegExp(RegExp.escape(function) + r'\s*\([^)]*\)[^;{]*\{'));
  if (start < 0) {
    return _Result('MISSING', '$function not found in ${_rel(path)}');
  }
  int end = text.indexOf('\n}', start);
  if (end < 0) {
    end = text.length;
  }
  return RegExp(pattern).hasMatch(text.substring(start, end))
      ? _Result('OK', '$function in ${_rel(path)}')
      : _Result('MISSING', '$function in ${_rel(path)}: no match for /$pattern/');
}

/// Finds every C++ class deriving from [baseClass] and checks each file has at
/// least as many mentions of [method] as it has implementing classes.
///
/// Files that do not mention [signature], an existing method of the interface,
/// are ignored: they derive from a different class with the same name (for
/// example `flutter_runner::Engine::Delegate` on Fuchsia).
_Result _implementors(String baseClass, String signature, String method) {
  final base = RegExp(r'(?<![\w:])' + baseClass + r'\b');
  final classDecl = RegExp(
    r'\b(?:class|struct)\s+(?:\w+\s+)?(?!final\b)(\w+)(?:\s+final)?\s*:\s*([^{;()]*?)\{',
    dotAll: true,
  );
  final methodRe = RegExp(r'\b' + method + r'\b');
  final String simpleBase = baseClass.split('::').last.replaceAll(RegExp(r'[^\w]'), '');
  final problems = <String>[];
  var classes = 0;
  var files = 0;
  for (final File file in _sources(
    Directory(_engine),
    extensions: const <String>['.h', '.cc', '.mm'],
  )) {
    final String? text = _read(file.path);
    if (text == null || !text.contains(simpleBase) || !text.contains(signature)) {
      continue;
    }
    final implementors = <String>[
      for (final RegExpMatch m in classDecl.allMatches(text))
        if (base.hasMatch(m.group(2)!)) m.group(1)!,
    ];
    if (implementors.isEmpty) {
      continue;
    }
    classes += implementors.length;
    files++;
    final int mentions = methodRe.allMatches(text).length;
    if (mentions < implementors.length) {
      problems.add(
        '${_rel(file.path)} (${implementors.join(', ')}: $mentions of ${implementors.length})',
      );
    }
  }
  if (classes == 0) {
    return _Result('MISSING', 'no implementors of $baseClass found (script bug?)');
  }
  if (problems.isEmpty) {
    return _Result('OK', '$classes implementors of $baseClass in $files files all mention $method');
  }
  return _Result('MISSING', '$method missing from: ${problems.join(', ')}');
}

_Result _apiCheck(_Names n) {
  final String? header = _read('$_engine/shell/platform/embedder/embedder.h');
  final newTypes = <String>[
    if (header != null)
      for (final RegExpMatch m in RegExp(
        r'\}\s*(Flutter' + n.name + r'\w*)\s*;',
      ).allMatches(header))
        if (RegExp(r'typedef\s+enum[^}]*\}\s*' + m.group(1)! + r'\s*;').hasMatch(header))
          m.group(1)!,
  ];
  if (newTypes.isEmpty) {
    return _Result('OK', 'no new embedder.h enum named Flutter${n.name}*');
  }
  final String? test = _read('$_engine/tools/api_check/test/apicheck_test.dart');
  final List<String> unchecked = newTypes.where((t) => test == null || !test.contains(t)).toList();
  if (unchecked.isEmpty) {
    // A comparison of two empty lists passes, so require a guard against that.
    final unguarded = <String>[
      for (final t in newTypes)
        if (!RegExp(r"test\('[^']*'", dotAll: true)
            .allMatches(test!)
            .map((m) => _testBody(test, m.start))
            .any((body) => body.contains(t) && _nonEmptyGuard.hasMatch(body)))
          t,
    ];
    if (unguarded.isNotEmpty) {
      return _Result(
        'WARN',
        'the api_check test for ${unguarded.join(', ')} has no isNotEmpty assertion; '
            'empty lists compare equal, so check each parser really finds the values',
      );
    }
    return _Result('OK', '${newTypes.join(', ')} covered by apicheck_test.dart');
  }
  return _Result(
    'MISSING',
    '${unchecked.join(', ')} not checked against the dart:ui enum in '
        r'$ENGINE/tools/api_check/test/apicheck_test.dart',
  );
}

final RegExp _nonEmptyGuard = RegExp(r'expect\([^;]*\bisNotEmpty\b');

/// The text of the `test(...)` call starting at [start], up to its closing `});`.
String _testBody(String text, int start) {
  final int indent = start - text.lastIndexOf('\n', start) - 1;
  final int end = text.indexOf(RegExp('\\n {$indent}\\}\\);'), start);
  return text.substring(start, end < 0 ? text.length : end);
}

_Result _abiAppendOnly(String? base) {
  final String? ref = base ?? _defaultBase();
  if (ref == null) {
    return _Result(
      'WARN',
      'no base ref found; pass --base <ref> to check embedder.h for removed lines',
    );
  }
  final ProcessResult result = Process.runSync('git', <String>[
    'diff',
    '-U0',
    ref,
    '--',
    'engine/src/flutter/shell/platform/embedder/embedder.h',
  ], workingDirectory: _root);
  if (result.exitCode != 0) {
    return _Result('WARN', 'git diff against $ref failed: ${result.stderr.toString().trim()}');
  }
  final List<String> removed = result.stdout
      .toString()
      .split('\n')
      .where((l) => l.startsWith('-') && !l.startsWith('---'))
      .map((l) => l.substring(1).trim())
      .where((l) => l.isNotEmpty && !l.startsWith('//'))
      .toList();
  if (removed.isEmpty) {
    return _Result('OK', 'embedder.h has no removed or changed code lines since $ref');
  }
  return _Result(
    'WARN',
    'embedder.h changed or removed ${removed.length} code line(s) since $ref, check the ABI: ${removed.first}',
  );
}

String? _defaultBase() {
  for (final candidate in <String>['upstream/main', 'origin/main', 'main']) {
    final ProcessResult r = Process.runSync('git', <String>[
      'merge-base',
      'HEAD',
      candidate,
    ], workingDirectory: _root);
    if (r.exitCode == 0) {
      return r.stdout.toString().trim();
    }
  }
  return null;
}

// ---------------------------------------------------------------------------
// Helpers.

const Set<String> _skipDirs = <String>{
  '.git',
  '.dart_tool',
  'third_party',
  'out',
  'build',
  'buildtools',
  'prebuilts',
  'node_modules',
};

Iterable<File> _sources(
  Directory dir, {
  List<String> extensions = const <String>['.dart', '.cc', '.h', '.mm', '.m', '.java', '.kt'],
}) sync* {
  if (!dir.existsSync()) {
    return;
  }
  for (final FileSystemEntity entity in dir.listSync(followLinks: false)) {
    final String name = entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
    if (entity is Directory) {
      if (!_skipDirs.contains(name)) {
        yield* _sources(entity, extensions: extensions);
      }
    } else if (entity is File && extensions.any(name.endsWith)) {
      yield entity;
    }
  }
}

class _Names {
  _Names(this.name, this.api)
    : lower = name[0].toLowerCase() + name.substring(1),
      apiLower = api[0].toLowerCase() + api.substring(1),
      snake = name
          .replaceAllMapped(
            RegExp(r'(?<=[a-z0-9])([A-Z])|(?<=[A-Z])([A-Z])(?=[a-z])'),
            (m) => '_${m[0]}',
          )
          .toLowerCase();
  final String name;
  final String lower;
  final String snake;
  final String api;
  final String apiLower;
}

class _Hop {
  _Hop(this.id, this.check);
  final String id;
  final _Result Function() check;
}

class _Result {
  _Result(this.status, this.detail);
  final String status;
  final String detail;
}

void _print(String status, String id, String detail) {
  stdout.writeln('${status.padRight(8)}${id.padRight(32)}$detail');
}

Map<String, String> _parseArgs(List<String> argv) {
  final args = <String, String>{};
  for (var i = 0; i < argv.length; i++) {
    final String a = argv[i];
    if (!a.startsWith('--')) {
      _usage();
    }
    final int eq = a.indexOf('=');
    if (eq > 0) {
      args[a.substring(2, eq)] = a.substring(eq + 1);
    } else if (i + 1 < argv.length) {
      args[a.substring(2)] = argv[++i];
    } else {
      _usage();
    }
  }
  return args;
}

Never _usage() {
  stderr.writeln(
    'Usage: dart check_hops.dart --direction in|out --name <PascalName> [--api <Api>]\n'
    '           [--kind state|event] [--channel <getter>] [--skip id,id] [--base <git ref>]\n'
    '\n'
    '  --name   PascalCase concept, e.g. AppLifecycleState.\n'
    '  --api    C++ method name. Default: Set<Name> (Send<Name> for inbound events).\n'
    '  --kind   Inbound only. state (default) or event.\n'
    '  --channel  Inbound only. SystemChannels getter (e.g. lifecycle) for framework-fallback.\n'
    '  --skip   Hop IDs that were reused or do not apply (explain each in the PR).\n'
    '  --base   Git ref for the embedder.h ABI check. Default: merge-base with main.',
  );
  exit(64);
}

String _findRepoRoot() {
  for (final start in <Directory>[Directory.current, File.fromUri(Platform.script).parent]) {
    Directory dir = start.absolute;
    while (true) {
      if (Directory('${dir.path}/engine/src/flutter').existsSync() &&
          Directory('${dir.path}/packages/flutter').existsSync()) {
        return dir.path;
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
