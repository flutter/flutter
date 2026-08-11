// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../flutter_command.dart';

/// Type-safe argument extraction extension for [FlutterCommand].
extension SafeArgResults on FlutterCommand {
  /// Returns the parsed value for [descriptor], falling back to its default value.
  T? getValue<T>(OptionDescriptor<T> descriptor) =>
      descriptor.getValue(argResults, globalResults: globalResults);

  /// Returns whether [descriptor] was explicitly provided on the command line.
  bool wasParsed(OptionDescriptor<dynamic> descriptor) =>
      descriptor.wasParsed(argResults, globalResults: globalResults);

  /// Returns the explicitly provided value for [descriptor], or `null` if omitted.
  T? getParsedValue<T>(OptionDescriptor<T> descriptor) =>
      descriptor.getParsedValue(argResults, globalResults: globalResults);
}
