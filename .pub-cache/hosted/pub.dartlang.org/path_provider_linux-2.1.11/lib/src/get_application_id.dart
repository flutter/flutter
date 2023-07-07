// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// getApplicationId() is implemented using FFI; export a stub for platforms
// that don't support FFI (e.g., web) to avoid having transitive dependencies
// break web compilation.
export 'get_application_id_stub.dart'
    if (dart.library.ffi) 'get_application_id_real.dart';
