// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "traceimpl_dependent_scope.h"

namespace blink {

// Template instantiation.
template class Derived<int>;
template class DerivedMissingTrace<int>;

}
