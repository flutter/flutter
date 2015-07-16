// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/environment/logging.h"

#include "mojo/public/cpp/environment/environment.h"

namespace mojo {
namespace internal {

namespace {

// Gets a pointer to the filename portion of |s|. Assumes that the filename
// follows the last slash or backslash in |s|, or is |s| if no slash or
// backslash is present.
//
// E.g., a pointer to "foo.cc" is returned for the following inputs: "foo.cc",
// "./foo.cc", ".\foo.cc", "/absolute/path/to/foo.cc",
// "relative/path/to/foo.cc", "C:\absolute\path\to\foo.cc", etc.
const char* GetFilename(const char* s) {
  const char* rv = s;
  while (*s) {
    if (*s == '/' || *s == '\\')
      rv = s + 1;
    s++;
  }
  return rv;
}

}  // namespace

// TODO(vtl): Maybe we should preserve the full path and strip it out at a
// different level instead?
LogMessage::LogMessage(MojoLogLevel log_level, const char* file, int line)
    : log_level_(log_level), file_(GetFilename(file)), line_(line) {
}

LogMessage::~LogMessage() {
  Environment::GetDefaultLogger()->LogMessage(
      log_level_, file_, static_cast<uint32_t>(line_), stream_.str().c_str());
}

}  // namespace internal
}  // namespace mojo
