// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/metal/shader_library_mtl.h"

#include "flutter/fml/closure.h"
#include "impeller/base/validation.h"
#include "impeller/renderer/backend/metal/shader_function_mtl.h"

namespace impeller {

ShaderLibraryMTL::ShaderLibraryMTL(NSArray<id<MTLLibrary>>* libraries)
    : libraries_([libraries mutableCopy]) {
  if (libraries_ == nil || libraries_.count == 0) {
    return;
  }

  is_valid_ = true;
}

ShaderLibraryMTL::~ShaderLibraryMTL() = default;

bool ShaderLibraryMTL::IsValid() const {
  return is_valid_;
}

static MTLFunctionType ToMTLFunctionType(ShaderStage stage) {
  switch (stage) {
    case ShaderStage::kVertex:
      return MTLFunctionTypeVertex;
    case ShaderStage::kFragment:
      return MTLFunctionTypeFragment;
    case ShaderStage::kUnknown:
    case ShaderStage::kTessellationControl:
    case ShaderStage::kTessellationEvaluation:
    case ShaderStage::kCompute:
      return MTLFunctionTypeKernel;
  }
  FML_UNREACHABLE();
}

std::shared_ptr<const ShaderFunction> ShaderLibraryMTL::GetFunction(
    std::string_view name,
    ShaderStage stage) {
  if (!IsValid()) {
    return nullptr;
  }

  if (name.empty()) {
    VALIDATION_LOG << "Library function name was empty.";
    return nullptr;
  }

  ShaderKey key(name, stage);

  if (auto found = functions_.find(key); found != functions_.end()) {
    return found->second;
  }

  id<MTLFunction> function = nil;

  {
    ReaderLock lock(libraries_mutex_);
    for (size_t i = 0, count = [libraries_ count]; i < count; i++) {
      function = [libraries_[i] newFunctionWithName:@(name.data())];
      if (function) {
        break;
      }
    }
  }

  if (function == nil) {
    VALIDATION_LOG << "No library function found for name: " << name;
    return nullptr;
  }

  if (function.functionType != ToMTLFunctionType(stage)) {
    VALIDATION_LOG << "Library function named " << name
                   << " was for an unexpected shader stage.";
    return nullptr;
  }

  auto func = std::shared_ptr<ShaderFunctionMTL>(new ShaderFunctionMTL(
      library_id_, function, {name.data(), name.size()}, stage));
  functions_[key] = func;
  return func;
}

id<MTLDevice> ShaderLibraryMTL::GetDevice() const {
  ReaderLock lock(libraries_mutex_);
  if (libraries_.count > 0u) {
    return libraries_[0].device;
  }
  return nil;
}

// |ShaderLibrary|
void ShaderLibraryMTL::RegisterFunction(std::string name,   // unused
                                        ShaderStage stage,  // unused
                                        std::shared_ptr<fml::Mapping> code,
                                        RegistrationCallback callback) {
  if (!callback) {
    callback = [](auto) {};
  }
  auto failure_callback = std::make_shared<fml::ScopedCleanupClosure>(
      [callback]() { callback(false); });
  if (!IsValid()) {
    return;
  }
  if (code == nullptr || code->GetMapping() == nullptr) {
    return;
  }
  auto device = GetDevice();
  if (device == nil) {
    return;
  }

  auto source = [[NSString alloc] initWithBytes:code->GetMapping()
                                         length:code->GetSize()
                                       encoding:NSUTF8StringEncoding];

  auto weak_this = weak_from_this();
  [device newLibraryWithSource:source
                       options:NULL
             completionHandler:^(id<MTLLibrary> library, NSError* error) {
               auto strong_this = weak_this.lock();
               if (!strong_this) {
                 VALIDATION_LOG << "Shader library was collected before "
                                   "dynamic shader stage could be registered.";
                 return;
               }
               if (!library) {
                 VALIDATION_LOG << "Could not register dynamic stage library: "
                                << error.localizedDescription.UTF8String;
                 return;
               }
               reinterpret_cast<ShaderLibraryMTL*>(strong_this.get())
                   ->RegisterLibrary(library);
               failure_callback->Release();
               callback(true);
             }];
}

void ShaderLibraryMTL::RegisterLibrary(id<MTLLibrary> library) {
  WriterLock lock(libraries_mutex_);
  [libraries_ addObject:library];
}

}  // namespace impeller
