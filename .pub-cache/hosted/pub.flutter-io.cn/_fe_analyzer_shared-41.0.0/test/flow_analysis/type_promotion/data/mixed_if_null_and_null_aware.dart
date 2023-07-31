// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that we don't crash when trying to analyze an expression
// that combines if-null with null-aware access.

f(int? i, List? l) => i ?? l?.length;
