// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Provides metadata about mixins to dart-protoc-plugin.
/// (Experimental API; subject to change.)
import 'indenting_writer.dart';

/// Finds [name] in the exported mixins.
PbMixin? findMixin(String name) {
  const _exportedMixins = {
    'PbMapMixin': _pbMapMixin,
    'PbEventMixin': _pbEventMixin,
  };
  return _exportedMixins[name];
}

/// PbMixin contains metadata needed by dart-protoc-plugin to apply a mixin.
///
/// The mixin can be applied to a message using options in dart_options.proto.
/// Only one mixin can be applied to each message, but that mixin can depend
/// on another mixin, recursively, similar to single inheritance.
class PbMixin {
  /// The name of the mixin class to import into the .pb.dart file.
  final String name;

  /// The file that the .pb.dart file should import the symbol from.
  final String importFrom;

  /// Another mixin to apply ahead of this one, or null for none.
  final PbMixin? parent;

  /// Names that shouldn't be used by properties in the generated child class.
  /// May be null if the mixin doesn't reserve any new names.
  final List<String>? reservedNames;

  /// Code to inject into the class using the mixin.
  ///
  /// Typically used for static helpers since you cannot mix in static members.
  final List<String>? injectedHelpers;

  /// If `True` the mixin should have static methods for converting to and from
  /// proto3 Json.
  final bool hasProto3JsonHelpers;

  const PbMixin(
    this.name, {
    required this.importFrom,
    this.parent,
    this.reservedNames,
    this.injectedHelpers,
    this.hasProto3JsonHelpers = false,
  });

  /// Returns the mixin and its ancestors, in the order they should be applied.
  Iterable<PbMixin> findMixinsToApply() {
    var result = [this];
    for (var p = parent; p != null; p = p.parent) {
      result.add(p);
    }
    return result.reversed;
  }

  /// Returns all the reserved names, including from ancestor mixins.
  Iterable<String> findReservedNames() {
    var names = <String>{};
    for (PbMixin? m = this; m != null; m = m.parent) {
      names.add(m.name);
      if (m.reservedNames != null) {
        names.addAll(m.reservedNames!);
      }
    }
    return names;
  }

  void injectHelpers(IndentingWriter out) {
    if (injectedHelpers != null && injectedHelpers!.isNotEmpty) {
      out.println(injectedHelpers!.join('\n'));
    }
  }
}

const _pbMapMixin = PbMixin('PbMapMixin',
    importFrom: 'package:protobuf/src/protobuf/mixins/map_mixin.dart',
    parent: _mapMixin);

const _pbEventMixin = PbMixin('PbEventMixin',
    importFrom: 'package:protobuf/src/protobuf/mixins/event_mixin.dart',
    reservedNames: ['changes', 'deliverChanges']);

const List<String> _reservedNamesForMap = [
  '[]',
  '[]=',
  'addAll',
  'addEntries',
  'cast',
  'containsKey',
  'containsValue',
  'entries',
  'forEach',
  'isEmpty',
  'isNotEmpty',
  'keys',
  'length',
  'map',
  'putIfAbsent',
  'remove',
  'removeWhere',
  'retype',
  'update',
  'updateAll',
  'values',
];

const _mapMixin = PbMixin('MapMixin',
    importFrom: 'dart:collection', reservedNames: _reservedNamesForMap);
