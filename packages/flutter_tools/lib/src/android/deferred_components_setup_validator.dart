// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:io' as io;

import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';
import 'package:xml/xml.dart';

import '../base/common.dart';
import '../base/deferred_component.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/terminal.dart';
import '../build_system/build_system.dart';
import '../build_system/depfile.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../template.dart';

/// Enumerates each of the available checks that [DeferredComponentsSetupValidator]
/// can perform.
enum DeferredComponentsSetupValidatorCheck {
  /// Checks if android/settings.gradle contains the
  /// necessary entries for each deferred component.
  /// Generates correct file if needed.
  androidRootSetup,
  /// Checks for the existence of an android dynamic feature
  /// for each deferred component. Generates correct file if needed.
  androidComponentSetup,
  /// Checks for the loading unit -> deferred component
  /// mapping in the base feature's AndroidManifest.xml and
  /// component name string resources in strings.xml.
  /// Generates correct file if needed.
  androidLoadingUnitComponentMapping,
  /// Checks if changes were detected in the loading units
  /// generated vs `deferred_components_golden.yaml`.
  loadingUnitGolden,
  /// Writes the latest generated loading units into the
  /// `deferred_components_golden.yaml`.
  writeGolden,
  /// Deletes the temporary directory that recommended file changes
  /// are generated into.
  clearTempDir,
  /// Generates a diff file that may be applied to the `android` directory
  /// to apply changes recommended by the setup process.
  generateDiff,
}

/// A class to configure and run a deferred component setup verification check.
///
/// To configure a setup verification run, supply a list of DeferredComponentsSetupValidatorCheck
/// values to the contstructor. To run the the setup verification, invoke [runSetup] which
/// will run each check in the order provided. The results of the checks will be displayed.
///
/// Failing a check will result in the tool to exit, ending the current command unless false is
/// passed to the [exitOnFail] parameter.
class DeferredComponentsSetupValidator {
  DeferredComponentsSetupValidator(this.checks, this.env, {
    String title,
    Logger logger,
    Directory templatesDir,
  }) : _outputDir = env.projectDir
      .childDirectory('build')
      .childDirectory(kDeferredComponentsTempDirectory),
      _inputs = <File>[],
      _outputs = <File>[],
      _logger = logger ?? env.logger,
      _title = title ?? 'Deferred components setup verification',
      _templatesDir = templatesDir;

  final List<DeferredComponentsSetupValidatorCheck> checks;

  final Environment env;

  final String _title;

  final Logger _logger;

  final Directory _templatesDir;

  /// The name of the golden file that tracks the latest loading units generated.
  @visibleForTesting
  static const String kDeferredComponentsGoldenFileName = 'deferred_components_golden.yaml';
  /// The directory in the build folder to generate missing/modified files into.
  @visibleForTesting
  static const String kDeferredComponentsTempDirectory = 'android_deferred_components_setup_files';

  final Directory _outputDir;

  final List<File> _inputs;
  final List<File> _outputs;

  Future<void> runSetup({
    // only needed if running androidRootSetup, androidComponentSetup, androidStringMapping
    List<DeferredComponent> components,
    // only needed if running androidStringMapping, loadingUnitGolden or writeGolden
    List<LoadingUnit> generatedLoadingUnits,
    bool exitOnFail = true,
    // Pass depfileOutput and depfileService if a depfile tracking inputs should be written
    File depfileOutput,
    DepfileService depfileService,
  }) async {
    final List<String> generatedFiles = <String>[];
    final List<String> modifiedFiles = <String>[];
    List<String> diffLines;
    Map<String, dynamic> goldenComparisonResults;
    if (checks != null) {
      for (final DeferredComponentsSetupValidatorCheck check in checks) {
        switch (check) {
          case DeferredComponentsSetupValidatorCheck.androidRootSetup:
            modifiedFiles.addAll(_checkAndroidRootSettings(components));
            break;
          case DeferredComponentsSetupValidatorCheck.androidComponentSetup:
            generatedFiles.addAll(await _checkAndroidComponentSetup(components));
            break;
          case DeferredComponentsSetupValidatorCheck.androidLoadingUnitComponentMapping:
            final Map<String, List<String>> results = _checkAndroidLoadingUnitComponentMapping(components, generatedLoadingUnits);
            modifiedFiles.addAll(results['modified']);
            generatedFiles.addAll(results['new']);
            break;
          case DeferredComponentsSetupValidatorCheck.loadingUnitGolden:
            final Map<String, dynamic> deferredComponentsGolden =
                _parseGolden(env.projectDir.childFile(kDeferredComponentsGoldenFileName));
            goldenComparisonResults = _checkLoadingUnitGolden(generatedLoadingUnits, deferredComponentsGolden);
            break;
          case DeferredComponentsSetupValidatorCheck.writeGolden:
            _writeGolden(generatedLoadingUnits);
            break;
          case DeferredComponentsSetupValidatorCheck.clearTempDir:
            _clearTempDir();
            break;
          case DeferredComponentsSetupValidatorCheck.generateDiff:
            diffLines = await _generateDiff();
            break;
        }
      }
    }
    final bool pass = _handleResults(generatedFiles, modifiedFiles, goldenComparisonResults, diffLines, exitOnFail);
    if (exitOnFail && !pass) {
      throwToolExit('Setup for deferred components incomplete. See recommended actions.', exitCode: 2);
    }
    if (depfileOutput != null && depfileService != null) {
      depfileService.writeToFile(
        Depfile(_inputs, _outputs),
        depfileOutput,
      );
    }
  }

  // Generates additions to settings.gradle
  // Since these files are static, the deps are tracked directly in the inputs
  // and we do not need to add them to the depfile.
  List<String> _checkAndroidRootSettings(List<DeferredComponent> components) {
    final Directory androidDir = env.projectDir.childDirectory('android');
    final List<String> modifiedFiles = <String>[];

    // settings.gradle add ':componentName'
    final File settingsGradle = androidDir.childFile('settings.gradle');
    final File settingsGradleOutput = _outputDir.childFile('settings.gradle');
    final List<String> lines = settingsGradle.readAsLinesSync();
    if (settingsGradleOutput.existsSync()) {
      settingsGradleOutput.deleteSync();
    }
    settingsGradleOutput.createSync(recursive: true);
    // Parse out all included entries
    final List<String> elements = <String>[];
    for (final String line in lines) {
      if (line.trim().startsWith('include')) {
        elements.addAll(line.substring(7).split(','));
      }
    }
    // Clean and trim included entries
    final List<String> trimmedElements = <String>[];
    for (final String element in elements) {
      trimmedElements.add(element.trim());
    }
    // Compute missing components
    final List<String> missingComponents = <String>[];
    for (final DeferredComponent component in components) {
      final String componentName = '\':${component.name}\'';
      if (!trimmedElements.contains(componentName)) {
        missingComponents.add(componentName);
      }
    }
    // Append missing components to first include line.
    if (missingComponents.isNotEmpty) {
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].trim().startsWith('include')) {
          for (final String missingName in missingComponents) {
            lines[i] += ', $missingName';
          }
          break;
        }
      }
      // write lines.
      for (final String line in lines) {
        settingsGradleOutput.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
      }
    }
    if (missingComponents.isEmpty) {
      settingsGradleOutput.deleteSync();
    } else {
      modifiedFiles.add(settingsGradleOutput.path);
    }
    return modifiedFiles;
  }

  Future<List<String>> _checkAndroidComponentSetup(List<DeferredComponent> components) async {
    final List<String> generatedFiles = <String>[];
    for (final DeferredComponent component in components) {
      final _DeferredComponentAndroidFiles androidFiles =
        _DeferredComponentAndroidFiles(
          name: component.name,
          env: env,
          templatesDir: _templatesDir
        );
      if (!androidFiles.verifyFilesExist()) {
        // generate into temp directory
        final Map<String, List<File>> results =
          await androidFiles.generateFiles(
            alternateAndroidDir: _outputDir,
            clearAlternateOutputDir: true,
          );
        for (final File file in results['outputs']) {
          generatedFiles.add(file.path);
        }
        _outputs.addAll(results['outputs']);
        _inputs.addAll(results['inputs']);
      }
    }
    return generatedFiles;
  }

  Map<String, List<String>> _checkAndroidLoadingUnitComponentMapping(List<DeferredComponent> components, List<LoadingUnit> generatedLoadingUnits) {
    final Directory androidDir = env.projectDir.childDirectory('android');
    final List<String> modifiedFiles = <String>[];
    final List<String> newFiles = <String>[];
    final Map<String, List<String>> results = <String, List<String>>{'modified': modifiedFiles, 'new': newFiles};
    List<String> lines;

    // We do not use the Xml package to handle the writing, as we do not want to
    // erase any user applied formatting and comments. The changes can be reliably
    // applied with dart io and custom parsing.
    final File appManifestFile = androidDir
      .childDirectory('app')
      .childDirectory('src')
      .childDirectory('main')
      .childFile('AndroidManifest.xml');
    _inputs.add(appManifestFile);
    XmlDocument document;
    try {
      document = XmlDocument.parse(appManifestFile.readAsStringSync());
    } on XmlParserException {
      throwToolExit('Error parsing $appManifestFile '
                    'Please ensure that the android manifest is a valid XML document and try again.');
    } on FileSystemException {
      throwToolExit('Error reading $appManifestFile even though it exists. '
                    'Please ensure that you have read permission to this file and try again.');
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
    String encodedMapping = '';
    for (final int key in mapping.keys) {
      encodedMapping += '$key:${mapping[key]},';
    }
    encodedMapping = encodedMapping.substring(0, encodedMapping.length - 1); // remove trailing comma.
    // Check for existing metadata entry and see if needs changes.
    bool exists = false;
    bool needsChange = false;
    const String mappingKey = 'io.flutter.embedding.engine.deferredcomponents.DeferredComponentManager.loadingUnitMapping';
    for (final XmlElement metaData in document.findAllElements('meta-data')) {
      final String name = metaData.getAttribute('android:name');
      if (name == mappingKey) {
        exists = true;
        final String storedMappingString = metaData.getAttribute('android:value');
        if (storedMappingString != encodedMapping) {
          needsChange = true;
        }
      }
    }
    if (needsChange || !exists) {
      lines = appManifestFile.readAsLinesSync();
      List<String> cleanedLines = <String>[];
      if (exists) {
        // Remove existing mapping entry. We do this line by line
        // to maintain the formatting and comments in the file.
        for (int i = 0; i < lines.length; i++) {
          final String line = lines[i];
          if (line.trim().startsWith(RegExp(r'<meta-data'))) {
            // Reconstruct metadata entry regardless of how many lines it is split over
            String metaDataLine = '';
            int j = i;
            while (!lines[j].contains('/>')) {
              metaDataLine += lines[j];
              j++;
            }
            metaDataLine += lines[j];
            if (metaDataLine.contains(RegExp(r'<meta-data[\s\n]*android:name[\s\n]*=[\s\n]*"' + mappingKey + r'"'))) {
              // found the relevant to remove. Skip adding to outLines.
              i = j; // the for loop will increment this one more time next loop.
            } else {
              cleanedLines.add(line);
            }
          } else {
            cleanedLines.add(line);
          }
        }
      } else {
        cleanedLines = lines;
      }
      // Create new metadata entry.
      final File manifestOutput = _outputDir
        .childDirectory('app')
        .childDirectory('src')
        .childDirectory('main')
        .childFile('AndroidManifest.xml');
      if (manifestOutput.existsSync()) {
        manifestOutput.deleteSync();
      }
      manifestOutput.createSync(recursive: true);
      for (final String line in cleanedLines) {
        if (line.contains(RegExp(r'^[\s\n]*</application>'))) {
          final String indent = line.substring(0, line.indexOf('</application>'));
          final String additionalIndent = indent.length > 2 ? '    ' : indent;
          manifestOutput.writeAsStringSync(
              '$indent$additionalIndent<meta-data android:name="$mappingKey" android:value="$encodedMapping" />\n',
              mode: FileMode.append, flush: true);
        }
        manifestOutput.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
      }
      modifiedFiles.add(manifestOutput.path);
    }

    // Add component name mapping to strings.xml
    final File stringRes = androidDir
      .childDirectory('app')
      .childDirectory('src')
      .childDirectory('main')
      .childDirectory('res')
      .childDirectory('values')
      .childFile('strings.xml');
    _inputs.add(stringRes);
    final File stringResOutput = _outputDir
      .childDirectory('app')
      .childDirectory('src')
      .childDirectory('main')
      .childDirectory('res')
      .childDirectory('values')
      .childFile('strings.xml');
    final Map<String, String> requiredEntriesMap  = <String, String>{};
    for (final DeferredComponent component in components) {
      requiredEntriesMap['${component.name}Name'] = component.name;
    }
    if (stringResOutput.existsSync()) {
      stringResOutput.deleteSync();
    }
    // Check if all required lines are present.
    if (stringRes.existsSync()) {
      lines = stringRes.readAsLinesSync();
      final Map<String, String> incorrectEntries = <String, String>{}; // Entries
      final Map<String, String> incorrectEntriesOriginal = <String, String>{};
      try {
        document = XmlDocument.parse(stringRes.readAsStringSync());
        for (final XmlElement element in document.findAllElements('string')) {
          final String name = element.getAttribute('name');
          if (requiredEntriesMap.containsKey(name)) {
            final String storedString = element.text;
            if (storedString != null && storedString != requiredEntriesMap[name]) {
              incorrectEntries[name] = requiredEntriesMap[name];
              incorrectEntriesOriginal[name] = storedString;
            }
            requiredEntriesMap.remove(name);
          }
        }
      } on XmlParserException {
        throwToolExit('Error parsing $appManifestFile '
                      'Please ensure that the android manifest is a valid XML document and try again.');
      }
      if (requiredEntriesMap.isNotEmpty || incorrectEntries.isNotEmpty) {
        final List<String> modifiedLines = <String>[];
        // Modify existing entries
        if (incorrectEntries.isNotEmpty) {
          for (int i = 0; i < lines.length; i++) {
            String line = lines[i];
            for (final String key in incorrectEntries.keys) {
              if (line.trim().startsWith(RegExp(r'[\s\n]*<[\s\n]*string[\s\n]*name[\s\n]*=[\s\n]*"' + key))) {
                // Collect all lines in the detected entry.
                String entry = '';
                int j = i;
                while (j < lines.length && !lines[j].contains('</string>')) {
                  entry += '${lines[j]}\n';
                  j++;
                }
                entry += lines[j];
                line = entry.replaceFirst(RegExp(r'>[\s\n]*' + incorrectEntriesOriginal[key] + r'[\s\n]*<'), '>${incorrectEntries[key]}<');
                i = j;
                break;
              }
            }
            modifiedLines.add(line);
          }
        } else {
          modifiedLines.addAll(lines);
        }
        // Add completely missing entries.
        stringResOutput.createSync(recursive: true);
        for (final String line in modifiedLines) {
          // This is safe because <resources> must be root node.
          if (line.trim().startsWith('<resources>')) {
            stringResOutput.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
            for (final String key in requiredEntriesMap.keys) {
              stringResOutput.writeAsStringSync('    <string name="$key">${requiredEntriesMap[key]}</string>\n',
                flush: false,
                mode: FileMode.append);
            }
            continue;
          } else {
            stringResOutput.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
          }
        }
        modifiedFiles.add(stringResOutput.path);
      }
    } else { // Generate completely new file
      stringResOutput.createSync(recursive: true);
      stringResOutput.writeAsStringSync(
'''
<?xml version="1.0" encoding="utf-8"?>
<resources>
''', flush: false);
      for (final String key in requiredEntriesMap.keys) {
        stringResOutput.writeAsStringSync('    <string name="$key">${requiredEntriesMap[key]}</string>\n',
          flush: false,
          mode: FileMode.append);
      }
      stringResOutput.writeAsStringSync(
'''
</resources>

''', flush: true, mode: FileMode.append);
      newFiles.add(stringResOutput.path);
    }
    return results;
  }

  Map<String, dynamic> _checkLoadingUnitGolden(
      List<LoadingUnit> generatedLoadingUnits,
      Map<String, dynamic> deferredComponentsGolden) {
    final Map<String, dynamic> results = <String, dynamic>{};
    final Set<LoadingUnit> unmatchedLoadingUnits = <LoadingUnit>{};
    final List<LoadingUnit> newLoadingUnits = <LoadingUnit>[];
    if (generatedLoadingUnits == null || deferredComponentsGolden == null) {
      results['new'] = newLoadingUnits;
      results['missing'] = unmatchedLoadingUnits;
      results['match'] = false;
      return results;
    }
    _inputs.add(env.projectDir.childFile(kDeferredComponentsGoldenFileName));
    final List<LoadingUnit> goldenLoadingUnits = deferredComponentsGolden['loading-units'] as List<LoadingUnit> ?? <LoadingUnit>[];
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
    results['new'] = newLoadingUnits;
    results['missing'] = unmatchedLoadingUnits;
    results['match'] = newLoadingUnits.isEmpty && unmatchedLoadingUnits.isEmpty;
    return results;
  }

  Map<String, dynamic> _parseGolden(File goldenFile) {
    _inputs.add(goldenFile);
    if (!goldenFile.existsSync()) {
      return <String, dynamic>{};
    }
    final YamlMap data = loadYaml(goldenFile.readAsStringSync()) as YamlMap;
    final Map<String, dynamic> output = <String, dynamic>{};

    final List<LoadingUnit> loadingUnits = <LoadingUnit>[];
    output['loading-units'] = loadingUnits;
    if (data.containsKey('loading-units') && data['loading-units'] != null) {
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
    return output;
  }

  void _writeGolden(List<LoadingUnit> generatedLoadingUnits) {
    if (generatedLoadingUnits == null) {
      return;
    }
    final File goldenFile = env.projectDir.childFile(kDeferredComponentsGoldenFileName);
    _outputs.add(goldenFile);
    if (goldenFile.existsSync()) {
      goldenFile.deleteSync();
    }
    goldenFile.createSync(recursive: true);

    goldenFile.writeAsStringSync(
  '''
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
#
# This list of loading units are a snapshot of the loading units generated
# by the latest successful gen_snapshot during the assembly of deferred
# components opted-in apps.
loading-units:
''', flush: false, mode: FileMode.append);
    final Set<int> usedIds = <int>{};
    for (final LoadingUnit unit in generatedLoadingUnits) {
      if (usedIds.contains(unit.id)) {
        continue;
      }
      goldenFile.writeAsStringSync('  - id: ${unit.id}\n', flush: false, mode: FileMode.append);
      goldenFile.writeAsStringSync('    libraries:\n', flush: false, mode: FileMode.append);
      for (final String lib in unit.libraries) {
        goldenFile.writeAsStringSync('      - $lib\n', flush: false, mode: FileMode.append);
      }
      usedIds.add(unit.id);
    }
  }

  void _clearTempDir() {
    final Directory dir = env.projectDir.childDirectory('build').childDirectory(kDeferredComponentsTempDirectory);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  }

  Future<List<String>> _generateDiff() async {
    final List<String> diffLines = <String>[];
    String consumeLog(String line) {
      diffLines.add(line);
      // Don't pipe output. We will display the results later.
      return null;
    }
    final List<String> command = <String>[];
    if (globals.platform.isLinux || globals.platform.isMacOS) {
      command.add('diff');
      command.add('-r');
      command.add('-u');
      command.add('--unidirectional-new-file');
      command.add('--exclude=*.diff');
      command.add('android');
      command.add('build/$kDeferredComponentsTempDirectory');
    } else if (globals.platform.isWindows) {
      command.add('fc');
      command.add('android/*');
      command.add('build/$kDeferredComponentsTempDirectory/*');
    }

    await globals.processUtils.stream(
      command,
      workingDirectory: env.projectDir.path,
      mapFunction: consumeLog,
    );
    if (diffLines.isNotEmpty) {
      final File diffFile = env.projectDir
        .childDirectory('build')
        .childDirectory(kDeferredComponentsTempDirectory)
        .childFile('setup.diff');
      if (diffFile.existsSync()) {
        diffFile.deleteSync();
      }
      diffFile.createSync(recursive: true);
      for (final String line in diffLines) {
        diffFile.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
      }
    }
    return diffLines;
  }

  static const String _thickDivider = '=================================================================================';
  static const String _thinDivider = '---------------------------------------------------------------------------------';

  // TODO(garyq): Gradle and re-entrant Flutter currently eats up any color and
  // text formatting/highlighting. Figure out how to preserve this info.
  bool _handleResults(
      List<String> generatedFiles,
      List<String> modifiedFiles,
      Map<String, dynamic> goldenComparisonResults,
      List<String> diffLines, bool exitOnFail) {
    final bool fileChangesNeeded =
      generatedFiles.isNotEmpty ||
      modifiedFiles.isNotEmpty ||
      (goldenComparisonResults != null && !(goldenComparisonResults['match'] as bool));
    if (fileChangesNeeded) {
      _logger.printStatus(_thickDivider);
      _logger.printStatus(_title, indent: (_thickDivider.length - _title.length) ~/ 2, emphasis: true);
      _logger.printStatus(_thickDivider);
      // Log diff file contents, with color highlighting
      if (diffLines != null && diffLines.isNotEmpty) {
        _logger.printStatus('Diff between `android` and expected files:', emphasis: true);
        _logger.printStatus('');
        for (final String line in diffLines) {
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
          _logger.printStatus(line, color: color);
        }
        _logger.printStatus('');
      }
      // Log any newly generated and modified files.
      if (generatedFiles.isNotEmpty) {
        _logger.printStatus('Newly generated android files:', emphasis: true);
        for (final String filePath in generatedFiles) {
          final String shortenedPath = filePath.substring(env.projectDir.parent.path.length + 1);
          _logger.printStatus('  - $shortenedPath', color: TerminalColor.grey);
        }
        _logger.printStatus('');
      }
      if (modifiedFiles.isNotEmpty) {
        _logger.printStatus('Modified android files:', emphasis: true);
        for (final String filePath in modifiedFiles) {
          final String shortenedPath = filePath.substring(env.projectDir.parent.path.length + 1);
          _logger.printStatus('  - $shortenedPath', color: TerminalColor.grey);
        }
        _logger.printStatus('');
      }
      if (generatedFiles.isNotEmpty || modifiedFiles.isNotEmpty) {
        _logger.printStatus('''
The above files have been placed into `build/$kDeferredComponentsTempDirectory`,
a temporary directory. The files should be reviewed and moved into the project's
`android` directory.''');
        if (diffLines != null && diffLines.isNotEmpty && !globals.platform.isWindows) {
          _logger.printStatus('''

The recommended changes can be quickly applied by running:

  \$ patch -p0 < build/$kDeferredComponentsTempDirectory/setup.diff
''');
        }
        _logger.printStatus('$_thinDivider\n');
      }
      // Log loading unit golden changes, if any.
      if (goldenComparisonResults != null) {
        if ((goldenComparisonResults['new'] as List<LoadingUnit>).isNotEmpty) {
          _logger.printStatus('New loading units were found:', emphasis: true);
          for (final LoadingUnit unit in goldenComparisonResults['new'] as List<LoadingUnit>) {
            _logger.printStatus(unit.toString(), color: TerminalColor.grey, indent: 2);
          }
          _logger.printStatus('');
        }
        if ((goldenComparisonResults['missing'] as Set<LoadingUnit>).isNotEmpty) {
          _logger.printStatus('Previously existing loading units no longer exist:', emphasis: true);
          for (final LoadingUnit unit in goldenComparisonResults['missing'] as Set<LoadingUnit>) {
            _logger.printStatus(unit.toString(), color: TerminalColor.grey, indent: 2);
          }
          _logger.printStatus('');
        }
        if (goldenComparisonResults['match'] as bool) {
          _logger.printStatus('No change in generated loading units.\n');
        } else {
          _logger.printStatus('''
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
      _logger.printStatus('''
Setup verification can be skipped by passing the `--no-verify-deferred-components`
flag, however, doing so may put your app at risk of not functioning even if the
build is successful.
$_thickDivider''');
      return false;
    }
    _logger.printStatus('$_title passed.');
    return true;
  }
}

// Handles a single deferred component's android dynamic feature module directory.
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
    final Directory outputDir = alternateAndroidDir == null ? componentDir : alternateAndroidDir.childDirectory(name);
    if (clearAlternateOutputDir && alternateAndroidDir != null && outputDir.existsSync()) {
      outputDir.deleteSync(recursive: true);
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
      final Directory templateComponentDir = _templatesDir.childDirectory('module${io.Platform.pathSeparator}android${io.Platform.pathSeparator}deferred_component');
      template = Template(templateComponentDir, templateComponentDir, _templatesDir,
        fileSystem: env.fileSystem,
        templateManifest: null,
        logger: globals.logger,
        templateRenderer: globals.templateRenderer,
      );
    } else {
      template = await Template.fromName('module${io.Platform.pathSeparator}android${io.Platform.pathSeparator}deferred_component',
        fileSystem: env.fileSystem,
        templateManifest: null,
        logger: globals.logger,
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
    } else if (tempBuildGradle.existsSync()) {
      tempBuildGradle.deleteSync();
    }
    final File tempAndroidManifest = outputDir
      .childDirectory('src')
      .childDirectory('main')
      .childFile('AndroidManifest.xml');
    if (!androidManifestFile.existsSync()) {
      generatedFiles.add(tempAndroidManifest);
    } else if (tempAndroidManifest.existsSync()) {
      tempAndroidManifest.deleteSync();
    }
    return generatedFiles;
  }
}
