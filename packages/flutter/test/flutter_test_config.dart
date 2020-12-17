// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

export '_goldens_io.dart'
  if (dart.library.html) '_goldens_web.dart' show testExecutable;
