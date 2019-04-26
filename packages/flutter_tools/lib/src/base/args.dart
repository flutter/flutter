// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';

/// A typed wrapper for the flutter command [ArgResults].
class TypedArgResults {
  TypedArgResults(this._argResults);

  final ArgResults _argResults;

  /// Returns the value of the command line flag `name`.
  bool getFlag(String name) => _argResults[name] as bool;

  /// Returns the value of the command line option `name`.
  String getOption(String name) => _argResults[name] as String;

  /// Returns the list of values of the command line multi-option `name`.
  List<String> getMultiOption(String name) => _argResults[name] as List<String>;

  /// Whether the argument parser saw `name` in the command arguments.
  bool wasParsed(String name) => _argResults.wasParsed(name);

  /// The remaining command-line arguments that were not parsed as options or
  /// flags.
  ///
  /// If `--` was used to separate the options from the remaining arguments,
  /// it will not be included in this list unless parsing stopped before the
  /// `--` was reached.
  List<String> get rest => _argResults.rest;

  /// The original list of arguments that were parsed.
  List<String> get arguments => _argResults.arguments;
}
