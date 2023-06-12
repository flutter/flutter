// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: prefer_initializing_formals
import 'dart:collection' as collection;

part 'annotation_part.dart';

const untypedAnnotation = PublicAnnotationClass();

const untypedAnnotationWithNonDefaultCtor =
    PublicAnnotationClass.withPositionalArgs(5, 'field', boolArg: true);

const PublicAnnotationClass typedAnnotation = PublicAnnotationClass();

class PublicAnnotationClass {
  final int anInt;
  final String aString;
  final List aList;
  final bool aBool;
  final PublicAnnotationClass? child1;
  final PublicAnnotationClass? child2;

  const PublicAnnotationClass()
      : anInt = 0,
        aString = 'str',
        aList = const [1, 2, 3],
        aBool = false,
        child1 = null,
        child2 = null;

  const PublicAnnotationClass.withAnIntAsOne()
      : anInt = 1,
        aString = 'str',
        aList = const [1, 2, 3],
        aBool = false,
        child1 = null,
        child2 = null;

  const PublicAnnotationClass.withPositionalArgs(int intArg, this.aString,
      {bool boolArg = false, List listArg = const [2, 3, 4]})
      : anInt = intArg,
        aList = listArg,
        aBool = boolArg,
        child1 = null,
        child2 = null;

  const PublicAnnotationClass.withKids()
      : anInt = 0,
        aList = const [1, 2, 3],
        aBool = false,
        aString = 'withKids',
        child1 = const PublicAnnotationClass(),
        child2 = const PublicAnnotationClass.withAnIntAsOne();
}

class OtherPublicAnnotationClass {
  const OtherPublicAnnotationClass();
}

const objectAnnotation = {
  'int': 1,
  'bool': true,
  'list': [1, 2, 3],
  'symbol': #foo,
  'double': 3.14,
  'null': null,
  'String': 'a string',
  'core type': bool,
  'imported sdk type': collection.Queue,
  'non-core type': OtherPublicAnnotationClass
};
