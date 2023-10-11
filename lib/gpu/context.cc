// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/context.h"

#include <future>

#include "dart_api.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "fml/make_copyable.h"
#include "tonic/converter/dart_converter.h"

namespace flutter {

IMPLEMENT_WRAPPERTYPEINFO(gpu, Context);

std::shared_ptr<impeller::Context> Context::default_context_;

void Context::SetOverrideContext(std::shared_ptr<impeller::Context> context) {
  default_context_ = std::move(context);
}

std::shared_ptr<impeller::Context> Context::GetDefaultContext() {
  return default_context_;
}

Context::Context(std::shared_ptr<impeller::Context> context)
    : context_(std::move(context)) {}

Context::~Context() = default;

std::shared_ptr<impeller::Context> Context::GetContext() {
  return context_;
}

}  // namespace flutter

//----------------------------------------------------------------------------
/// Exports
///

Dart_Handle InternalFlutterGpu_Context_InitializeDefault(Dart_Handle wrapper) {
  auto dart_state = flutter::UIDartState::Current();

  std::shared_ptr<impeller::Context> impeller_context =
      flutter::Context::GetDefaultContext();

  if (!impeller_context) {
    if (!dart_state->IsImpellerEnabled()) {
      return tonic::ToDart(
          "Flutter GPU requires the Impeller rendering backend to be enabled.");
    }

    // Grab the Impeller context from the IO manager.
    std::promise<std::shared_ptr<impeller::Context>> context_promise;
    auto impeller_context_future = context_promise.get_future();
    fml::TaskRunner::RunNowOrPostTask(
        dart_state->GetTaskRunners().GetIOTaskRunner(),
        fml::MakeCopyable([promise = std::move(context_promise),
                           io_manager = dart_state->GetIOManager()]() mutable {
          promise.set_value(io_manager ? io_manager->GetImpellerContext()
                                       : nullptr);
        }));
    impeller_context = impeller_context_future.get();
  }

  if (!impeller_context) {
    return tonic::ToDart("Unable to retrieve the Impeller context.");
  }
  auto res = fml::MakeRefCounted<flutter::Context>(impeller_context);
  res->AssociateWithDartWrapper(wrapper);

  return Dart_Null();
}
