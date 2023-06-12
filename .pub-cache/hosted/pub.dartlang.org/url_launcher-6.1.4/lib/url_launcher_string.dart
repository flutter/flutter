// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Provides a String-based alterantive to the Uri-based primary API.
//
// This is provided as a separate import because it's much easier to use
// incorrectly, so should require explicit opt-in (to avoid issues such as
// IDE auto-complete to the more error-prone APIs just by importing the
// main API).

export 'src/types.dart';
export 'src/url_launcher_string.dart';
