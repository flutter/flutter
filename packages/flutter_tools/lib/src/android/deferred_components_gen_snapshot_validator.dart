// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:xml/xml.dart';
import 'package:yaml/yaml.dart';

import '../base/deferred_component.dart';
import '../base/error_handling_io.dart';
import '../base/file_system.dart';
import '../build_system/build_system.dart';
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
  DeferredComponentsGenSnapshotValidator(Environment env, {
    bool exitOnFail = true,
    String title,
  }) : super(env, exitOnFail: exitOnFail, title: title);

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
    inputs.add(env.projectDir.childFile('pubspec.yaml'));

    // We do not use the Xml package to handle the writing, as we do not want to
    // erase any user applied formatting and comments. The changes can be
    // applied with dart io and custom parsing.
    final File appManifestFile = androidDir
      .childDirectory('app')
      .childDirectory('src')
      .childDirectory('main')
      .childFile('AndroidManifest.xml');
    inputs.add(appManifestFile);
    if (!appManifestFile.existsSync()) {
      invalidFiles[appManifestFile.path] = 'Error: $appManifestFile does not '
        'exist or could not be found. Please ensure an AndroidManifest.xml '
        'exists for the app\'s base module.';
      return false;
    }
    XmlDocument document;
    try {
      document = XmlDocument.parse(appManifestFile.readAsStringSync());
    } on XmlParserException {
      invalidFiles[appManifestFile.path] = 'Error parsing $appManifestFile '
        'Please ensure that the android manifest is a valid XML document and '
        'try again.';
      return false;
    } on FileSystemException {
      invalidFiles[appManifestFile.path] = 'Error reading $appManifestFile '
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
      final File manifestOutput = outputDir
        .childDirectory('app')
        .childDirectory('src')
        .childDirectory('main')
        .childFile('AndroidManifest.xml');
      ErrorHandlingFileSystem.deleteIfExists(manifestOutput);
      manifestOutput.createSync(recursive: true);
      manifestOutput.writeAsStringSync(document.toXmlString(pretty: true), flush: true);
      modifiedFiles.add(manifestOutput.path);
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
    final List<LoadingUnit> goldenLoadingUnits = _parseGolden(env.projectDir.childFile(DeferredComponentsValidator.kDeferredComponentsGoldenFileName));
    goldenComparisonResults = <String, dynamic>{};
    final Set<LoadingUnit> unmatchedLoadingUnits = <LoadingUnit>{};
    final List<LoadingUnit> newLoadingUnits = <LoadingUnit>[];
    if (generatedLoadingUnits == null || goldenLoadingUnits == null) {
      goldenComparisonResults['new'] = newLoadingUnits;
      goldenComparisonResults['missing'] = unmatchedLoadingUnits;
      goldenComparisonResults['match'] = false;
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
    goldenComparisonResults['new'] = newLoadingUnits;
    goldenComparisonResults['missing'] = unmatchedLoadingUnits;
    goldenComparisonResults['match'] = newLoadingUnits.isEmpty && unmatchedLoadingUnits.isEmpty;
    return goldenComparisonResults['match'] as bool;
  }

  List<LoadingUnit> _parseGolden(File goldenFile) {
    final List<LoadingUnit> loadingUnits = <LoadingUnit>[];
    inputs.add(goldenFile);
    if (!goldenFile.existsSync()) {
      return loadingUnits;
    }
    final YamlMap data = loadYaml(goldenFile.readAsStringSync()) as YamlMap;
    // validate yaml format.
    if (!data.containsKey('loading-units')) {
      invalidFiles[goldenFile.path] = 'Invalid golden yaml file, \'loading-units\' '
                                       'entry did not exist.';
      return loadingUnits;
    } else {
      if (data['loading-units'] is! YamlList && data['loading-units'] != null) {
        invalidFiles[goldenFile.path] = 'Invalid golden yaml file, \'loading-units\' '
                                         'is not a list.';
        return loadingUnits;
      }
      if (data['loading-units'] != null) {
        for (final dynamic loadingUnitData in data['loading-units']) {
          if (loadingUnitData is! YamlMap) {
            invalidFiles[goldenFile.path] = 'Invalid golden yaml file, \'loading-units\' '
                                             'is not a list of maps.';
            return loadingUnits;
          }
          final YamlMap loadingUnitDataMap = loadingUnitData as YamlMap;
          if (loadingUnitDataMap['id'] == null) {
            invalidFiles[goldenFile.path] = 'Invalid golden yaml file, all '
                                             'loading units must have an \'id\'';
            return loadingUnits;
          }
          if (loadingUnitDataMap['libraries'] != null) {
            if (loadingUnitDataMap['libraries'] is! YamlList) {
              invalidFiles[goldenFile.path] = 'Invalid golden yaml file, \'libraries\' '
                                               'is not a list.';
              return loadingUnits;
            }
            for (final dynamic node in loadingUnitDataMap['libraries'] as YamlList) {
              if (node is! String) {
                invalidFiles[goldenFile.path] = 'Invalid golden yaml file, \'libraries\' '
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
    final File goldenFile = env.projectDir.childFile(DeferredComponentsValidator.kDeferredComponentsGoldenFileName);
    outputs.add(goldenFile);
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
}
