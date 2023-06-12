// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/

/*class: GenericInterface:GenericInterface<T>,Object*/
abstract class GenericInterface<T> {}

/*class: GenericSubInterface:GenericInterface<T>,GenericSubInterface<T>,Object*/
abstract class GenericSubInterface<T> extends GenericInterface<T> {}

/*class: Class1:Class1,Object*/
class Class1 {}

/*class: Class2:Class2<T>,Object*/
class Class2<T> {}

/*class: Class3:Class3<T>,GenericInterface<T>,Object*/
class Class3<T> implements GenericInterface<T> {}

/*class: Class4a:Class4a,GenericInterface<num>,Object*/
class Class4a implements GenericInterface<num> {}

/*class: Class4b:Class4b,GenericInterface<num?>,Object*/
class Class4b implements GenericInterface<num?> {}

/*class: Class5:Class5,GenericInterface<dynamic>,Object*/
class Class5 implements GenericInterface<dynamic> {}
