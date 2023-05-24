// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/gpu/context.h"

#include <memory>
#include <sstream>

#include "flutter/fml/log_level.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/make_copyable.h"
#include "flutter/fml/memory/ref_ptr.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "third_party/tonic/dart_wrappable.h"

namespace flutter {

IMPLEMENT_WRAPPERTYPEINFO(ui, GpuContext);

std::string GpuContext::InitializeDefault(Dart_Handle wrapper) {
  auto dart_state = UIDartState::Current();
  if (!dart_state->IsImpellerEnabled()) {
    return "The GpuContext API requires the Impeller rendering backend to be "
           "enabled.";
  }

  // Grab the Impeller context from the IO manager.

  std::promise<std::shared_ptr<impeller::Context>> context_promise;
  auto impeller_context_future = context_promise.get_future();
  dart_state->GetTaskRunners().GetIOTaskRunner()->PostTask(
      fml::MakeCopyable([promise = std::move(context_promise),
                         io_manager = dart_state->GetIOManager()]() mutable {
        promise.set_value(io_manager ? io_manager->GetImpellerContext()
                                     : nullptr);
      }));

  auto impeller_context = impeller_context_future.get();
  if (!impeller_context) {
    return "Unable to retrieve the Impeller context.";
  }
  auto res = fml::MakeRefCounted<GpuContext>(impeller_context);
  res->AssociateWithDartWrapper(wrapper);

  return "";
}

GpuContext::GpuContext(std::shared_ptr<impeller::Context> context)
    : context_(std::move(context)) {}

GpuContext::~GpuContext() = default;

}  // namespace flutter
