// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

final RegExp _clangRegexp = RegExp(r'("command"\s*:\s*").*(\s(?:\S*/)?clang(\+\+)?)(?=[\s"])');

/// Strips compiler wrapper prefixes from compiler commands in [contents].
///
/// Our build toolchain invokes certain `clang` commands from wrappers (such as
/// rewrapper and ccache) for use with RBE. This can confuse C and C++ language
/// servers like `clangd` when indexing source files.
///
/// See: https://github.com/flutter/flutter/issues/147767
String stripCompilerWrappers(String contents) {
  return contents.replaceAllMapped(_clangRegexp, (Match match) {
    return '${match[1]}${match[2]!.trim()}';
  });
}
