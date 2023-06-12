// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import '../asset_graph/node.dart';
import '../util/constants.dart';

/// A tracker for the errors which have already been reported during the current
/// build.
///
/// Errors that occur due to actions that are run within this build will be
/// reported directly as they happen. When an action is skipped and remains a
/// failure the error will not have been reported by the time we check wether
/// the build is failed.
///
/// The lifetime of this class should be a single build.
class FailureReporter {
  /// Removes all stored errors from previous builds.
  ///
  /// This should be called any time the build phases change since the naming
  /// scheme is dependent on the build phases.
  static Future<void> cleanErrorCache() async {
    final errorCacheDirectory = Directory(errorCachePath);
    if (await errorCacheDirectory.exists()) {
      await errorCacheDirectory.delete(recursive: true);
    }
  }

  /// Remove the stored error for [phaseNumber] runnon on [primaryInput].
  ///
  /// This should be called anytime the action is being run.
  static Future<void> clean(int phaseNumber, AssetId primaryInput) async {
    final errorFile =
        File(_errorPathForPrimaryInput(phaseNumber, primaryInput));
    if (await errorFile.exists()) {
      await errorFile.delete();
    }
  }

  /// A set of Strings which uniquely identify a particular build action and
  /// it's primary input.
  final _reportedActions = <String>{};

  /// Indicate that a failure reason for the build step which would produce
  /// [output] and all other outputs from the same build step has been printed.
  Future<void> markReported(String actionDescription, GeneratedAssetNode output,
      Iterable<ErrorReport> errors) async {
    if (!_reportedActions.add(_actionKey(output))) return;
    final errorFile =
        await File(_errorPathForOutput(output)).create(recursive: true);
    await errorFile.writeAsString(jsonEncode(<dynamic>[actionDescription]
        .followedBy(errors
            .map((e) => [e.message, e.error, e.stackTrace?.toString() ?? '']))
        .toList()));
  }

  /// Indicate that the build steps which would produce [outputs] are failing
  /// due to a dependency and being skipped so no actuall error will be
  /// produced.
  Future<void> markSkipped(Iterable<GeneratedAssetNode> outputs) =>
      Future.wait(outputs.map((output) async {
        if (!_reportedActions.add(_actionKey(output))) return;
        await clean(output.phaseNumber, output.primaryInput);
      }));

  /// Log stored errors for any build steps which would output nodes in
  /// [failingNodes] which haven't already been reported.
  Future<void> reportErrors(Iterable<GeneratedAssetNode> failingNodes) {
    final errorFiles = <File>[];
    for (final failure in failingNodes) {
      final key = _actionKey(failure);
      if (!_reportedActions.add(key)) continue;
      errorFiles.add(File(_errorPathForOutput(failure)));
    }
    return Future.wait(errorFiles.map((errorFile) async {
      if (await errorFile.exists()) {
        final errorReports = jsonDecode(await errorFile.readAsString()) as List;
        final actionDescription = '${errorReports.first} (cached)';
        final logger = Logger(actionDescription);
        for (final error in errorReports.skip(1).cast<List>()) {
          final stackTraceString = error[2] as String;
          final stackTrace = stackTraceString.isEmpty
              ? null
              : StackTrace.fromString(stackTraceString);
          logger.severe(error[0], error[1], stackTrace);
        }
      }
    }));
  }
}

/// Matches the call to [Logger.severe] except the [message] and [error] are
/// eagerly converted to String.
class ErrorReport {
  final String message;
  final String error;
  final StackTrace stackTrace;
  ErrorReport(this.message, this.error, this.stackTrace);
}

String _actionKey(GeneratedAssetNode node) =>
    '${node.builderOptionsId} on ${node.primaryInput}';

String _errorPathForOutput(GeneratedAssetNode output) => p.joinAll([
      errorCachePath,
      output.id.package,
      '${output.phaseNumber}',
      ...p.posix.split(output.primaryInput.path)
    ]);

String _errorPathForPrimaryInput(int phaseNumber, AssetId primaryInput) =>
    p.joinAll([
      errorCachePath,
      primaryInput.package,
      '$phaseNumber',
      ...p.posix.split(primaryInput.path)
    ]);
