// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helpers for parsing Code object name produced by Code::QualifiedName
library vm_snapshot_analysis.name;

// Wrapper around the name of a Code object produced by Code::QualifiedName.
//
// Raw textual representation of the name contains not just the name of itself,
// but also various attributes (whether this code object originates from the
// Dart function or from a stub, whether it is optimized or not, whether
// it corresponds to some synthetic function, etc).
class Name {
  /// Raw textual representation of the name as it occurred in the output
  /// of the AOT compiler.
  final String raw;

  /// Pretty version of the name, with some of the irrelevant information
  /// removed from it.
  ///
  /// Note: we still expect this name to be unique within compilation,
  /// so we are not removing any details that are used for disambiguation.
  /// The only exception are type testing stubs, these refer to type names
  /// and types names are not bound to be unique between compilations.
  late final String scrubbed =
      raw.replaceAll(isStub ? _stubScrubbingRe : _scrubbingRe, '');

  Name(this.raw);

  /// Returns true if this name refers to a stub.
  bool get isStub => raw.startsWith('[Stub] ');

  /// Returns true if this name refers to an allocation stub.
  bool get isAllocationStub => raw.startsWith('[Stub] Allocate ');

  /// Returns true if this name refers to a type testing stub.
  bool get isTypeTestingStub => raw.startsWith('[Stub] Type Test ');

  /// Split this name into individual '.' separated components (e.g. names of
  /// its parent functions).
  List<String> get components {
    // Break the rest of the name into components.
    final result = scrubbed.split('.');

    // Constructor names look like this 'new <ClassName>.<CtorName>' so
    // we need to concatenate the first two components back to form
    // the constructor name.
    if (result.first.startsWith('new ')) {
      result[0] = '${result[0]}${result[1]}';
      result.removeAt(1);
    }

    return result;
  }

  /// Split raw name into individual '.' separated components (e.g. names of
  /// its parent functions).
  List<String> get rawComponents {
    // Break the rest of the name into components.
    final result = raw.split('.');

    // Constructor names look like this 'new <ClassName>.<CtorName>' so
    // we need to concatenate the first two components back to form
    // the constructor name.
    if (result.first.startsWith('new ')) {
      result[0] = '${result[0]}.${result[1]}';
      result.removeAt(1);
    }

    return result;
  }

  static String collapse(String name) =>
      name.replaceAll(_collapseRe, '<anonymous closure>');
}

// Remove useless prefixes and private library suffixes from the raw name.
//
// Note that we want to keep anonymous closure token positions in the name
// still, these names are formatted as '<anonymous closure @\d+>'.
final _scrubbingRe =
    RegExp(r'\[(Optimized|Unoptimized|Stub)\]\s*|@\d+(?![>\d])');

// Remove useless prefixes and private library suffixes from the raw name
// for stubs.
final _stubScrubbingRe = RegExp(r'\[Stub\]\s*|@\d+|\(H[a-f\d]+\) ');

// Remove token positions from anonymous closure names.
final _collapseRe = RegExp(r'<anonymous closure @\d+>');
