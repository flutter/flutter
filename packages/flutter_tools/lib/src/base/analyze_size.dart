import 'dart:convert';

import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';
import 'package:vm_snapshot_analysis/treemap.dart';

import '../base/file_system.dart';
import '../globals.dart' as globals;

// This file can be in devtools_shared
class SizeAnalyzer {
  static const String kAotSizeJson = 'aot-size.json';

  static String getAotSizeAnalysisJsonFile(String aotOutputPath) {
    return globals.fs.path.join(aotOutputPath, kAotSizeJson);
  }

  static String getAotSizeAnalysisExtraGenSnapshotOption(String aotOutputPath) {
    return '--print-instructions-sizes-to=${getAotSizeAnalysisJsonFile(aotOutputPath)}';
  }

  // Parse the output of unzip -v which shows the zip's contents' compressed sizes.
  final RegExp _kGetUnzipOutput =
      RegExp(r'^\s*\d+\s+[\w|:]+\s+(\d+)\s+.*  (.+)$');

  Map<String, dynamic> analyzeApkSize(
      {@required File apk, @required File aotSizeJson}) {
    globals.printStatus('▒' * 80);
    _printEntitySize(
      '${apk.basename} (total compressed)',
      apk.lengthSync() ~/ 1024,
      0,
    );
    globals.printStatus('━' * 80);
    final Directory tempApkContent = globals.fs.systemTempDirectory.createTempSync('flutter_tools.');
    // TODO: implement Windows.
    final String unzipOut = processUtils.runSync(<String>[
      'unzip',
      '-o',
      '-v',
      apk.path,
      '-d',
      tempApkContent.path
    ]).stdout;
    // We just want the the stdout printout. We don't need the files.
    tempApkContent.deleteSync(recursive: true);

    final Map<String, dynamic> apkAnalysisJson = _parseUnzipFile(
      unzipOut,
      json.decode(aotSizeJson.readAsStringSync()) as List<dynamic>,
    );

    final List<Map<String, dynamic>> firstLevelPaths = apkAnalysisJson['children'] as List<Map<String, dynamic>>;

    // Print all first level paths and their total sizes.
    // Expand 'lib' path to print a level deeper.
    for (final Map<String, dynamic> firstLevelPath in firstLevelPaths) {
      final String name = firstLevelPath['n'] as String;
      _printEntitySize(
        name,
        (firstLevelPath['value'] as int) ~/ 1024,
        1,
      );
      if (name == 'lib') {
        _printLibDetails(firstLevelPath, '', aotSizeJson);
      }
    }

    globals.printStatus('▒' * 80);

    return apkAnalysisJson;
  }

  Map<String, dynamic> _parseUnzipFile(
    String unzipOut,
    List<dynamic> aotSizeJson,
  ) {
    final Map<List<String>, int> pathsToSize = <List<String>, int>{};

    // Parse each path into pathsToSize so that the key is a list of
    // path parts and the value is the size.
    // For example:
    // 'path/to/file' where file = 1500 => pathsToSize[['path', 'to', 'file']] = 1500
    for (final String line in const LineSplitter().convert(unzipOut)) {
      final RegExpMatch match = _kGetUnzipOutput.firstMatch(line);
      if (match == null) {
        continue;
      }
      pathsToSize[match.group(2).split('/')] = int.parse(match.group(1));
    }

    final Map<String, dynamic> root = <String, dynamic>{'n': '', 'type': 'apk'};

    Map<String, dynamic> currentLevel = root;
    // Parse through pathsToSize to create a map object with tree-like structure.
    for (final List<String> paths in pathsToSize.keys) {
      for (final String path in paths) {
        if (!currentLevel.containsKey('children')) {
          currentLevel['children'] = <Map<String, dynamic>>[];
        }

        // TODO(peterdjlee): Optimize children look up time to O(1) by using a
        // set instead of a list for children field.
        Map<String, dynamic> childWithPathAsName =
            currentLevel['children'].firstWhere(
          (Map<String, dynamic> child) => child['n'] == path,
          orElse: () => null,
        ) as Map<String, dynamic>;

        if (childWithPathAsName == null) {
          childWithPathAsName = <String, dynamic>{'n': path, 'value': 0};

          if (path.endsWith('libapp.so')) {
            childWithPathAsName['n'] += ' (Dart AOT)';
          } else if (path.endsWith('libflutter.so')) {
            childWithPathAsName['n'] += ' (Flutter Engine)';
          }

          // TODO(peterdjlee): Include corresponding aot size data for all 3 platforms.
          // Convert aotSizeJson to a tree-like structure and include it as children of libapp.so.
          if (paths.contains('arm64-v8a') && path == 'libapp.so') {
            childWithPathAsName['children'] = treemapFromJson(aotSizeJson)['children'];
          }
          currentLevel['children'].add(childWithPathAsName);
        }
        childWithPathAsName['value'] += pathsToSize[paths];
        currentLevel = childWithPathAsName;
      }
      currentLevel = root;
    }
    return root;
  }

  // Prints all the paths from level to
  void _printLibDetails(
    Map<String, dynamic> currentPath,
    String totalPath,
    File aotSizeJson,
  ) {
    final String name = currentPath['n'] as String;
    totalPath += name;

    if (currentPath.containsKey('children') && !name.contains('libapp.so')) {
      for (final Map<String, dynamic> child
          in currentPath['children'] as List<Map<String, dynamic>>) {
        _printLibDetails(child, totalPath + '/', aotSizeJson);
      }
    } else {
      // Print total path and size if currentPath does not have any chilren.
      _printEntitySize(totalPath, (currentPath['value'] as int) ~/ 1024, 2);
      if (totalPath.contains('lib/arm64-v8a/libapp.so')) {
        _analyzeAotSize(aotSizeJson);
      }
    }
  }

  // Go through the AOT gen snapshot size JSON and print out a collapsed summary
  // for the first package level.
  void _analyzeAotSize(File aotSizeJson) {
    final SymbolNode root = _parseSymbols(
      json.decode(aotSizeJson.readAsStringSync()) as List<dynamic>,
    );

    final int totalSymbolSize = root.children.fold(
      0,
      (int previousValue, SymbolNode element) => previousValue + element.value,
    );

    _printEntitySize(
      'Dart AOT symbols accounted decompressed size',
      totalSymbolSize ~/ 1024,
      3,
    );

    final List<SymbolNode> sortedSymbols = root.children.toList()
      ..sort((SymbolNode a, SymbolNode b) => b.value.compareTo(a.value));
    for (final SymbolNode node in sortedSymbols.take(10)) {
      _printEntitySize(node.name, node.value ~/ 1024, 4);
    }
  }

  final NumberFormat numberFormat = NumberFormat('#,###,###');

  // A pretty printer for an entity with a size.
  void _printEntitySize(String entityName, int sizeInKb, int level) {
    const int tableWidth = 80;
    final bool emphasis = level <= 1;
    final TerminalColor color = level == 0
        ? null
        : level == 1
            ? TerminalColor.blue
            : level == 2
                ? TerminalColor.green
                : level == 3 ? TerminalColor.red : TerminalColor.yellow;
    final String formattedSize = '${numberFormat.format(sizeInKb)}kB';
    final int spaceInBetween = tableWidth - level * 2 - entityName.length - formattedSize.length;
    globals.printStatus(
      entityName + ' ' * spaceInBetween,
      newline: false,
      emphasis: emphasis,
      indent: level * 2,
    );
    globals.printStatus(formattedSize, color: color);
  }
}

class SymbolNode {
  SymbolNode(
    this.name, {
    int value = 0,
  })  : assert(name != null),
        assert(value != null),
        _children = <String, SymbolNode>{},
        _value = value;

  /// The human friendly identifier for this node.
  final String name;

  int _value;
  int get value {
    _value ??= children.fold(
      0,
      (int accumulator, SymbolNode node) => accumulator + node.value,
    );
    return _value;
  }

  SymbolNode _parent;
  SymbolNode get parent => _parent;

  final Map<String, SymbolNode> _children;

  Iterable<SymbolNode> get children => _children.values;

  SymbolNode childByName(String name) => _children[name];

  SymbolNode addChild(SymbolNode child) {
    assert(child.parent == null);
    assert(!_children.containsKey(child.name),
        'Cannot add duplicate child key ${child.name}');

    child._parent = this;
    _children[child.name] = child;
    SymbolNode ancestor = this;
    while (ancestor != null) {
      ancestor._value += child.value;
      ancestor = ancestor.parent;
    }
    return child;
  }

  List<SymbolNode> get ancestors {
    final List<SymbolNode> nodes = <SymbolNode>[];
    SymbolNode current = this;
    while (current.parent != null) {
      nodes.add(current.parent);
      current = current.parent;
    }
    return nodes;
  }

  bool get isLeaf => _children.isEmpty;

  Iterable<SymbolNode> get siblings {
    final List<SymbolNode> result = <SymbolNode>[];
    if (parent == null) {
      return result;
    }
    for (final SymbolNode sibling in parent.children) {
      if (sibling != this) {
        result.add(sibling);
      }
    }
    return result;
  }
}

SymbolNode _parseSymbols(List<dynamic> symbols) {
  final Iterable<Symbol> iter =
      symbols.cast<Map<String, dynamic>>().map(Symbol.fromMap);
  final SymbolNode root = SymbolNode('root');
  SymbolNode currentParent = root;
  for (final Symbol symbol in iter) {
    final SymbolNode parentReset = currentParent;
    for (final String pathPart in symbol.parts.take(symbol.parts.length - 1)) {
      currentParent = currentParent.childByName(pathPart) ??
          currentParent.addChild(SymbolNode(pathPart));
    }
    // TODO: this shouldn't be necessary, https://github.com/dart-lang/sdk/issues/41137
    String leafName = symbol.parts.last;
    int duplicates = 0;
    while (currentParent.childByName(leafName) != null) {
      duplicates += 1;
      leafName = '${symbol.parts.last}_$duplicates';
    }
    currentParent.addChild(
      SymbolNode(leafName, value: symbol.size),
    );
    currentParent = parentReset;
  }
  return root;
}

class Symbol {
  const Symbol({
    @required this.name,
    @required this.size,
    this.libraryUri,
    this.className,
  })  : assert(name != null),
        assert(size != null);

  static Symbol fromMap(Map<String, dynamic> json) {
    return Symbol(
      name: (json['n'] as String).replaceAll('[Optimized] ', ''),
      size: json['s'] as int,
      className: json['c'] as String,
      libraryUri: json['l'] as String,
    );
  }

  final String name;
  final int size;
  final String libraryUri;
  final String className;

  List<String> get parts {
    return <String>[
      if (libraryUri != null) ...libraryUri.split('/') else '@stubs',
      if (className != null && className.isNotEmpty) className,
      name,
    ];
  }
}
