// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The default set implementation is based on a Uint32List+List where both are
// linear in the number of entries. That means we consume on 64-bit VMs at
// least 12 bytes per entry.
//
// We should consider making a more memory efficient hash set implementation
// that uses Int32List and utilizing the fact that we never store negative
// numbers in it.
typedef IntSet = Set<int>;
