// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/tonic/dart_dependency_catcher.h"

#include "flutter/tonic/dart_library_loader.h"

namespace blink {

DartDependencyCatcher::DartDependencyCatcher(DartLibraryLoader& loader)
    : loader_(loader) {
  loader_.set_dependency_catcher(this);
}

DartDependencyCatcher::~DartDependencyCatcher() {
  loader_.set_dependency_catcher(nullptr);
}

void DartDependencyCatcher::AddDependency(DartDependency* dependency) {
  dependencies_.insert(dependency);
}

}  // namespace blink
