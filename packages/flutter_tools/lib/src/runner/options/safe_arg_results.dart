// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../flutter_command.dart';

/// Type-safe argument extraction extension for [FlutterCommand].
extension SafeArgResults on FlutterCommand {
  /// Returns the resolved value for [descriptor], falling back to its default value.
  T getValue<T>(OptionDescriptor<T> descriptor) =>
      descriptor.getValue(argResults, globalResults: globalResults);

  /// Returns whether [descriptor] was explicitly provided on the command line.
  bool wasProvided(OptionDescriptor<Object?> descriptor) =>
      descriptor.wasProvided(argResults, globalResults: globalResults);

  /// Checks if this option was explicitly parsed (alias for [wasProvided]).
  bool wasParsed(OptionDescriptor<Object?> descriptor) =>
      descriptor.wasProvided(argResults, globalResults: globalResults);

  /// Returns whether [descriptor] is registered on this command (or globally).
  bool hasOption(OptionDescriptor<Object?> descriptor) =>
      descriptor.isRegistered(argResults, globalResults: globalResults);
}
