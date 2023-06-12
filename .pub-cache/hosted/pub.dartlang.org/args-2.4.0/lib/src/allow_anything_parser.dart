// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'arg_parser.dart';
import 'arg_results.dart';
import 'option.dart';
import 'parser.dart';

/// An ArgParser that treats *all input* as non-option arguments.
class AllowAnythingParser implements ArgParser {
  @override
  Map<String, Option> get options => const {};
  @override
  Map<String, ArgParser> get commands => const {};
  @override
  bool get allowTrailingOptions => false;
  @override
  bool get allowsAnything => true;
  @override
  int? get usageLineLength => null;

  @override
  ArgParser addCommand(String name, [ArgParser? parser]) {
    throw UnsupportedError(
        "ArgParser.allowAnything().addCommands() isn't supported.");
  }

  @override
  void addFlag(String name,
      {String? abbr,
      String? help,
      bool? defaultsTo = false,
      bool negatable = true,
      void Function(bool)? callback,
      bool hide = false,
      List<String> aliases = const []}) {
    throw UnsupportedError(
        "ArgParser.allowAnything().addFlag() isn't supported.");
  }

  @override
  void addOption(String name,
      {String? abbr,
      String? help,
      String? valueHelp,
      Iterable<String>? allowed,
      Map<String, String>? allowedHelp,
      String? defaultsTo,
      void Function(String?)? callback,
      bool allowMultiple = false,
      bool? splitCommas,
      bool mandatory = false,
      bool hide = false,
      List<String> aliases = const []}) {
    throw UnsupportedError(
        "ArgParser.allowAnything().addOption() isn't supported.");
  }

  @override
  void addMultiOption(String name,
      {String? abbr,
      String? help,
      String? valueHelp,
      Iterable<String>? allowed,
      Map<String, String>? allowedHelp,
      Iterable<String>? defaultsTo,
      void Function(List<String>)? callback,
      bool splitCommas = true,
      bool hide = false,
      List<String> aliases = const []}) {
    throw UnsupportedError(
        "ArgParser.allowAnything().addMultiOption() isn't supported.");
  }

  @override
  void addSeparator(String text) {
    throw UnsupportedError(
        "ArgParser.allowAnything().addSeparator() isn't supported.");
  }

  @override
  ArgResults parse(Iterable<String> args) =>
      Parser(null, this, Queue.of(args)).parse();

  @override
  String get usage => '';

  @override
  dynamic defaultFor(String option) {
    throw ArgumentError('No option named $option');
  }

  @override
  dynamic getDefault(String option) {
    throw ArgumentError('No option named $option');
  }

  @override
  Option? findByAbbreviation(String abbr) => null;

  @override
  Option? findByNameOrAlias(String name) => null;
}
