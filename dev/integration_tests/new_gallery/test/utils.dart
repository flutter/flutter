// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Replace Windows line endings with Unix line endings
String standardizeLineEndings(String str) => str.replaceAll('\r\n', '\n');
