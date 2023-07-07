// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helpers for working with the output of `--trace-precompiler-to` VM flag.
library vm_snapshot_analysis.precompiler_trace;

import 'package:vm_snapshot_analysis/name.dart';
import 'package:vm_snapshot_analysis/program_info.dart';
import 'package:vm_snapshot_analysis/src/dominators.dart' as dominators;

/// Build [CallGraph] based on the trace written by `--trace-precompiler-to`
/// flag.
CallGraph loadTrace(Object inputJson) =>
    _TraceReader(inputJson as Map<String, dynamic>).readTrace();

/// [CallGraphNode] represents a node of the call-graph. It can either be:
///
///   - a function, in which case [data] will be [ProgramInfoNode] of type
///     [NodeType.functionNode];
///   - a dynamic call node, in which case [data] will be a [String] selector;
///   - a dispatch table call node, in which case [data] will be an [int]
///     selector id.
///
class CallGraphNode {
  /// An index of this node in [CallGraph.nodes].
  final int id;

  /// Successors of this node.
  final List<CallGraphNode> succ = [];

  /// Predecessors of this node.
  final List<CallGraphNode> pred = [];

  /// Datum associated with this node: a [ProgramInfoNode] (function), a
  /// [String] (dynamic call selector) or an [int] (dispatch table selector id).
  final dynamic data;

  /// Dominator of this node.
  ///
  /// Computed by [CallGraph.computeDominators].
  CallGraphNode? dominator;

  /// Nodes dominated by this node.
  ///
  /// Computed by [CallGraph.computeDominators].
  List<CallGraphNode> dominated = _emptyNodeList;

  CallGraphNode(this.id, {this.data});

  bool get isFunctionNode =>
      data is ProgramInfoNode && data.type == NodeType.functionNode;

  bool get isClassNode =>
      data is ProgramInfoNode && data.type == NodeType.classNode;

  bool get isDynamicCallNode => data is String;

  /// Create outgoing edge from this node to the given node [n].
  void connectTo(CallGraphNode n) {
    if (n == this) {
      return;
    }

    if (!succ.contains(n)) {
      n.pred.add(this);
      succ.add(n);
    }
  }

  void _addDominatedBlock(CallGraphNode n) {
    if (identical(dominated, _emptyNodeList)) {
      dominated = [];
    }
    dominated.add(n);
    n.dominator = this;
  }

  void visitDominatorTree(bool Function(CallGraphNode n, int depth) callback,
      [int depth = 0]) {
    if (callback(this, depth)) {
      for (var n in dominated) {
        n.visitDominatorTree(callback, depth + 1);
      }
    }
  }

  @override
  String toString() {
    return 'CallGraphNode(${data is ProgramInfoNode ? data.qualifiedName : data})';
  }
}

const _emptyNodeList = <CallGraphNode>[];

class CallGraph {
  final ProgramInfo program;
  final List<CallGraphNode> nodes;

  // Mapping from [ProgramInfoNode] to a corresponding [CallGraphNode] (if any)
  // via [ProgramInfoNode.id].
  final List<CallGraphNode?> _graphNodeByEntityId;

  CallGraph._(this.program, this.nodes, this._graphNodeByEntityId);

  CallGraphNode get root => nodes.first;

  CallGraphNode lookup(ProgramInfoNode node) => _graphNodeByEntityId[node.id]!;

  Iterable<CallGraphNode> get dynamicCalls =>
      nodes.where((n) => n.isDynamicCallNode);

  /// Compute a collapsed version of the call-graph, where
  CallGraph collapse(NodeType type, {bool dropCallNodes = false}) {
    final graphNodesByData = <Object, CallGraphNode>{};
    final graphNodeByEntityId = <CallGraphNode?>[];

    ProgramInfoNode collapsed(ProgramInfoNode nn) {
      // Root always collapses onto itself.
      if (nn == program.root) {
        return nn;
      }

      // Even though all code is grouped into libraries, not all libraries
      // are grouped into packages (e.g. dart:* libraries). Meaning
      // that if we are collapsing by package we need to stop right before
      // hitting the root node.
      var n = nn;
      while (n.parent != program.root && n.type != type) {
        n = n.parent!;
      }
      return n;
    }

    CallGraphNode callGraphNodeFor(Object data) {
      return graphNodesByData.putIfAbsent(data, () {
        final n = CallGraphNode(graphNodesByData.length, data: data);
        if (data is ProgramInfoNode) {
          if (graphNodeByEntityId.length <= data.id) {
            graphNodeByEntityId.length = data.id * 2 + 1;
          }
          graphNodeByEntityId[data.id] = n;
        }
        return n;
      });
    }

    final newNodes = nodes.map((n) {
      if (n.data is ProgramInfoNode) {
        return callGraphNodeFor(collapsed(n.data));
      } else if (!dropCallNodes) {
        return callGraphNodeFor(n.data);
      }
    }).toList(growable: false);

    for (var n in nodes) {
      for (var succ in n.succ) {
        final from = newNodes[n.id];
        final to = newNodes[succ.id];

        if (from != null && to != null) {
          from.connectTo(to);
        }
      }
    }

    return CallGraph._(program, graphNodesByData.values.toList(growable: false),
        graphNodeByEntityId);
  }

  /// Compute dominator tree of the call-graph.
  void computeDominators() {
    final dom = dominators.computeDominators(
        size: nodes.length,
        root: nodes.first.id,
        succ: (i) => nodes[i].succ.map((n) => n.id),
        predOf: (i) => nodes[i].pred.map((n) => n.id),
        handleEdge: (from, to) {});
    for (var i = 1; i < nodes.length; i++) {
      nodes[dom[i]]._addDominatedBlock(nodes[i]);
    }
  }
}

/// Helper class for reading `--trace-precompiler-to` output.
///
/// See README.md for description of the format.
class _TraceReader {
  final List<dynamic> trace;
  final List<String> strings;
  final List<dynamic> entities;

  final program = ProgramInfo();

  /// Mapping between entity ids and corresponding [ProgramInfoNode] nodes.
  final entityById = List<ProgramInfoNode?>.filled(1024, null, growable: true);

  /// Mapping between functions (represented as [ProgramInfoNode]s) and
  /// their selector ids.
  final selectorIdMap = <ProgramInfoNode, int>{};

  /// Set of functions which can be reached through dynamic dispatch.
  final dynamicFunctions = <ProgramInfoNode>{};

  _TraceReader(Map<String, dynamic> data)
      : strings = (data['strings'] as List<dynamic>).cast<String>(),
        entities = data['entities'],
        trace = data['trace'];

  /// Read all trace events and construct the call graph based on them.
  CallGraph readTrace() {
    var pos = 0; // Position in the [trace] array.
    late CallGraphNode currentNode;
    int maxId = 0;

    final nodes = <CallGraphNode>[];
    final nodeByEntityId = <CallGraphNode?>[];
    final callNodesBySelector = <dynamic, CallGraphNode>{};
    final allocated = <ProgramInfoNode>{};

    T next<T>() => trace[pos++] as T;

    CallGraphNode makeNode({dynamic data}) {
      final n = CallGraphNode(nodes.length, data: data);
      nodes.add(n);
      return n;
    }

    CallGraphNode makeCallNode(dynamic selector) => callNodesBySelector
        .putIfAbsent(selector, () => makeNode(data: selector));

    CallGraphNode nodeFor(ProgramInfoNode n) {
      if (nodeByEntityId.length <= n.id) {
        nodeByEntityId.length = n.id * 2 + 1;
      }
      if (n.id > maxId) {
        maxId = n.id;
      }
      return nodeByEntityId[n.id] ??= makeNode(data: n);
    }

    void recordDynamicCall(String selector) {
      currentNode.connectTo(makeCallNode(selector));
    }

    void recordInterfaceCall(int selector) {
      currentNode.connectTo(makeCallNode(selector));
    }

    void recordStaticCall(ProgramInfoNode to) {
      currentNode.connectTo(nodeFor(to));
    }

    void recordFieldRef(ProgramInfoNode field) {
      currentNode.connectTo(nodeFor(field));
    }

    void recordAllocation(ProgramInfoNode cls) {
      currentNode.connectTo(nodeFor(cls));
      allocated.add(cls);
    }

    bool readRef() {
      final ref = next();
      if (ref is int) {
        final entity = getEntityAt(ref);
        if (entity.type == NodeType.classNode) {
          recordAllocation(entity);
        } else if (entity.type == NodeType.functionNode) {
          recordStaticCall(entity);
        } else if (entity.type == NodeType.other) {
          recordFieldRef(entity);
        }
      } else if (ref == 'S') {
        final String selector = strings[next()];
        recordDynamicCall(selector);
      } else if (ref == 'T') {
        recordInterfaceCall(next());
      } else if (ref == 'C' || ref == 'E') {
        pos--;
        return false;
      } else {
        throw FormatException('unexpected ref: $ref');
      }
      return true;
    }

    void readRefs() {
      while (readRef()) {}
    }

    void readEvents() {
      while (true) {
        final op = next();
        switch (op) {
          case 'E': // End.
            return;
          case 'R': // Roots.
            currentNode = nodeFor(program.root);
            readRefs();
            break;
          case 'C': // Function compilation.
            currentNode = nodeFor(getEntityAt(next()));
            readRefs();
            break;
          default:
            throw FormatException('Unknown event: $op at ${pos - 1}');
        }
      }
    }

    readEvents();

    // Finally connect nodes representing dynamic and dispatch table calls
    // to their potential targets.
    for (var cls in allocated) {
      for (var fun in cls.children.values.where(dynamicFunctions.contains)) {
        final funNode = nodeFor(fun);

        callNodesBySelector[selectorIdMap[fun]]?.connectTo(funNode);

        final name = fun.name;
        callNodesBySelector[name]?.connectTo(funNode);

        const dynPrefix = 'dyn:';
        const getterPrefix = 'get:';
        const extractorPrefix = '[tear-off-extractor] ';

        if (!name.startsWith(dynPrefix)) {
          // Normal methods can be hit by dyn: selectors if the class
          // does not contain a dedicated dyn: forwarder for this name.
          if (!cls.children.containsKey('$dynPrefix$name')) {
            callNodesBySelector['$dynPrefix$name']?.connectTo(funNode);
          }

          if (name.startsWith(getterPrefix)) {
            // Handle potential calls through getters: getter get:foo can be
            // hit by dyn:foo and foo selectors.
            final targetName = name.substring(getterPrefix.length);
            callNodesBySelector[targetName]?.connectTo(funNode);
            callNodesBySelector['$dynPrefix$targetName']?.connectTo(funNode);
          } else if (name.startsWith(extractorPrefix)) {
            // Handle method tear-off: [tear-off-extractor] get:foo can be hit
            // by dyn:get:foo and get:foo.
            final targetName = name.substring(extractorPrefix.length);
            callNodesBySelector[targetName]?.connectTo(funNode);
            callNodesBySelector['$dynPrefix$targetName']?.connectTo(funNode);
          }
        }
      }
    }

    return CallGraph._(program, nodes, nodeByEntityId);
  }

  /// Return [ProgramInfoNode] representing the entity with the given [id].
  ProgramInfoNode getEntityAt(int id) {
    if (entityById.length <= id) {
      entityById.length = id * 2;
    }

    // Entity records have fixed size which allows us to perform random access.
    const elementsPerEntity = 4;
    return entityById[id] ??= readEntityAt(id * elementsPerEntity);
  }

  /// Read the entity at the given [index] in [entities].
  ProgramInfoNode readEntityAt(int index) {
    final type = entities[index];
    final idx0 = entities[index + 1] as int;
    final idx1 = entities[index + 2] as int;
    final idx2 = entities[index + 3] as int;
    switch (type) {
      case 'C': // Class: 'C', <library-uri-idx>, <name-idx>, 0
        final libraryUri = strings[idx0];
        final className = strings[idx1];

        return program.makeNode(
            name: className,
            parent: getLibraryNode(libraryUri),
            type: NodeType.classNode);

      case 'S':
      case 'F': // Function: 'F'|'S', <class-idx>, <name-idx>, <selector-id>
        final classNode = getEntityAt(idx0);
        final functionName = strings[idx1];
        final int selectorId = idx2;

        final path = Name(functionName).rawComponents;
        if (path.last == 'FfiTrampoline') {
          path[path.length - 1] = '${path.last}@$index';
        }
        var node = program.makeNode(
            name: path.first, parent: classNode, type: NodeType.functionNode);
        for (var name in path.skip(1)) {
          node = program.makeNode(
              name: name, parent: node, type: NodeType.functionNode);
        }
        if (selectorId >= 0) {
          selectorIdMap[node] = selectorId;
        }
        if (type == 'F') {
          dynamicFunctions.add(node);
        }
        return node;

      case 'V': // Field: 'V', <class-idx>, <name-idx>, 0
        final classNode = getEntityAt(idx0);
        final fieldName = strings[idx1];

        return program.makeNode(
            name: fieldName, parent: classNode, type: NodeType.other);

      default:
        throw FormatException('unrecognized entity type $type');
    }
  }

  ProgramInfoNode getLibraryNode(String libraryUri) {
    final package = packageOf(libraryUri);
    var node = program.root;
    if (package != libraryUri) {
      node = program.makeNode(
          name: package, parent: node, type: NodeType.packageNode);
    }
    return program.makeNode(
        name: libraryUri, parent: node, type: NodeType.libraryNode);
  }
}

/// Generates a [CallGraph] from the given [precompilerTrace], which is produced
/// by `--trace-precompiler-to`, then collapses it down to the granularity
/// specified by [nodeType], and computes dominators of the resulting graph.
CallGraph generateCallGraphWithDominators(
  Object precompilerTrace,
  NodeType nodeType,
) {
  var callGraph = loadTrace(precompilerTrace);

  // Convert call graph into the approximate dependency graph, dropping any
  // dynamic and dispatch table based dependencies from the graph and only
  // following the static call, field access and allocation edges.
  callGraph = callGraph.collapse(nodeType, dropCallNodes: true)
    ..computeDominators();

  return callGraph;
}
