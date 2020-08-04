// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:package_config/package_config.dart';
import 'package:package_config/package_config_types.dart';

import 'base/common.dart';
import 'base/file_system.dart';
import 'cache.dart';
import 'dart/package_map.dart';
import 'dart/pub.dart';
import 'globals.dart' as globals hide fs;

/// Expands templates in a directory to a destination. All files that must
/// undergo template expansion should end with the '.tmpl' extension. All files
/// that should be replaced with the corresponding image from
/// flutter_template_images should end with the '.img.tmpl' extension. All other
/// files are ignored. In case the contents of entire directories must be copied
/// as is, the directory itself can end with '.tmpl' extension. Files within
/// such a directory may also contain the '.tmpl' or '.img.tmpl' extensions and
/// will be considered for expansion. In case certain files need to be copied
/// but without template expansion (data files, etc.), the '.copy.tmpl'
/// extension may be used.
///
/// Folders with platform/language-specific content must be named
/// '<platform>-<language>.tmpl'.
///
/// Files in the destination will contain none of the '.tmpl', '.copy.tmpl',
/// 'img.tmpl', or '-<language>.tmpl' extensions.
class Template {
  Template(Directory templateSource, Directory baseDir, this.imageSourceDir, {
    @required FileSystem fileSystem,
    @required Set<Uri> templateManifest,
  }) : _fileSystem = fileSystem,
       _templateManifest = templateManifest {
    _templateFilePaths = <String, String>{};

    if (!templateSource.existsSync()) {
      return;
    }

    final List<FileSystemEntity> templateFiles = templateSource.listSync(recursive: true);

    for (final FileSystemEntity entity in templateFiles) {
      if (entity is! File) {
        // We are only interesting in template *file* URIs.
        continue;
      }
      if (_templateManifest != null && !_templateManifest.contains(Uri.file(entity.absolute.path))) {
        globals.logger.printTrace('Skipping ${entity.absolute.path}, missing from the template manifest.');
        // Skip stale files in the flutter_tools directory.
        continue;
      }

      final String relativePath = fileSystem.path.relative(entity.path,
          from: baseDir.absolute.path);
      if (relativePath.contains(templateExtension)) {
        // If '.tmpl' appears anywhere within the path of this entity, it is
        // is a candidate for rendering. This catches cases where the folder
        // itself is a template.
        _templateFilePaths[relativePath] = fileSystem.path.absolute(entity.path);
      }
    }
  }

  static Future<Template> fromName(String name, {
    @required FileSystem fileSystem,
    @required Set<Uri> templateManifest,
  }) async {
    // All named templates are placed in the 'templates' directory
    final Directory templateDir = _templateDirectoryInPackage(name, fileSystem);
    final Directory imageDir = await _templateImageDirectory(name, fileSystem);
    return Template(
      templateDir,
      templateDir, imageDir,
      fileSystem: fileSystem,
      templateManifest: templateManifest,
    );
  }

  final FileSystem _fileSystem;
  final Set<Uri> _templateManifest;
  static const String templateExtension = '.tmpl';
  static const String copyTemplateExtension = '.copy.tmpl';
  static const String imageTemplateExtension = '.img.tmpl';
  final Pattern _kTemplateLanguageVariant = RegExp(r'(\w+)-(\w+)\.tmpl.*');
  final Directory imageSourceDir;

  Map<String /* relative */, String /* absolute source */> _templateFilePaths;

  /// Render the template into [directory].
  ///
  /// May throw a [ToolExit] if the directory is not writable.
  int render(
    Directory destination,
    Map<String, dynamic> context, {
    bool overwriteExisting = true,
    bool printStatusWhenWriting = true,
  }) {
    try {
      destination.createSync(recursive: true);
    } on FileSystemException catch (err) {
      globals.printError(err.toString());
      throwToolExit('Failed to flutter create at ${destination.path}.');
      return 0;
    }
    int fileCount = 0;

    /// Returns the resolved destination path corresponding to the specified
    /// raw destination path, after performing language filtering and template
    /// expansion on the path itself.
    ///
    /// Returns null if the given raw destination path has been filtered.
    String renderPath(String relativeDestinationPath) {
      final Match match = _kTemplateLanguageVariant.matchAsPrefix(relativeDestinationPath);
      if (match != null) {
        final String platform = match.group(1);
        final String language = context['${platform}Language'] as String;
        if (language != match.group(2)) {
          return null;
        }
        relativeDestinationPath = relativeDestinationPath.replaceAll('$platform-$language.tmpl', platform);
      }

      final bool android = context['android'] as bool;
      if (relativeDestinationPath.contains('android') && !android) {
        return null;
      }

      // TODO(cyanglaz): do not add iOS folder by default when 1.20.0 is released.
      // Also need to update the flutter SDK min constraint in the pubspec.yaml to 1.20.0.
      // https://github.com/flutter/flutter/issues/59787

      // Only build a web project if explicitly asked.
      final bool web = context['web'] as bool;
      if (relativeDestinationPath.contains('web') && !web) {
        return null;
      }
      // Only build a Linux project if explicitly asked.
      final bool linux = context['linux'] as bool;
      if (relativeDestinationPath.startsWith('linux.tmpl') && !linux) {
        return null;
      }
      // Only build a macOS project if explicitly asked.
      final bool macOS = context['macos'] as bool;
      if (relativeDestinationPath.startsWith('macos.tmpl') && !macOS) {
        return null;
      }
      // Only build a Windows project if explicitly asked.
      final bool windows = context['windows'] as bool;
      if (relativeDestinationPath.startsWith('windows.tmpl') && !windows) {
        return null;
      }

      final String projectName = context['projectName'] as String;
      final String androidIdentifier = context['androidIdentifier'] as String;
      final String pluginClass = context['pluginClass'] as String;
      final String destinationDirPath = destination.absolute.path;
      final String pathSeparator = _fileSystem.path.separator;
      String finalDestinationPath = _fileSystem.path
        .join(destinationDirPath, relativeDestinationPath)
        .replaceAll(copyTemplateExtension, '')
        .replaceAll(imageTemplateExtension, '')
        .replaceAll(templateExtension, '');

      if (android != null && android && androidIdentifier != null) {
        finalDestinationPath = finalDestinationPath
            .replaceAll('androidIdentifier', androidIdentifier.replaceAll('.', pathSeparator));
      }
      if (projectName != null) {
        finalDestinationPath = finalDestinationPath.replaceAll('projectName', projectName);
      }
      if (pluginClass != null) {
        finalDestinationPath = finalDestinationPath.replaceAll('pluginClass', pluginClass);
      }
      return finalDestinationPath;
    }

    _templateFilePaths.forEach((String relativeDestinationPath, String absoluteSourcePath) {
      final bool withRootModule = context['withRootModule'] as bool ?? false;
      if (!withRootModule && absoluteSourcePath.contains('flutter_root')) {
        return;
      }

      final String finalDestinationPath = renderPath(relativeDestinationPath);
      if (finalDestinationPath == null) {
        return;
      }
      final File finalDestinationFile = _fileSystem.file(finalDestinationPath);
      final String relativePathForLogging = _fileSystem.path.relative(finalDestinationFile.path);

      // Step 1: Check if the file needs to be overwritten.

      if (finalDestinationFile.existsSync()) {
        if (overwriteExisting) {
          finalDestinationFile.deleteSync(recursive: true);
          if (printStatusWhenWriting) {
            globals.printStatus('  $relativePathForLogging (overwritten)');
          }
        } else {
          // The file exists but we cannot overwrite it, move on.
          if (printStatusWhenWriting) {
            globals.printTrace('  $relativePathForLogging (existing - skipped)');
          }
          return;
        }
      } else {
        if (printStatusWhenWriting) {
          globals.printStatus('  $relativePathForLogging (created)');
        }
      }

      fileCount++;

      finalDestinationFile.createSync(recursive: true);
      final File sourceFile = _fileSystem.file(absoluteSourcePath);

      // Step 2: If the absolute paths ends with a '.copy.tmpl', this file does
      //         not need mustache rendering but needs to be directly copied.

      if (sourceFile.path.endsWith(copyTemplateExtension)) {
        sourceFile.copySync(finalDestinationFile.path);

        return;
      }

      // Step 3: If the absolute paths ends with a '.img.tmpl', this file needs
      //         to be copied from the template image package.

      if (sourceFile.path.endsWith(imageTemplateExtension)) {
        final File imageSourceFile = _fileSystem.file(_fileSystem.path.join(
            imageSourceDir.path, relativeDestinationPath.replaceAll(imageTemplateExtension, '')));
        imageSourceFile.copySync(finalDestinationFile.path);

        return;
      }

      // Step 4: If the absolute path ends with a '.tmpl', this file needs
      //         rendering via mustache.

      if (sourceFile.path.endsWith(templateExtension)) {
        final String templateContents = sourceFile.readAsStringSync();
        final String renderedContents = globals.templateRenderer.renderString(templateContents, context);

        finalDestinationFile.writeAsStringSync(renderedContents);

        return;
      }

      // Step 5: This file does not end in .tmpl but is in a directory that
      //         does. Directly copy the file to the destination.

      sourceFile.copySync(finalDestinationFile.path);
    });

    return fileCount;
  }
}

Directory _templateDirectoryInPackage(String name, FileSystem fileSystem) {
  final String templatesDir = fileSystem.path.join(Cache.flutterRoot,
      'packages', 'flutter_tools', 'templates');
  return fileSystem.directory(fileSystem.path.join(templatesDir, name));
}

// Returns the directory containing the 'name' template directory in
// flutter_template_images, to resolve image placeholder against.
Future<Directory> _templateImageDirectory(String name, FileSystem fileSystem) async {
  final String toolPackagePath = fileSystem.path.join(
      Cache.flutterRoot, 'packages', 'flutter_tools');
  final String packageFilePath = fileSystem.path.join(toolPackagePath, kPackagesFileName);
  // Ensure that .packgaes is present.
  if (!fileSystem.file(packageFilePath).existsSync()) {
    await _ensurePackageDependencies(toolPackagePath);
  }
  PackageConfig packageConfig = await loadPackageConfigWithLogging(
    fileSystem.file(packageFilePath),
    logger: globals.logger,
  );
  Uri imagePackageLibDir = packageConfig['flutter_template_images']?.packageUriRoot;
  // Ensure that the template image package is present.
  if (imagePackageLibDir == null || !fileSystem.directory(imagePackageLibDir).existsSync()) {
    await _ensurePackageDependencies(toolPackagePath);
    packageConfig = await loadPackageConfigWithLogging(
      fileSystem.file(packageFilePath),
      logger: globals.logger,
    );
    imagePackageLibDir = packageConfig['flutter_template_images']?.packageUriRoot;
  }
  return fileSystem.directory(imagePackageLibDir)
      .parent
      .childDirectory('templates')
      .childDirectory(name);
}

// Runs 'pub get' for the given path to ensure that .packages is created and
// all dependencies are present.
Future<void> _ensurePackageDependencies(String packagePath) async {
  await pub.get(
    context: PubContext.pubGet,
    directory: packagePath,
  );
}
