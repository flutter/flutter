// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_V8_INSPECTOR_INSPECTOR_BACKEND_MOJO_H_
#define SKY_ENGINE_V8_INSPECTOR_INSPECTOR_BACKEND_MOJO_H_

#include "base/basictypes.h"
#include "base/memory/scoped_ptr.h"
#include "sky/services/inspector/inspector.mojom.h"

// The impl still uses namespace blink for convenience.
namespace blink {
class InspectorBackendMojoImpl;
}

namespace inspector {
class InspectorHost;

class InspectorBackendMojo {
 public:
  explicit InspectorBackendMojo(InspectorHost*);
  ~InspectorBackendMojo();

  void Connect();

 private:
  scoped_ptr<blink::InspectorBackendMojoImpl> impl_;

  DISALLOW_COPY_AND_ASSIGN(InspectorBackendMojo);
};

}  // namespace inspector

#endif  // SKY_ENGINE_V8_INSPECTOR_INSPECTOR_BACKEND_MOJO_H_