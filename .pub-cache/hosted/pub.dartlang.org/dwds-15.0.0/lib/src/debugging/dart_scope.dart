// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import '../utilities/objects.dart';
import 'debugger.dart';

// TODO(sdk/issues/44262) - use an alternative way to identify synthetic
// variables.
final ddcTemporaryVariableRegExp = RegExp(r'^(t[0-9]+\$?[0-9]*|__t[\$\w*]+)$');

/// Find the visible Dart properties from a JS Scope Chain, coming from the
/// scopeChain attribute of a Chrome CallFrame corresponding to [frame].
///
/// See chromedevtools.github.io/devtools-protocol/tot/Debugger#type-CallFrame.
Future<List<Property>> visibleProperties({
  Debugger debugger,
  WipCallFrame frame,
}) async {
  final allProperties = <Property>[];

  if (frame.thisObject != null && frame.thisObject.type != 'undefined') {
    allProperties.add(
      Property({
        'name': 'this',
        'value': frame.thisObject,
      }),
    );
  }

  // TODO: Try and populate all the property info for the scopes in one backend
  // call. Along with some other optimizations (caching classRef lookups), we'd
  // end up averaging one backend call per frame.

  // Iterate to least specific scope last to help preserve order in the local
  // variables view when stepping.
  for (var scope in filterScopes(frame).reversed) {
    final properties = await debugger.getProperties(scope.object.objectId);
    allProperties.addAll(properties);
  }

  if (frame.returnValue != null && frame.returnValue.type != 'undefined') {
    allProperties.add(
      Property({
        'name': 'return',
        'value': frame.returnValue,
      }),
    );
  }

  allProperties.removeWhere((property) {
    final value = property.value;

    // TODO(#786) Handle these correctly rather than just suppressing them.
    // We should never see a raw JS class. The only case where this happens is a
    // Dart generic function, where the type arguments get passed in as
    // parameters. Hide those.
    return (value.type == 'function' &&
            value.description.startsWith('class ')) ||
        (ddcTemporaryVariableRegExp.hasMatch(property.name)) ||
        (value.type == 'object' && value.description == 'dart.LegacyType.new');
  });

  return allProperties;
}

/// Filters the provided frame scopes to those that are pertinent for Dart
/// debugging.
List<WipScope> filterScopes(WipCallFrame frame) {
  final scopes = frame.getScopeChain().toList();
  // Remove outer scopes up to and including the Dart SDK.
  while (
      scopes.isNotEmpty && !(scopes.last.name?.startsWith('load__') ?? false)) {
    scopes.removeLast();
  }
  if (scopes.isNotEmpty) scopes.removeLast();
  return scopes;
}
