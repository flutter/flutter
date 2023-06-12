// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart' show BuilderOptions;
import 'package:build_config/build_config.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:graphs/graphs.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import '../package_graph/build_config_overrides.dart';
import 'builder_ordering.dart';

const scriptLocation = '$entryPointDir/build.dart';
const scriptSnapshotLocation = '$scriptLocation.snapshot';

final _log = Logger('Entrypoint');

Future<String> generateBuildScript() =>
    logTimedAsync(_log, 'Generating build script', _generateBuildScript);

Future<String> _generateBuildScript() async {
  final builders = await findBuilderApplications();
  final library = Library((b) => b.body.addAll([
        literalList(
                builders,
                refer('BuilderApplication',
                    'package:build_runner_core/build_runner_core.dart'))
            .assignFinal('_builders')
            .statement,
        _main()
      ]));
  final emitter = DartEmitter(Allocator.simplePrefixing());
  try {
    return DartFormatter().format('''
      // Ensure that the build script itself is not opted in to null safety,
      // instead of taking the language version from the current package.
      //
      // @dart=2.9
      //
      // ignore_for_file: directives_ordering

      ${library.accept(emitter)}''');
  } on FormatterException {
    _log.severe('Generated build script could not be parsed.\n'
        'This is likely caused by a misconfigured builder definition.');
    throw CannotBuildException();
  }
}

/// Finds expressions to create all the `BuilderApplication` instances that
/// should be applied packages in the build.
///
/// Adds `apply` expressions based on the BuildefDefinitions from any package
/// which has a `build.yaml`.
///
/// Optionally, a custom [packageGraph] and [buildConfigOverrides] can be used
/// to change which packages and build configurations are considered.
/// By default, the [PackageGraph.forThisPackage] will be used and configuration
/// overrides will be loaded from the root package.
Future<Iterable<Expression>> findBuilderApplications({
  PackageGraph packageGraph,
  Map<String, BuildConfig> buildConfigOverrides,
}) async {
  packageGraph ??= await PackageGraph.forThisPackage();
  final orderedPackages = stronglyConnectedComponents<PackageNode>(
    [packageGraph.root],
    (node) => node.dependencies,
    equals: (a, b) => a.name == b.name,
    hashCode: (n) => n.name.hashCode,
  ).expand((c) => c);
  buildConfigOverrides ??= await findBuildConfigOverrides(
      packageGraph, null, FileBasedAssetReader(packageGraph));
  Future<BuildConfig> _packageBuildConfig(PackageNode package) async {
    if (buildConfigOverrides.containsKey(package.name)) {
      return buildConfigOverrides[package.name];
    }
    try {
      return await BuildConfig.fromBuildConfigDir(
          package.name, package.dependencies.map((n) => n.name), package.path);
    } on ArgumentError catch (_) {
      // During the build an error will be logged.
      return BuildConfig.useDefault(
          package.name, package.dependencies.map((n) => n.name));
    }
  }

  bool _isValidDefinition(dynamic definition) {
    // Filter out builderDefinitions with relative imports that aren't
    // from the root package, because they will never work.
    if (definition.import.startsWith('package:') as bool) return true;
    return definition.package == packageGraph.root.name;
  }

  final orderedConfigs =
      await Future.wait(orderedPackages.map(_packageBuildConfig));
  final builderDefinitions = orderedConfigs
      .expand((c) => c.builderDefinitions.values)
      .where(_isValidDefinition);

  final orderedBuilders = findBuilderOrder(builderDefinitions).toList();

  final postProcessBuilderDefinitions = orderedConfigs
      .expand((c) => c.postProcessBuilderDefinitions.values)
      .where(_isValidDefinition);

  return [
    for (var builder in orderedBuilders) _applyBuilder(builder),
    for (var builder in postProcessBuilderDefinitions)
      _applyPostProcessBuilder(builder)
  ];
}

/// A method forwarding to `run`.
Method _main() => Method((b) => b
  ..name = 'main'
  ..returns = refer('void')
  ..modifier = MethodModifier.async
  ..requiredParameters.add(Parameter((b) => b
    ..name = 'args'
    ..type = TypeReference((b) => b
      ..symbol = 'List'
      ..types.add(refer('String')))))
  ..optionalParameters.add(Parameter((b) => b
    ..name = 'sendPort'
    ..type = refer('SendPort', 'dart:isolate')))
  ..body = Block.of([
    refer('run', 'package:build_runner/build_runner.dart')
        .call([refer('args'), refer('_builders')])
        .awaited
        .assignVar('result')
        .statement,
    refer('sendPort')
        .nullSafeProperty('send')
        .call([refer('result')]).statement,
    refer('exitCode', 'dart:io').assign(refer('result')).statement,
  ]));

/// An expression calling `apply` with appropriate setup for a Builder.
Expression _applyBuilder(BuilderDefinition definition) {
  final namedArgs = {
    if (definition.isOptional) 'isOptional': literalTrue,
    if (definition.buildTo == BuildTo.cache)
      'hideOutput': literalTrue
    else
      'hideOutput': literalFalse,
    if (!identical(definition.defaults?.generateFor, InputSet.anything))
      'defaultGenerateFor':
          refer('InputSet', 'package:build_config/build_config.dart')
              .constInstance([], {
        if (definition.defaults.generateFor.include != null)
          'include': _rawStringList(definition.defaults.generateFor.include),
        if (definition.defaults.generateFor.exclude != null)
          'exclude': _rawStringList(definition.defaults.generateFor.exclude),
      }),
    if (definition.defaults?.options?.isNotEmpty ?? false)
      'defaultOptions': _constructBuilderOptions(definition.defaults.options),
    if (definition.defaults?.devOptions?.isNotEmpty ?? false)
      'defaultDevOptions':
          _constructBuilderOptions(definition.defaults.devOptions),
    if (definition.defaults?.releaseOptions?.isNotEmpty ?? false)
      'defaultReleaseOptions':
          _constructBuilderOptions(definition.defaults.releaseOptions),
    if (definition.appliesBuilders.isNotEmpty)
      'appliesBuilders': _rawStringList(definition.appliesBuilders),
  };
  var import = _buildScriptImport(definition.import);
  return refer('apply', 'package:build_runner_core/build_runner_core.dart')
      .call([
    literalString(definition.key, raw: true),
    literalList([for (var f in definition.builderFactories) refer(f, import)]),
    _findToExpression(definition),
  ], namedArgs);
}

/// An expression calling `applyPostProcess` with appropriate setup for a
/// PostProcessBuilder.
Expression _applyPostProcessBuilder(PostProcessBuilderDefinition definition) {
  final namedArgs = {
    if (!identical(definition.defaults?.generateFor, InputSet.anything))
      'defaultGenerateFor':
          refer('InputSet', 'package:build_config/build_config.dart')
              .constInstance([], {
        if (definition.defaults.generateFor.include != null)
          'include': _rawStringList(definition.defaults.generateFor.include),
        if (definition.defaults.generateFor.exclude != null)
          'exclude': _rawStringList(definition.defaults.generateFor.exclude),
      }),
    if (definition.defaults?.options?.isNotEmpty ?? false)
      'defaultOptions': _constructBuilderOptions(definition.defaults.options),
    if (definition.defaults?.devOptions?.isNotEmpty ?? false)
      'defaultDevOptions':
          _constructBuilderOptions(definition.defaults.devOptions),
    if (definition.defaults?.releaseOptions?.isNotEmpty ?? false)
      'defaultReleaseOptions':
          _constructBuilderOptions(definition.defaults.releaseOptions),
  };
  var import = _buildScriptImport(definition.import);
  return refer('applyPostProcess',
          'package:build_runner_core/build_runner_core.dart')
      .call([
    literalString(definition.key, raw: true),
    refer(definition.builderFactory, import),
  ], namedArgs);
}

Expression _rawStringList(List<String> strings) => literalConstList(
    [for (var string in strings) literalString(string, raw: true)]);

/// Returns the actual import to put in the generated script based on an import
/// found in the build.yaml.
String _buildScriptImport(String import) {
  if (import.startsWith('package:')) {
    return import;
  } else if (import.startsWith('../') || import.startsWith('/')) {
    _log.warning('The `../` import syntax in build.yaml is now deprecated, '
        'instead do a normal relative import as if it was from the root of '
        'the package. Found `$import` in your `build.yaml` file.');
    return import;
  } else {
    return p.url.relative(import, from: p.url.dirname(scriptLocation));
  }
}

Expression _findToExpression(BuilderDefinition definition) {
  switch (definition.autoApply) {
    case AutoApply.none:
      return refer('toNoneByDefault',
              'package:build_runner_core/build_runner_core.dart')
          .call([]);
    case AutoApply.dependents:
      return refer('toDependentsOf',
              'package:build_runner_core/build_runner_core.dart')
          .call([literalString(definition.package, raw: true)]);
    case AutoApply.allPackages:
      return refer('toAllPackages',
              'package:build_runner_core/build_runner_core.dart')
          .call([]);
    case AutoApply.rootPackage:
      return refer('toRoot', 'package:build_runner_core/build_runner_core.dart')
          .call([]);
  }
  throw ArgumentError('Unhandled AutoApply type: ${definition.autoApply}');
}

/// An expression creating a [BuilderOptions] from a json string.
Expression _constructBuilderOptions(Map<String, dynamic> options) =>
    refer('BuilderOptions', 'package:build/build.dart')
        .newInstance([literalMap(options)]);
