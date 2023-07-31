// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C<T extends num?> {
  void promotes(T t) {
    if (t is int) {
      /*T & int*/ t;
    }
  }

  void promoteNullable(T? t) {
    T? s;
    if (t is int) {
      s = /*cfe.T? & int*/ /*analyzer.T & int*/ t;
    }
  }

  void doesNotPromote(T t) {
    if (t is String) {
      t;
    }
  }

  void nonNull(T t) {
    if (t != null) {
      /*T & num*/ t;
    }
  }
}

class D<T extends dynamic> {
  void nonNull(T t) {
    if (t != null) {
      // Does not promote because the bound (`dynamic`) has no
      // non-nullable counterpart
      t;
    }
  }
}

class E<T> {
  void nonNull(T t) {
    if (t != null) {
      /*T & Object*/ t;
    }
  }
}

class F<S, T extends S> {
  void nonNull(T t) {
    if (t != null) {
      /*T & S & Object*/ t;
    }
  }
}
