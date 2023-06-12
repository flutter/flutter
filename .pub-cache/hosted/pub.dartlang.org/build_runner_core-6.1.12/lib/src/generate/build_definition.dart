// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:async/async.dart';
import 'package:build/build.dart';
import 'package:build/experiments.dart';
import 'package:collection/collection.dart';
import 'package:glob/glob.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

import '../asset/build_cache.dart';
import '../asset/reader.dart';
import '../asset/writer.dart';
import '../asset_graph/exceptions.dart';
import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';
import '../changes/build_script_updates.dart';
import '../environment/build_environment.dart';
import '../logging/failure_reporter.dart';
import '../logging/logging.dart';
import '../package_graph/package_graph.dart';
import '../package_graph/target_graph.dart';
import '../util/constants.dart';
import '../util/sdk_version_match.dart';
import 'exceptions.dart';
import 'options.dart';
import 'phase.dart';

final _logger = Logger('BuildDefinition');

class BuildDefinition {
  final AssetGraph assetGraph;
  final TargetGraph targetGraph;

  final AssetReader reader;
  final RunnerAssetWriter writer;

  final PackageGraph packageGraph;
  final bool deleteFilesByDefault;
  final ResourceManager resourceManager;

  final BuildScriptUpdates buildScriptUpdates;

  /// Whether or not to run in a mode that conserves RAM at the cost of build
  /// speed.
  final bool enableLowResourcesMode;

  final BuildEnvironment environment;

  BuildDefinition._(
      this.assetGraph,
      this.targetGraph,
      this.reader,
      this.writer,
      this.packageGraph,
      this.deleteFilesByDefault,
      this.resourceManager,
      this.buildScriptUpdates,
      this.enableLowResourcesMode,
      this.environment);

  static Future<BuildDefinition> prepareWorkspace(BuildEnvironment environment,
          BuildOptions options, List<BuildPhase> buildPhases) =>
      _Loader(environment, options, buildPhases).prepareWorkspace();
}

/// Understands how to find all assets relevant to a build as well as compute
/// updates to those assets.
class AssetTracker {
  final AssetGraph _assetGraph;
  final RunnerAssetReader _reader;
  final TargetGraph _targetGraph;

  AssetTracker(this._assetGraph, this._reader, this._targetGraph);

  /// Checks for and returns any file system changes compared to the current
  /// state of the asset graph.
  Future<Map<AssetId, ChangeType>> collectChanges() async {
    var inputSources = await _findInputSources();
    var generatedSources = await _findCacheDirSources();
    var internalSources = await _findInternalSources();
    return _computeSourceUpdates(
        inputSources, generatedSources, internalSources);
  }

  /// Returns the all the sources found in the cache directory.
  Future<Set<AssetId>> _findCacheDirSources() =>
      _listGeneratedAssetIds().toSet();

  /// Returns the set of original package inputs on disk.
  Future<Set<AssetId>> _findInputSources() {
    final targets =
        Stream<TargetNode>.fromIterable(_targetGraph.allModules.values);
    return targets.asyncExpand(_listAssetIds).toSet();
  }

  /// Returns all the internal sources, such as those under [entryPointDir].
  Future<Set<AssetId>> _findInternalSources() async {
    var ids = await _listIdsSafe(Glob('$entryPointDir/**')).toSet();
    var packageConfigId = AssetId(_targetGraph.rootPackageConfig.packageName,
        '.dart_tool/package_config.json');

    if (await _reader.canRead(packageConfigId)) {
      ids.add(packageConfigId);
    }
    return ids;
  }

  /// Finds the asset changes which have happened while unwatched between builds
  /// by taking a difference between the assets in the graph and the assets on
  /// disk.
  Future<Map<AssetId, ChangeType>> _computeSourceUpdates(
      Set<AssetId> inputSources,
      Set<AssetId> generatedSources,
      Set<AssetId> internalSources) async {
    final allSources = <AssetId>{}
      ..addAll(inputSources)
      ..addAll(generatedSources)
      ..addAll(internalSources);
    var updates = <AssetId, ChangeType>{};
    void addUpdates(Iterable<AssetId> assets, ChangeType type) {
      for (var asset in assets) {
        updates[asset] = type;
      }
    }

    var newSources = inputSources.difference(_assetGraph.allNodes
        .where((node) => node.isValidInput)
        .map((node) => node.id)
        .toSet());
    addUpdates(newSources, ChangeType.ADD);
    var removedAssets = _assetGraph.allNodes
        .where((n) {
          if (!n.isReadable) return false;
          if (n is GeneratedAssetNode) return n.wasOutput;
          return true;
        })
        .map((n) => n.id)
        .where((id) => !allSources.contains(id));

    addUpdates(removedAssets, ChangeType.REMOVE);

    var originalGraphSources = _assetGraph.sources.toSet();
    var preExistingSources = originalGraphSources.intersection(inputSources)
      ..addAll(internalSources.where(_assetGraph.contains));
    var modifyChecks = preExistingSources.map((id) async {
      var node = _assetGraph.get(id);
      assert(node != null);
      var originalDigest = node.lastKnownDigest;
      if (originalDigest == null) return;
      var currentDigest = await _reader.digest(id);
      if (currentDigest != originalDigest) {
        updates[id] = ChangeType.MODIFY;
      }
    });
    await Future.wait(modifyChecks);
    return updates;
  }

  Stream<AssetId> _listAssetIds(TargetNode targetNode) {
    return targetNode.sourceIncludes.isEmpty
        ? Stream<AssetId>.empty()
        : StreamGroup.merge(targetNode.sourceIncludes.map((glob) =>
            _listIdsSafe(glob, package: targetNode.package.name)
                .where((id) =>
                    _targetGraph.isVisibleInBuild(id, targetNode.package))
                .where((id) => !targetNode.excludesSource(id))));
  }

  Stream<AssetId> _listGeneratedAssetIds() {
    var glob = Glob('$generatedOutputDirectory/**');

    return _listIdsSafe(glob).map((id) {
      var packagePath = id.path.substring(generatedOutputDirectory.length + 1);
      var firstSlash = packagePath.indexOf('/');
      if (firstSlash == -1) return null;
      var package = packagePath.substring(0, firstSlash);
      var path = packagePath.substring(firstSlash + 1);
      return AssetId(package, path);
    }).where((id) => id != null);
  }

  /// Lists asset IDs and swallows file not found errors.
  ///
  /// Ideally we would warn but in practice the default sources list will give
  /// this error a lot and it would be noisy.
  Stream<AssetId> _listIdsSafe(Glob glob, {String package}) =>
      _reader.findAssets(glob, package: package).handleError((void _) {},
          test: (e) => e is FileSystemException && e.osError.errorCode == 2);
}

class _Loader {
  final List<BuildPhase> _buildPhases;
  final BuildOptions _options;
  final BuildEnvironment _environment;

  _Loader(this._environment, this._options, this._buildPhases);

  Future<BuildDefinition> prepareWorkspace() async {
    _checkBuildPhases();

    _logger.info('Initializing inputs');

    var assetGraph = await _tryReadCachedAssetGraph();
    var assetTracker =
        AssetTracker(assetGraph, _environment.reader, _options.targetGraph);
    var inputSources = await assetTracker._findInputSources();
    var cacheDirSources = await assetTracker._findCacheDirSources();
    var internalSources = await assetTracker._findInternalSources();

    BuildScriptUpdates buildScriptUpdates;
    if (assetGraph != null) {
      var updates = await logTimedAsync(
          _logger,
          'Checking for updates since last build',
          () => _updateAssetGraph(assetGraph, assetTracker, _buildPhases,
              inputSources, cacheDirSources, internalSources));
      buildScriptUpdates = await BuildScriptUpdates.create(
          _environment.reader, _options.packageGraph, assetGraph,
          disabled: _options.skipBuildScriptCheck);

      var buildScriptUpdated = !_options.skipBuildScriptCheck &&
          buildScriptUpdates.hasBeenUpdated(updates.keys.toSet());
      if (buildScriptUpdated) {
        _logger.warning('Invalidating asset graph due to build script update!');

        var deletedSourceOutputs = await _cleanupOldOutputs(assetGraph);

        if (_runningFromSnapshot) {
          // We have to be regenerated if running from a snapshot.
          throw BuildScriptChangedException();
        }

        inputSources.removeAll(deletedSourceOutputs);
        assetGraph = null;
        buildScriptUpdates = null;
      }
    }

    if (assetGraph == null) {
      Set<AssetId> conflictingOutputs;

      await logTimedAsync(_logger, 'Building new asset graph', () async {
        try {
          assetGraph = await AssetGraph.build(_buildPhases, inputSources,
              internalSources, _options.packageGraph, _environment.reader);
        } on DuplicateAssetNodeException catch (e, st) {
          _logger.severe('Conflicting outputs', e, st);
          throw CannotBuildException();
        }
        buildScriptUpdates = await BuildScriptUpdates.create(
            _environment.reader, _options.packageGraph, assetGraph,
            disabled: _options.skipBuildScriptCheck);

        conflictingOutputs = assetGraph.outputs
            .where((n) => n.package == _options.packageGraph.root.name)
            .where(inputSources.contains)
            .toSet();
        final conflictsInDeps = assetGraph.outputs
            .where((n) => n.package != _options.packageGraph.root.name)
            .where(inputSources.contains)
            .toSet();
        if (conflictsInDeps.isNotEmpty) {
          log.severe('There are existing files in dependencies which conflict '
              'with files that a Builder may produce. These must be removed or '
              'the Builders disabled before a build can continue: '
              '${conflictsInDeps.map((a) => a.uri).join('\n')}');
          throw CannotBuildException();
        }
      });

      await logTimedAsync(
          _logger,
          'Checking for unexpected pre-existing outputs.',
          () => _initialBuildCleanup(conflictingOutputs,
              _wrapWriter(_environment.writer, assetGraph)));
    }

    return BuildDefinition._(
        assetGraph,
        _options.targetGraph,
        _wrapReader(_environment.reader, assetGraph),
        _wrapWriter(_environment.writer, assetGraph),
        _options.packageGraph,
        _options.deleteFilesByDefault,
        ResourceManager(),
        buildScriptUpdates,
        _options.enableLowResourcesMode,
        _environment);
  }

  /// Checks that the [_buildPhases] are valid based on whether they are
  /// written to the build cache.
  void _checkBuildPhases() {
    final root = _options.packageGraph.root.name;
    for (final action in _buildPhases) {
      if (!action.hideOutput) {
        // Only `InBuildPhase`s can be not hidden.
        if (action is InBuildPhase && action.package != root) {
          // This should happen only with a manual build script since the build
          // script generation filters these out.
          _logger.severe('A build phase (${action.builderLabel}) is attempting '
              'to operate on package "${action.package}", but the build script '
              'is located in package "$root". It\'s not valid to attempt to '
              'generate files for another package unless the BuilderApplication'
              'specified "hideOutput".'
              '\n\n'
              'Did you mean to write:\n'
              '  new BuilderApplication(..., toRoot())\n'
              'or\n'
              '  new BuilderApplication(..., hideOutput: true)\n'
              '... instead?');
          throw CannotBuildException();
        }
      }
    }
  }

  /// Deletes the generated output directory.
  ///
  /// Typically this should be done whenever an asset graph is thrown away.
  Future<void> _deleteGeneratedDir() async {
    var generatedDir = Directory(generatedOutputDirectory);
    if (await generatedDir.exists()) {
      await generatedDir.delete(recursive: true);
    }
  }

  /// Attempts to read in an [AssetGraph] from disk, and returns `null` if it
  /// fails for any reason.
  Future<AssetGraph> _tryReadCachedAssetGraph() async {
    final assetGraphId =
        AssetId(_options.packageGraph.root.name, assetGraphPath);
    if (!await _environment.reader.canRead(assetGraphId)) {
      return null;
    }

    return logTimedAsync(_logger, 'Reading cached asset graph', () async {
      try {
        var cachedGraph = AssetGraph.deserialize(
            await _environment.reader.readAsBytes(assetGraphId));
        var buildPhasesChanged = computeBuildPhasesDigest(_buildPhases) !=
            cachedGraph.buildPhasesDigest;
        var pkgVersionsChanged = !const DeepCollectionEquality()
            .equals(cachedGraph.packageLanguageVersions, {
          for (var pkg in _options.packageGraph.allPackages.values)
            pkg.name: pkg.languageVersion
        });
        var enabledExperimentsChanged =
            !const DeepCollectionEquality.unordered()
                .equals(cachedGraph.enabledExperiments, enabledExperiments);
        if (buildPhasesChanged ||
            pkgVersionsChanged ||
            enabledExperimentsChanged) {
          if (buildPhasesChanged) {
            _logger.warning(
                'Throwing away cached asset graph because the build phases have '
                'changed. This most commonly would happen as a result of adding a '
                'new dependency or updating your dependencies.');
          }
          if (pkgVersionsChanged) {
            _logger.warning(
                'Throwing away cached asset graph because the language '
                'version of some package(s) changed. This would most commonly '
                'happen when updating dependencies or changing your min sdk '
                'constraint.');
          }
          if (enabledExperimentsChanged) {
            _logger.warning(
                'Throwing away cached asset graph because the enabled Dart '
                'language experiments changed:\n\n'
                'Previous value: ${cachedGraph.enabledExperiments.join(' ')}\n'
                'Current value: ${enabledExperiments.join(' ')}');
          }
          await Future.wait([
            _deleteAssetGraph(_options.packageGraph),
            _cleanupOldOutputs(cachedGraph),
            FailureReporter.cleanErrorCache(),
          ]);
          if (_runningFromSnapshot) {
            throw BuildScriptChangedException();
          }
          return null;
        }
        if (!isSameSdkVersion(cachedGraph.dartVersion, Platform.version)) {
          _logger.warning(
              'Throwing away cached asset graph due to Dart SDK update.');
          await Future.wait([
            _deleteAssetGraph(_options.packageGraph),
            _cleanupOldOutputs(cachedGraph),
            FailureReporter.cleanErrorCache(),
          ]);
          if (_runningFromSnapshot) {
            throw BuildScriptChangedException();
          }
          return null;
        }
        return cachedGraph;
      } on AssetGraphCorruptedException catch (_) {
        // Start fresh if the cached asset_graph cannot be deserialized
        _logger.warning('Throwing away cached asset graph due to '
            'version mismatch or corrupted asset graph.');
        await Future.wait([
          _deleteGeneratedDir(),
          FailureReporter.cleanErrorCache(),
        ]);
        return null;
      }
    });
  }

  /// Deletes all the old outputs from [graph] that were written to the source
  /// tree, and deletes the entire generated directory.
  Future<Iterable<AssetId>> _cleanupOldOutputs(AssetGraph graph) async {
    var deletedSources = <AssetId>[];
    await logTimedAsync(_logger, 'Cleaning up outputs from previous builds.',
        () async {
      // Delete all the non-hidden outputs.
      await Future.wait(graph.outputs.map((id) {
        var node = graph.get(id) as GeneratedAssetNode;
        if (node.wasOutput && !node.isHidden) {
          var idToDelete = id;
          // If the package no longer exists, then the user must have renamed
          // the root package.
          //
          // In that case we change `idToDelete` to be in the root package.
          if (_options.packageGraph[id.package] == null) {
            idToDelete = AssetId(_options.packageGraph.root.name, id.path);
          }
          deletedSources.add(idToDelete);
          return _environment.writer.delete(idToDelete);
        }
        return null;
      }).whereType<Future>());

      await _deleteGeneratedDir();
    });
    return deletedSources;
  }

  Future<void> _deleteAssetGraph(PackageGraph packageGraph) =>
      File(p.join(packageGraph.root.path, assetGraphPath)).delete();

  /// Updates [assetGraph] based on a the new view of the world.
  ///
  /// Once done, this returns a map of [AssetId] to [ChangeType] for all the
  /// changes.
  Future<Map<AssetId, ChangeType>> _updateAssetGraph(
      AssetGraph assetGraph,
      AssetTracker assetTracker,
      List<BuildPhase> buildPhases,
      Set<AssetId> inputSources,
      Set<AssetId> cacheDirSources,
      Set<AssetId> internalSources) async {
    var updates = await assetTracker._computeSourceUpdates(
        inputSources, cacheDirSources, internalSources);
    updates.addAll(_computeBuilderOptionsUpdates(assetGraph, buildPhases));
    await assetGraph.updateAndInvalidate(
        _buildPhases,
        updates,
        _options.packageGraph.root.name,
        (id) => _wrapWriter(_environment.writer, assetGraph).delete(id),
        _wrapReader(_environment.reader, assetGraph));
    return updates;
  }

  /// Wraps [original] in a [BuildCacheWriter].
  RunnerAssetWriter _wrapWriter(
      RunnerAssetWriter original, AssetGraph assetGraph) {
    assert(assetGraph != null);
    return BuildCacheWriter(
        original, assetGraph, _options.packageGraph.root.name);
  }

  /// Wraps [original] in a [BuildCacheReader].
  AssetReader _wrapReader(AssetReader original, AssetGraph assetGraph) {
    assert(assetGraph != null);
    return BuildCacheReader(
        original, assetGraph, _options.packageGraph.root.name);
  }

  /// Checks for any updates to the [BuilderOptionsAssetNode]s for
  /// [buildPhases] compared to the last known state.
  Map<AssetId, ChangeType> _computeBuilderOptionsUpdates(
      AssetGraph assetGraph, List<BuildPhase> buildPhases) {
    var result = <AssetId, ChangeType>{};

    void updateBuilderOptionsNode(
        AssetId builderOptionsId, BuilderOptions options) {
      var builderOptionsNode =
          assetGraph.get(builderOptionsId) as BuilderOptionsAssetNode;
      var oldDigest = builderOptionsNode.lastKnownDigest;
      builderOptionsNode.lastKnownDigest = computeBuilderOptionsDigest(options);
      if (builderOptionsNode.lastKnownDigest != oldDigest) {
        result[builderOptionsId] = ChangeType.MODIFY;
      }
    }

    for (var phase = 0; phase < buildPhases.length; phase++) {
      var action = buildPhases[phase];
      if (action is InBuildPhase) {
        updateBuilderOptionsNode(
            builderOptionsIdForAction(action, phase), action.builderOptions);
      } else if (action is PostBuildPhase) {
        var actionNum = 0;
        for (var builderAction in action.builderActions) {
          updateBuilderOptionsNode(
              builderOptionsIdForAction(builderAction, actionNum),
              builderAction.builderOptions);
          actionNum++;
        }
      }
    }
    return result;
  }

  /// Handles cleanup of pre-existing outputs for initial builds (where there is
  /// no cached graph).
  Future<void> _initialBuildCleanup(
      Set<AssetId> conflictingAssets, RunnerAssetWriter writer) async {
    if (conflictingAssets.isEmpty) return;

    // Skip the prompt if using this option.
    if (_options.deleteFilesByDefault) {
      _logger.info('Deleting ${conflictingAssets.length} declared outputs '
          'which already existed on disk.');
      await Future.wait(conflictingAssets.map((id) => writer.delete(id)));
      return;
    }

    // Prompt the user to delete files that are declared as outputs.
    _logger.info('Found ${conflictingAssets.length} declared outputs '
        'which already exist on disk. This is likely because the'
        '`$cacheDir` folder was deleted, or you are submitting generated '
        'files to your source repository.');

    var done = false;
    while (!done) {
      try {
        var choice = await _environment.prompt('Delete these files?',
            ['Delete', 'Cancel build', 'List conflicts']);
        switch (choice) {
          case 0:
            _logger.info('Deleting files...');
            done = true;
            await Future.wait(conflictingAssets.map((id) => writer.delete(id)));
            break;
          case 1:
            _logger.severe('The build will not be able to contiue until the '
                'conflicting assets are removed or the Builders which may '
                'output them are disabled. The outputs are: '
                '${conflictingAssets.map((a) => a.path).join('\n')}');
            throw CannotBuildException();
            break;
          case 2:
            _logger.info('Conflicts:\n${conflictingAssets.join('\n')}');
            // Logging should be sync :(
            await Future(() {});
        }
      } on NonInteractiveBuildException {
        _logger.severe('Conflicting outputs were detected and the build '
            'is unable to prompt for permission to remove them. '
            'These outputs must be removed manually or the build can be '
            'run with `--delete-conflicting-outputs`. The outputs are: '
            '${conflictingAssets.map((a) => a.path).join('\n')}');
        throw CannotBuildException();
      }
    }
  }
}

bool get _runningFromSnapshot => !Platform.script.path.endsWith('.dart');
