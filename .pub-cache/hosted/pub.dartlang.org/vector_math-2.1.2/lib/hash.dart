// Copyright (c) 2016, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

@Deprecated('Use Object.hashAll instead')
library hash;

///
/// Generates a hash code for multiple [objects].
///
@Deprecated('Use Object.hashAll instead')
int hashObjects(Iterable<Object> objects) => Object.hashAll(objects);
