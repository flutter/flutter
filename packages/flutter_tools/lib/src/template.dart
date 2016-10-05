// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:mustache4dart/mustache4dart.dart' as mustache;
import 'package:path/path.dart' as path;

import 'cache.dart';
import 'globals.dart';

const String _kTemplateExtension = '.tmpl';
const String _kCopyTemplateExtension = '.copy.tmpl';

/// Expands templates in a directory to a destination. All files that must
/// undergo template expansion should end with the '.tmpl' extension. All other
/// files are ignored. In case the contents of entire directories must be copied
/// as is, the directory itself can end with '.tmpl' extension. Files within
/// such a directory may also contain the '.tmpl' extension and will be
/// considered for expansion. In case certain files need to be copied but
/// without template expansion (images, data files, etc.), the '.copy.tmpl'
/// extension may be used.
///
/// Files in the destination will not contain either the '.tmpl' or '.copy.tmpl'
/// extensions.
class Template {
  Template(Directory templateSource, Directory baseDir) {
    _templateFilePaths = new Map<String, String>();

    if (!templateSource.existsSync()) {
      return;
    }

    List<FileSystemEntity> templateFiles = templateSource.listSync(recursive: true);

    for (FileSystemEntity entity in templateFiles) {
      if (entity is! File) {
        // We are only interesting in template *file* URIs.
        continue;
      }

      String relativePath = path.relative(entity.path,
          from: baseDir.absolute.path);

      if (relativePath.contains(_kTemplateExtension)) {
        // If '.tmpl' appears anywhere within the path of this entity, it is
        // is a candidate for rendering. This catches cases where the folder
        // itself is a template.
        _templateFilePaths[relativePath] = path.absolute(entity.path);
      }
    }
  }

  factory Template.fromName(String name) {
    // All named templates are placed in the 'templates' directory
    Directory templateDir = _templateDirectoryInPackage(name);
    return new Template(templateDir, templateDir);
  }

  Map<String /* relative */, String /* absolute source */> _templateFilePaths;

  int render(Directory destination, Map<String, dynamic> context,
      { bool overwriteExisting: true }) {
    destination.createSync(recursive: true);
    int fileCount = 0;

    String destinationDirPath = destination.absolute.path;

    _templateFilePaths.forEach((String relativeDestPath, String absoluteSrcPath) {
      String finalDestinationPath = path
          .join(destinationDirPath, relativeDestPath)
          .replaceAll(_kCopyTemplateExtension, '')
          .replaceAll(_kTemplateExtension, '');
      File finalDestinationFile = new File(finalDestinationPath);
      String relativePathForLogging = path.relative(finalDestinationFile.path);

      // Step 1: Check if the file needs to be overwritten.

      if (finalDestinationFile.existsSync()) {
        if (overwriteExisting) {
          finalDestinationFile.delete(recursive: true);
          printStatus('  $relativePathForLogging (overwritten)');
        } else {
          // The file exists but we cannot overwrite it, move on.
          printTrace('  $relativePathForLogging (existing - skipped)');
          return;
        }
      } else {
        printTrace('  $relativePathForLogging');
      }

      fileCount++;

      finalDestinationFile.createSync(recursive: true);
      File sourceFile = new File(absoluteSrcPath);

      // Step 2: If the absolute paths ends with a 'copy.tmpl', this file does
      //         not need mustache rendering but needs to be directly copied.

      if (sourceFile.path.endsWith(_kCopyTemplateExtension)) {
        finalDestinationFile.writeAsBytesSync(sourceFile.readAsBytesSync());

        return;
      }

      // Step 3: If the absolute path ends with a '.tmpl', this file needs
      //         rendering via mustache.

      if (sourceFile.path.endsWith(_kTemplateExtension)) {
        String templateContents = sourceFile.readAsStringSync();
        String renderedContents = mustache.render(templateContents, context);

        finalDestinationFile.writeAsStringSync(renderedContents);

        return;
      }

      // Step 4: This file does not end in .tmpl but is in a directory that
      //         does. Directly copy the file to the destination.

      sourceFile.copySync(finalDestinationFile.path);
    });

    return fileCount;
  }
}

Directory _templateDirectoryInPackage(String name) {
  String templatesDir = path.join(Cache.flutterRoot,
      'packages', 'flutter_tools', 'templates');
  return new Directory(path.join(templatesDir, name));
}
