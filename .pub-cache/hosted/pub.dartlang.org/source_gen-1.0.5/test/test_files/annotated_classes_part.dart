// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of source_gen.test.annotation_test.classes;

const localUntypedAnnotationInPart = PublicAnnotationClass();

const PublicAnnotationClass localTypedAnnotationInPart =
    PublicAnnotationClass();

@PublicAnnotationClass()
class CtorNoParamsInPart {}

@PublicAnnotationClassInPart()
class CtorNoParamsFromPartInPart {}
