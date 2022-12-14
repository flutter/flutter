// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../base/file_system.dart';
import '../../convert.dart';
import '../../localizations/gen_l10n.dart';
import '../../localizations/localizations_utils.dart';
import '../build_system.dart';
import '../depfile.dart';

const String _kDependenciesFileName = 'gen_l10n_inputs_and_outputs.json';

/// A build step that runs the generate localizations script from
/// dev/tool/localizations.
class GenerateLocalizationsTarget extends Target {
  const GenerateLocalizationsTarget();

  @override
  List<Target> get dependencies => <Target>[];

  @override
  List<Source> get inputs => <Source>[
    // This is added as a convenience for developing the tool.
    const Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/localizations.dart'),
  ];

  @override
  String get name => 'gen_localizations';

  @override
  List<Source> get outputs => <Source>[];

  @override
  List<String> get depfiles => <String>['gen_localizations.d'];

  @override
  bool canSkip(Environment environment) {
    final File configFile = environment.projectDir.childFile('l10n.yaml');
    return !configFile.existsSync();
  }

  @override
  Future<void> build(Environment environment) async {
    final File configFile = environment.projectDir.childFile('l10n.yaml');
    assert(configFile.existsSync());

    final LocalizationOptions options = parseLocalizationsOptions(
      file: configFile,
      logger: environment.logger,
    );
    final DepfileService depfileService = DepfileService(
      logger: environment.logger,
      fileSystem: environment.fileSystem,
    );
    generateLocalizations(
      logger: environment.logger,
      options: options,
      projectDir: environment.projectDir,
      dependenciesDir: environment.buildDir,
      fileSystem: environment.fileSystem,
    );

    final Map<String, Object?> dependencies = json.decode(
      environment.buildDir.childFile(_kDependenciesFileName).readAsStringSync()
    ) as Map<String, Object?>;
    final List<Object?>? inputs = dependencies['inputs'] as List<Object?>?;
    final List<Object?>? outputs = dependencies['outputs'] as List<Object?>?;
    final Depfile depfile = Depfile(
      <File>[
        configFile,
        if (inputs != null)
          for (Object inputFile in inputs.whereType<Object>())
            environment.fileSystem.file(inputFile),
      ],
      <File>[
        if (outputs != null)
          for (Object outputFile in outputs.whereType<Object>())
            environment.fileSystem.file(outputFile),
      ],
    );
    depfileService.writeToFile(
      depfile,
      environment.buildDir.childFile('gen_localizations.d'),
    );
  }
}
