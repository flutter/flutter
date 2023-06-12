// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

export 'types/interface.dart'
    if (dart.library.html) 'types/html.dart'
    if (dart.library.io) 'types/io.dart';
