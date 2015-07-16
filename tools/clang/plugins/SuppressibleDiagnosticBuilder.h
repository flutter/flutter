// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TOOLS_CLANG_PLUGINS_HESIENDIAGNOSTICBUILDER_H_
#define TOOLS_CLANG_PLUGINS_HESIENDIAGNOSTICBUILDER_H_

#include "clang/Basic/Diagnostic.h"
#include "clang/Basic/SourceLocation.h"

namespace chrome_checker {

// A simple wrapper around DiagnosticBuilder that allows a diagnostic to be
// suppressed. The intended use case is for helper functions that return a
// DiagnosticBuilder, but only want to emit the diagnostic if some conditions
// are met.
class SuppressibleDiagnosticBuilder : public clang::DiagnosticBuilder {
 public:
  SuppressibleDiagnosticBuilder(clang::DiagnosticsEngine* diagnostics,
                                clang::SourceLocation loc,
                                unsigned diagnostic_id,
                                bool suppressed)
      : DiagnosticBuilder(diagnostics->Report(loc, diagnostic_id)),
        diagnostics_(diagnostics),
        suppressed_(suppressed) {}

  ~SuppressibleDiagnosticBuilder() {
    if (suppressed_) {
      // Clear the counts and underlying data, so the base class destructor
      // doesn't try to emit the diagnostic.
      FlushCounts();
      Clear();
      // Also clear the current diagnostic being processed by the
      // DiagnosticsEngine, since it won't be emitted.
      diagnostics_->Clear();
    }
  }

  template <typename T>
  friend const SuppressibleDiagnosticBuilder& operator<<(
      const SuppressibleDiagnosticBuilder& builder,
      const T& value) {
    const DiagnosticBuilder& base_builder = builder;
    base_builder << value;
    return builder;
  }

 private:
  clang::DiagnosticsEngine* const diagnostics_;
  const bool suppressed_;
};

}  // namespace chrome_checker

#endif  // TOOLS_CLANG_PLUGINS_HESIENDIAGNOSTICBUILDER_H_
