library reflect;

import 'dart:mirrors';
import 'dart:collection';

HashMap<ClassMirror, List> _fieldCache = new HashMap<ClassMirror, List>();

List<Symbol> _getPublicFields(ClassMirror mirror) {
  var fields = _fieldCache[mirror];
  if (fields == null) {
    fields = new List<Symbol>();
    _fieldCache[mirror] = fields;

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
  }

  return fields;
}

void copyPublicFields(Object source, Object target) {
  assert(source.runtimeType == target.runtimeType);

  var sourceMirror = reflect(source);
  var targetMirror = reflect(target);
  for (var symbol in _getPublicFields(sourceMirror.type)) {
    targetMirror.setField(symbol, sourceMirror.getField(symbol).reflectee);
  }
}
