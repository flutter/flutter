// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';
import 'package:meta/meta.dart';

import '../generate/phase.dart';

/// A node in the asset graph which may be an input to other assets.
abstract class AssetNode {
  final AssetId id;

  /// The assets that any [Builder] in the build graph declares it may output
  /// when run on this asset.
  final Set<AssetId> primaryOutputs = <AssetId>{};

  /// The [AssetId]s of all generated assets which are output by a [Builder]
  /// which reads this asset.
  final Set<AssetId> outputs = <AssetId>{};

  /// The [AssetId]s of all [PostProcessAnchorNode] assets for which this node
  /// is the primary input.
  final Set<AssetId> anchorOutputs = <AssetId>{};

  /// The [Digest] for this node in its last known state.
  ///
  /// May be `null` if this asset has no outputs, or if it doesn't actually
  /// exist.
  Digest lastKnownDigest;

  /// Whether or not this node was an output of this build.
  bool get isGenerated => false;

  /// Whether or not this asset type can be read.
  ///
  /// This does not indicate whether or not this specific node actually exists
  /// at this moment in time.
  bool get isReadable => true;

  /// The IDs of the [PostProcessAnchorNode] for post process builder which
  /// requested to delete this asset.
  final Set<AssetId> deletedBy = <AssetId>{};

  /// Whether the node is deleted.
  ///
  /// Deleted nodes are ignored in the final merge step and watch handlers.
  bool get isDeleted => deletedBy.isNotEmpty;

  /// Whether or not this node can be read by a builder as a primary or
  /// secondary input.
  ///
  /// Some nodes are valid primary inputs but are not readable (see
  /// [PlaceHolderAssetNode]), while others are readable in the overall build
  /// system  but are not valid builder inputs (see [InternalAssetNode]).
  bool get isValidInput => true;

  /// Whether or not changes to this node will have any effect on other nodes.
  ///
  /// Be default, if we haven't computed a digest for this asset and it has no
  /// outputs, then it isn't interesting.
  ///
  /// Checking for a digest alone isn't enough because a file may be deleted
  /// and re-added, in which case it won't have a digest.
  bool get isInteresting => outputs.isNotEmpty || lastKnownDigest != null;

  AssetNode(this.id, {this.lastKnownDigest});

  /// Work around issue where you can't mixin classes into a class with optional
  /// constructor args.
  AssetNode._forMixins(this.id);

  /// Work around issue where you can't mixin classes into a class with optional
  /// constructor args, this one includes the digest.
  AssetNode._forMixinsWithDigest(this.id, this.lastKnownDigest);

  @override
  String toString() => 'AssetNode: $id';
}

/// A node representing some internal asset.
///
/// These nodes are not used as primary inputs, but they are tracked in the
/// asset graph and are readable.
class InternalAssetNode extends AssetNode {
  // These don't have [outputs] but they are interesting regardless.
  @override
  bool get isInteresting => true;

  @override
  bool get isValidInput => false;

  InternalAssetNode(AssetId id, {Digest lastKnownDigest})
      : super(id, lastKnownDigest: lastKnownDigest);

  @override
  String toString() => 'InternalAssetNode: $id';
}

/// A node which is an original source asset (not generated).
class SourceAssetNode extends AssetNode {
  SourceAssetNode(AssetId id, {Digest lastKnownDigest})
      : super(id, lastKnownDigest: lastKnownDigest);

  @override
  String toString() => 'SourceAssetNode: $id';
}

/// States for nodes that can be invalidated.
enum NodeState {
  // This node does not need an update, and no checks need to be performed.
  upToDate,
  // This node may need an update, the inputs hash should be checked for
  // changes.
  mayNeedUpdate,
  // This node definitely needs an update, the inputs hash check can be skipped.
  definitelyNeedsUpdate,
}

/// A generated node in the asset graph.
class GeneratedAssetNode extends AssetNode implements NodeWithInputs {
  @override
  bool get isGenerated => true;

  @override
  final int phaseNumber;

  /// The primary input which generated this node.
  final AssetId primaryInput;

  @override
  NodeState state;

  /// Whether the asset was actually output.
  bool wasOutput;

  /// All the inputs that were read when generating this asset, or deciding not
  /// to generate it.
  ///
  /// This needs to be an ordered set because we compute combined input digests
  /// using this later on.
  @override
  HashSet<AssetId> inputs;

  /// A digest combining all digests of all previous inputs.
  ///
  /// Used to determine whether all the inputs to a build step are identical to
  /// the previous run, indicating that the previous output is still valid.
  Digest previousInputsDigest;

  /// Whether the action which did or would produce this node failed.
  bool isFailure;

  /// The [AssetId] of the node representing the [BuilderOptions] used to create
  /// this node.
  final AssetId builderOptionsId;

  /// Whether the asset should be placed in the build cache.
  final bool isHidden;

  GeneratedAssetNode(
    AssetId id, {
    Digest lastKnownDigest,
    Iterable<AssetId> inputs,
    this.previousInputsDigest,
    @required this.isHidden,
    @required this.state,
    @required this.phaseNumber,
    @required this.wasOutput,
    @required this.isFailure,
    @required this.primaryInput,
    @required this.builderOptionsId,
  })  : inputs = inputs != null ? HashSet.from(inputs) : HashSet(),
        super(id, lastKnownDigest: lastKnownDigest);

  @override
  String toString() =>
      'GeneratedAssetNode: $id generated from input $primaryInput.';
}

/// A node which is not a generated or source asset.
///
/// These are typically not readable or valid as inputs.
abstract class _SyntheticAssetNode implements AssetNode {
  @override
  bool get isReadable => false;

  @override
  bool get isValidInput => false;
}

/// A [_SyntheticAssetNode] representing a non-existent source.
///
/// Typically these are created as a result of `canRead` calls for assets that
/// don't exist in the graph. We still need to set up proper dependencies so
/// that if that asset gets added later the outputs are properly invalidated.
class SyntheticSourceAssetNode extends AssetNode with _SyntheticAssetNode {
  SyntheticSourceAssetNode(AssetId id) : super._forMixins(id);
}

/// A [_SyntheticAssetNode] which represents an individual [BuilderOptions]
/// object.
///
/// These are used to track the state of a [BuilderOptions] object, and all
/// [GeneratedAssetNode]s should depend on one of these nodes, which represents
/// their configuration.
class BuilderOptionsAssetNode extends AssetNode with _SyntheticAssetNode {
  BuilderOptionsAssetNode(AssetId id, Digest lastKnownDigest)
      : super._forMixinsWithDigest(id, lastKnownDigest);

  @override
  String toString() => 'BuildOptionsAssetNode: $id';
}

/// Placeholder assets are magic files that are usable as inputs but are not
/// readable.
class PlaceHolderAssetNode extends AssetNode with _SyntheticAssetNode {
  @override
  bool get isValidInput => true;

  PlaceHolderAssetNode(AssetId id) : super._forMixins(id);

  @override
  String toString() => 'PlaceHolderAssetNode: $id';
}

/// A [_SyntheticAssetNode] which is created for each [primaryInput] to a
/// [PostBuildAction].
///
/// The [outputs] of this node are the individual outputs created for the
/// [primaryInput] during the [PostBuildAction] at index [actionNumber].
class PostProcessAnchorNode extends AssetNode with _SyntheticAssetNode {
  final int actionNumber;
  final AssetId builderOptionsId;
  final AssetId primaryInput;
  Digest previousInputsDigest;

  PostProcessAnchorNode(
      AssetId id, this.primaryInput, this.actionNumber, this.builderOptionsId,
      {this.previousInputsDigest})
      : super._forMixins(id);

  PostProcessAnchorNode.forInputAndAction(
      AssetId primaryInput, int actionNumber, AssetId builderOptionsId)
      : this(primaryInput.addExtension('.post_anchor.$actionNumber'),
            primaryInput, actionNumber, builderOptionsId);
}

/// A node representing a glob ran from a builder.
///
/// The [id] must always be unique to a given package, phase, and glob
/// pattern.
class GlobAssetNode extends InternalAssetNode implements NodeWithInputs {
  final Glob glob;

  /// All the potential inputs matching this glob.
  ///
  /// This field differs from [results] in that [GeneratedAssetNode] which may
  /// have been readable but were not output are included here and not in
  /// [results].
  @override
  HashSet<AssetId> inputs;

  @override
  bool get isReadable => false;

  @override
  final int phaseNumber;

  /// The actual results of the glob.
  List<AssetId> results;

  @override
  NodeState state;

  GlobAssetNode(AssetId id, this.glob, this.phaseNumber, this.state,
      {this.inputs, Digest lastKnownDigest, this.results})
      : super(id, lastKnownDigest: lastKnownDigest);

  static AssetId createId(String package, Glob glob, int phaseNum) => AssetId(
      package, 'glob.$phaseNum.${base64.encode(utf8.encode(glob.pattern))}');
}

/// A node which has [inputs], a [NodeState], and a [phaseNumber].
abstract class NodeWithInputs implements AssetNode {
  HashSet<AssetId> inputs;

  int get phaseNumber;

  NodeState state;
}
