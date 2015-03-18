// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:mirrors';
import 'dart:collection';

final HashMap<ClassMirror, List> _fieldCache = new HashMap<ClassMirror, List>();

List<Symbol> _getPublicFields(ClassMirror mirror) {
  return _fieldCache.putIfAbsent(mirror, () {
    List<Symbol> fields = new List<Symbol>();

    while (mirror != null) {
      var decls = mirror.declarations;
      fields.addAll(decls.keys.where((symbol) {
        var mirror = decls[symbol];
        if (mirror is! VariableMirror) {
          return false;
        }

        var vMirror = mirror as VariableMirror;
        return !vMirror.isPrivate && !vMirror.isStatic && !vMirror.isFinal;
      }));

      mirror = mirror.superclass;
    }

    return fields;
  });
}

void copyPublicFields(Object source, Object target) {
  assert(source.runtimeType == target.runtimeType);

  var sourceMirror = reflect(source);
  var targetMirror = reflect(target);
  for (var symbol in _getPublicFields(sourceMirror.type)) {
    targetMirror.setField(symbol, sourceMirror.getField(symbol).reflectee);
  }
}
