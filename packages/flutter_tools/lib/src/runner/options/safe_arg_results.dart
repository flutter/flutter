// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../flutter_command.dart';

/// Type-safe argument extraction extension for [FlutterCommand].
extension SafeArgResults on FlutterCommand {
  /// Returns the resolved boolean value for [descriptor], falling back to its default.
  bool getFlag(FlagOptionDescriptor descriptor) =>
      descriptor.getValue(argResults, globalResults: globalResults);

  /// Returns the resolved string value for [descriptor], or `null` if optional and omitted.
  String? getString(StringOptionDescriptor descriptor) =>
      descriptor.getValue(argResults, globalResults: globalResults);

  /// Returns the resolved string value for [descriptor], falling back to [fallback] if omitted.
  String getStringOrDefault(StringOptionDescriptor descriptor, [String fallback = '']) =>
      descriptor.getValueOrDefault(argResults, globalResults: globalResults, fallback: fallback);

  /// Returns the resolved list of strings for [descriptor], falling back to an empty list.
  List<String> getStrings(MultiOptionDescriptor descriptor) =>
      descriptor.getValue(argResults, globalResults: globalResults);

  /// Returns whether [descriptor] was explicitly provided on the command line.
  bool wasParsed(OptionDescriptor<dynamic> descriptor) =>
      descriptor.wasParsed(argResults, globalResults: globalResults);

  /// Returns the explicitly provided value for [descriptor], or `null` if omitted (tri-state).
  T? getParsedValue<T>(OptionDescriptor<T> descriptor) =>
      descriptor.getParsedValue(argResults, globalResults: globalResults);

  /// Returns the explicitly provided boolean value for [descriptor], or `null` if omitted (tri-state).
  bool? getParsedFlag(FlagOptionDescriptor descriptor) =>
      descriptor.getParsedValue(argResults, globalResults: globalResults);

  /// Generic fallback accessor.
  T? getValue<T>(OptionDescriptor<T> descriptor) =>
      descriptor.getValue(argResults, globalResults: globalResults);
}
