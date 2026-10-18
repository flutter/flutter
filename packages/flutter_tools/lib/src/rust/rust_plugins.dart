// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:package_config/package_config.dart';

import '../base/common.dart';
import '../base/error_handling_io.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/net.dart';
import '../cache.dart';
import '../convert.dart';
import '../dart/package_map.dart';
import '../globals.dart' as globals;
import '../package_graph.dart';
import '../project.dart';
import 'native_libraries.dart';

const rustPluginDependenciesBegin = '# === BEGIN FLUTTER GENERATED RUST PLUGINS ===';
const rustPluginDependenciesEnd = '# === END FLUTTER GENERATED RUST PLUGINS ===';

/// Version of the tool-owned runner files generated from `templates/rust_shell`.
/// Keep in sync with the `flutter-rust-runner-version` marker in the templates.
const rustRunnerVersion = 4;
const _rustRunnerVersionMarker = '// flutter-rust-runner-version: ';
const _rustShellBundleUrl =
    'https://github.com/nrbnlulu/flutter/releases/download/BETA/flutter-rust-linux-x64.tar.gz';

final RegExp _rustPath = RegExp(
  r'^(?:r#)?[A-Za-z_][A-Za-z0-9_]*(?:::(?:r#)?[A-Za-z_][A-Za-z0-9_]*)*$',
);

class RustPlugin {
  const RustPlugin({
    required this.dartPackageName,
    required this.cargoPackageName,
    required this.registrar,
    required this.rustDirectory,
  });

  final String dartPackageName;
  final String cargoPackageName;
  final String registrar;
  final Directory rustDirectory;

  String get dependencyAlias => 'flutter_rs_plugin_$dartPackageName';
}

String replaceGeneratedRustDependencies(String manifest, List<String> dependencies) {
  final int begin = manifest.indexOf(rustPluginDependenciesBegin);
  final int end = manifest.indexOf(rustPluginDependenciesEnd);
  if (begin < 0 || end < 0 || begin >= end) {
    throwToolExit(
      'runner-rs/Cargo.toml must contain one valid Flutter generated Rust plugins section.',
    );
  }
  if (manifest.indexOf(rustPluginDependenciesBegin, begin + 1) >= 0 ||
      manifest.indexOf(rustPluginDependenciesEnd, end + 1) >= 0) {
    throwToolExit(
      'runner-rs/Cargo.toml contains more than one Flutter generated Rust plugins section.',
    );
  }
  final int contentStart = begin + rustPluginDependenciesBegin.length;
  final generated = dependencies.isEmpty ? '\n' : '\n${dependencies.join('\n')}\n';
  return manifest.replaceRange(contentStart, end, generated);
}

Future<void> refreshRustPlugins(
  FlutterProject project, {
  required bool releaseMode,
  PackageGraph? packageGraph,
  PackageConfig? packageConfig,
}) async {
  if (!project.manifest.usesRustShell) {
    return;
  }
  final Directory runner = project.directory.childDirectory('runner-rs');
  final File cargoManifest = runner.childFile('Cargo.toml');
  if (!cargoManifest.existsSync()) {
    throwToolExit('Rust-shell project is missing ${cargoManifest.path}.');
  }

  await _ensureRustShellSdk(project);
  _regenerateRunnerIfOutdated(project, runner);

  final bool useSharedResources =
      packageGraph != null && packageGraph.dependencies.containsKey(project.manifest.appName);
  final File packageConfigFile = findPackageConfigFileOrDefault(project.directory);
  final PackageConfig resolvedPackageConfig =
      (useSharedResources ? packageConfig : null) ??
      await loadPackageConfigWithLogging(packageConfigFile, logger: globals.logger);
  final List<Dependency> dependencies = computeTransitiveDependencies(
    project,
    resolvedPackageConfig,
    packageGraph: useSharedResources ? packageGraph : null,
  );
  final plugins = <RustPlugin>[];
  final nativeLibraries = <RustNativeLibrary>[];
  for (final dependency in dependencies) {
    if (dependency.name == project.manifest.appName ||
        (releaseMode && dependency.isExclusiveDevDependency)) {
      continue;
    }
    final Directory rustDirectory = globals.fs.directory(dependency.rootUri.resolve('rust/'));
    final File manifest = rustDirectory.childFile('Cargo.toml');
    if (!manifest.existsSync()) {
      continue;
    }
    final (RustPlugin? plugin, RustNativeLibrary? nativeLibrary) = await _readRustPackage(
      dependency.name,
      rustDirectory,
      manifest,
    );
    if (plugin != null) {
      plugins.add(plugin);
    } else if (nativeLibrary != null) {
      nativeLibraries.add(nativeLibrary);
    }
  }
  writeNativeLibraries(project, nativeLibraries);
  plugins.sort(
    (RustPlugin left, RustPlugin right) => left.dartPackageName.compareTo(right.dartPackageName),
  );

  final Directory links = project.directory
      .childDirectory('.dart_tool')
      .childDirectory('flutter_rs')
      .childDirectory('plugins');
  links.createSync(recursive: true);
  final keep = <String>{};
  for (final plugin in plugins) {
    keep.add(plugin.dartPackageName);
    _replaceLink(links.childLink(plugin.dartPackageName), plugin.rustDirectory.path);
  }
  for (final FileSystemEntity entity in links.listSync(followLinks: false)) {
    if (!keep.contains(entity.basename)) {
      ErrorHandlingFileSystem.deleteIfExists(entity, recursive: true);
    }
  }

  final dependencyLines = <String>[
    for (final RustPlugin plugin in plugins)
      '${plugin.dependencyAlias} = { package = "${plugin.cargoPackageName}", path = "../.dart_tool/flutter_rs/plugins/${plugin.dartPackageName}" }',
  ];
  final String oldManifest = cargoManifest.readAsStringSync();
  final String newManifest = replaceGeneratedRustDependencies(oldManifest, dependencyLines);
  if (newManifest != oldManifest) {
    cargoManifest.writeAsStringSync(newManifest);
  }

  final File registrant = runner.childDirectory('src').childFile('flutter_plugins.rs');
  final buffer = StringBuffer()
    ..writeln('// Generated by Flutter. Do not edit.')
    ..writeln()
    ..writeln('use flutter_plugin_sdk::{PluginRegistrar, Result};')
    ..writeln()
    ..writeln('pub(crate) fn register_plugins(registrar: &mut PluginRegistrar) -> Result<()> {');
  if (plugins.isEmpty) {
    buffer.writeln('    let _ = registrar;');
  } else {
    for (final plugin in plugins) {
      buffer.writeln('    ${plugin.dependencyAlias}::${plugin.registrar}(registrar)?;');
    }
  }
  buffer
    ..writeln('    Ok(())')
    ..writeln('}');
  final generatedRegistrant = buffer.toString();
  if (!registrant.existsSync() || registrant.readAsStringSync() != generatedRegistrant) {
    registrant.createSync(recursive: true);
    registrant.writeAsStringSync(generatedRegistrant);
  }
  if (plugins.isNotEmpty) {
    await _validatePluginSdkResolution(cargoManifest, runner);
  }
}

Future<void> _validatePluginSdkResolution(File manifest, Directory runner) async {
  final ProcessResult result = await globals.processManager.run(<String>[
    'cargo',
    'metadata',
    '--format-version',
    '1',
    '--manifest-path',
    manifest.path,
  ], workingDirectory: runner.path);
  if (result.exitCode != 0) {
    throwToolExit('Unable to resolve Rust-shell dependencies:\n${result.stderr}');
  }
  final metadata = json.decode(result.stdout as String) as Map<String, Object?>;
  final List<Map<String, Object?>> packages = (metadata['packages']! as List<Object?>)
      .cast<Map<String, Object?>>();
  final Iterable<Map<String, Object?>> sdkPackages = packages.where(
    (Map<String, Object?> package) => package['name'] == 'flutter-plugin-sdk',
  );
  if (sdkPackages.length != 1) {
    throwToolExit(
      'Rust-shell applications must resolve exactly one flutter-plugin-sdk package; '
      'Cargo resolved ${sdkPackages.length}.',
    );
  }
}

Future<(RustPlugin?, RustNativeLibrary?)> _readRustPackage(
  String dartPackageName,
  Directory rustDirectory,
  File manifest,
) async {
  if (!globals.processManager.canRun('cargo')) {
    throwToolExit('Cargo is required to resolve Rust-shell plugins. Install Rust and try again.');
  }
  final ProcessResult result = await globals.processManager.run(<String>[
    'cargo',
    'metadata',
    '--no-deps',
    '--format-version',
    '1',
    '--manifest-path',
    manifest.path,
  ]);
  if (result.exitCode != 0) {
    throwToolExit('Unable to read ${manifest.path}:\n${result.stderr}');
  }
  final metadata = json.decode(result.stdout as String) as Map<String, Object?>;
  final List<Map<String, Object?>> packages = (metadata['packages']! as List<Object?>)
      .cast<Map<String, Object?>>();
  final String manifestPath = globals.fs.path.canonicalize(manifest.path);
  final Map<String, Object?> package = packages.firstWhere(
    (Map<String, Object?> value) =>
        globals.fs.path.canonicalize(value['manifest_path']! as String) == manifestPath,
    orElse: () => throwToolExit('Cargo metadata did not describe ${manifest.path}.'),
  );
  final flutterMetadata =
      (package['metadata'] as Map<String, Object?>?)?['flutter'] as Map<String, Object?>?;
  if (flutterMetadata?['plugin'] != true) {
    return (null, _readNativeLibrary(dartPackageName, package, manifest, flutterMetadata));
  }
  final Object? registrarValue = flutterMetadata?['registrar'];
  if (registrarValue is! String || !_rustPath.hasMatch(registrarValue)) {
    throwToolExit(
      'Rust plugin $dartPackageName must provide a valid '
      '[package.metadata.flutter] registrar.',
    );
  }
  return (
    RustPlugin(
      dartPackageName: dartPackageName,
      cargoPackageName: package['name']! as String,
      registrar: registrarValue,
      rustDirectory: rustDirectory,
    ),
    null,
  );
}

/// A package with a Rust `cdylib` but no Rust-shell plugin metadata, such as a
/// flutter_rust_bridge package. It keeps its own shared library (statically
/// linking several flutter_rust_bridge crates into one executable fails with
/// duplicate `frb_*` symbols), loaded by name at runtime.
RustNativeLibrary? _readNativeLibrary(
  String dartPackageName,
  Map<String, Object?> package,
  File manifest,
  Map<String, Object?>? flutterMetadata,
) {
  for (final Object? target in package['targets'] as List<Object?>? ?? const <Object?>[]) {
    final targetMap = target! as Map<String, Object?>;
    final List<Object?> crateTypes =
        (targetMap['crate_types'] as List<Object?>?) ?? const <Object?>[];
    if (!crateTypes.contains('cdylib')) {
      continue;
    }
    final Object? rustflags = flutterMetadata?['rustflags'];
    if (rustflags != null &&
        (rustflags is! List<Object?> || rustflags.any((Object? f) => f is! String))) {
      throwToolExit(
        'Rust package $dartPackageName must provide [package.metadata.flutter] '
        'rustflags as a list of strings.',
      );
    }
    return RustNativeLibrary(
      dartPackageName: dartPackageName,
      manifestPath: manifest.path,
      libraryName: (targetMap['name']! as String).replaceAll('-', '_'),
      rustflags: rustflags == null ? const <String>[] : (rustflags as List<Object?>).cast<String>(),
    );
  }
  return null;
}

Future<void> _ensureRustShellSdk(FlutterProject project) async {
  final Directory sdk = project.directory
      .childDirectory('.dart_tool')
      .childDirectory('flutter_rs')
      .childDirectory('sdk');
  final File sdkManifest = sdk
      .childDirectory('crates')
      .childDirectory('flutter-plugin-sdk')
      .childFile('Cargo.toml');
  final File sdkWorkspaceManifest = sdk.childFile('Cargo.toml');
  // Cargo's build.rs picks the engine under sdk/lib/<profile>/ matching the
  // profile it was invoked with (debug or release); the debug engine is the
  // mandatory baseline since debug is always supported.
  final File engineLibrary = sdk
      .childDirectory('lib')
      .childDirectory('debug')
      .childFile('libflutter_rust_engine.so');

  // A local engine checkout's per-profile builds can appear (e.g. a release
  // engine built after this SDK was first linked) independently of whether
  // the rest of the SDK is already set up, so always re-check both rather
  // than only doing this the first time the SDK directory is created.
  final Directory localShell = globals.fs.directory(
    globals.fs.path.join(
      Cache.flutterRoot!,
      'engine',
      'src',
      'flutter',
      'shell',
      'platform',
      'rust',
    ),
  );
  if (localShell.childDirectory('crates').existsSync()) {
    // Always re-sync with the local checkout: an SDK directory created
    // earlier (from another checkout or the downloaded bundle) would
    // otherwise keep Rust crates that no longer match the engine library
    // linked below, which fails at runtime with a misaligned shell ABI.
    sdk.createSync(recursive: true);
    _copyIfChanged(localShell.childFile('Cargo.toml'), sdkWorkspaceManifest);
    _copyIfChanged(localShell.childFile('Cargo.lock'), sdk.childFile('Cargo.lock'));
    _replaceLink(sdk.childLink('crates'), localShell.childDirectory('crates').path);
    _replaceLink(sdk.childLink('third_party'), localShell.childDirectory('third_party').path);
    final Directory outDir = globals.fs.directory(
      globals.fs.path.join(Cache.flutterRoot!, 'engine', 'src', 'out'),
    );
    _linkLocalEngine(sdk, outDir.childDirectory('host_debug'), 'debug');
    _linkLocalEngine(sdk, outDir.childDirectory('host_release'), 'release');
    if (engineLibrary.existsSync()) {
      return;
    }
  }

  if (sdkWorkspaceManifest.existsSync() && sdkManifest.existsSync() && engineLibrary.existsSync()) {
    return;
  }

  if (!globals.platform.isLinux) {
    throwToolExit('The BETA Rust-shell SDK currently provides Linux x64 artifacts only.');
  }
  globals.logger.printStatus('Downloading the Flutter Rust shell BETA SDK...');
  final File archive = project.directory
      .childDirectory('.dart_tool')
      .childDirectory('flutter_rs')
      .childFile('flutter-rust-sdk.tar.gz');
  archive.parent.createSync(recursive: true);
  final net = Net(
    httpClientFactory: globals.httpClientFactory,
    logger: globals.logger,
    platform: globals.platform,
  );
  final List<int>? result = await net.fetchUrl(
    Uri.parse(_rustShellBundleUrl),
    maxAttempts: 3,
    destFile: archive,
  );
  if (result == null) {
    throwToolExit('Unable to download the Flutter Rust shell BETA SDK.');
  }
  if (sdk.existsSync()) {
    ErrorHandlingFileSystem.deleteIfExists(sdk, recursive: true);
  }
  sdk.createSync(recursive: true);
  globals.os.unpack(archive, sdk);
  ErrorHandlingFileSystem.deleteIfExists(archive);
  if (!sdkWorkspaceManifest.existsSync() ||
      !sdkManifest.existsSync() ||
      !engineLibrary.existsSync()) {
    throwToolExit('The Flutter Rust shell BETA SDK archive is incomplete.');
  }
}

void _copyIfChanged(File source, File destination) {
  if (destination.existsSync() && destination.readAsStringSync() == source.readAsStringSync()) {
    return;
  }
  source.copySync(destination.path);
}

/// Regenerates the tool-owned runner files (`build.rs`, `src/main.rs`) when
/// their `flutter-rust-runner-version` marker is absent or differs from
/// [rustRunnerVersion], e.g. for projects created by an older Flutter tool.
///
/// Bump [rustRunnerVersion] and the marker in the templates whenever the
/// runner must change in lockstep with the SDK or engine.
void _regenerateRunnerIfOutdated(FlutterProject project, Directory runner) {
  final File buildScript = runner.childFile('build.rs');
  final File main = runner.childDirectory('src').childFile('main.rs');
  const marker = '$_rustRunnerVersionMarker$rustRunnerVersion';
  bool isCurrent(File file) =>
      file.existsSync() &&
      RegExp('${RegExp.escape(marker)}\\s*\$', multiLine: true).hasMatch(file.readAsStringSync());
  if (isCurrent(buildScript) && isCurrent(main)) {
    return;
  }

  final Directory templates = globals.fs.directory(
    globals.fs.path.join(
      Cache.flutterRoot!,
      'packages',
      'flutter_tools',
      'templates',
      'rust_shell',
      'runner-rs',
    ),
  );
  final File buildTemplate = templates.childFile('build.rs.tmpl');
  final File mainTemplate = templates.childDirectory('src').childFile('main.rs.tmpl');
  if (!buildTemplate.existsSync() || !mainTemplate.existsSync()) {
    return;
  }
  buildScript.writeAsStringSync(buildTemplate.readAsStringSync());
  main.createSync(recursive: true);
  main.writeAsStringSync(
    mainTemplate.readAsStringSync().replaceAll('{{projectName}}', project.manifest.appName),
  );
  globals.logger.printStatus(
    'Regenerated runner-rs/build.rs and runner-rs/src/main.rs (runner version $rustRunnerVersion).',
  );
}

/// Symlinks a local `out/host_<profile>` engine build's library and ICU data
/// into `sdk/lib/<profile>/`, if that engine build exists. Does nothing
/// otherwise (e.g. a checkout that has only built the debug engine).
///
/// Local checkouts compile kernels by passing `--local-engine*` flags at the
/// real `out/` directory instead.
void _linkLocalEngine(Directory sdk, Directory localEngine, String profile) {
  if (!localEngine.childFile('libflutter_rust_engine.so').existsSync()) {
    return;
  }
  final Directory libDir = sdk.childDirectory('lib').childDirectory(profile);
  libDir.createSync(recursive: true);
  // Never replace files inside the engine build itself if `lib/<profile>`
  // was manually pointed at it.
  if (libDir.resolveSymbolicLinksSync() == localEngine.resolveSymbolicLinksSync()) {
    return;
  }
  _replaceLink(
    libDir.childLink('libflutter_rust_engine.so'),
    localEngine.childFile('libflutter_rust_engine.so').path,
  );
  _replaceLink(libDir.childLink('icudtl.dat'), localEngine.childFile('icudtl.dat').path);
}

void _replaceLink(Link link, String target) {
  final FileSystemEntityType type = link.fileSystem.typeSync(link.path, followLinks: false);
  if (type == FileSystemEntityType.link) {
    try {
      if (link.targetSync() == target && link.existsSync()) {
        return;
      }
    } on FileSystemException {
      // Replace broken links below.
    }
  }
  if (type != FileSystemEntityType.notFound) {
    ErrorHandlingFileSystem.deleteIfExists(link, recursive: true);
  }
  link.createSync(target, recursive: true);
}
