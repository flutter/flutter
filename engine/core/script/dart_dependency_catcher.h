// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_SCRIPT_DEPENDENCY_CATCHER_H_
#define SKY_ENGINE_CORE_SCRIPT_DEPENDENCY_CATCHER_H_

#include "base/macros.h"
#include "sky/engine/wtf/HashSet.h"

namespace blink {
class DartLoader;

// A base class to represent a dependency.
class DartDependency {
};

// To catch the dependencies for a library, put a DartDependencyCatcher on the
// stack during the call to Dart_LoadLibrary.
class DartDependencyCatcher {
 public:
  explicit DartDependencyCatcher(DartLoader& loader);
  ~DartDependencyCatcher();

  void AddDependency(DartDependency* dependency);
  const HashSet<DartDependency*>& dependencies() const { return dependencies_; }

 private:
  DartLoader& loader_;
  HashSet<DartDependency*> dependencies_;

  DISALLOW_COPY_AND_ASSIGN(DartDependencyCatcher);
};

}  // namespace blink

#endif  // SKY_ENGINE_CORE_SCRIPT_DEPENDENCY_CATCHER_H_
