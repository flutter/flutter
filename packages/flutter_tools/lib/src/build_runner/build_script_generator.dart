// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:build_runner_core/build_runner_core.dart';
import 'package:build/build.dart' show BuilderOptions;
import 'package:build_config/build_config.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:graphs/graphs.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../project.dart';

class BuildScriptGeneratorFactory {
  const BuildScriptGeneratorFactory();

  /// Creates a [BuildScriptGenerator] for the current flutter project.
  BuildScriptGenerator create(FlutterProject flutterProject, PackageGraph packageGraph) {
    return BuildScriptGenerator(flutterProject, packageGraph);
  }
}

/// Generates a build_script for the current flutter project.
class BuildScriptGenerator {
  const BuildScriptGenerator(this.flutterProject, this.packageGraph);

  final FlutterProject flutterProject;
  final PackageGraph packageGraph;

  /// Generate a build script for the curent flutter project.
  ///
  /// Requires the project to have a pubspec.yaml.
  Future<void> generateBuildScript() async {
    final Iterable<Expression> builders = await _findBuilderApplications();
    final Library library = Library((LibraryBuilder libraryBuilder) => libraryBuilder.body.addAll(<Spec>[
      literalList(builders, refer('BuilderApplication', 'package:build_runner_core/build_runner_core.dart'))
        .assignFinal('_builders')
        .statement,
      _createMain(),
    ]));
    final DartEmitter emitter = DartEmitter(Allocator.simplePrefixing());
    try {
      final String location = fs.path.join(flutterProject.dartTool.path, 'build', 'entrypoint', 'build.dart');
      final String result = DartFormatter().format('''
        // ignore_for_file: directives_ordering
        ${library.accept(emitter)}''');
      final File output = fs.file(location);
      output.createSync(recursive: true);
      fs.file(location).writeAsStringSync(result);
    } on FormatterException {
      throwToolExit('Generated build script could not be parsed. '
        'This is likely caused by a misconfigured builder definition.');
    }
  }

  /// Finds expressions to create all the `BuilderApplication` instances that
  /// should be applied packages in the build.
  ///
  /// Adds `apply` expressions based on the BuildefDefinitions from any package
  /// which has a `build.yaml`.
  Future<Iterable<Expression>> _findBuilderApplications() async {
    final List<Expression> builderApplications = <Expression>[];
    final Iterable<PackageNode> orderedPackages = stronglyConnectedComponents<PackageNode>(
      <PackageNode>[packageGraph.root],
      (PackageNode node) => node.dependencies,
      equals: (PackageNode a, PackageNode b) => a.name == b.name,
      hashCode: (PackageNode n) => n.name.hashCode,
    ).expand((List<PackageNode> nodes) => nodes);
    Future<BuildConfig> _packageBuildConfig(PackageNode package) async {
      try {
        return await BuildConfig.fromBuildConfigDir(package.name, package.dependencies.map((PackageNode node) => node.name), package.path);
      } on ArgumentError catch (_) {
        // During the build an error will be logged.
        return BuildConfig.useDefault(package.name, package.dependencies.map((PackageNode node) => node.name));
      }
    }

    final Iterable<BuildConfig> orderedConfigs = await Future.wait(orderedPackages.map(_packageBuildConfig));
    final List<BuilderDefinition> builderDefinitions = orderedConfigs
      .expand((BuildConfig buildConfig) => buildConfig.builderDefinitions.values)
      .where((BuilderDefinition builderDefinition) {
        if (builderDefinition.import.startsWith('package:')) {
          return true;
        }
        return builderDefinition.package == packageGraph.root.name;
      })
      .toList();

    final List<BuilderDefinition> orderedBuilders = _findBuilderOrder(builderDefinitions).toList();
    builderApplications.addAll(orderedBuilders.map(_applyBuilder));

    final List<PostProcessBuilderDefinition> postProcessBuilderDefinitions = orderedConfigs
      .expand((BuildConfig buildConfig) => buildConfig.postProcessBuilderDefinitions.values)
      .where((PostProcessBuilderDefinition builderDefinition) {
        if (builderDefinition.import.startsWith('package:')) {
          return true;
        }
        return builderDefinition.package == packageGraph.root.name;
      })
      .toList();
    builderApplications.addAll(postProcessBuilderDefinitions.map(_applyPostProcessBuilder));

    return builderApplications;
  }

  /// A method forwarding to `run`.
  Method _createMain() {
    return Method((MethodBuilder b) => b
    ..name = 'main'
    ..modifier = MethodModifier.async
    ..requiredParameters.add(Parameter((ParameterBuilder parameterBuilder) => parameterBuilder
      ..name = 'args'
      ..type = TypeReference((TypeReferenceBuilder typeReferenceBuilder) => typeReferenceBuilder
        ..symbol = 'List'
        ..types.add(refer('String')))))
    ..optionalParameters.add(Parameter((ParameterBuilder parameterBuilder) => parameterBuilder
      ..name = 'sendPort'
      ..type = refer('SendPort', 'dart:isolate')))
    ..body = Block.of(<Code>[
      refer('run', 'package:build_runner/build_runner.dart')
          .call(<Expression>[refer('args'), refer('_builders')])
          .awaited
          .assignVar('result')
          .statement,
      refer('sendPort')
          .nullSafeProperty('send')
          .call(<Expression>[refer('result')]).statement,
    ]));
  }

  /// An expression calling `apply` with appropriate setup for a Builder.
  Expression _applyBuilder(BuilderDefinition definition) {
    final Map<String, Expression> namedArgs = <String, Expression>{};
    if (definition.isOptional) {
      namedArgs['isOptional'] = literalTrue;
    }
    if (definition.buildTo == BuildTo.cache) {
      namedArgs['hideOutput'] = literalTrue;
    } else {
      namedArgs['hideOutput'] = literalFalse;
    }
    if (!identical(definition.defaults?.generateFor, InputSet.anything)) {
      final Map<String, Expression> inputSetArgs = <String, Expression>{};
      if (definition.defaults.generateFor.include != null) {
        inputSetArgs['include'] = literalConstList(definition.defaults.generateFor.include);
      }
      if (definition.defaults.generateFor.exclude != null) {
        inputSetArgs['exclude'] = literalConstList(definition.defaults.generateFor.exclude);
      }
      namedArgs['defaultGenerateFor'] =
          refer('InputSet', 'package:build_config/build_config.dart')
              .constInstance(<Expression>[], inputSetArgs);
    }
    if (!identical(definition.defaults?.options, BuilderOptions.empty)) {
      namedArgs['defaultOptions'] = _constructBuilderOptions(definition.defaults.options);
    }
    if (!identical(definition.defaults?.devOptions, BuilderOptions.empty)) {
      namedArgs['defaultDevOptions'] = _constructBuilderOptions(definition.defaults.devOptions);
    }
    if (!identical(definition.defaults?.releaseOptions, BuilderOptions.empty)) {
      namedArgs['defaultReleaseOptions'] = _constructBuilderOptions(definition.defaults.releaseOptions);
    }
    if (definition.appliesBuilders.isNotEmpty) {
      namedArgs['appliesBuilders'] = literalList(definition.appliesBuilders);
    }
    final String import = _buildScriptImport(definition.import);
    return refer('apply', 'package:build_runner_core/build_runner_core.dart')
        .call(<Expression>[
      literalString(definition.key),
      literalList(
          definition.builderFactories.map((String f) => refer(f, import)).toList()),
      _findToExpression(definition),
    ], namedArgs);
  }

  /// An expression calling `applyPostProcess` with appropriate setup for a
  /// PostProcessBuilder.
  Expression _applyPostProcessBuilder(PostProcessBuilderDefinition definition) {
    final Map<String, Expression> namedArgs = <String, Expression>{};
    if (definition.defaults?.generateFor != null) {
      final Map<String, Expression> inputSetArgs = <String, Expression>{};
      if (definition.defaults.generateFor.include != null) {
        inputSetArgs['include'] = literalConstList(definition.defaults.generateFor.include);
      }
      if (definition.defaults.generateFor.exclude != null) {
        inputSetArgs['exclude'] = literalConstList(definition.defaults.generateFor.exclude);
      }
      if (!identical(definition.defaults?.options, BuilderOptions.empty)) {
        namedArgs['defaultOptions'] = _constructBuilderOptions(definition.defaults.options);
      }
      if (!identical(definition.defaults?.devOptions, BuilderOptions.empty)) {
        namedArgs['defaultDevOptions'] = _constructBuilderOptions(definition.defaults.devOptions);
      }
      if (!identical(definition.defaults?.releaseOptions, BuilderOptions.empty)) {
        namedArgs['defaultReleaseOptions'] = _constructBuilderOptions(definition.defaults.releaseOptions);
      }
      namedArgs['defaultGenerateFor'] = refer('InputSet', 'package:build_config/build_config.dart').constInstance(<Expression>[], inputSetArgs);
    }
    final String import = _buildScriptImport(definition.import);
    return refer('applyPostProcess', 'package:build_runner_core/build_runner_core.dart')
      .call(<Expression>[
        literalString(definition.key),
        refer(definition.builderFactory, import),
      ], namedArgs);
  }

  /// Returns the actual import to put in the generated script based on an import
  /// found in the build.yaml.
  String _buildScriptImport(String import) {
    if (import.startsWith('package:')) {
      return import;
    }
    throwToolExit('non-package import syntax in build.yaml is not supported');
    return null;
  }

  Expression _findToExpression(BuilderDefinition definition) {
    switch (definition.autoApply) {
      case AutoApply.none:
        return refer('toNoneByDefault',
                'package:build_runner_core/build_runner_core.dart')
            .call(<Expression>[]);
      // TODO(jonahwilliams): re-enabled when we have the builders strategy fleshed out.
      // case AutoApply.dependents:
      //   return refer('toDependentsOf',
      //           'package:build_runner_core/build_runner_core.dart')
      //       .call(<Expression>[literalString(definition.package)]);
      case AutoApply.allPackages:
        return refer('toAllPackages',
                'package:build_runner_core/build_runner_core.dart')
            .call(<Expression>[]);
      case AutoApply.dependents:
      case AutoApply.rootPackage:
        return refer('toRoot', 'package:build_runner_core/build_runner_core.dart')
            .call(<Expression>[]);
    }
    throw ArgumentError('Unhandled AutoApply type: ${definition.autoApply}');
  }

  /// An expression creating a [BuilderOptions] from a json string.
  Expression _constructBuilderOptions(Map<String, dynamic> options) {
    return refer('BuilderOptions', 'package:build/build.dart').newInstance(<Expression>[literalMap(options)]);
  }

  /// Put [builders] into an order such that any builder which specifies
  /// [BuilderDefinition.requiredInputs] will come after any builder which
  /// produces a desired output.
  ///
  /// Builders will be ordered such that their `required_inputs` and `runs_before`
  /// constraints are met, but the rest of the ordering is arbitrary.
  Iterable<BuilderDefinition> _findBuilderOrder(Iterable<BuilderDefinition> builders) {
    Iterable<BuilderDefinition> dependencies(BuilderDefinition parent) {
      return builders.where((BuilderDefinition child) => _hasInputDependency(parent, child) || _mustRunBefore(parent, child));
    }
    final List<List<BuilderDefinition>> components = stronglyConnectedComponents<BuilderDefinition>(
      builders,
      dependencies,
      equals: (BuilderDefinition a, BuilderDefinition b) => a.key == b.key,
      hashCode: (BuilderDefinition b) => b.key.hashCode,
    );
    return components.map((List<BuilderDefinition> component) {
      if (component.length > 1) {
        throw ArgumentError('Required input cycle for ${component.toList()}');
      }
      return component.single;
    }).toList();
  }

  /// Whether [parent] has a `required_input` that wants to read outputs produced
  /// by [child].
  bool _hasInputDependency(BuilderDefinition parent, BuilderDefinition child) {
    final Set<String> childOutputs = child.buildExtensions.values.expand((List<String> values) => values).toSet();
    return parent.requiredInputs.any((String input) => childOutputs.any((String output) => output.endsWith(input)));
  }

  /// Whether [child] specifies that it wants to run before [parent].
  bool _mustRunBefore(BuilderDefinition parent, BuilderDefinition child) => child.runsBefore.contains(parent.key);
}
