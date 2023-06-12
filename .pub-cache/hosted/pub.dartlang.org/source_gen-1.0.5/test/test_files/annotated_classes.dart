// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source_gen.test.annotation_test.classes;

import 'package:_test_annotations/test_annotations.dart';

import 'annotations.dart';

part 'annotated_classes_part.dart';

const localUntypedAnnotation = PublicAnnotationClass();

const PublicAnnotationClass localTypedAnnotation = PublicAnnotationClass();

@PublicAnnotationClass()
class CtorNoParams {}

@OtherPublicAnnotationClass()
class OtherClassCtorNoParams {}

@PublicAnnotationClassInPart()
class CtorNoParamsFromPart {}

@PublicAnnotationClass.withAnIntAsOne()
class NonDefaultCtorNoParams {}

@PublicAnnotationClass.withPositionalArgs(42, 'custom value')
class NonDefaultCtorWithPositionalParams {}

@PublicAnnotationClass.withPositionalArgs(43, 'another value',
    boolArg: true, listArg: [5, 6, 7])
class NonDefaultCtorWithPositionalAndNamedParams {}

@PublicAnnotationClass.withKids()
class WithNestedObjects {}

@objectAnnotation
class WithConstMapLiteral {}

@TestAnnotation()
class AnnotatedThroughPackage {}

@localTypedAnnotation
class WithLocalTypedField {}

@localUntypedAnnotation
class WithLocalUntypedField {}

@typedAnnotation
class WithTypedField {}

@untypedAnnotation
class WithUntypedField {}

@untypedAnnotationWithNonDefaultCtor
class WithAFieldFromNonDefaultCtor {}
