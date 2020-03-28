

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/depfile.dart';
import 'package:flutter_tools/src/project.dart';
import '../../convert.dart';
import '../../globals.dart' as globals;

import '../build_system.dart';

/// Bundle the SkSL shader files into an application.
///
/// This target is only executed if the user has opted into the functionality
/// with the `sksl: true` key in their pubspec.yaml.
class BundleSkSLShadersTarget extends Target {
  const BundleSkSLShadersTarget(this._outputDirectory);

  // The path relative to {OUTPUT_DIR} that shaders should be
  // written to.
  final String _outputDirectory;

  @override
  Future<void> build(Environment environment) async {
    final DepfileService depfileService = DepfileService(
      fileSystem: globals.fs,
      logger: globals.logger,
      platform: globals.platform,
    );
    final FlutterProject flutterProject = FlutterProject
      .fromDirectory(environment.projectDir);
    final bool includeSkSL = flutterProject.manifest.includeSkSL;
    if (!includeSkSL) {
      return;
    }
    final Directory shaderDirectory = globals.fs.directory(getBuildDirectory())
      .childDirectory('shaders')
      .childDirectory('sksl');
    final File shaderManifestFile = shaderDirectory.childFile('manifest.json');

    // Verify that the shader directory exists, along with the manifest.
    if (!shaderDirectory.existsSync() || !shaderManifestFile.existsSync()) {
      globals.printError(
        'pubspec.yaml contained "sksl: true" but no compiled shaders were '
        'not found in ${shaderDirectory.path}. Skipping shader bundling.'
      );
      return;
    }

    // Read and verify that the manifest is a JSON map.
    Map<String, Object> shaderManifest;
    try {
      shaderManifest = json.decode(
        shaderManifestFile.readAsStringSync()) as Map<String, Object>;
    } on FormatException {
      globals.printError('${shaderManifestFile.path} contained invalid JSON.');
      throw Exception();
    } on TypeError {
      globals.printError('Expected ${shaderManifestFile.path} to contain a JSON map.');
      throw Exception();
    }

    // Read an verify that the manifest contains an engine version and a list
    // of shader files.
    String version;
    List<String> files;
    try {
      version = shaderManifest['version'] as String;
      files = (shaderManifest['files'] as List<Object>).cast<String>();
    } on TypeError {
      globals.printError(
        'Expected ${shaderManifestFile.path} to contain a JSON map with a '
        '"version" String property and a "files" List of Strings'
      );
      throw Exception();
    }

    // Verify that the engine version that generated the SkSL is the same as the
    // current engine version.
    final String currentEngineVersion = environment.flutterRootDir
      .childDirectory('bin')
      .childDirectory('internal')
      .childFile('engine.version')
      .readAsStringSync().trim();
    if (currentEngineVersion != version) {
      globals.printError(
        'The SkSL shader files were generated for a different version of '
        'Flutter and must be regenerated.\n'
        'expected: "$currentEngineVersion"\n'
        'found: "$version"\n'
      );
      throw Exception();
    }

    final List<File> inputs = <File>[
      shaderManifestFile,
    ];
    final List<File> outputs = <File>[];

    final Directory outputDirectory = globals.fs.directory(
      globals.fs.path.joinAll(<String>[
        environment.outputDir.path,
        ..._outputDirectory.split('/'),
        'shaders',
        'sksl',
      ]))..createSync(recursive: true);
    for (final String shaderFileName in files) {
      final File shaderFile = shaderDirectory.childFile(shaderFileName);
      final File outputFile = outputDirectory
        .childFile(shaderFileName);
      shaderFile.copySync(outputFile.path);
      outputs.add(outputFile);
      inputs.add(shaderFile);
    }
    depfileService.writeToFile(
      Depfile(inputs, outputs),
      environment.buildDir.childFile('bundle_sksl_$_outputDirectory.d'),
    );
  }

  @override
  List<Target> get dependencies => const <Target>[];

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{PROJECT_DIR}/pubspec.yaml')
  ];

  @override
  String get name => 'bundle_sksl';

  @override
  List<Source> get outputs => const <Source>[];

  @override
  List<String> get depfiles => <String>['bundle_sksl.d'];
}
