// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:meta/meta.dart';

import '../base/file_system.dart';
import '../build_info.dart';
import '../build_system/build_system.dart';
import '../build_system/depfile.dart';
import '../convert.dart';
import '../globals.dart' as globals;

/// Represents a configured deferred component as defined in
/// the app's pubspec.yaml.
class DeferredComponent {
  DeferredComponent({
    @required this.name,
    this.libraries = const <String>[],
    this.assets = const <Uri>[],
  }) : _assigned = false;

  /// The name of the deferred component. There should be a matching
  /// android dynamic feature module with the same name.
  final String name;

  /// The dart libraries this component includes as listed in pubspec.yaml.
  ///
  /// This list is only of dart libraries manually configured to be in this component.
  /// Valid libraries that are listed here will always be guaranteed to be
  /// packaged in this component. However, libraries that are not listed here
  /// may also be included if the loading units that are needed also contain
  /// libraries that are not listed here.
  final List<String> libraries;

  /// Assets that are part of this component as a Uri relative to the project directory.
  final List<Uri> assets;

  /// The minimal set of [LoadingUnit]s needed that contain all of the dart libraries in
  /// [libraries].
  ///
  /// Each [LoadingUnit] contains the compiled code for a set of dart libraries. Each
  /// [DeferredComponent] contains a list of dart libraries that must be included in the
  /// component. The set [loadingUnits] is all of the [LoadingUnit]s needed such that
  /// all required dart libs in [libraries] are in the union of the [LoadingUnit.libraries]
  /// included by the loading units in [loadingUnits].
  ///
  /// When [loadingUnits] is non-null, then the component is considered [assigned] and the
  /// field [assigned] will be true. When [loadingUnits] is null, then the component is
  /// unassigned and should not be used for any tasks that require loading unit information.
  /// When using [loadingUnits], [assigned] should be checked first. Loading units can be
  /// assigned with [assignLoadingUnits].
  Set<LoadingUnit> get loadingUnits => _loadingUnits;
  Set<LoadingUnit> _loadingUnits;

  /// Indicates if the component has loading units assigned.
  ///
  /// Unassigned components simply reflect the pubspec.yaml configuration directly,
  /// contain no loading unit data, and [loadingUnits] is null. Once assigned, the component
  /// will contain a set of [loadingUnits] which contains the [LoadingUnit]s that the
  /// component needs to include. Loading units can be assigned with the [assignLoadingUnits]
  /// call.
  bool get assigned => _assigned;
  bool _assigned;

  /// Selects the [LoadingUnit]s that contain this component's dart libraries.
  ///
  /// After calling this method, this [DeferredComponent] will be considered [assigned],
  /// and [loadingUnits] will return a non-null result.
  ///
  /// [LoadingUnit]s in `allLoadingUnits` that contain libraries that are in [libraries]
  /// are added to the set [loadingUnits].
  ///
  /// Providing null or empty list of `allLoadingUnits` will still change the assigned
  /// status, but will result in [loadingUnits] returning an empty set.
  void assignLoadingUnits(List<LoadingUnit> allLoadingUnits) {
    _assigned = true;
    _loadingUnits = <LoadingUnit>{};
    if (allLoadingUnits == null) {
      return;
    }
    for (final String lib in libraries) {
      for (final LoadingUnit loadingUnit in allLoadingUnits) {
        if (loadingUnit.libraries.contains(lib)) {
          _loadingUnits.add(loadingUnit);
        }
      }
    }
  }

  /// Provides a human readable string representation of the
  /// configuration.
  @override
  String toString() {
    String out = '\nDeferredComponent: $name\n  Libs:';
    for (final String lib in libraries) {
      out += '\n    $lib';
    }
    out += '\n  LoadingUnits:';
    if (loadingUnits != null) {
      for (final LoadingUnit loadingUnit in loadingUnits) {
        out += '\n    ${loadingUnit.id}';
      }
    }
    out += '\n  Assets:';
    for (final Uri asset in assets) {
      out += '\n    ${asset.path}';
    }
    return out;
  }
}

/// Represents a single loading unit and holds information regarding it's id,
/// shared library path, and dart libraries in it.
class LoadingUnit {
  /// Constructs a [LoadingUnit].
  ///
  /// Loading units must include an [id] and [libraries]. The [path] is only present when
  /// parsing the loading unit from a laoding unit manifest produced by gen_snapshot.
  LoadingUnit({
    @required this.id,
    @required this.libraries,
    this.path,
  });

  /// The unique loading unit id that is used to identify the loading unit within dart.
  final int id;

  /// A list of dart libraries that the loading unit contains.
  final List<String> libraries;

  /// The output path of the shared library .so file created by gen_snapshot.
  ///
  /// This value may be null when the loading unit is parsed from a
  /// `deferred_components_golden.yaml` file, which does not store the path.
  final String path;

  /// Returns a human readable string representation of this LoadingUnit, ignoring
  /// the [path] field. The [path] is not included as it is not relevant when the
  @override
  String toString() {
    String out = '\nLoadingUnit $id\n  Libraries:';
    for (final String lib in libraries) {
      out += '\n  - $lib';
    }
    return out;
  }

  /// Returns true if the other loading unit has the same [id] and the same set of [libraries],
  /// ignoring order.
  bool equalsIgnoringPath(LoadingUnit other) {
    return other.id == id && other.libraries.toSet().containsAll(libraries);
  }

  /// Parses the loading unit manifests from the [Environment.outputDir] of the latest
  /// gen_snapshot/assemble run.
  ///
  /// This will read all existing loading units for every provided abi. If no abis are
  /// provided, loading units for all abis will be parsed.
  static List<LoadingUnit> parseGeneratedLoadingUnits(Environment env, {List<String> abis}) {
    final List<LoadingUnit> loadingUnits = <LoadingUnit>[];
    final List<FileSystemEntity> files = env.outputDir.listSync(recursive: true);
    while (files.isNotEmpty) {
      if (files.last is File) {
        final File file = files.last as File;
        // Determine if the abi is one we build.
        bool matchingAbi = abis == null;
        if (abis != null) {
          for (final String abi in abis) {
            if (file.parent.path.endsWith(abi)) {
              matchingAbi = true;
              break;
            }
          }
        }
        if (!file.path.endsWith('manifest.json') || !matchingAbi) {
          files.removeLast();
          continue;
        }
        loadingUnits.addAll(parseLoadingUnitManifest(file));
      }
      files.removeLast();
    }
    return loadingUnits;
  }

  /// Parses loading units from a single loading unit manifest json file.
  ///
  /// Returns an empty list if the manifestFile does not exist or is invalid.
  static List<LoadingUnit> parseLoadingUnitManifest(File manifestFile) {
    if (!manifestFile.existsSync()) {
      return <LoadingUnit>[];
    }
    // Read gen_snapshot manifest
    final String fileString = manifestFile.readAsStringSync();
    Map<String, dynamic> manifest;
    try {
      manifest = jsonDecode(fileString) as Map<String, dynamic>;
    } on FormatException catch (e) {
      globals.printError(e.toString());
    }
    final List<LoadingUnit> loadingUnits = <LoadingUnit>[];
    // Setup android source directory
    if (manifest != null) {
      for (final dynamic loadingUnitMetadata in manifest['loadingUnits']) {
        final Map<String, dynamic> loadingUnitMap = loadingUnitMetadata as Map<String, dynamic>;
        if (loadingUnitMap['id'] == 1) {
          continue; // Skip base unit
        }
        loadingUnits.add(LoadingUnit(
          id: loadingUnitMap['id'] as int,
          path: loadingUnitMap['path'] as String,
          libraries: List<String>.from(loadingUnitMap['libraries'] as List<dynamic>)),
        );
      }
    }
    return loadingUnits;
  }
}

/// Utility method to copy and rename the required .so shared libs from the build output
/// to the correct component intermediate directory.
///
/// The [DeferredComponent]s passed to this method must have had loading units assigned.
/// Assigned components are components that have determined which loading units contains
/// the dart libraries it has via the DeferredComponent.assignLoadingUnits method.
Depfile copyDeferredComponentSoFiles(
    Environment env,
    List<DeferredComponent> components,
    List<LoadingUnit> loadingUnits,
    Directory buildDir, // generally `<projectDir>/build`
    List<String> abis,
    BuildMode buildMode,) {
  final List<File> inputs = <File>[];
  final List<File> outputs = <File>[];
  final Set<int> usedLoadingUnits = <int>{};
  // Copy all .so files for loading units that are paired with a deferred component.
  for (final String abi in abis) {
    for (final DeferredComponent component in components) {
      if (!component.assigned) {
        globals.printError('Deferred component require loading units to be assigned.');
        return Depfile(inputs, outputs);
      }
      for (final LoadingUnit unit in component.loadingUnits) {
        // ensure the abi for the unit is one of the abis we build for.
        final List<String> splitPath = unit.path.split(env.fileSystem.path.separator);
        if (splitPath[splitPath.length - 2] != abi) {
          continue;
        }
        usedLoadingUnits.add(unit.id);
        // the deferred_libs directory is added as a source set for the component.
        final File destination = buildDir
            .childDirectory(component.name)
            .childDirectory('intermediates')
            .childDirectory('flutter')
            .childDirectory(buildMode.name)
            .childDirectory('deferred_libs')
            .childDirectory(abi)
            .childFile('libapp.so-${unit.id}.part.so');
        final File source = env.fileSystem.file(unit.path);
        source.copySync(destination.path);
        inputs.add(source);
        outputs.add(destination);
      }
    }
  }
  // Copy unused loading units, which are included in the base module.
  for (final String abi in abis) {
    for (final LoadingUnit unit in loadingUnits) {
      if (usedLoadingUnits.contains(unit.id)) {
        continue;
      }
        // ensure the abi for the unit is one of the abis we build for.
      final List<String> splitPath = unit.path.split(env.fileSystem.path.separator);
      if (splitPath[splitPath.length - 2] != abi) {
        continue;
      }
      final File destination = env.outputDir
          .childDirectory(abi)
          // Omit 'lib' prefix here as it is added by the gradle task that adds 'lib' to 'app.so'.
          .childFile('app.so-${unit.id}.part.so');
      final File source = env.fileSystem.file(unit.path);
      source.copySync(destination.path);
      inputs.add(source);
      outputs.add(destination);
    }
  }
  return Depfile(inputs, outputs);
}
