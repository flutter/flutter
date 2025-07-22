// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The native JavaScript Object prototype is sealed before loading the Dart
// program to guard against prototype pollution.
delete Object.prototype.__proto__;
Object.seal(Object.prototype);
