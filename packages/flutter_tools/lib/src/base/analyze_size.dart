// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:meta/meta.dart';
import 'package:vm_snapshot_analysis/treemap.dart';

import '../base/file_system.dart';
import '../convert.dart';
import 'logger.dart';

/// A class to analyze APK and AOT snapshot and generate a breakdown of the data.
class SizeAnalyzer {
  SizeAnalyzer({
    @required this.fileSystem,
    @required this.logger,
    @required this.processUtils,
  });

  final FileSystem fileSystem;
  final Logger logger;
  final ProcessUtils processUtils;

  static const String aotSnapshotFileName = 'aot-snapshot.json';

  static const int tableWidth = 80;

  /// Analyzes [apk] and [aotSnapshot] to output a [Map] object that includes
  /// the breakdown of the both files, where the breakdown of [aotSnapshot] is placed
  /// under 'lib/arm64-v8a/libapp.so'.
  /// 
  /// The [aotSnapshot] can be either instruction sizes snapshot or v8 snapshot.
  Future<Map<String, dynamic>> analyzeApkSizeAndAotSnapshot({
    @required File apk,
    @required File aotSnapshot,
  }) async {
    logger.printStatus('▒' * tableWidth);
    _printEntitySize(
      '${apk.basename} (total compressed)',
      numBytes: apk.lengthSync(),
      level: 0,
      showColor: false,
    );
    logger.printStatus('━' * tableWidth);
    final Directory tempApkContent = fileSystem.systemTempDirectory.createTempSync('flutter_tools.');
    // TODO: implement Windows.
    String unzipOut;
    try {
      // TODO(peterdjlee): Use zipinfo instead of unzip.
      unzipOut = (await processUtils.run(<String>[
        'unzip',
        '-o',
        '-v',
        apk.path,
        '-d',
        tempApkContent.path
      ])).stdout;
    } on Exception catch (e) {
      print(e);
    } finally {
      // We just want the the stdout printout. We don't need the files.
      tempApkContent.deleteSync(recursive: true);
    }

    final SymbolNode apkAnalysisRoot = _parseUnzipFile(unzipOut);

    // Convert an AOT snapshot file into a map.
    final Map<String, dynamic> processedAotSnapshotJson = treemapFromJson(
      json.decode(aotSnapshot.readAsStringSync()),
    );
    final SymbolNode aotSnapshotJsonRoot = _parseAotSnapshot(processedAotSnapshotJson);

    for (final SymbolNode firstLevelPath in apkAnalysisRoot.children) {
      _printEntitySize(
        firstLevelPath.name,
        numBytes: firstLevelPath.value,
        level: 1,
      );
      if (firstLevelPath.name == 'lib') {
        _printLibChildrenPaths(firstLevelPath, '', aotSnapshotJsonRoot);
      }
    }

    logger.printStatus('▒' * tableWidth);
    
    Map<String, dynamic> apkAnalysisJson = apkAnalysisRoot.toJson();

    apkAnalysisJson['type'] = 'apk';
    
    // TODO(peterdjlee): Add aot snapshot for all platforms.
    apkAnalysisJson = _addAotSnapshotDataToApkAnalysis(
      apkAnalysisJson: apkAnalysisJson,
      path: 'lib/arm64-v8a/libapp.so (Dart AOT)'.split('/'), // Pass in a list of paths by splitting with '/'.
      aotSnapshotJson: processedAotSnapshotJson,
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
  SymbolNode _parseUnzipFile(String unzipOut) {
    final Map<List<String>, int> pathsToSize = <List<String>, int>{};

    // Parse each path into pathsToSize so that the key is a list of
    // path parts and the value is the size.
    // For example:
    // 'path/to/file' where file = 1500 => pathsToSize[['path', 'to', 'file']] = 1500
    for (final String line in const LineSplitter().convert(unzipOut)) {
      // Expression to match 'Size' column to group 1 and 'Name' column to group 2.
      final RegExp parseUnzipOutput = RegExp(r'^\s*\d+\s+[\w|:]+\s+(\d+)\s+.*  (.+)$');
      final RegExpMatch match = parseUnzipOutput.firstMatch(line);
      if (match == null) {
        continue;
      }
      const int sizeGroupIndex = 1;
      const int nameGroupIndex = 2;
      pathsToSize[match.group(nameGroupIndex).split('/')] = int.parse(match.group(sizeGroupIndex));
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

  /// Prints all children paths for the lib/ directory in an APK.
  /// 
  /// A brief summary of aot snapshot is printed under 'lib/arm64-v8a/libapp.so'.
  void _printLibChildrenPaths(
    SymbolNode currentNode,
    String totalPath,
    SymbolNode aotSnapshotJsonRoot,
  ) {
    totalPath += currentNode.name;

    if (currentNode.children.isNotEmpty && !currentNode.name.contains('libapp.so')) {
      for (final SymbolNode child in currentNode.children) {
        _printLibChildrenPaths(child, '$totalPath/', aotSnapshotJsonRoot);
      }
    } else {
      // Print total path and size if currentNode does not have any chilren.
      _printEntitySize(totalPath, numBytes: currentNode.value, level: 2);

      // We picked this file because arm64-v8a is likely the most popular
      // architecture. ther architecture sizes should be similar.
      const String libappPath = 'lib/arm64-v8a/libapp.so';
      // TODO(peterdjlee): Analyze aot size for all platforms.
      if (totalPath.contains(libappPath)) {
        _printAotSnapshotSummary(aotSnapshotJsonRoot);
      }
    }
  }

  /// Go through the AOT gen snapshot size JSON and print out a collapsed summary
  /// for the first package level.
  void _printAotSnapshotSummary(SymbolNode aotSnapshotRoot, {int maxDirectoriesShown = 10}) {
    _printEntitySize(
      'Dart AOT symbols accounted decompressed size',
      numBytes: aotSnapshotRoot.value,
      level: 3,
    );

    final List<SymbolNode> sortedSymbols = aotSnapshotRoot.children.toList()
      ..sort((SymbolNode a, SymbolNode b) => b.value.compareTo(a.value));
    for (final SymbolNode node in sortedSymbols.take(maxDirectoriesShown)) {
      _printEntitySize(node.name, numBytes: node.value, level: 4);
    }
  }

  /// Adds breakdown of aot snapshot data as the children of the node at the given path.
  Map<String, dynamic> _addAotSnapshotDataToApkAnalysis({
    @required Map<String, dynamic> apkAnalysisJson,
    @required List<String> path,
    @required Map<String, dynamic> aotSnapshotJson,
  }) {
    Map<String, dynamic> currentLevel = apkAnalysisJson;
    while (path.isNotEmpty) {
      final List<Map<String, dynamic>> children = currentLevel['children'] as List<Map<String, dynamic>>;
      final Map<String, dynamic> childWithPathAsName = children.firstWhere(
        (Map<String, dynamic> child) => child['n'] as String == path.first,
      );
      path.removeAt(0);
      currentLevel = childWithPathAsName;
    }
    currentLevel['children'] = aotSnapshotJson['children'];
    return apkAnalysisJson;
  }

  /// A pretty printer for an entity with a size.
  void _printEntitySize(
    String entityName, {
    @required int numBytes,
    @required int level, 
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
    logger.printStatus(
      entityName + ' ' * spaceInBetween,
      newline: false,
      emphasis: emphasis,
      indent: level * 2,
    );
    logger.printStatus(formattedSize, color: showColor ? color : null);
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

  SymbolNode _parseAotSnapshot(Map<String, dynamic> aotSnapshotJson) {
    final bool isLeafNode = aotSnapshotJson['children'] == null;
    if (!isLeafNode) {
      return _buildNodeWithChildren(aotSnapshotJson);
    } else {
      // TODO(peterdjlee): Investigate why there are leaf nodes with size of null.
      final int byteSize = aotSnapshotJson['value'] as int;
      if (byteSize == null) {
        return null;
      }
      return _buildNode(aotSnapshotJson, byteSize);
    }
  }

  SymbolNode _buildNode(
    Map<String, dynamic> aotSnapshotJson,
    int byteSize, {
    List<SymbolNode> children = const <SymbolNode>[],
  }) {
    final String name = aotSnapshotJson['n'] as String;
    final Map<String, SymbolNode> childrenMap = <String, SymbolNode>{};

    for (final SymbolNode child in children) {
      childrenMap[child.name] = child;
    }

    return SymbolNode(
      name,
      value: byteSize,
    )..addAllChildren(children);
  }

  /// Builds a node by recursively building all of its children first
  /// in order to calculate the sum of its children's sizes.
  SymbolNode _buildNodeWithChildren(Map<String, dynamic> aotSnapshotJson) {
    final List<dynamic> rawChildren = aotSnapshotJson['children'] as List<dynamic>;
    final List<SymbolNode> symbolNodeChildren = <SymbolNode>[];
    int totalByteSize = 0;

    // Given a child, build its subtree.
    for (final dynamic child in rawChildren) {
      final SymbolNode childTreemapNode = _parseAotSnapshot(child as Map<String, dynamic>);
      symbolNodeChildren.add(childTreemapNode);
      totalByteSize += childTreemapNode.value;
    }

    // If none of the children matched the diff tree type
    if (totalByteSize == 0) {
      return null;
    } else {
      return _buildNode(
        aotSnapshotJson,
        totalByteSize,
        children: symbolNodeChildren,
      );
    }
  }
}

class SymbolNode {
  SymbolNode(
    this.name, {
    this.value = 0,
  })  : assert(name != null),
        assert(value != null),
        _children = <String, SymbolNode>{};

  /// The human friendly identifier for this node.
  String name;

  int value;
  void addValue(int valueToBeAdded) {
    value += valueToBeAdded;
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
    return child;
  }

  void addAllChildren(List<SymbolNode> children) {
    children.forEach(addChild);
  }
  
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{
      'n': name,
      'value': value
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