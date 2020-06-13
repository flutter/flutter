import 'dart:convert';

import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

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

  final RegExp _kGetDuOutput = RegExp(r'(\d+)');
  final RegExp _kGetUnzipOutput =
      RegExp(r'^\s*\d+\s+[\w|:]+\s+(\d+)\s+.*  (.+)$');

  void analyzeApkSize({@required File apk, @required File aotSizeJson}) {
    globals.printStatus('▒' * 80);
    _printEntrySize(
        '${apk.basename} (total compressed)', apk.lengthSync() ~/ 1024, 0);
    globals.printStatus('━' * 80);
    final Directory tempApkContent =
        globals.fs.systemTempDirectory.createTempSync('flutter_tools.');
    // TODO: implement Windows.
    final String unzipOut = processUtils.runSync(<String>[
      'unzip',
      '-o',
      '-v',
      apk.path,
      '-d',
      tempApkContent.path
    ]).stdout;
    final Map<String, int> collapsedPathsToSizes =
        _parseUnzipFileList(unzipOut);

    bool shownAotBreakdown = false;
    for (final String path in collapsedPathsToSizes.keys) {
      _printEntrySize(
        path,
        collapsedPathsToSizes[path] ~/ 1024,
        path.startsWith('lib/') ? 2 : 1);
      if (path.endsWith('(Dart AOT)') && !shownAotBreakdown) {
        _analyzeAotSize(aotSizeJson);
        shownAotBreakdown = true;
      }
    }

    globals.printStatus('▒' * 80);
  }

  void _analyzeAotSize(File aotSizeJson) {
    final SymbolNode root = _parseSymbols(
        json.decode(aotSizeJson.readAsStringSync()) as List<dynamic>);
    final int totalSymbolSize = root.children.fold(
        0,
        (int previousValue, SymbolNode element) =>
            previousValue + element.value);
    _printEntrySize(
        'Dart AOT symbols accounted decompressed size', totalSymbolSize ~/ 1024, 3);
    final List<SymbolNode> sortedSymbols = root.children.toList()
      ..sort((SymbolNode a, SymbolNode b) => b.value.compareTo(a.value));
    for (final SymbolNode node in sortedSymbols.take(10)) {
      _printEntrySize(node.name, node.value ~/ 1024, 4);
    }
  }

  final NumberFormat numberFormat = NumberFormat('#,###,###');
  void _printEntrySize(String entityName, int sizeInKb, int level) {
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
    final int spaceInBetween =
        tableWidth - level * 2 - entityName.length - formattedSize.length;
    globals.printStatus(entityName + ' ' * spaceInBetween,
        newline: false, emphasis: emphasis, indent: level * 2);
    globals.printStatus(formattedSize, color: color);
  }

  Map<String, int> _parseUnzipFileList(String unzipOut) {
    Map<List<String>, int> pathsToSize = <List<String>, int>{};
    Map<String, int> collapsedPathsToSize = <String, int>{};
    for (final String line in const LineSplitter().convert(unzipOut)) {
      final RegExpMatch match = _kGetUnzipOutput.firstMatch(line);
      if (match == null) {
        continue;
      }
      pathsToSize[match.group(2).split('/')] = int.parse(match.group(1));
    }

    for (final List<String> paths in pathsToSize.keys) {
      final String firstDepthPath = paths[0];

      if (firstDepthPath == 'lib') {
        // Also sum up lib as well as showing all the shared libraries' sizes.
        if (collapsedPathsToSize['lib'] == null) {
          collapsedPathsToSize['lib'] = 0;
        }
        collapsedPathsToSize['lib'] += pathsToSize[paths];
        if (paths[paths.length - 1] == 'libflutter.so') {
          collapsedPathsToSize[paths.join('/') + ' (Flutter engine)'] =
              pathsToSize[paths];
        }
        if (paths[paths.length - 1] == 'libapp.so') {
          collapsedPathsToSize[paths.join('/') + ' (Dart AOT)'] =
              pathsToSize[paths];
        }
      } else {
        if (collapsedPathsToSize[firstDepthPath] == null) {
          collapsedPathsToSize[firstDepthPath] = 0;
        }
        collapsedPathsToSize[firstDepthPath] += pathsToSize[paths];
      }
    }
    return collapsedPathsToSize;
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
