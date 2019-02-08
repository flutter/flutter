// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The largest SMI value.
///
/// See <https://www.dartlang.org/articles/numeric-computation/#smis-and-mints>
///
/// When compiled to JavaScript, this value is intead the largest 32bit int.
const int kMaxUnsignedSMI = 0x3FFFFFFFFFFFFFFF;
