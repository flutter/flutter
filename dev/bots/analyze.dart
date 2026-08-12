// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:core' hide print;
import 'dart:io' hide exit;
import 'dart:typed_data';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:collection/equality.dart';
import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import 'allowlist.dart';
import 'custom_rules/analyze.dart';
import 'custom_rules/avoid_future_catcherror.dart';
import 'custom_rules/no_double_clamp.dart';
import 'custom_rules/no_stop_watches.dart';
import 'custom_rules/protect_public_state_subtypes.dart';
import 'custom_rules/render_box_intrinsics.dart';
import 'run_command.dart';
import 'utils.dart';

final String flutterPackages = path.join(flutterRoot, 'packages');
final String flutterExamples = path.join(flutterRoot, 'examples');

/// The path to the `dart` executable; set at the top of `main`
late final String dart;

/// The path to the `pub` executable; set at the top of `main`
late final String pub;

/// When you call this, you can pass additional arguments to pass custom
/// arguments to flutter analyze. For example, you might want to call this
/// script with the parameter --dart-sdk to use custom dart sdk.
///
/// For example:
/// bin/cache/dart-sdk/bin/dart dev/bots/analyze.dart --dart-sdk=/tmp/dart-sdk
Future<void> main(List<String> arguments) async {
  final String dartSdk = path.join(
    Directory.current.absolute.path,
    _getDartSdkFromArguments(arguments) ?? path.join(flutterRoot, 'bin', 'cache', 'dart-sdk'),
  );
  dart = path.join(dartSdk, 'bin', Platform.isWindows ? 'dart.exe' : 'dart');
  pub = path.join(dartSdk, 'bin', Platform.isWindows ? 'pub.bat' : 'pub');
  printProgress('STARTING ANALYSIS');
  await run(arguments);
  if (hasError) {
    reportErrorsAndExit('${bold}Analysis failed.$reset');
  }
  reportSuccessAndExit('${bold}Analysis successful.$reset');
}

/// Scans [arguments] for an argument of the form `--dart-sdk` or
/// `--dart-sdk=...` and returns the configured SDK, if any.
String? _getDartSdkFromArguments(List<String> arguments) {
  String? result;
  for (var i = 0; i < arguments.length; i += 1) {
    if (arguments[i] == '--dart-sdk') {
      if (result != null) {
        foundError(<String>['The --dart-sdk argument must not be used more than once.']);
        return null;
      }
      if (i + 1 < arguments.length) {
        result = arguments[i + 1];
      } else {
        foundError(<String>['--dart-sdk must be followed by a path.']);
        return null;
      }
    }
    if (arguments[i].startsWith('--dart-sdk=')) {
      if (result != null) {
        foundError(<String>['The --dart-sdk argument must not be used more than once.']);
        return null;
      }
      result = arguments[i].substring('--dart-sdk='.length);
    }
  }
  return result;
}

void _printHelp(List<Validation> validations) {
  print('Usage: dart dev/bots/analyze.dart [arguments]');
  print('');
  print('Options:');
  print('  -h, --help                  Show this help message.');
  print('  --only=rule1,rule2,...      Run only the specified validations.');
  print('  --skip=rule1,rule2,...      Skip the specified validations.');
  print('');
  print('Available rules:');
  for (final validation in validations) {
    print('  ${validation.name.padRight(25)} ${validation.description}');
  }
}

/// Represents a specific validation step in the analyze script.
@visibleForTesting
class Validation {
  /// Creates a new validation step.
    ),
