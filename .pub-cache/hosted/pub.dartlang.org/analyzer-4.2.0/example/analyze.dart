// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/physical_file_system.dart';

/// A simple example of using the AnalysisContextCollection API.
void main(List<String> args) async {
  FileSystemEntity entity = Directory.current;
  if (args.isNotEmpty) {
    String arg = args.first;
    entity = FileSystemEntity.isDirectorySync(arg) ? Directory(arg) : File(arg);
  }

  var issueCount = 0;
  final collection = AnalysisContextCollection(
      includedPaths: [entity.absolute.path],
      resourceProvider: PhysicalResourceProvider.INSTANCE);

  // Often one context is returned, but depending on the project structure we
  // can see multiple contexts.
  for (final context in collection.contexts) {
    print('Analyzing ${context.contextRoot.root.path} ...');

    for (final filePath in context.contextRoot.analyzedFiles()) {
      if (!filePath.endsWith('.dart')) {
        continue;
      }

      final errorsResult = await context.currentSession.getErrors(filePath);
      if (errorsResult is ErrorsResult) {
        for (final error in errorsResult.errors) {
          if (error.errorCode.type != ErrorType.TODO) {
            print(
                '  \u001b[1m${error.source.shortName}\u001b[0m ${error.message}');
            issueCount++;
          }
        }
      }
    }
  }

  print('$issueCount issues found.');
}
