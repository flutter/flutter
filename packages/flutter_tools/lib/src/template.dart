// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:mustache/mustache.dart' as mustache;

import 'base/file_system.dart';
import 'cache.dart';
import 'globals.dart';

/// Copies a directory from a source to a destination while applying template
/// expansion and name transformation rules.
///
/// All files that must undergo template expansion should end with the '.tmpl'
/// extension. All other files are ignored. In case the contents of entire
/// directories must be copied as is, the directory itself can end with '.tmpl'
/// extension. Files within such a directory may also contain the '.tmpl'
/// extension and will be considered for expansion. In case certain files need
/// to be copied but without template expansion (images, data files, etc.), the
/// '.copy.tmpl' extension may be used.
///
/// Folders with platform-language-specific content must be named
/// '<dirname>-<language>.tmpl'.
///
/// Files in the destination will contain none of the '.tmpl', '.copy.tmpl'
/// or '-<language>.tmpl' extensions.
class Template {
  Template({this.printDebug = false});

  static Directory directoryByTemplateName(String name) {
    final String templatesDir = fs.path.join(Cache.flutterRoot,
        'packages', 'flutter_tools', 'templates');
    return fs.directory(fs.path.join(templatesDir, name));
  }

  static Directory directoryByRelativePath(String relativePath) {
    final String templatesDir = fs.path.join(Cache.flutterRoot,
        'packages', 'flutter_tools', 'templates');
    return fs.directory(fs.path.join(templatesDir, relativePath));
  }

  static const String templateExtension = '.tmpl';
  static const String copyTemplateExtension = '.copy.tmpl';
  final bool printDebug;

  Future<int> render(
    Directory source,
    Directory destination,
    Map<String, dynamic> context, {
    bool overwriteExisting = true,
    bool printStatusWhenWriting = true,
  }) async {
    // If the source directory doesn't exist then there is no template to render.
    if (!source.existsSync()) {
      print('Could not find template source: ${source.path}');
      return 0;
    }

    // Configure instructions for template processing.
    final TemplateInstructions templateInstructions = TemplateInstructions.fromDirectories(
      sourceDir: source,
      destinationDir: destination,
    );
    TemplateRules().applyTo(context, templateInstructions, templateExtension, copyTemplateExtension);
    print('Template instructions assembled:\n$templateInstructions');

    // Use the template instructions to copy desired files from the source directory
    // to the destination directory.  Return the total number of files created.
    return _copyTemplateFilesToDestination(
      context: context,
      templateInstructions: templateInstructions,
      overwriteExisting: overwriteExisting,
      printStatusWhenWriting: printStatusWhenWriting,
    );
  }

  int _copyTemplateFilesToDestination({
    @required Map<String, dynamic> context,
    @required TemplateInstructions templateInstructions,
    @required bool overwriteExisting,
    @required bool printStatusWhenWriting,
  }) {
    // Execute template instructions by copying all desired files from source
    // to destination, expanding any mustache templates along the way.
    int fileCount = 0;

    // Create the directory that will hold all the files we create.
    templateInstructions.destinationDir.createSync(recursive: true);

    for (TemplatePathMapping mapping in templateInstructions.pathMappings) {
      if (mapping.action != FileAction.ignore) {
        // Create the file
        final bool fileCreated = _createDestinationFile(
          mapping,
          overwriteExisting: overwriteExisting,
          printStatusWhenWriting: printStatusWhenWriting,
        );

        // Increment fileCount
        fileCount += fileCreated ? 1 : 0;

        // Apply mustache template, or do direct copy
        if (mapping.action == FileAction.applyMustach) {
          _copyFileWithMustacheExpansion(context, mapping);
        } else if (mapping.action == FileAction.copy) {
          _copyFileDirectly(mapping);
        }
      }
    }

    return fileCount;
  }

  bool _createDestinationFile(TemplatePathMapping mapping, {bool overwriteExisting = false, bool printStatusWhenWriting = false}) {
    final File destinationFile = fs.file(fs.path.join(mapping.baseDestinationPath, mapping.relativeDestinationPath));
    final String relativePathForLogging = fs.path.relative(destinationFile.path);

    if (destinationFile.existsSync()) {
      if (overwriteExisting) {
        destinationFile.deleteSync(recursive: true);
        if (printStatusWhenWriting) {
          printStatus('  $relativePathForLogging (overwritten)');
        }
      } else {
        // The file exists but we cannot overwrite it, exclude it.
        if (printStatusWhenWriting) {
          printTrace('  $relativePathForLogging (existing - skipped)');
        }
        return false;
      }
    } else {
      if (printStatusWhenWriting) {
        printStatus('  $relativePathForLogging (created)');
      }
    }

    destinationFile.createSync(recursive: true);

    return true;
  }

  void _copyFileWithMustacheExpansion(Map<String, dynamic> context, TemplatePathMapping mapping) {
    final File sourceFile = fs.file(fs.path.join(mapping.baseTemplatePath, mapping.relativeTemplatePath));
    final String templateContents = sourceFile.readAsStringSync();
    final String renderedContents = mustache.Template(templateContents).renderString(context);

    final File destinationFile = fs.file(fs.path.join(mapping.baseDestinationPath, mapping.relativeDestinationPath));
    destinationFile.writeAsStringSync(renderedContents);
  }

  void _copyFileDirectly(TemplatePathMapping mapping) {
    final File sourceFile = fs.file(fs.path.join(mapping.baseTemplatePath, mapping.relativeTemplatePath));
    sourceFile.copySync(fs.path.join(mapping.baseDestinationPath, mapping.relativeDestinationPath));
  }
}

/// Instructions for how to render a template from a source directory to a
/// destination directory.
///
/// [sourceDirPath] is the absolute path of the directory that contains the
/// template to be rendered.
///
/// [destinationDirPath] is the absolute path to the directory where the
/// template files should be rendered.
///
/// Rendering a template consists of copying, and possibly transforming, some
/// number of files from the source directory to the destination directory.
/// [pathMappings] contains a [TemplatePathMapping] for every file in the source
/// directory. Each [TemplatePathMapping] indicates what the path of the source
/// file is, what the path of the destination file should be, and what [FileAction]
/// should be taken for this file, e.g., ignore, copy, apply mustache rendering.
@visibleForTesting
class TemplateInstructions {
  TemplateInstructions({
    @required this.sourceDirPath,
    @required this.destinationDirPath,
    this.pathMappings,
  });

  factory TemplateInstructions.fromPaths({
    String sourceDirPath,
    List<String> relativeSourceFilePaths,
    String destinationDirPath,
  }) {
    return TemplateInstructions(
      sourceDirPath: sourceDirPath,
      destinationDirPath: destinationDirPath,
      pathMappings: relativeSourceFilePaths.map((String relativeSourcePath) => TemplatePathMapping(
        baseTemplatePath: sourceDirPath,
        relativeTemplatePath: relativeSourcePath,
        baseDestinationPath: destinationDirPath,
      ))
    );
  }

  factory TemplateInstructions.fromDirectories({
    Directory sourceDir,
    Directory destinationDir,
  }) {
    final List<FileSystemEntity> sourceFiles = sourceDir
        .listSync(recursive: true)
        ..retainWhere((FileSystemEntity entity) {
          return entity is File;
        });

    final List<String> relativeSourceFilePaths = sourceFiles
        .map((FileSystemEntity entity) {
          return fs.path.relative(entity.path, from:sourceDir.absolute.path);
        })
        .toList();

    return TemplateInstructions(
      sourceDirPath: sourceDir.absolute.path,
      destinationDirPath: destinationDir.absolute.path,
      pathMappings: relativeSourceFilePaths.map((String relativeSourcePath) {
        return TemplatePathMapping(
          baseTemplatePath: sourceDir.absolute.path,
          relativeTemplatePath: relativeSourcePath,
          baseDestinationPath: destinationDir.absolute.path,
        );
      }).toList()
    );
  }

  final String sourceDirPath;
  Directory get sourceDir => fs.directory(sourceDirPath);

  final String destinationDirPath;
  Directory get destinationDir => fs.directory(destinationDirPath);

  final List<TemplatePathMapping> pathMappings;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is TemplateInstructions &&
              runtimeType == other.runtimeType &&
              sourceDirPath == other.sourceDirPath &&
              destinationDirPath == other.destinationDirPath &&
              const ListEquality<TemplatePathMapping>().equals(pathMappings, other.pathMappings);

  @override
  int get hashCode =>
      sourceDirPath.hashCode ^
      destinationDirPath.hashCode ^
      pathMappings.hashCode;

  @override
  String toString() {
    return '\n'
      ' - sourceDir: $sourceDirPath\n'
      ' - destinationDir: $destinationDirPath\n'
      ' - pathMappings: [\n'
      '${_printPathMappings(prefix: "   - ")}'
      '   ]';
  }

  String _printPathMappings({String prefix}) {
    final StringBuffer buffer = StringBuffer();
    for (TemplatePathMapping mapping in pathMappings) {
      buffer.writeln('${prefix ?? ''}$mapping');
    }
    return buffer.toString();
  }
}

/// A mapping from a template source file to a rendered destination file.
///
/// Each [TemplatePathMapping] includes the absolute path to the base directory
/// for the source template, and the rendered destination, as well as the
/// relative path of the source file, and the relative path of the destination
/// file that needs to be rendered.
///
/// Each [TemplatePathMapping] also includes a desires [action] which represents
/// what should be done with the source file, e.g., ignore, copy, or apply mustache
/// rendering.
@visibleForTesting
class TemplatePathMapping {
  TemplatePathMapping({
    @required this.baseTemplatePath,
    @required this.relativeTemplatePath,
    @required this.baseDestinationPath,
    this.relativeDestinationPath,
  }) {
    relativeDestinationPath ??= relativeTemplatePath;
  }

  final String baseTemplatePath;
  final String relativeTemplatePath;
  String get absoluteTemplatePath => fs.path.join(baseTemplatePath, relativeTemplatePath);

  final String baseDestinationPath;
  String relativeDestinationPath;
  String get absoluteDestinationPath => fs.path.join(baseDestinationPath, relativeDestinationPath);

  FileAction action = FileAction.copy;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TemplatePathMapping &&
            runtimeType == other.runtimeType &&
            relativeTemplatePath == other.relativeTemplatePath &&
            relativeDestinationPath == other.relativeDestinationPath &&
            action == other.action;
  }

  @override
  int get hashCode {
    return relativeTemplatePath.hashCode ^
      relativeDestinationPath.hashCode ^
      action.hashCode;
  }

  @override
  String toString() {
    return 'TemplateMapping: $relativeTemplatePath => $relativeDestinationPath, action: $action';
  }

}

/// The template action to take for a given file mapping.
@visibleForTesting
enum FileAction {
  ignore,       // Don't copy the file.
  copy,         // Copy the file exactly, replacing any path ornamentation along the way.
  applyMustach, // Copy the file and apply mustache templating to its content.
}

/// The complete series of template rules that can be applied to a given set
/// of source files.
@visibleForTesting
class TemplateRules {
  /// Applies all templating rules to a set of sources represents by [instructions].
  ///
  /// [context] holds configuration data to be utilized by the templating rules.
  ///
  /// [templateExtension] is the path ornamentation string that indicates a given
  /// path requires template attention, e.g., .tmpl
  ///
  /// [copyTemplateExtension] is a file extension ornamentation that indicates a
  /// given file should be copied exactly to the destination, e.g., .copy.tmpl
  void applyTo(Map<String, dynamic> context, TemplateInstructions instructions, String templateExtension, String copyTemplateExtension) {
    final List<_TemplateRule> rules = <_TemplateRule>[
      // Exclude template files that are part of "flutter_root"
      FlutterRootFilterRule(withRootModule: context['withRootModule'] ?? false),

      // Exclude directories that are made for a platform language other than
      // the platform language we're using.
      LanguageFilterRule(
        iosLanguage: context['iosLanguage'],
        androidLanguage: context['androidLanguage'],
      ),

      // Remove special template symbols like ".tmpl" and ".copy.tmpl" extensions.
      FileCopyAndExpansionRule(
        templateExtension: templateExtension,
        copyTemplateExtension: copyTemplateExtension,
      ),

      // Replace any "androidIdentifier" placeholders with a series of directories
      // that reflect the Android package path.
      AndroidIdentifierNameReplacementRule(
        androidIdentifier: context['androidIdentifier'],
        pathSeparator: fs.path.separator,
      ),

      // Replace any "projectName" placeholders with the desired name of the
      // project being created.
      ProjectNameReplacementRule(
        projectName: context['projectName'],
      ),

      // Replace any "pluginClass" placeholders with the class name of the
      // plugin being created by this project.
      PluginNameReplacementRule(
        pluginClassName: context['pluginClass'],
      ),
    ];

    // Apply the rules to the TemplateInstructions.
    for (_TemplateRule rule in rules) {
      rule.applyTo(instructions);
    }
  }
}

/// Excludes paths that include "flutter_root" when [withRootModule] is false.
@visibleForTesting
class FlutterRootFilterRule implements _TemplateRule {
  FlutterRootFilterRule({
    @required this.withRootModule,
  });

  final bool withRootModule;

  @override
  void applyTo(TemplateInstructions instructions) {
    instructions.pathMappings.removeWhere((TemplatePathMapping mapping) {
      if (!withRootModule
          && (mapping.baseTemplatePath.contains('flutter_root')
              || mapping.relativeTemplatePath.contains('flutter_root'))) {
        // This template file belongs to flutter_root but we don't want
        // flutter_root files. Exclude it.
        return true;
      } else {
        // We want this file. Keep it.
        return false;
      }
    });
  }
}

/// Filters template paths based on the desired source code language for a given
/// platform.
///
/// If a given path includes one or more directories or files that specify a
/// language other than the language wanted, that path is excluded from the
/// rendered template. Otherwise, the path has all associated template
/// ornamentation stripped and a clean path is returned.
///
/// In a project where Java and Obj-C are desired, the following path
/// transformations would occurs:
///  - /my_dir/             =>  /my_dir/
///  - /my_dir-java.tmpl/   =>  /my_dir/
///  - /my_dir-kotlin.tmpl/ =>  null
///  - /my_dir-objc.tmpl/   =>  /my_dir/
///  - /my_dir-swift.tmpl/  =>  null
///
/// For Android paths:
///  - Java:    *-java.tmpl*
///  - Kotlin:  *-kotlin.tmpl*
///
/// For iOS paths:
///  - Obj-C:   *-objc.tmpl*
///  - Kotlin:  *-kotlin.tmpl*
@visibleForTesting
class LanguageFilterRule implements _TemplateRule {
  LanguageFilterRule({
    this.iosLanguage,
    this.androidLanguage,
  });

  final Pattern _kAndroidTemplateLanguageVariant = RegExp(r'(.*/)?(\w+)-(java|kotlin)\.tmpl.*');
  final Pattern _kIOSTemplateLanguageVariant = RegExp(r'(.*/)?(\w+)-(objc|swift)\.tmpl.*');
  final String iosLanguage;
  final String androidLanguage;

  @override
  void applyTo(TemplateInstructions instructions) {
    final List<TemplatePathMapping> mappingsToRemove = <TemplatePathMapping>[];

    for (TemplatePathMapping mapping in instructions.pathMappings) {
      final Match androidLanguageMatch = _kAndroidTemplateLanguageVariant.matchAsPrefix(mapping.relativeDestinationPath);
      if (androidLanguageMatch != null) {
        final String finalDirectoryName = androidLanguageMatch.group(2);
        if (androidLanguage == androidLanguageMatch.group(3)) {
          // This is an Android-language-specific path and it's the language
          // we want, so forward it on.
          mapping.relativeDestinationPath = mapping.relativeDestinationPath.replaceAll('$finalDirectoryName-$androidLanguage.tmpl', finalDirectoryName);
          continue;
        } else {
          // This path wants a different platform language. Exclude it.
          mappingsToRemove.add(mapping);
          continue;
        }
      }


      final Match iosLanguageMatch = _kIOSTemplateLanguageVariant.matchAsPrefix(mapping.relativeDestinationPath);
      if (iosLanguageMatch != null) {
        final String finalDirectoryName = iosLanguageMatch.group(2);
        if (iosLanguage == iosLanguageMatch.group(3)) {
          // This is an ios-language-specific path and it's the language
          // we want, so forward it on.
          mapping.relativeDestinationPath = mapping.relativeDestinationPath.replaceAll('$finalDirectoryName-$iosLanguage.tmpl', finalDirectoryName);
          continue;
        } else {
          // This path wants a different platform language. Exclude it.
          mappingsToRemove.add(mapping);
          continue;
        }
      }
    }

    // Remove the mappings that are intended for languages that we're not using.
    instructions.pathMappings.removeWhere((TemplatePathMapping mapping) {
      return mappingsToRemove.contains(mapping);
    });
  }
}

/// Determines whether a file needs to be mustache expanded, or just copied.
///
/// Strips any template ornamentation within directory and file names in a given
/// path, e.g., "my_dir-java.tmpl" becomes "my_dir".
@visibleForTesting
class FileCopyAndExpansionRule implements _TemplateRule {
  FileCopyAndExpansionRule({
    @required this.templateExtension,
    @required this.copyTemplateExtension,
  });

  final String templateExtension;
  final String copyTemplateExtension;

  @override
  void applyTo(TemplateInstructions instructions) {
    for (TemplatePathMapping mapping in instructions.pathMappings) {
      // Determine if this file needs mustache expansion.
      if (mapping.relativeTemplatePath.contains(templateExtension)) {
        if (mapping.relativeTemplatePath.endsWith(templateExtension)) {
          if (mapping.relativeTemplatePath.endsWith(copyTemplateExtension)) {
            mapping.action = FileAction.copy;
          } else {
            mapping.action = FileAction.applyMustach;
          }
        }
      } else {
        mapping.action = FileAction.ignore;
      }

      // Remove all template ornamentation.
      mapping.relativeDestinationPath = mapping.relativeDestinationPath
          .replaceAll(copyTemplateExtension, '')
          .replaceAll(templateExtension, '');
    }
  }
}

/// Expands instances of "androidIdentifier" into a directory structure that
/// corresponds to the package name represented by [androidIdentifier].
///
/// E.g., given an androidIdentifier of "com.mycompany.app", the following expansion
/// would take place:
///    "template_dir/androidIdentifier/src" =>
///    "template_dir/com/mycompany/myapp/src"
@visibleForTesting
class AndroidIdentifierNameReplacementRule implements _TemplateRule {
  AndroidIdentifierNameReplacementRule({
    this.androidIdentifier,
    this.pathSeparator,
  });

  final String androidIdentifier;
  final String pathSeparator;

  @override
  void applyTo(TemplateInstructions instructions) {
    for (TemplatePathMapping mapping in instructions.pathMappings) {
      if (androidIdentifier != null && pathSeparator != null) {
        // Replace the androidIdentifier with an expanded path.
        mapping.relativeDestinationPath = mapping.relativeDestinationPath.replaceAll('androidIdentifier', androidIdentifier.replaceAll('.', pathSeparator));
      }
    }
  }
}

/// Replaces occurrences of "projectName" in a path with the given [projectName].
@visibleForTesting
class ProjectNameReplacementRule implements _TemplateRule {
  ProjectNameReplacementRule({
    this.projectName,
  });

  final String projectName;

  @override
  void applyTo(TemplateInstructions instructions) {
    for (TemplatePathMapping mapping in instructions.pathMappings) {
      if (projectName != null) {
        // Replace the project name placeholder with the actual project name.
        mapping.relativeDestinationPath = mapping.relativeDestinationPath.replaceAll('projectName', projectName.replaceAll('projectName', projectName));
      }
    }
  }
}

/// Replaces occurrences of "pluginClass" in a path with the given [pluginClassName].
@visibleForTesting
class PluginNameReplacementRule implements _TemplateRule {
  PluginNameReplacementRule({
    this.pluginClassName,
  });

  final String pluginClassName;

  @override
  void applyTo(TemplateInstructions instructions) {
    for (TemplatePathMapping mapping in instructions.pathMappings) {
      if (pluginClassName != null) {
        // Replace the plugin class name placeholder with the actual plugin class name.
        mapping.relativeDestinationPath = mapping.relativeDestinationPath.replaceAll('pluginClass', pluginClassName.replaceAll('pluginClass', pluginClassName));
      } else {
        // No pluginClass placeholder found, send the path on without change.
        mapping.relativeDestinationPath = mapping.relativeDestinationPath;
      }
    }
  }
}

/// Modifies [TemplateInstructions] based on the logic of this [_TemplateRule].
abstract class _TemplateRule {
  void applyTo(TemplateInstructions instructions);
}

// The following code facilitates white box testing template processing pieces.
@visibleForTesting
InitialTemplateInstructionsBuilder initialInstructions() => InitialTemplateInstructionsBuilder();

@visibleForTesting
class InitialTemplateInstructionsBuilder {
  InitialTemplateInstructionsBuilder({
    this.sourcePath = '/root/path',
    this.destinationPath = '/root/destination',
  });

  String sourcePath;
  String destinationPath;
  List<TemplatePathMapping> pathMappings = <TemplatePathMapping>[];

  InitialTemplateInstructionsBuilder sources(List<String> sourcePaths) {
    sourcePaths.forEach(source);
    return this;
  }

  InitialTemplateInstructionsBuilder source(String from) {
    pathMappings.add(
        TemplatePathMapping(
          baseTemplatePath: sourcePath,
          relativeTemplatePath: from,
          baseDestinationPath: destinationPath,
        )
    );
    return this;
  }

  TemplateInstructions build() {
    return TemplateInstructions(
      sourceDirPath: sourcePath,
      destinationDirPath: destinationPath,
      pathMappings: pathMappings,
    );
  }
}

@visibleForTesting
ExpectedTemplateInstructionsBuilder expectInstructions() => ExpectedTemplateInstructionsBuilder();

@visibleForTesting
class ExpectedTemplateInstructionsBuilder {
  ExpectedTemplateInstructionsBuilder({
    this.sourcePath = '/root/path',
    this.destinationPath = '/root/destination',
  });

  String sourcePath;
  String destinationPath;
  List<TemplatePathMapping> pathMappings = <TemplatePathMapping>[];

  ExpectedTemplateInstructionsBuilder copy({String from, String to}) {
    pathMappings.add(
      TemplatePathMapping(
        baseTemplatePath: sourcePath,
        relativeTemplatePath: from,
        baseDestinationPath: destinationPath,
      )
        ..relativeDestinationPath = to
        ..action = FileAction.copy,
    );
    return this;
  }

  ExpectedTemplateInstructionsBuilder mustache({String from, String to}) {
    pathMappings.add(
      TemplatePathMapping(
        baseTemplatePath: sourcePath,
        relativeTemplatePath: from,
        baseDestinationPath: destinationPath,
      )
        ..relativeDestinationPath = to
        ..action = FileAction.applyMustach,
    );
    return this;
  }

  TemplateInstructions build() {
    return TemplateInstructions(
      sourceDirPath: sourcePath,
      destinationDirPath: destinationPath,
      pathMappings: pathMappings,
    );
  }
}