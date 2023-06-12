// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

import 'base.dart';
import 'specs/class.dart';
import 'specs/constructor.dart';
import 'specs/directive.dart';
import 'specs/enum.dart';
import 'specs/expression.dart';
import 'specs/extension.dart';
import 'specs/field.dart';
import 'specs/library.dart';
import 'specs/method.dart';
import 'specs/reference.dart';
import 'specs/type_function.dart';
import 'specs/type_reference.dart';

@optionalTypeArgs
abstract class SpecVisitor<T> {
  const SpecVisitor._();

  T visitAnnotation(Expression spec, [T context]);

  T visitClass(Class spec, [T context]);

  T visitExtension(Extension spec, [T context]);

  T visitEnum(Enum spec, [T context]);

  T visitConstructor(Constructor spec, String clazz, [T context]);

  T visitDirective(Directive spec, [T context]);

  T visitField(Field spec, [T context]);

  T visitLibrary(Library spec, [T context]);

  T visitFunctionType(FunctionType spec, [T context]);

  T visitMethod(Method spec, [T context]);

  T visitReference(Reference spec, [T context]);

  T visitSpec(Spec spec, [T context]);

  T visitType(TypeReference spec, [T context]);

  T visitTypeParameters(Iterable<Reference> specs, [T context]);
}
