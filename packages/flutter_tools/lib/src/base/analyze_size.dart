// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:meta/meta.dart';
import 'package:vm_snapshot_analysis/treemap.dart';

import '../base/file_system.dart';
import '../convert.dart';
import '../globals.dart' as globals;

class SizeAnalyzer {
  static const String aotSizeFileName = 'aot-size.json';

  static String aotSizeAnalysisJsonFile(String aotOutputPath) {
    return globals.fs.path.join(aotOutputPath, aotSizeFileName);
  }

  static String aotSizeAnalysisExtraGenSnapshotOption(String aotOutputPath) {
    return '--print-instructions-sizes-to=${aotSizeAnalysisJsonFile(aotOutputPath)}';
  }

  static const int tableWidth = 80;

  Map<String, dynamic> analyzeApkSize({
    @required File apk,
    @required File aotSizeJson,
  }) {
    globals.printStatus('▒' * tableWidth);
    _printEntitySize(
      '${apk.basename} (total compressed)',
      apk.lengthSync(),
      0,
      showColor: false,
    );
    globals.printStatus('━' * tableWidth);
    final Directory tempApkContent = globals.fs.systemTempDirectory.createTempSync('flutter_tools.');
    // TODO: implement Windows.
    String unzipOut;
    try {
      unzipOut = processUtils.runSync(<String>[
        'unzip',
        '-o',
        '-v',
        apk.path,
        '-d',
        tempApkContent.path
      ]).stdout;
    } on Exception catch (e) {
      print(e);
    } finally {
      // We just want the the stdout printout. We don't need the files.
      tempApkContent.deleteSync(recursive: true);
    }

    final SymbolNode apkAnalysisRoot = _parseUnzipFile(unzipOut);

    for (final SymbolNode firstLevelPath in apkAnalysisRoot.children) {
      _printEntitySize(
        firstLevelPath.name,
        firstLevelPath.value,
        1,
      );
      if (firstLevelPath.name == 'lib') {
        _printLibDetails(firstLevelPath, '', aotSizeJson);
      }
    }

    globals.printStatus('▒' * tableWidth);
    
    Map<String, dynamic> apkAnalysisJson = apkAnalysisRoot.toJson();
    
    // TODO(peterdjlee): Add aot size for all platforms.
    apkAnalysisJson = addAotSizeDataToJson(
      apkAnalysisJson,
      'lib/arm64-v8a/libapp.so (Dart AOT)'.split('/'), 
      json.decode(aotSizeJson.readAsStringSync()) as List<dynamic>,
    );

    return apkAnalysisJson;
  }

  // Parse the output of unzip -v which shows the zip's contents' compressed sizes.
  // Example output of unzip -v:
  //  Length   Method    Size  Cmpr    Date    Time   CRC-32   Name
  // --------  ------  ------- ---- ---------- ----- --------  ----
  //    11708  Defl:N     2592  78% 00-00-1980 00:00 07733eef  AndroidManifest.xml
  //     1399  Defl:N     1092  22% 00-00-1980 00:00 f53d952a  META-INF/CERT.RSA
  //    46298  Defl:N    14530  69% 00-00-1980 00:00 17df02b8  META-INF/CERT.SF

  final RegExp _parseUnzipOutput = RegExp(r'^\s*\d+\s+[\w|:]+\s+(\d+)\s+.*  (.+)$');

  SymbolNode _parseUnzipFile(String unzipOut) {
    final Map<List<String>, int> pathsToSize = <List<String>, int>{};

    // Parse each path into pathsToSize so that the key is a list of
    // path parts and the value is the size.
    // For example:
    // 'path/to/file' where file = 1500 => pathsToSize[['path', 'to', 'file']] = 1500
    for (final String line in const LineSplitter().convert(unzipOut)) {
      final RegExpMatch match = _parseUnzipOutput.firstMatch(line);
      if (match == null) {
        continue;
      }
      pathsToSize[match.group(2).split('/')] = int.parse(match.group(1));
    }

    final SymbolNode rootNode = SymbolNode('Root');

    SymbolNode currentNode = rootNode;
    for (final List<String> paths in pathsToSize.keys) {
      for (final String path in paths) {
        SymbolNode childWithPathAsName = currentNode.childByName(path);

        if (childWithPathAsName == null) {
          childWithPathAsName = SymbolNode(path);

          if (path.endsWith('libapp.so')) {
            childWithPathAsName.name += ' (Dart AOT)';
          } else if (path.endsWith('libflutter.so')) {
            childWithPathAsName.name += ' (Flutter Engine)';
          }
          currentNode.addChild(childWithPathAsName);
        }
        childWithPathAsName.addValue(pathsToSize[paths]);
        currentNode = childWithPathAsName;
      }
      currentNode = rootNode;
    }

    return rootNode;
  }

  /// Prints the paths from currentNode all leaf nodes.
  void _printLibDetails(
    SymbolNode currentNode,
    String totalPath,
    File aotSizeJson,
  ) {
    totalPath += currentNode.name;

    if (currentNode.children.isNotEmpty && !currentNode.name.contains('libapp.so')) {
      for (final SymbolNode child in currentNode.children) {
        _printLibDetails(child, totalPath + '/', aotSizeJson);
      }
    } else {
      // Print total path and size if currentPath does not have any chilren.
      _printEntitySize(totalPath, currentNode.value, 2);

      const String libappPath = 'lib/arm64-v8a/libapp.so';
      // TODO(peterdjlee): Analyze aot size for all platforms.
      if (totalPath.contains(libappPath)) {
        _printAotSizeDetails(aotSizeJson);
      }
    }
  }

  /// Go through the AOT gen snapshot size JSON and print out a collapsed summary
  /// for the first package level.
  void _printAotSizeDetails(File aotSizeJson) {
    final SymbolNode root = _parseSymbols(
      json.decode(aotSizeJson.readAsStringSync()) as List<dynamic>,
    );

    final int totalSymbolSize = root.children.fold(
      0,
      (int previousValue, SymbolNode element) => previousValue + element.value,
    );

    _printEntitySize(
      'Dart AOT symbols accounted decompressed size',
      totalSymbolSize,
      3,
    );

    final List<SymbolNode> sortedSymbols = root.children.toList()
      ..sort((SymbolNode a, SymbolNode b) => b.value.compareTo(a.value));
    for (final SymbolNode node in sortedSymbols.take(10)) {
      _printEntitySize(node.name, node.value, 4);
    }
  }

  /// Adds breakdown of aot size data as the children of the node at the given path.
  Map<String, dynamic> addAotSizeDataToJson(
    Map<String, dynamic> apkAnalysisJson,
    List<String> path, 
    List<dynamic> aotSizeJson,
  ) {
    Map<String, dynamic> currentLevel = apkAnalysisJson;
    while (path.isNotEmpty) {
      final List<Map<String, dynamic>> children = currentLevel['children'] as List<Map<String, dynamic>>;
      final Map<String, dynamic> childWithPathAsName = children.firstWhere(
        (Map<String, dynamic> child) => child['n'] as String == path.first,
      );
      path.removeAt(0);
      currentLevel = childWithPathAsName;
    }
    currentLevel['children'] = treemapFromJson(aotSizeJson)['children'];
    return apkAnalysisJson;
  }

  /// A pretty printer for an entity with a size.
  void _printEntitySize(
    String entityName,
    int numBytes,
    int level, {
    bool showColor = true,
    }) {
    final bool emphasis = level <= 1;
    final String formattedSize = _prettyPrintBytes(numBytes);

    TerminalColor color = TerminalColor.green;
    if (formattedSize.endsWith('MB')) {
      color = TerminalColor.cyan;
    } else if (formattedSize.endsWith('KB')) {
      color = TerminalColor.yellow;
    }

    final int spaceInBetween = tableWidth - level * 2 - entityName.length - formattedSize.length;
    globals.printStatus(
      entityName + ' ' * spaceInBetween,
      newline: false,
      emphasis: emphasis,
      indent: level * 2,
    );
    globals.printStatus(formattedSize, color: showColor ? color : null);
  }

  String _prettyPrintBytes(int numBytes) {
    const int kB = 1024;
    const int mB = kB * 1024;
    if (numBytes < kB) {
      return '$numBytes B';
    } else if (numBytes < mB) {
      return '${(numBytes / kB).round()} KB';
    } else {
      return '${(numBytes / mB).round()} MB';
    }
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
  String name;

  int _value;
  int get value {
    _value ??= children.fold(
      0,
      (int accumulator, SymbolNode node) => accumulator + node.value,
    );
    return _value;
  }

  void addValue(int valueToBeAdded) {
    _value += valueToBeAdded;
  }

  SymbolNode get parent => _parent;
  SymbolNode _parent;

  Iterable<SymbolNode> get children => _children.values;
  final Map<String, SymbolNode> _children;

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

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{
      'n': name,
      'value': _value
    };
    final List<Map<String, dynamic>> childrenAsJson = <Map<String, dynamic>>[];
    for (final SymbolNode child in children) {
      childrenAsJson.add(child.toJson());
    }
    if (childrenAsJson.isNotEmpty) {
      json['children'] = childrenAsJson;
    }
    return json;
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
      if (className?.isNotEmpty ?? false) className,
      name,
    ];
  }
}
