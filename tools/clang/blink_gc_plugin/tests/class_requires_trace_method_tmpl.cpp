// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "class_requires_trace_method_tmpl.h"

namespace blink {

// Does not need a trace method.
class NoTrace : public TemplatedObject<PartObjectA> { };

// Needs a trace method.
class NeedsTrace : public TemplatedObject<PartObjectB> { };

}
