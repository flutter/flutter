// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A flag indicating whether code that opts back to before 2.12 (null safety)
/// is unsupported. That is, when the flag is `true` all code is analyzed
/// assuming that null-safety is required, and when the flag is `false` all code
/// is analyzed assuming that null-safety is optional.
///
/// This flag is only writable in order to allow us to continue to test the
/// pre-3.0 behavior while developing 3.0.
///
/// This flag will be removed in Dart 3.0 (with an implied value of `true`), so
/// it should not be used outside the analyzer package.
bool noSoundNullSafety = true;
