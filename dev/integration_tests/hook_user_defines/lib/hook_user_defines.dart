// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi' as ffi;

@ffi.Native<ffi.IntPtr Function(ffi.IntPtr, ffi.IntPtr)>()
external int sum(int a, int b);
