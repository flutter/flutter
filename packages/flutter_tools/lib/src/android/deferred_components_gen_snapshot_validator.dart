// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:meta/meta.dart';
import 'package:xml/xml.dart';
import 'package:yaml/yaml.dart';

import '../base/common.dart';
import '../base/deferred_component.dart';
import '../base/error_handling_io.dart';
import '../base/file_system.dart';
import '../base/terminal.dart';
import '../build_system/build_system.dart';
import '../globals.dart' as globals;
import '../project.dart';
import 'deferred_components_validator.dart';

/// A class to configure and run deferred component setup verification checks
/// and tasks.
///
/// Once constructed, checks and tasks can be executed by calling the respective
/// methods. The results of the checks are stored internally and can be
/// displayed to the user by calling [displayResults].
class DeferredComponentsGenSnapshotValidator extends DeferredComponentsValidator {
  /// Constructs a validator instance.
  ///
  /// The [env] property is used to locate the project files that are checked.
  ///
  /// The [templatesDir] parameter is optional. If null, the tool's default
  /// templates directory will be used.
  ///
  /// When [exitOnFail] is set to true, the [handleResults] and [attemptToolExit]
  /// methods will exit the tool when this validator detects a recommended
  /// change. This defaults to true.
  DeferredComponentsGenSnapshotValidator(this.env, {
    this.exitOnFail = true,
    String title,
  }) : _outputDir = env.projectDir
        .childDirectory('build')
        .childDirectory(kDeferredComponentsTempDirectory),
      _inputs = <File>[],
      _outputs = <File>[],
      _title = title ?? 'Deferred components setup verification',
      _generatedFiles = <String>[],
      _modifiedFiles = <String>[],
      _invalidFiles = <String, String>{},
      _diffLines = <String>[];

  // The key used to identify the metadata element as the loading unit id to
  // deferred component mapping.
  static const String _mappingKey = 'io.flutter.embedding.engine.deferredcomponents.DeferredComponentManager.loadingUnitMapping';

  /// Checks if the base module `app`'s `AndroidManifest.xml` contains the
  /// required meta-data that maps loading units to deferred components.
  ///
  /// Returns true if the check passed with no recommended changes, and false
  /// otherwise.
  ///
  /// Flutter engine uses a manifest meta-data mapping to determine which
  /// deferred component includes a particular loading unit id. This method
  /// checks if `app`'s `AndroidManifest.xml` contains this metadata. If not, it
  /// will generate a modified AndroidManifest.xml with the correct metadata
  /// entry.
  ///
  /// An example mapping:
  ///
  ///   2:componentA,3:componentB,4:componentC
  ///
  /// Where loading unit 2 is included in componentA, loading unit 3 is included
  /// in componentB, and loading unit 4 is included in componentC.
  bool checkAppAndroidManifestComponentLoadingUnitMapping(List<DeferredComponent> components, List<LoadingUnit> generatedLoadingUnits) {
    final Directory androidDir = env.projectDir.childDirectory('android');
    _inputs.add(env.projectDir.childFile('pubspec.yaml'));

    // We do not use the Xml package to handle the writing, as we do not want to
    // erase any user applied formatting and comments. The changes can be
    // applied with dart io and custom parsing.
    final File appManifestFile = androidDir
      .childDirectory('app')
      .childDirectory('src')
      .childDirectory('main')
      .childFile('AndroidManifest.xml');
    _inputs.add(appManifestFile);
    if (!appManifestFile.existsSync()) {
      _invalidFiles[appManifestFile.path] = 'Error: $appManifestFile does not '
        'exist or could not be found. Please ensure an AndroidManifest.xml '
        'exists for the app\'s base module.';
      return false;
    }
    XmlDocument document;
    try {
      document = XmlDocument.parse(appManifestFile.readAsStringSync());
    } on XmlParserException {
      _invalidFiles[appManifestFile.path] = 'Error parsing $appManifestFile '
        'Please ensure that the android manifest is a valid XML document and '
        'try again.';
      return false;
    } on FileSystemException {
      _invalidFiles[appManifestFile.path] = 'Error reading $appManifestFile '
        'even though it exists. Please ensure that you have read permission for '
        'this file and try again.';
      return false;
    }
    // Create loading unit mapping.
    final Map<int, String> mapping = <int, String>{};
    for (final DeferredComponent component in components) {
      component.assignLoadingUnits(generatedLoadingUnits);
      for (final LoadingUnit unit in component.loadingUnits) {
        if (!mapping.containsKey(unit.id)) {
          mapping[unit.id] = component.name;
        }
      }
    }
    // Encode the mapping as a string.
    final StringBuffer mappingBuffer = StringBuffer();
    for (final int key in mapping.keys) {
      mappingBuffer.write('$key:${mapping[key]},');
    }
    String encodedMapping = mappingBuffer.toString();
    // remove trailing comma.
    encodedMapping = encodedMapping.substring(0, encodedMapping.length - 1);
    // Check for existing metadata entry and see if needs changes.
    bool exists = false;
    bool modified = false;
    for (final XmlElement metaData in document.findAllElements('meta-data')) {
      final String name = metaData.getAttribute('android:name');
      if (name == _mappingKey) {
        exists = true;
        final String storedMappingString = metaData.getAttribute('android:value');
        if (storedMappingString != encodedMapping) {
          metaData.setAttribute('android:value', encodedMapping);
          modified = true;
        }
      }
    }
    if (!exists) {
      // Create an meta-data XmlElement that contains the mapping.
      final XmlElement mappingMetadataElement = XmlElement(XmlName.fromString('meta-data'),
        <XmlAttribute>[
          XmlAttribute(XmlName.fromString('android:name'), _mappingKey),
          XmlAttribute(XmlName.fromString('android:value'), encodedMapping),
        ],
      );
      for (final XmlElement application in document.findAllElements('application')) {
        application.children.add(mappingMetadataElement);
        break;
      }
    }
    if (!exists || modified) {
      final File manifestOutput = _outputDir
        .childDirectory('app')
        .childDirectory('src')
        .childDirectory('main')
        .childFile('AndroidManifest.xml');
      ErrorHandlingFileSystem.deleteIfExists(manifestOutput);
      manifestOutput.createSync(recursive: true);
      manifestOutput.writeAsStringSync(document.toXmlString(pretty: true), flush: true);
      _modifiedFiles.add(manifestOutput.path);
      return false;
    }
    return true;
  }

  /// Compares the provided loading units against the contents of the
  /// `deferred_components_golden.yaml` file.
  ///
  /// Returns true if a golden exists and all loading units match, and false
  /// otherwise.
  ///
  /// This method will parse the golden file if it exists and compare it to
  /// the provided generatedLoadingUnits. It will distinguish between newly
  /// added loading units and no longer existing loading units. If the golden
  /// file does not exist, then all generatedLoadingUnits will be considered
  /// new.
  bool checkAgainstLoadingUnitGolden(
      List<LoadingUnit> generatedLoadingUnits) {
    final List<LoadingUnit> goldenLoadingUnits = _parseGolden(env.projectDir.childFile(kDeferredComponentsGoldenFileName));
    _goldenComparisonResults = <String, dynamic>{};
    final Set<LoadingUnit> unmatchedLoadingUnits = <LoadingUnit>{};
    final List<LoadingUnit> newLoadingUnits = <LoadingUnit>[];
    if (generatedLoadingUnits == null || goldenLoadingUnits == null) {
      _goldenComparisonResults['new'] = newLoadingUnits;
      _goldenComparisonResults['missing'] = unmatchedLoadingUnits;
      _goldenComparisonResults['match'] = false;
      return false;
    }
    unmatchedLoadingUnits.addAll(goldenLoadingUnits);
    final Set<int> addedNewIds = <int>{};
    for (final LoadingUnit genUnit in generatedLoadingUnits) {
      bool matched = false;
      for (final LoadingUnit goldUnit in goldenLoadingUnits) {
        if (genUnit.equalsIgnoringPath(goldUnit)) {
          matched = true;
          unmatchedLoadingUnits.remove(goldUnit);
          break;
        }
      }
      if (!matched && !addedNewIds.contains(genUnit.id)) {
        newLoadingUnits.add(genUnit);
        addedNewIds.add(genUnit.id);
      }
    }
    _goldenComparisonResults['new'] = newLoadingUnits;
    _goldenComparisonResults['missing'] = unmatchedLoadingUnits;
    _goldenComparisonResults['match'] = newLoadingUnits.isEmpty && unmatchedLoadingUnits.isEmpty;
    return _goldenComparisonResults['match'] as bool;
  }

  List<LoadingUnit> _parseGolden(File goldenFile) {
    final List<LoadingUnit> loadingUnits = <LoadingUnit>[];
    _inputs.add(goldenFile);
    if (!goldenFile.existsSync()) {
      return loadingUnits;
    }
    final YamlMap data = loadYaml(goldenFile.readAsStringSync()) as YamlMap;
    // validate yaml format.
    if (!data.containsKey('loading-units')) {
      _invalidFiles[goldenFile.path] = 'Invalid golden yaml file, \'loading-units\' '
                                       'entry did not exist.';
      return loadingUnits;
    } else {
      if (data['loading-units'] is! YamlList && data['loading-units'] != null) {
        _invalidFiles[goldenFile.path] = 'Invalid golden yaml file, \'loading-units\' '
                                         'is not a list.';
        return loadingUnits;
      }
      if (data['loading-units'] != null) {
        for (final dynamic loadingUnitData in data['loading-units']) {
          if (loadingUnitData is! YamlMap) {
            _invalidFiles[goldenFile.path] = 'Invalid golden yaml file, \'loading-units\' '
                                             'is not a list of maps.';
            return loadingUnits;
          }
          final YamlMap loadingUnitDataMap = loadingUnitData as YamlMap;
          if (loadingUnitDataMap['id'] == null) {
            _invalidFiles[goldenFile.path] = 'Invalid golden yaml file, all '
                                             'loading units must have an \'id\'';
            return loadingUnits;
          }
          if (loadingUnitDataMap['libraries'] != null) {
            if (loadingUnitDataMap['libraries'] is! YamlList) {
              _invalidFiles[goldenFile.path] = 'Invalid golden yaml file, \'libraries\' '
                                               'is not a list.';
              return loadingUnits;
            }
            for (final dynamic node in loadingUnitDataMap['libraries'] as YamlList) {
              if (node is! String) {
                _invalidFiles[goldenFile.path] = 'Invalid golden yaml file, \'libraries\' '
                                                 'is not a list of strings.';
                return loadingUnits;
              }
            }
          }
        }
      }
    }

    // Parse out validated yaml.
    if (data.containsKey('loading-units')) {
      if (data['loading-units'] != null) {
        for (final dynamic loadingUnitData in data['loading-units']) {
          final YamlMap loadingUnitDataMap = loadingUnitData as YamlMap;
          final List<String> libraries = <String>[];
          if (loadingUnitDataMap['libraries'] != null) {
            for (final dynamic node in loadingUnitDataMap['libraries'] as YamlList) {
              libraries.add(node as String);
            }
          }
          loadingUnits.add(
              LoadingUnit(
                id: loadingUnitDataMap['id'] as int,
                path: null,
                libraries: libraries,
              ));
        }
      }
    }
    return loadingUnits;
  }

  /// Writes the provided generatedLoadingUnits as `deferred_components_golden.yaml`
  ///
  /// This golden file is used to detect any changes in the loading units
  /// produced by gen_snapshot. Running [checkAgainstLoadingUnitGolden] with a
  /// mismatching or missing golden will result in a failed validation. This
  /// prevents unexpected changes in loading units causing misconfigured
  /// deferred components.
  void writeGolden(List<LoadingUnit> generatedLoadingUnits) {
    generatedLoadingUnits ??= <LoadingUnit>[];
    final File goldenFile = env.projectDir.childFile(kDeferredComponentsGoldenFileName);
    _outputs.add(goldenFile);
    ErrorHandlingFileSystem.deleteIfExists(goldenFile);
    goldenFile.createSync(recursive: true);

    final StringBuffer buffer = StringBuffer();
    buffer.write('''
# ===============================================================================
# The contents of this file are automatically generated and it is not recommended
# to modify this file manually.
# ===============================================================================
#
# In order to prevent unexpected splitting of deferred apps, this golden
# file records the last generated set of loading units. It only possible
# to obtain the final configuration of loading units after compilation is
# complete. This means improperly setup imports can only be detected after
# compilation.
#
# This golden file allows the build tool to detect any changes in the generated
# loading units. During the next build attempt, loading units in this file are
# compared against the newly generated loading units to check for any new or
# removed loading units. In the case where loading units do not match, the build
# will fail and ask the developer to verify that the `deferred-components`
# configuration in `pubspec.yaml` is correct. Developers should make any necessary
# changes to integrate new and changed loading units or remove no longer existing
# loading units from the configuration. The build command should then be
# re-run to continue the build process.
#
# Sometimes, changes to the generated loading units may be unintentional. If
# the list of loading units in this golden is not what is expected, the app's
# deferred imports should be reviewed. Third party plugins and packages may
# also introduce deferred imports that result in unexpected loading units.
loading-units:
''');
    final Set<int> usedIds = <int>{};
    for (final LoadingUnit unit in generatedLoadingUnits) {
      if (usedIds.contains(unit.id)) {
        continue;
      }
      buffer.write('  - id: ${unit.id}\n');
      if (unit.libraries != null && unit.libraries.isNotEmpty) {
        buffer.write('    libraries:\n');
        for (final String lib in unit.libraries) {
          buffer.write('      - $lib\n');
        }
      }
      usedIds.add(unit.id);
    }
    goldenFile.writeAsStringSync(buffer.toString(), flush: true);
  }

  /// Handles the results of all executed checks by calling [displayResults] and
  /// [attemptToolExit].
  ///
  /// This should be called after all desired checks and tasks are executed.
  void handleResults() {
    displayResults();
    attemptToolExit();
  }

  static const String _thickDivider = '=================================================================================';
  static const String _thinDivider = '---------------------------------------------------------------------------------';

  /// Displays the results of this validator's executed checks and tasks in a
  /// human readable format.
  ///
  /// All checks that are desired should be run before calling this method.
  void displayResults() {
    if (changesNeeded) {
      env.logger.printStatus(_thickDivider);
      env.logger.printStatus(_title, indent: (_thickDivider.length - _title.length) ~/ 2, emphasis: true);
      env.logger.printStatus(_thickDivider);
      // Log any file reading/existence errors.
      if (_invalidFiles.isNotEmpty) {
        env.logger.printStatus('Errors checking the following files:\n', emphasis: true);
        for (final String key in _invalidFiles.keys) {
          env.logger.printStatus('  - $key: ${_invalidFiles[key]}\n');
        }
      }
      // Log diff file contents, with color highlighting
      if (_diffLines != null && _diffLines.isNotEmpty) {
        env.logger.printStatus('Diff between `android` and expected files:', emphasis: true);
        env.logger.printStatus('');
        for (final String line in _diffLines) {
          // We only care about diffs in files that have
          // counterparts.
          if (line.startsWith('Only in android')) {
            continue;
          }
          TerminalColor color = TerminalColor.grey;
          if (line.startsWith('+')) {
            color = TerminalColor.green;
          } else if (line.startsWith('-')) {
            color = TerminalColor.red;
          }
          env.logger.printStatus(line, color: color);
        }
        env.logger.printStatus('');
      }
      // Log any newly generated and modified files.
      if (_generatedFiles.isNotEmpty) {
        env.logger.printStatus('Newly generated android files:', emphasis: true);
        for (final String filePath in _generatedFiles) {
          final String shortenedPath = filePath.substring(env.projectDir.parent.path.length + 1);
          env.logger.printStatus('  - $shortenedPath', color: TerminalColor.grey);
        }
        env.logger.printStatus('');
      }
      if (_modifiedFiles.isNotEmpty) {
        env.logger.printStatus('Modified android files:', emphasis: true);
        for (final String filePath in _modifiedFiles) {
          final String shortenedPath = filePath.substring(env.projectDir.parent.path.length + 1);
          env.logger.printStatus('  - $shortenedPath', color: TerminalColor.grey);
        }
        env.logger.printStatus('');
      }
      if (_generatedFiles.isNotEmpty || _modifiedFiles.isNotEmpty) {
        env.logger.printStatus('''
The above files have been placed into `build/$kDeferredComponentsTempDirectory`,
a temporary directory. The files should be reviewed and moved into the project's
`android` directory.''');
        if (_diffLines != null && _diffLines.isNotEmpty && !globals.platform.isWindows) {
          env.logger.printStatus(r'''

The recommended changes can be quickly applied by running:

  $ patch -p0 < build/setup_deferred_components.diff
''');
        }
        env.logger.printStatus('$_thinDivider\n');
      }
      // Log loading unit golden changes, if any.
      if (_goldenComparisonResults != null) {
        if ((_goldenComparisonResults['new'] as List<LoadingUnit>).isNotEmpty) {
          env.logger.printStatus('New loading units were found:', emphasis: true);
          for (final LoadingUnit unit in _goldenComparisonResults['new'] as List<LoadingUnit>) {
            env.logger.printStatus(unit.toString(), color: TerminalColor.grey, indent: 2);
          }
          env.logger.printStatus('');
        }
        if ((_goldenComparisonResults['missing'] as Set<LoadingUnit>).isNotEmpty) {
          env.logger.printStatus('Previously existing loading units no longer exist:', emphasis: true);
          for (final LoadingUnit unit in _goldenComparisonResults['missing'] as Set<LoadingUnit>) {
            env.logger.printStatus(unit.toString(), color: TerminalColor.grey, indent: 2);
          }
          env.logger.printStatus('');
        }
        if (_goldenComparisonResults['match'] as bool) {
          env.logger.printStatus('No change in generated loading units.\n');
        } else {
          env.logger.printStatus('''
It is recommended to verify that the changed loading units are expected
and to update the `deferred-components` section in `pubspec.yaml` to
incorporate any changes. The full list of generated loading units can be
referenced in the $kDeferredComponentsGoldenFileName file located alongside
pubspec.yaml.

This loading unit check will not fail again on the next build attempt
if no additional changes to the loading units are detected.
$_thinDivider\n''');
        }
      }
      // TODO(garyq): Add link to web tutorial/guide once it is written.
      env.logger.printStatus('''
Setup verification can be skipped by passing the `--no-verify-deferred-components`
flag, however, doing so may put your app at risk of not functioning even if the
build is successful.
$_thickDivider''');
      return;
    }
    env.logger.printStatus('$_title passed.');
  }

  void attemptToolExit() {
    if (exitOnFail && changesNeeded) {
      throwToolExit('Setup for deferred components incomplete. See recommended actions.', exitCode: 1);
    }
  }
}

// Handles a single deferred component's android dynamic feature module
// directory.
class _DeferredComponentAndroidFiles {
  _DeferredComponentAndroidFiles({
    @required this.name,
    @required this.env,
    Directory templatesDir,
  }) : _templatesDir = templatesDir;

  // The name of the deferred component.
  final String name;
  final Environment env;
  final Directory _templatesDir;

  Directory get androidDir => env.projectDir.childDirectory('android');
  Directory get componentDir => androidDir.childDirectory(name);

  File get androidManifestFile => componentDir.childDirectory('src').childDirectory('main').childFile('AndroidManifest.xml');
  File get buildGradleFile => componentDir.childFile('build.gradle');

  // True when AndroidManifest.xml and build.gradle exist for the android dynamic feature.
  bool verifyFilesExist() {
    return androidManifestFile.existsSync() && buildGradleFile.existsSync();
  }

  // Generates any missing basic files for the dynamic feature into a temporary directory.
  Future<Map<String, List<File>>> generateFiles({Directory alternateAndroidDir, bool clearAlternateOutputDir = false}) async {
    final Directory outputDir = alternateAndroidDir?.childDirectory(name) ?? componentDir;
    if (clearAlternateOutputDir && alternateAndroidDir != null) {
      ErrorHandlingFileSystem.deleteIfExists(outputDir);
    }
    final List<File> inputs = <File>[];
    inputs.add(androidManifestFile);
    inputs.add(buildGradleFile);
    final Map<String, List<File>> results = <String, List<File>>{'inputs': inputs};
    results['outputs'] = await _setupComponentFiles(outputDir);
    return results;
  }

  // generates default build.gradle and AndroidManifest.xml for the deferred component.
  Future<List<File>> _setupComponentFiles(Directory outputDir) async {
    Template template;
    if (_templatesDir != null) {
      final Directory templateComponentDir = _templatesDir.childDirectory('module${env.fileSystem.path.separator}android${env.fileSystem.path.separator}deferred_component');
      template = Template(templateComponentDir, templateComponentDir, _templatesDir,
        fileSystem: env.fileSystem,
        templateManifest: null,
        logger: env.logger,
        templateRenderer: globals.templateRenderer,
      );
    } else {
      template = await Template.fromName('module${env.fileSystem.path.separator}android${env.fileSystem.path.separator}deferred_component',
        fileSystem: env.fileSystem,
        templateManifest: null,
        logger: env.logger,
        templateRenderer: globals.templateRenderer,
      );
    }
    final Map<String, dynamic> context = <String, dynamic>{
      'androidIdentifier': FlutterProject.current().manifest.androidPackage ?? 'com.example.${FlutterProject.current().manifest.appName}',
      'componentName': name,
    };

    template.render(outputDir, context);

    final List<File> generatedFiles = <File>[];

    final File tempBuildGradle = outputDir.childFile('build.gradle');
    if (!buildGradleFile.existsSync()) {
      generatedFiles.add(tempBuildGradle);
    } else {
      ErrorHandlingFileSystem.deleteIfExists(tempBuildGradle);
    }
    final File tempAndroidManifest = outputDir
      .childDirectory('src')
      .childDirectory('main')
      .childFile('AndroidManifest.xml');
    if (!androidManifestFile.existsSync()) {
      generatedFiles.add(tempAndroidManifest);
    } else {
      ErrorHandlingFileSystem.deleteIfExists(tempAndroidManifest);
    }
    return generatedFiles;
  }
}
