// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'link_hook_bindings_generated.dart' as bindings;

/// A very short-lived native function.
int difference(int a, int b) => bindings.difference(a, b);
