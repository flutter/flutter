// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void eqNullExit_body(int? x) {
  try {
    if (x == null) return;
    /*nonNullable*/ x;
  } finally {
    x;
  }
  /*nonNullable*/ x;
}

void eqNullExit_finally(int? x) {
  try {
    x;
  } finally {
    if (x == null) return;
    /*nonNullable*/ x;
  }
  /*nonNullable*/ x;
}

void outerEqNotNullExit_assignUnknown_body(int? a, int? b) {
  if (a != null) return;
  try {
    a;
    a = b;
    a;
  } finally {
    a;
  }
  a;
}

void outerEqNullExit_assignUnknown_body(int? a, int? b) {
  if (a == null) return;
  try {
    /*nonNullable*/ a;
    a = b;
    a;
  } finally {
    a;
  }
  a;
}

void outerEqNullExit_assignUnknown_finally(int? a, int? b) {
  if (a == null) return;
  try {
    /*nonNullable*/ a;
  } finally {
    /*nonNullable*/ a;
    a = b;
    a;
  }
  a;
}
