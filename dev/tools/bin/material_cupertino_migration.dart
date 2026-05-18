// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

const List<_DesignLibrary> _designLibraries = <_DesignLibrary>[
  _DesignLibrary(
    dependency: 'material_ui',
    legacyUri: 'package:flutter/material.dart',
    packageUri: 'package:material_ui/material_ui.dart',
  ),
  _DesignLibrary(
    dependency: 'cupertino_ui',
    legacyUri: 'package:flutter/cupertino.dart',
    packageUri: 'package:cupertino_ui/cupertino_ui.dart',
  ),
];

const List<_FrameworkLibrary> _frameworkLibraries = <_FrameworkLibrary>[
  _FrameworkLibrary(
    uri: 'package:flutter/widgets.dart',
    symbols: <String>{
      'Action',
      'Alignment',
      'AnimatedBuilder',
      'AnimatedWidget',
      'AspectRatio',
      'AutomaticKeepAliveClientMixin',
      'BuildContext',
      'Builder',
      'Center',
      'Column',
      'ConnectionState',
      'Container',
      'DefaultTextStyle',
      'Directionality',
      'EdgeInsets',
      'Expanded',
      'Flexible',
      'FocusNode',
      'Form',
      'FormState',
      'GestureDetector',
      'GlobalKey',
      'GridView',
      'Icon',
      'IconData',
      'Image',
      'IndexedWidgetBuilder',
      'InheritedWidget',
      'Key',
      'LayoutBuilder',
      'ListView',
      'LocalKey',
      'MediaQuery',
      'Navigator',
      'Padding',
      'Page',
      'PageRoute',
      'Positioned',
      'Route',
      'RouteSettings',
      'Row',
      'SafeArea',
      'ScrollController',
      'ScrollPhysics',
      'SingleChildScrollView',
      'SizedBox',
      'SliverList',
      'Spacer',
      'Stack',
      'State',
      'StatefulBuilder',
      'StatefulWidget',
      'StatelessWidget',
      'StreamBuilder',
      'Text',
      'TextEditingController',
      'ValueKey',
      'Widget',
      'WidgetBuilder',
      'WidgetsApp',
      'runApp',
    },
  ),
  _FrameworkLibrary(
    uri: 'package:flutter/foundation.dart',
    symbols: <String>{
      'ChangeNotifier',
      'Diagnosticable',
      'Key',
      'Listenable',
      'ValueChanged',
      'ValueGetter',
      'ValueListenable',
      'ValueNotifier',
      'VoidCallback',
      'immutable',
      'protected',
      'visibleForTesting',
    },
  ),
  _FrameworkLibrary(
    uri: 'package:flutter/painting.dart',
    symbols: <String>{
      'Border',
      'BorderRadius',
      'BoxDecoration',
      'BoxFit',
      'BoxShadow',
      'Color',
      'Decoration',
      'Gradient',
      'ImageProvider',
      'LinearGradient',
      'NetworkImage',
      'Radius',
      'RoundedRectangleBorder',
      'TextAlign',
      'TextDirection',
      'TextStyle',
    },
  ),
  _FrameworkLibrary(
    uri: 'package:flutter/services.dart',
    symbols: <String>{
      'Clipboard',
      'HapticFeedback',
      'LogicalKeyboardKey',
      'PlatformException',
      'SystemChrome',
      'TextInputAction',
      'TextInputFormatter',
    },
  ),
  _FrameworkLibrary(
    uri: 'package:flutter/animation.dart',
    symbols: <String>{
      'Animation',
      'AnimationController',
      'AnimationStatus',
      'CurvedAnimation',
      'Curves',
      'Tween',
    },
  ),
  _FrameworkLibrary(
    uri: 'package:flutter/gestures.dart',
    symbols: <String>{
      'DragStartDetails',
      'DragUpdateDetails',
      'GestureRecognizer',
      'PointerDownEvent',
      'TapGestureRecognizer',
    },
  ),
  _FrameworkLibrary(
    uri: 'package:flutter/rendering.dart',
    symbols: <String>{'BoxConstraints', 'CustomPainter', 'RenderBox', 'RenderObject', 'Size'},
  ),
];

final Set<String> _frameworkSymbols = <String>{
  for (final _FrameworkLibrary library in _frameworkLibraries) ...library.symbols,
};

final RegExp _directivePattern = RegExp(
  r"""^([ \t]*)(import|export)\s+(['"])([^'"]+)\3([^;]*);""",
  multiLine: true,
);
final RegExp _partPattern = RegExp(r"""^\s*part\s+['"]([^'"]+)['"]\s*;""", multiLine: true);
final RegExp _partOfPattern = RegExp(r'^\s*part\s+of\s+', multiLine: true);
final RegExp _asPattern = RegExp(r'\bas\s+([A-Za-z_]\w*)');
final RegExp _showPattern = RegExp(r'\bshow\s+([^;]+?)(?:\s+hide\b|$)');
final RegExp _hidePattern = RegExp(r'\bhide\s+([^;]+?)(?:\s+show\b|$)');
final RegExp _topLevelSectionPattern = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*:', multiLine: true);

void main(List<String> args) {
  if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return;
  }

  final MigrationResult result = migratePaths(args);
  stdout.writeln(
    'Updated ${result.changedDartFiles} Dart file(s) and '
    '${result.changedPubspecs} pubspec file(s).',
  );
}

void _printUsage() {
  stdout.writeln(
    'Usage: dart dev/tools/bin/material_cupertino_migration.dart '
    '<app-or-dart-file> [...]',
  );
}

/// Migrates the Dart files and pubspecs under [paths].
///
/// Returns the number of Dart files and pubspecs that were changed.
MigrationResult migratePaths(Iterable<String> paths) {
  final List<FileSystemEntity> roots = paths.map(_pathToEntity).toList();
  for (final root in roots) {
    if (!root.existsSync()) {
      throw ArgumentError.value(root.path, 'path', 'Path does not exist');
    }
  }

  final files = <File>[];
  for (final root in roots) {
    files.addAll(_collectDartFiles(root));
  }

  final Map<String, List<File>> partOwners = _buildPartOwnerIndex(files);
  var changedFiles = 0;
  final dependencies = <String>{};

  for (final file in files) {
    final _RewriteResult result = _rewriteFile(
      file,
      partOwners[file.absolute.path] ?? const <File>[],
    );
    dependencies.addAll(result.dependencies);
    if (!result.changed) {
      continue;
    }
    file.writeAsStringSync(result.source);
    changedFiles += 1;
  }

  var changedPubspecs = 0;
  for (final Directory root in roots.whereType<Directory>()) {
    if (_updatePubspec(root, dependencies)) {
      changedPubspecs += 1;
    }
  }

  return MigrationResult(changedDartFiles: changedFiles, changedPubspecs: changedPubspecs);
}

FileSystemEntity _pathToEntity(String path) {
  final file = File(path);
  if (file.existsSync()) {
    return file;
  }
  return Directory(path);
}

List<File> _collectDartFiles(FileSystemEntity entity) {
  if (entity is File) {
    return entity.path.endsWith('.dart') ? <File>[entity] : const <File>[];
  }
  if (entity is! Directory) {
    return const <File>[];
  }

  final files = <File>[];
  for (final FileSystemEntity child in entity.listSync(followLinks: false)) {
    final String name = child.path.split(Platform.pathSeparator).last;
    if (child is Directory) {
      if (name == '.dart_tool' || name == '.git' || name == 'build') {
        continue;
      }
      files.addAll(_collectDartFiles(child));
    } else if (child is File && child.path.endsWith('.dart')) {
      files.add(child);
    }
  }
  return files;
}

Map<String, List<File>> _buildPartOwnerIndex(List<File> files) {
  final index = <String, List<File>>{};
  for (final file in files) {
    final String source = file.readAsStringSync();
    if (_partOfPattern.hasMatch(source)) {
      continue;
    }
    for (final RegExpMatch match in _partPattern.allMatches(source)) {
      final String uri = match.group(1)!;
      if (uri.startsWith('package:') || uri.startsWith('dart:')) {
        continue;
      }
      final part = File('${file.parent.path}/$uri');
      if (part.existsSync()) {
        index.putIfAbsent(file.absolute.path, () => <File>[]).add(part);
      }
    }
  }
  return index;
}

_RewriteResult _rewriteFile(File file, List<File> parts) {
  final String source = file.readAsStringSync();
  if (_partOfPattern.hasMatch(source)) {
    return _RewriteResult(source: source);
  }

  final String partSource = parts.map((File part) => part.readAsStringSync()).join('\n');
  final String maskedSource = _maskCommentsAndStrings(source);
  final String maskedPartSource = _maskCommentsAndStrings(partSource);
  final state = _RewriteState(
    frameworkImports: _frameworkDirectives(source, 'import'),
    frameworkExports: _frameworkDirectives(source, 'export'),
    frameworkUsage: _scanFrameworkUsage('$maskedSource\n$maskedPartSource'),
    maskedSource: '$maskedSource\n$maskedPartSource',
  );
  final dependencies = <String>{};
  final buffer = StringBuffer();
  var lastEnd = 0;
  var changed = false;

  for (final RegExpMatch match in _directivePattern.allMatches(source)) {
    final String kind = match.group(2)!;
    final String uri = match.group(4)!;
    final String rest = match.group(5) ?? '';
    final _DesignLibrary? library = _libraryFor(uri);
    if (library == null) {
      continue;
    }

    final String replacement = _rewriteDirective(
      kind: kind,
      rest: rest,
      library: library,
      state: state,
    );
    if (replacement.contains(library.packageUri)) {
      dependencies.add(library.dependency);
    }
    final String original = match.group(0)!;

    buffer
      ..write(source.substring(lastEnd, match.start))
      ..write(replacement);
    lastEnd = match.end;
    changed = changed || replacement != original;
  }

  if (lastEnd == 0) {
    return _RewriteResult(source: source);
  }

  buffer.write(source.substring(lastEnd));
  return _RewriteResult(changed: changed, dependencies: dependencies, source: buffer.toString());
}

Map<String, List<_DirectiveInfo>> _frameworkDirectives(String source, String kind) {
  final directives = <String, List<_DirectiveInfo>>{};
  for (final RegExpMatch match in _directivePattern.allMatches(source)) {
    if (match.group(2) != kind) {
      continue;
    }
    final String uri = match.group(4)!;
    if (_frameworkLibraryForUri(uri) == null) {
      continue;
    }
    directives
        .putIfAbsent(uri, () => <_DirectiveInfo>[])
        .add(_DirectiveInfo.parse(match.group(5) ?? ''));
  }
  return directives;
}

_DesignLibrary? _libraryFor(String uri) {
  for (final _DesignLibrary library in _designLibraries) {
    if (uri == library.legacyUri || uri == library.packageUri) {
      return library;
    }
  }
  return null;
}

String _rewriteDirective({
  required String kind,
  required String rest,
  required _DesignLibrary library,
  required _RewriteState state,
}) {
  final info = _DirectiveInfo.parse(rest);
  final List<String> effectiveShowNames = _effectiveShowNames(info);
  if (effectiveShowNames.isNotEmpty) {
    return _rewriteShowDirective(kind, library, info, effectiveShowNames, state);
  }

  if (info.hideNames.isNotEmpty) {
    return _rewriteHideDirective(kind, library, info, state);
  }

  final directives = <String>[];
  final Map<String, Set<String>> requiredFrameworkNames = info.prefix == null
      ? state.frameworkUsage
      : state.frameworkUsageForPrefix(info.prefix!);
  final bool needsFrameworkDirective = kind == 'export' || requiredFrameworkNames.isNotEmpty;
  if (needsFrameworkDirective) {
    directives.addAll(
      _takeFrameworkDirectives(
        kind,
        state,
        prefix: info.prefix,
        requiredNames: requiredFrameworkNames,
        includeAll: kind == 'export',
      ),
    );
  }
  directives.add(_formatDirective(kind, library.packageUri, prefix: info.prefix));
  return directives.join('\n');
}

String _rewriteShowDirective(
  String kind,
  _DesignLibrary library,
  _DirectiveInfo info,
  List<String> names,
  _RewriteState state,
) {
  final frameworkNames = <String>[];
  final designNames = <String>[];
  for (final name in names) {
    if (_frameworkSymbols.contains(name)) {
      frameworkNames.add(name);
    } else {
      designNames.add(name);
    }
  }

  final directives = <String>[];
  if (frameworkNames.isNotEmpty) {
    directives.addAll(
      _takeFrameworkDirectives(
        kind,
        state,
        prefix: info.prefix,
        showNames: _groupFrameworkNames(frameworkNames),
      ),
    );
  }
  if (designNames.isNotEmpty) {
    directives.add(
      _formatDirective(kind, library.packageUri, prefix: info.prefix, showNames: designNames),
    );
  }
  return directives.join('\n');
}

String _rewriteHideDirective(
  String kind,
  _DesignLibrary library,
  _DirectiveInfo info,
  _RewriteState state,
) {
  final frameworkHidden = <String>[];
  final designHidden = <String>[];
  for (final String name in info.hideNames) {
    if (_frameworkSymbols.contains(name)) {
      frameworkHidden.add(name);
    } else {
      designHidden.add(name);
    }
  }

  final directives = <String>[];
  final Map<String, Set<String>> requiredFrameworkNames = info.prefix == null
      ? state.frameworkUsage
      : state.frameworkUsageForPrefix(info.prefix!);
  if (kind == 'export' || requiredFrameworkNames.isNotEmpty) {
    directives.addAll(
      _takeFrameworkDirectives(
        kind,
        state,
        prefix: info.prefix,
        requiredNames: requiredFrameworkNames,
        hideNames: _groupFrameworkNames(frameworkHidden),
        includeAll: kind == 'export',
      ),
    );
  }
  directives.add(
    _formatDirective(kind, library.packageUri, prefix: info.prefix, hideNames: designHidden),
  );
  return directives.join('\n');
}

List<String> _takeFrameworkDirectives(
  String kind,
  _RewriteState state, {
  String? prefix,
  Map<String, Set<String>> requiredNames = const <String, Set<String>>{},
  Map<String, List<String>> showNames = const <String, List<String>>{},
  Map<String, List<String>> hideNames = const <String, List<String>>{},
  bool includeAll = false,
}) {
  final _FrameworkDirectiveTrackers trackers = kind == 'import'
      ? state.frameworkImports
      : state.frameworkExports;
  final directives = <String>[];
  for (final _FrameworkLibrary library in _frameworkLibraries) {
    final Set<String> required = requiredNames[library.uri] ?? const <String>{};
    final List<String> show = showNames[library.uri] ?? const <String>[];
    final List<String> hide = hideNames[library.uri] ?? const <String>[];
    if (kind == 'import' && required.isEmpty && show.isEmpty) {
      continue;
    }
    if (!includeAll && required.isEmpty && show.isEmpty && hide.isEmpty) {
      continue;
    }
    final String? directive = trackers.take(
      kind,
      library.uri,
      prefix: prefix,
      requiredNames: required.toList(),
      showNames: show,
      hideNames: hide,
    );
    if (directive != null) {
      directives.add(directive);
    }
  }
  return directives;
}

String _formatDirective(
  String kind,
  String uri, {
  String? prefix,
  List<String> showNames = const <String>[],
  List<String> hideNames = const <String>[],
}) {
  final combinators = <String>[];
  if (showNames.isNotEmpty) {
    combinators.add('show ${showNames.join(', ')}');
  }
  if (hideNames.isNotEmpty) {
    combinators.add('hide ${hideNames.join(', ')}');
  }
  if (combinators.isEmpty) {
    return "$kind '$uri'${prefix == null ? '' : ' as $prefix'};";
  }
  if (showNames.length + hideNames.length == 1) {
    return "$kind '$uri'${prefix == null ? '' : ' as $prefix'} ${combinators.join(' ')};";
  }
  return "$kind '$uri'${prefix == null ? '' : ' as $prefix'}\n    ${combinators.join(' ')};";
}

List<String> _parseCombinatorNames(RegExp pattern, String rest) {
  final RegExpMatch? match = pattern.firstMatch(rest);
  if (match == null) {
    return const <String>[];
  }
  return match
      .group(1)!
      .split(',')
      .map((String name) => name.trim())
      .where((String name) => name.isNotEmpty)
      .toList();
}

List<String> _effectiveShowNames(_DirectiveInfo info) {
  if (info.showNames.isEmpty) {
    return const <String>[];
  }
  return info.showNames.where((String name) => !info.hideNames.contains(name)).toList();
}

Map<String, Set<String>> _scanFrameworkUsage(String source) {
  final usage = <String, Set<String>>{};
  for (final String symbol in _frameworkSymbols) {
    if (RegExp('\\b${RegExp.escape(symbol)}\\b').hasMatch(source)) {
      final _FrameworkLibrary? library = _frameworkLibraryForSymbol(symbol);
      if (library != null) {
        usage.putIfAbsent(library.uri, () => <String>{}).add(symbol);
      }
    }
  }
  return usage;
}

Map<String, Set<String>> _scanPrefixedFrameworkUsage(String source, String prefix) {
  final usage = <String, Set<String>>{};
  for (final String symbol in _frameworkSymbols) {
    if (RegExp(
      '\\b${RegExp.escape(prefix)}\\s*\\.\\s*${RegExp.escape(symbol)}\\b',
    ).hasMatch(source)) {
      final _FrameworkLibrary? library = _frameworkLibraryForSymbol(symbol);
      if (library != null) {
        usage.putIfAbsent(library.uri, () => <String>{}).add(symbol);
      }
    }
  }
  return usage;
}

Map<String, List<String>> _groupFrameworkNames(Iterable<String> names) {
  final grouped = <String, List<String>>{};
  for (final name in names) {
    final _FrameworkLibrary? library = _frameworkLibraryForSymbol(name);
    if (library != null) {
      grouped.putIfAbsent(library.uri, () => <String>[]).add(name);
    }
  }
  return grouped;
}

_FrameworkLibrary? _frameworkLibraryForSymbol(String symbol) {
  for (final _FrameworkLibrary library in _frameworkLibraries) {
    if (library.symbols.contains(symbol)) {
      return library;
    }
  }
  return null;
}

_FrameworkLibrary? _frameworkLibraryForUri(String uri) {
  for (final _FrameworkLibrary library in _frameworkLibraries) {
    if (library.uri == uri) {
      return library;
    }
  }
  return null;
}

String _maskCommentsAndStrings(String source) {
  final buffer = StringBuffer();
  var index = 0;
  while (index < source.length) {
    if (source.startsWith('//', index)) {
      final int end = source.indexOf('\n', index);
      if (end == -1) {
        buffer.write(' ' * (source.length - index));
        break;
      }
      buffer
        ..write(' ' * (end - index))
        ..write('\n');
      index = end + 1;
      continue;
    }
    if (source.startsWith('/*', index)) {
      final int end = source.indexOf('*/', index + 2);
      final int commentEnd = end == -1 ? source.length : end + 2;
      buffer.write(source.substring(index, commentEnd).replaceAll(RegExp(r'[^\n]'), ' '));
      index = commentEnd;
      continue;
    }
    final String char = source[index];
    if (char == "'" || char == '"') {
      final bool triple = source.startsWith(char * 3, index);
      final String delimiter = triple ? char * 3 : char;
      final start = index;
      index += delimiter.length;
      while (index < source.length) {
        if (!triple && source[index] == r'\') {
          index += 2;
          continue;
        }
        if (source.startsWith(delimiter, index)) {
          index += delimiter.length;
          break;
        }
        index += 1;
      }
      buffer.write(source.substring(start, index).replaceAll(RegExp(r'[^\n]'), ' '));
      continue;
    }
    buffer.write(char);
    index += 1;
  }
  return buffer.toString();
}

bool _updatePubspec(Directory root, Set<String> dependencies) {
  if (dependencies.isEmpty) {
    return false;
  }
  final file = File('${root.path}/pubspec.yaml');
  if (!file.existsSync()) {
    return false;
  }

  String source = file.readAsStringSync();
  final List<String> missing =
      dependencies
          .where(
            (String dependency) =>
                !RegExp('^  ${RegExp.escape(dependency)}:', multiLine: true).hasMatch(source),
          )
          .toList()
        ..sort();
  if (missing.isEmpty) {
    return false;
  }

  final String lines = missing.map((String dependency) => '  $dependency: any').join('\n');
  final RegExpMatch? dependenciesMatch = RegExp(
    r'^dependencies:\s*$',
    multiLine: true,
  ).firstMatch(source);
  if (dependenciesMatch == null) {
    source = source.trimRight();
    source = '$source\n\ndependencies:\n$lines\n';
    file.writeAsStringSync(source);
    return true;
  }

  RegExpMatch? nextSection;
  for (final RegExpMatch match in _topLevelSectionPattern.allMatches(
    source,
    dependenciesMatch.end,
  )) {
    nextSection = match;
    break;
  }
  final int insertOffset = nextSection?.start ?? source.length;
  final String prefix = source.substring(0, insertOffset).trimRight();
  final String suffix = source.substring(insertOffset);
  source = '$prefix\n$lines\n$suffix';
  file.writeAsStringSync(source);
  return true;
}

/// The result of a Material/Cupertino package migration run.
class MigrationResult {
  /// Creates a migration result.
  const MigrationResult({required this.changedDartFiles, required this.changedPubspecs});

  /// The number of Dart files rewritten by the migration.
  final int changedDartFiles;

  /// The number of pubspec files updated by the migration.
  final int changedPubspecs;
}

class _DirectiveInfo {
  const _DirectiveInfo({required this.prefix, required this.showNames, required this.hideNames});

  factory _DirectiveInfo.parse(String rest) {
    return _DirectiveInfo(
      prefix: _asPattern.firstMatch(rest)?.group(1),
      showNames: _parseCombinatorNames(_showPattern, rest),
      hideNames: _parseCombinatorNames(_hidePattern, rest),
    );
  }

  final String? prefix;
  final List<String> showNames;
  final List<String> hideNames;

  bool allows(String symbol) {
    if (showNames.isNotEmpty && !showNames.contains(symbol)) {
      return false;
    }
    return !hideNames.contains(symbol);
  }
}

class _FrameworkDirectiveTrackers {
  _FrameworkDirectiveTrackers(Map<String, List<_DirectiveInfo>> existing)
    : _trackers = <String, _FrameworkDirectiveTracker>{
        for (final _FrameworkLibrary library in _frameworkLibraries)
          library.uri: _FrameworkDirectiveTracker(
            existing[library.uri] ?? const <_DirectiveInfo>[],
          ),
      };

  final Map<String, _FrameworkDirectiveTracker> _trackers;

  String? take(
    String kind,
    String uri, {
    String? prefix,
    List<String> requiredNames = const <String>[],
    List<String> showNames = const <String>[],
    List<String> hideNames = const <String>[],
  }) {
    return _trackers[uri]?.take(
      kind,
      uri,
      prefix: prefix,
      requiredNames: requiredNames,
      showNames: showNames,
      hideNames: hideNames,
    );
  }
}

class _FrameworkDirectiveTracker {
  _FrameworkDirectiveTracker(List<_DirectiveInfo> existing)
    : _directives = <_DirectiveInfo>[...existing];

  final List<_DirectiveInfo> _directives;

  String? take(
    String kind,
    String uri, {
    String? prefix,
    List<String> requiredNames = const <String>[],
    List<String> showNames = const <String>[],
    List<String> hideNames = const <String>[],
  }) {
    if (showNames.isNotEmpty) {
      final List<String> missing = showNames.where((String name) => !allows(prefix, name)).toList();
      if (missing.isEmpty) {
        return null;
      }
      _directives.add(
        _DirectiveInfo(prefix: prefix, showNames: missing, hideNames: const <String>[]),
      );
      return _formatDirective(kind, uri, prefix: prefix, showNames: missing);
    }

    if (hideNames.isNotEmpty) {
      if (hasBroad(prefix)) {
        return null;
      }
      _directives.add(
        _DirectiveInfo(prefix: prefix, showNames: const <String>[], hideNames: hideNames),
      );
      return _formatDirective(kind, uri, prefix: prefix, hideNames: hideNames);
    }

    if (hasBroad(prefix)) {
      return null;
    }
    final List<String> missing =
        requiredNames.where((String name) => !allows(prefix, name)).toList()..sort();
    if (_hasDirectiveForPrefix(prefix) && missing.isEmpty) {
      return null;
    }
    if (_hasDirectiveForPrefix(prefix)) {
      _directives.add(
        _DirectiveInfo(prefix: prefix, showNames: missing, hideNames: const <String>[]),
      );
      return _formatDirective(kind, uri, prefix: prefix, showNames: missing);
    }
    _directives.add(
      _DirectiveInfo(prefix: prefix, showNames: const <String>[], hideNames: const <String>[]),
    );
    return _formatDirective(kind, uri, prefix: prefix);
  }

  bool allows(String? prefix, String symbol) {
    return _directives.any(
      (_DirectiveInfo directive) => directive.prefix == prefix && directive.allows(symbol),
    );
  }

  bool hasBroad(String? prefix) {
    return _directives.any(
      (_DirectiveInfo directive) =>
          directive.prefix == prefix && directive.showNames.isEmpty && directive.hideNames.isEmpty,
    );
  }

  bool _hasDirectiveForPrefix(String? prefix) {
    return _directives.any((_DirectiveInfo directive) => directive.prefix == prefix);
  }
}

class _DesignLibrary {
  const _DesignLibrary({
    required this.dependency,
    required this.legacyUri,
    required this.packageUri,
  });

  final String dependency;
  final String legacyUri;
  final String packageUri;
}

class _FrameworkLibrary {
  const _FrameworkLibrary({required this.uri, required this.symbols});

  final String uri;
  final Set<String> symbols;
}

class _RewriteState {
  _RewriteState({
    required Map<String, List<_DirectiveInfo>> frameworkImports,
    required Map<String, List<_DirectiveInfo>> frameworkExports,
    required this.frameworkUsage,
    required this.maskedSource,
  }) : frameworkImports = _FrameworkDirectiveTrackers(frameworkImports),
       frameworkExports = _FrameworkDirectiveTrackers(frameworkExports);

  final _FrameworkDirectiveTrackers frameworkImports;
  final _FrameworkDirectiveTrackers frameworkExports;
  final Map<String, Set<String>> frameworkUsage;
  final String maskedSource;
  final Map<String, Map<String, Set<String>>> _frameworkUsageByPrefix =
      <String, Map<String, Set<String>>>{};

  Map<String, Set<String>> frameworkUsageForPrefix(String prefix) {
    return _frameworkUsageByPrefix.putIfAbsent(
      prefix,
      () => _scanPrefixedFrameworkUsage(maskedSource, prefix),
    );
  }
}

class _RewriteResult {
  const _RewriteResult({
    required this.source,
    this.changed = false,
    this.dependencies = const <String>{},
  });

  final bool changed;
  final Set<String> dependencies;
  final String source;
}
