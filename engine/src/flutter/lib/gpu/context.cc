// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/context.h"

#include <future>

#include "flutter/lib/gpu/formats.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "fml/make_copyable.h"
#include "impeller/core/platform.h"
#include "impeller/renderer/context.h"
#include "tonic/converter/dart_converter.h"

namespace flutter {
namespace gpu {

bool SupportsNormalOffscreenMSAA(const impeller::Context& context) {
  auto& capabilities = context.GetCapabilities();
  return capabilities->SupportsOffscreenMSAA() &&
         !capabilities->SupportsImplicitResolvingMSAA();
}

IMPLEMENT_WRAPPERTYPEINFO(flutter_gpu, Context);

std::shared_ptr<impeller::Context> Context::default_context_;

void Context::SetOverrideContext(std::shared_ptr<impeller::Context> context) {
  default_context_ = std::move(context);
}

std::shared_ptr<impeller::Context> Context::GetOverrideContext() {
  return default_context_;
}

std::shared_ptr<impeller::Context> Context::GetDefaultContext(
    std::optional<std::string>& out_error) {
  auto override_context = GetOverrideContext();
  if (override_context) {
    return override_context;
  }

  out_error = "Flutter GPU not currently available.";
  return nullptr;
}

Context::Context(std::shared_ptr<impeller::Context> context)
    : context_(std::move(context)) {}

Context::~Context() = default;

std::shared_ptr<impeller::Context> Context::GetContext() {
  return context_;
}

}  // namespace gpu
}  // namespace flutter

//----------------------------------------------------------------------------
/// Exports
///

Dart_Handle InternalFlutterGpu_Context_InitializeDefault(Dart_Handle wrapper) {
  std::optional<std::string> out_error;
  auto impeller_context = flutter::gpu::Context::GetDefaultContext(out_error);
  if (out_error.has_value()) {
    return tonic::ToDart(out_error.value());
  }

  auto res = fml::MakeRefCounted<flutter::gpu::Context>(impeller_context);
  res->AssociateWithDartWrapper(wrapper);

  return Dart_Null();
}

extern int InternalFlutterGpu_Context_GetDefaultColorFormat(
    flutter::gpu::Context* wrapper) {
  return static_cast<int>(flutter::gpu::FromImpellerPixelFormat(
      wrapper->GetContext()->GetCapabilities()->GetDefaultColorFormat()));
}

extern int InternalFlutterGpu_Context_GetDefaultStencilFormat(
    flutter::gpu::Context* wrapper) {
  return static_cast<int>(flutter::gpu::FromImpellerPixelFormat(
      wrapper->GetContext()->GetCapabilities()->GetDefaultStencilFormat()));
}

extern int InternalFlutterGpu_Context_GetDefaultDepthStencilFormat(
    flutter::gpu::Context* wrapper) {
  return static_cast<int>(flutter::gpu::FromImpellerPixelFormat(
      wrapper->GetContext()
          ->GetCapabilities()
          ->GetDefaultDepthStencilFormat()));
}

extern int InternalFlutterGpu_Context_GetMinimumUniformByteAlignment(
    flutter::gpu::Context* wrapper) {
  return impeller::DefaultUniformAlignment();
}

extern bool InternalFlutterGpu_Context_GetSupportsOffscreenMSAA(
    flutter::gpu::Context* wrapper) {
  return flutter::gpu::SupportsNormalOffscreenMSAA(*wrapper->GetContext());
}
