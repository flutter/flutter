// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';

import 'context.dart';

/// command-line flags and options that were specified during the invocation of
/// the Flutter tool.
Flags get flags => context[Flags];

/// Encapsulation of the command-line flags and options that were specified
/// during the invocation of the Flutter tool.
///
/// An instance of this class is set into the [AppContext] upon invocation of
/// the Flutter tool (immediately after the arguments have been parsed in
/// [FlutterCommandRunner]) and is available via the [flags] global property.
class Flags {
  Flags(this._globalResults)
    : assert(_globalResults != null);

  final ArgResults _globalResults;

  /// Gets the value of the specified command-line flag/option that was set
  /// during the invocation of the Flutter tool.
  ///
  /// This will first search for flags that are specific to the command and will
  /// fall back to global flags.
  ///
  /// If a flag has a default value and the user did not explicitly specify a
  /// value on the command-line, this will return the default value.
  ///
  /// If the specified flag is not defined or was not specified and had no
  /// default, then this will return `null`.
  dynamic operator [](String key) {
    final ArgResults commandResults = _globalResults.command;
    final Iterable<String> options = commandResults?.options;
    if (options != null && options.contains(key))
      return commandResults[key];
    else if (_globalResults.options.contains(key))
      return _globalResults[key];
    return null;
  }

  /// `true` iff the given flag/option was either explicitly specified by the
  /// user at the command-line or it was defined to have a default value.
  bool contains(String key) {
    final ArgResults commandResults = _globalResults.command;
    final Iterable<String> options = commandResults?.options;
    return (options != null && options.contains(key)) || _globalResults.options.contains(key);
  }
}

class EmptyFlags implements Flags {
  const EmptyFlags();

  @override
  ArgResults get _globalResults => null;

  @override
  String operator [](String key) => null;

  @override
  bool contains(String key) => false;
}
