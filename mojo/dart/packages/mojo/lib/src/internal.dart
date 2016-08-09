// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library mojo_internal;

// Import 'internal_contract.dart' by default, but use 'dart:mojo.internal' if
// the embedder supports it.
export 'internal_contract.dart'
  if (dart.library.mojo.internal) 'dart:mojo.internal';
