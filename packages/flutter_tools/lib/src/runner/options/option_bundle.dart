// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';

import '../flutter_command.dart';

/// An aggregation of related [OptionDescriptor] instances that can be
/// registered and bound to a [FlutterCommand] as a cohesive domain unit.
abstract class OptionBundle {
  const OptionBundle();

  /// The list of option descriptors contained within this bundle.
  List<OptionDescriptor<dynamic>> get descriptors;

  /// Optional lifecycle hook invoked when this bundle is registered on [command].
  void onRegister(FlutterCommand command) {}

  /// Registers all option descriptors in this bundle into [parser] and binds
  /// to [command].
  void register(
    FlutterCommand command,
    ArgParser parser,
    Map<String, OptionDescriptor<dynamic>> registry,
  ) {
    onRegister(command);
    for (final OptionDescriptor<dynamic> descriptor in descriptors) {
      descriptor.addTo(parser, registry: registry);
    }
  }
}
