// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';

extension ParserExtension on ArgParser {
  void addEnumOption<T extends HasHelpText>({
    required String name,
    required String help,
    required T defaultsTo,
    required List<T> values,
  }) {
    addOption(
      name,
      defaultsTo: defaultsTo.cliName,
      help: help,
      allowed: values.map((T e) => e.cliName),
      allowedHelp: Map<String, String>.fromEntries(
        values.map((T e) => MapEntry<String, String>(e.cliName, e.helpText)),
      ),
    );
  }
}

abstract interface class HasHelpText implements Enum {
  String get helpText;
  String get cliName;
}
