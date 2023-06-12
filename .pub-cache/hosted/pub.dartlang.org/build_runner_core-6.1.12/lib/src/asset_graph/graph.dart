// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build/experiments.dart' as experiments_zone;
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';
import 'package:meta/meta.dart';
import 'package:package_config/package_config.dart';
import 'package:watcher/watcher.dart';

import '../generate/phase.dart';
import '../package_graph/package_graph.dart';
import 'exceptions.dart';
import 'node.dart';

part 'serialization.dart';

/// All the [AssetId]s involved in a build, and all of their outputs.
class AssetGraph {
  /// All the [AssetNode]s in the graph, indexed by package and then path.
  final _nodesByPackage = <String, Map<String, AssetNode>>{};

  /// A [Digest] of the build actions this graph was originally created with.
  ///
  /// When an [AssetGraph] is deserialized we check whether or not it matches
  /// the new [BuildPhase]s and throw away the graph if it doesn't.
  final Digest buildPhasesDigest;

  /// The [Platform.version] this graph was created with.
  final String dartVersion;

  /// The Dart language experiments that were enabled when this graph was
  /// originally created from the [build] constructor.
  final List<String> enabledExperiments;

  final Map<String, LanguageVersion> packageLanguageVersions;

  AssetGraph._(this.buildPhasesDigest, this.dartVersion,
      this.packageLanguageVersions, this.enabledExperiments);

  /// Deserializes this graph.
  factory AssetGraph.deserialize(List<int> serializedGraph) =>
      _AssetGraphDeserializer(serializedGraph).deserialize();

  static Future<AssetGraph> build(
      List<BuildPhase> buildPhases,
      Set<AssetId> sources,
      Set<AssetId> internalSources,
      PackageGraph packageGraph,
      AssetReader digestReader) async {
    var packageLanguageVersions = {
      for (var pkg in packageGraph.allPackages.values)
        pkg.name: pkg.languageVersion
    };
    var graph = AssetGraph._(
        computeBuildPhasesDigest(buildPhases),
        Platform.version,
        packageLanguageVersions,
        experiments_zone.enabledExperiments);
    var placeholders = graph._addPlaceHolderNodes(packageGraph);
    var sourceNodes = graph._addSources(sources);
    graph
      .._addBuilderOptionsNodes(buildPhases)
      .._addOutputsForSources(buildPhases, sources, packageGraph.root.name,
          placeholders: placeholders);
    // Pre-emptively compute digests for the nodes we know have outputs.
    await graph._setLastKnownDigests(
        sourceNodes.where((node) => node.primaryOutputs.isNotEmpty),
        digestReader);
    // Always compute digests for all internal nodes.
    var internalNodes = graph._addInternalSources(internalSources);
    await graph._setLastKnownDigests(internalNodes, digestReader);
    return graph;
  }

  List<int> serialize() => _AssetGraphSerializer(this).serialize();

  /// Checks if [id] exists in the graph.
  bool contains(AssetId id) =>
      _nodesByPackage[id.package]?.containsKey(id.path) ?? false;

  /// Gets the [AssetNode] for [id], if one exists.
  AssetNode get(AssetId id) {
    var pkg = _nodesByPackage[id?.package];
    if (pkg == null) return null;
    return pkg[id.path];
  }

  /// Adds [node] to the graph if it doesn't exist.
  ///
  /// Throws a [StateError] if it already exists in the graph.
  void _add(AssetNode node) {
    var existing = get(node.id);
    if (existing != null) {
      if (existing is SyntheticSourceAssetNode) {
        // Don't call _removeRecursive, that recursively removes all transitive
        // primary outputs. We only want to remove this node.
        _nodesByPackage[existing.id.package].remove(existing.id.path);
        node.outputs.addAll(existing.outputs);
        node.primaryOutputs.addAll(existing.primaryOutputs);
      } else {
        throw StateError(
            'Tried to add node ${node.id} to the asset graph but it already '
            'exists.');
      }
    }
    _nodesByPackage.putIfAbsent(node.id.package, () => {})[node.id.path] = node;
  }

  /// Adds [assetIds] as [InternalAssetNode]s to this graph.
  Iterable<AssetNode> _addInternalSources(Set<AssetId> assetIds) sync* {
    for (var id in assetIds) {
      var node = InternalAssetNode(id);
      _add(node);
      yield node;
    }
  }

  /// Adds [PlaceHolderAssetNode]s for every package in [packageGraph].
  Set<AssetId> _addPlaceHolderNodes(PackageGraph packageGraph) {
    var placeholders = placeholderIdsFor(packageGraph);
    for (var id in placeholders) {
      _add(PlaceHolderAssetNode(id));
    }
    return placeholders;
  }

  /// Adds [assetIds] as [AssetNode]s to this graph, and returns the newly
  /// created nodes.
  List<AssetNode> _addSources(Set<AssetId> assetIds) {
    return assetIds.map((id) {
      var node = SourceAssetNode(id);
      _add(node);
      return node;
    }).toList();
  }

  /// Adds [BuilderOptionsAssetNode]s for all [buildPhases] to this graph.
  void _addBuilderOptionsNodes(List<BuildPhase> buildPhases) {
    for (var phaseNum = 0; phaseNum < buildPhases.length; phaseNum++) {
      var phase = buildPhases[phaseNum];
      if (phase is InBuildPhase) {
        add(BuilderOptionsAssetNode(builderOptionsIdForAction(phase, phaseNum),
            computeBuilderOptionsDigest(phase.builderOptions)));
      } else if (phase is PostBuildPhase) {
        var actionNum = 0;
        for (var builderAction in phase.builderActions) {
          add(BuilderOptionsAssetNode(
              builderOptionsIdForAction(builderAction, actionNum),
              computeBuilderOptionsDigest(builderAction.builderOptions)));
          actionNum++;
        }
      } else {
        throw StateError('Invalid action type $phase');
      }
    }
  }

  /// Uses [digestReader] to compute the [Digest] for [nodes] and set the
  /// `lastKnownDigest` field.
  Future<void> _setLastKnownDigests(
      Iterable<AssetNode> nodes, AssetReader digestReader) async {
    await Future.wait(nodes.map((node) async {
      node.lastKnownDigest = await digestReader.digest(node.id);
    }));
  }

  /// Removes the node representing [id] from the graph, and all of its
  /// `primaryOutput`s.
  ///
  /// Also removes all edges between all removed nodes and other nodes.
  ///
  /// Returns a [Set<AssetId>] of all removed nodes.
  Set<AssetId> _removeRecursive(AssetId id, {Set<AssetId> removedIds}) {
    removedIds ??= <AssetId>{};
    var node = get(id);
    if (node == null) return removedIds;
    removedIds.add(id);
    for (var anchor in node.anchorOutputs.toList()) {
      _removeRecursive(anchor, removedIds: removedIds);
    }
    for (var output in node.primaryOutputs.toList()) {
      _removeRecursive(output, removedIds: removedIds);
    }
    for (var output in node.outputs) {
      var inputsNode = get(output) as NodeWithInputs;
      if (inputsNode != null) {
        inputsNode.inputs.remove(id);
        if (inputsNode is GlobAssetNode) {
          inputsNode.results.remove(id);
        }
      }
    }
    if (node is NodeWithInputs) {
      for (var input in node.inputs) {
        var inputNode = get(input);
        // We may have already removed this node entirely.
        if (inputNode != null) {
          inputNode.outputs.remove(id);
          inputNode.primaryOutputs.remove(id);
        }
      }
      if (node is GeneratedAssetNode) {
        get(node.builderOptionsId).outputs.remove(id);
      }
    }
    // Synthetic nodes need to be kept to retain dependency tracking.
    if (node is! SyntheticSourceAssetNode) {
      _nodesByPackage[id.package].remove(id.path);
    }
    return removedIds;
  }

  /// All nodes in the graph, whether source files or generated outputs.
  Iterable<AssetNode> get allNodes =>
      _nodesByPackage.values.expand((pkdIds) => pkdIds.values);

  /// All nodes in the graph for `package`.
  Iterable<AssetNode> packageNodes(String package) =>
      _nodesByPackage[package]?.values ?? [];

  /// All the generated outputs in the graph.
  Iterable<AssetId> get outputs =>
      allNodes.where((n) => n.isGenerated).map((n) => n.id);

  /// The outputs which were, or would have been, produced by failing actions.
  Iterable<GeneratedAssetNode> get failedOutputs => allNodes
      .where((n) =>
          n is GeneratedAssetNode &&
          n.isFailure &&
          n.state == NodeState.upToDate)
      .map((n) => n as GeneratedAssetNode);

  /// All the generated outputs for a particular phase.
  Iterable<GeneratedAssetNode> outputsForPhase(String package, int phase) =>
      packageNodes(package)
          .whereType<GeneratedAssetNode>()
          .where((n) => n.phaseNumber == phase);

  /// All the source files in the graph.
  Iterable<AssetId> get sources =>
      allNodes.whereType<SourceAssetNode>().map((n) => n.id);

  /// Updates graph structure, invalidating and deleting any outputs that were
  /// affected.
  ///
  /// Returns the list of [AssetId]s that were invalidated.
  Future<Set<AssetId>> updateAndInvalidate(
      List<BuildPhase> buildPhases,
      Map<AssetId, ChangeType> updates,
      String rootPackage,
      Future Function(AssetId id) delete,
      AssetReader digestReader) async {
    var newIds = <AssetId>{};
    var modifyIds = <AssetId>{};
    var removeIds = <AssetId>{};
    updates.forEach((id, changeType) {
      if (changeType != ChangeType.ADD && get(id) == null) return;
      switch (changeType) {
        case ChangeType.ADD:
          newIds.add(id);
          break;
        case ChangeType.MODIFY:
          modifyIds.add(id);
          break;
        case ChangeType.REMOVE:
          removeIds.add(id);
          break;
      }
    });

    var newAndModifiedNodes = modifyIds.map(get).toList()
      ..addAll(_addSources(newIds));
    // Pre-emptively compute digests for the new and modified nodes we know have
    // outputs.
    await _setLastKnownDigests(
        newAndModifiedNodes.where((node) =>
            node.isValidInput &&
            (node.outputs.isNotEmpty ||
                node.primaryOutputs.isNotEmpty ||
                node.lastKnownDigest != null)),
        digestReader);

    // Collects the set of all transitive ids to be removed from the graph,
    // based on the removed `SourceAssetNode`s by following the
    // `primaryOutputs`.
    var transitiveRemovedIds = <AssetId>{};
    void addTransitivePrimaryOutputs(AssetId id) {
      transitiveRemovedIds.add(id);
      get(id).primaryOutputs.forEach(addTransitivePrimaryOutputs);
    }

    removeIds
        .where((id) => get(id) is SourceAssetNode)
        .forEach(addTransitivePrimaryOutputs);

    // The generated nodes to actually delete from the file system.
    var idsToDelete = Set<AssetId>.from(transitiveRemovedIds)
      ..removeAll(removeIds);

    // We definitely need to update manually deleted outputs.
    for (var deletedOutput
        in removeIds.map(get).whereType<GeneratedAssetNode>()) {
      deletedOutput.state = NodeState.definitelyNeedsUpdate;
    }

    // Transitively invalidates all assets. This needs to happen after the
    // structure of the graph has been updated.
    var invalidatedIds = <AssetId>{};

    var newGeneratedOutputs =
        _addOutputsForSources(buildPhases, newIds, rootPackage);
    var allNewAndDeletedIds =
        Set.of(newGeneratedOutputs.followedBy(transitiveRemovedIds));

    void invalidateNodeAndDeps(AssetId id) {
      var node = get(id);
      if (node == null) return;
      if (!invalidatedIds.add(id)) return;

      if (node is NodeWithInputs && node.state == NodeState.upToDate) {
        node.state = NodeState.mayNeedUpdate;
      }

      // Update all outputs of this asset as well.
      for (var output in node.outputs) {
        invalidateNodeAndDeps(output);
      }
    }

    for (var changed in updates.keys.followedBy(newGeneratedOutputs)) {
      invalidateNodeAndDeps(changed);
    }

    // For all new or deleted assets, check if they match any glob nodes and
    // invalidate those.
    for (var id in allNewAndDeletedIds) {
      var samePackageGlobNodes = packageNodes(id.package)
          .whereType<GlobAssetNode>()
          .where((n) => n.state == NodeState.upToDate);
      for (final node in samePackageGlobNodes) {
        if (node.glob.matches(id.path)) {
          invalidateNodeAndDeps(node.id);
          node.state = NodeState.mayNeedUpdate;
        }
      }
    }

    // Delete all the invalidated assets, then remove them from the graph. This
    // order is important because some `AssetWriter`s throw if the id is not in
    // the graph.
    await Future.wait(idsToDelete.map(delete));

    // Remove all deleted source assets from the graph, which also recursively
    // removes all their primary outputs.
    for (var id in removeIds.where((id) => get(id) is SourceAssetNode)) {
      invalidateNodeAndDeps(id);
      _removeRecursive(id);
    }

    return invalidatedIds;
  }

  /// Crawl up primary inputs to see if the original Source file matches the
  /// glob on [action].
  bool _actionMatches(BuildAction action, AssetId input) {
    if (input.package != action.package) return false;
    if (!action.generateFor.matches(input)) return false;
    Iterable<String> inputExtensions;
    if (action is InBuildPhase) {
      inputExtensions = action.builder.buildExtensions.keys;
    } else if (action is PostBuildAction) {
      inputExtensions = action.builder.inputExtensions;
    } else {
      throw StateError('Unrecognized action type $action');
    }
    if (!inputExtensions.any(input.path.endsWith)) {
      return false;
    }
    var inputNode = get(input);
    while (inputNode is GeneratedAssetNode) {
      inputNode = get((inputNode as GeneratedAssetNode).primaryInput);
    }
    return action.targetSources.matches(inputNode.id);
  }

  /// Returns a set containing [newSources] plus any new generated sources
  /// based on [buildPhases], and updates this graph to contain all the
  /// new outputs.
  ///
  /// If [placeholders] is supplied they will be added to [newSources] to create
  /// the full input set.
  Set<AssetId> _addOutputsForSources(
      List<BuildPhase> buildPhases, Set<AssetId> newSources, String rootPackage,
      {Set<AssetId> placeholders}) {
    var allInputs = Set<AssetId>.from(newSources);
    if (placeholders != null) allInputs.addAll(placeholders);

    for (var phaseNum = 0; phaseNum < buildPhases.length; phaseNum++) {
      var phase = buildPhases[phaseNum];
      if (phase is InBuildPhase) {
        allInputs.addAll(_addInBuildPhaseOutputs(
          phase,
          phaseNum,
          allInputs,
          buildPhases,
          rootPackage,
        ));
      } else if (phase is PostBuildPhase) {
        _addPostBuildPhaseAnchors(phase, allInputs);
      } else {
        throw StateError('Unrecognized phase type $phase');
      }
    }
    return allInputs;
  }

  /// Adds all [GeneratedAssetNode]s for [phase] given [allInputs].
  ///
  /// May remove some items from [allInputs], if they are deemed to actually be
  /// outputs of this phase and not original sources.
  ///
  /// Returns all newly created asset ids.
  Set<AssetId> _addInBuildPhaseOutputs(
      InBuildPhase phase,
      int phaseNum,
      Set<AssetId> allInputs,
      List<BuildPhase> buildPhases,
      String rootPackage) {
    var phaseOutputs = <AssetId>{};
    var buildOptionsNodeId = builderOptionsIdForAction(phase, phaseNum);
    var builderOptionsNode = get(buildOptionsNodeId) as BuilderOptionsAssetNode;
    var inputs =
        allInputs.where((input) => _actionMatches(phase, input)).toList();
    for (var input in inputs) {
      // We might have deleted some inputs during this loop, if they turned
      // out to be generated assets.
      if (!allInputs.contains(input)) continue;
      var node = get(input);
      assert(node != null, 'The node from `$input` does not exist.');

      var outputs = expectedOutputs(phase.builder, input);
      phaseOutputs.addAll(outputs);
      node.primaryOutputs.addAll(outputs);
      var deleted = _addGeneratedOutputs(
          outputs, phaseNum, builderOptionsNode, buildPhases, rootPackage,
          primaryInput: input, isHidden: phase.hideOutput);
      allInputs.removeAll(deleted);
      // We may delete source nodes that were producing outputs previously.
      // Detect this by checking for deleted nodes that no longer exist in the
      // graph at all, and remove them from `phaseOutputs`.
      phaseOutputs.removeAll(deleted.where((id) => !contains(id)));
    }
    return phaseOutputs;
  }

  /// Adds all [PostProcessAnchorNode]s for [phase] given [allInputs];
  ///
  /// Does not return anything because [PostProcessAnchorNode]s are synthetic
  /// and should not be treated as inputs.
  void _addPostBuildPhaseAnchors(PostBuildPhase phase, Set<AssetId> allInputs) {
    var actionNum = 0;
    for (var action in phase.builderActions) {
      var inputs = allInputs.where((input) => _actionMatches(action, input));
      for (var input in inputs) {
        var buildOptionsNodeId = builderOptionsIdForAction(action, actionNum);
        var anchor = PostProcessAnchorNode.forInputAndAction(
            input, actionNum, buildOptionsNodeId);
        add(anchor);
        get(input).anchorOutputs.add(anchor.id);
      }
      actionNum++;
    }
  }

  /// Adds [outputs] as [GeneratedAssetNode]s to the graph.
  ///
  /// If there are existing [SourceAssetNode]s or [SyntheticSourceAssetNode]s
  /// that overlap the [GeneratedAssetNode]s, then they will be replaced with
  /// [GeneratedAssetNode]s, and all their `primaryOutputs` will be removed
  /// from the graph as well. The return value is the set of assets that were
  /// removed from the graph.
  Set<AssetId> _addGeneratedOutputs(
      Iterable<AssetId> outputs,
      int phaseNumber,
      BuilderOptionsAssetNode builderOptionsNode,
      List<BuildPhase> buildPhases,
      String rootPackage,
      {AssetId primaryInput,
      @required bool isHidden}) {
    var removed = <AssetId>{};
    for (var output in outputs) {
      AssetNode existing;
      // When any outputs aren't hidden we can pick up old generated outputs as
      // regular `AssetNode`s, we need to delete them and all their primary
      // outputs, and replace them with a `GeneratedAssetNode`.
      if (contains(output)) {
        existing = get(output);
        if (existing is GeneratedAssetNode) {
          throw DuplicateAssetNodeException(
              rootPackage,
              existing.id,
              (buildPhases[existing.phaseNumber] as InBuildPhase).builderLabel,
              (buildPhases[phaseNumber] as InBuildPhase).builderLabel);
        }
        _removeRecursive(output, removedIds: removed);
      }

      var newNode = GeneratedAssetNode(output,
          phaseNumber: phaseNumber,
          primaryInput: primaryInput,
          state: NodeState.definitelyNeedsUpdate,
          wasOutput: false,
          isFailure: false,
          builderOptionsId: builderOptionsNode.id,
          isHidden: isHidden);
      if (existing != null) {
        newNode.outputs.addAll(existing.outputs);
        // Ensure we set up the reverse link for NodeWithInput nodes.
        _addInput(existing.outputs, output);
      }
      builderOptionsNode.outputs.add(output);
      _add(newNode);
    }
    return removed;
  }

  @override
  String toString() => allNodes.toList().toString();

  // TODO remove once tests are updated
  void add(AssetNode node) => _add(node);
  Set<AssetId> remove(AssetId id) => _removeRecursive(id);

  /// Adds [input] to all [outputs] if they represent [NodeWithInputs] nodes.
  void _addInput(Iterable<AssetId> outputs, AssetId input) {
    for (var output in outputs) {
      var node = get(output);
      if (node is NodeWithInputs) node.inputs.add(input);
    }
  }
}

/// Computes a [Digest] for [buildPhases] which can be used to compare one set
/// of [BuildPhase]s against another.
Digest computeBuildPhasesDigest(Iterable<BuildPhase> buildPhases) {
  var digestSink = AccumulatorSink<Digest>();
  md5.startChunkedConversion(digestSink)
    ..add(buildPhases.map((phase) => phase.identity).toList())
    ..close();
  assert(digestSink.events.length == 1);
  return digestSink.events.first;
}

Digest computeBuilderOptionsDigest(BuilderOptions options) =>
    md5.convert(utf8.encode(json.encode(options.config)));

AssetId builderOptionsIdForAction(BuildAction action, int actionNum) {
  if (action is InBuildPhase) {
    return AssetId(action.package, 'Phase$actionNum.builderOptions');
  } else if (action is PostBuildAction) {
    return AssetId(action.package, 'PostPhase$actionNum.builderOptions');
  } else {
    throw StateError('Unsupported action type $action');
  }
}

Set<AssetId> placeholderIdsFor(PackageGraph packageGraph) =>
    Set<AssetId>.from(packageGraph.allPackages.keys.expand((package) => [
          AssetId(package, r'lib/$lib$'),
          AssetId(package, r'test/$test$'),
          AssetId(package, r'web/$web$'),
          AssetId(package, r'$package$'),
        ]));
