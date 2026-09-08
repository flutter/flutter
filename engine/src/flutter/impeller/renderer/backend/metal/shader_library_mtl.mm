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

  id<MTLFunction> function = nil;
  id<MTLLibrary> library = nil;

  {
    ReaderLock lock(libraries_mutex_);

    if (auto found = functions_.find(key); found != functions_.end()) {
      return found->second;
    }

    for (size_t i = 0, count = [libraries_ count]; i < count; i++) {
      library = libraries_[i];
      function = [library newFunctionWithName:@(name.data())];
      if (function) {
        break;
      }
    }

    if (function == nil) {
      return nullptr;
    }

    if (function.functionType != ToMTLFunctionType(stage)) {
      VALIDATION_LOG << "Library function named " << name
                     << " was for an unexpected shader stage.";
      return nullptr;
    }

    auto func = std::shared_ptr<ShaderFunctionMTL>(new ShaderFunctionMTL(
        library_id_, function, library, {name.data(), name.size()}, stage));
    functions_[key] = func;

    return func;
  }
}

id<MTLDevice> ShaderLibraryMTL::GetDevice() const {
  ReaderLock lock(libraries_mutex_);
  if (libraries_.count > 0u) {
    return libraries_[0].device;
  }
  return nil;
}

// |ShaderLibrary|
void ShaderLibraryMTL::RegisterFunction(std::string name,
                                        ShaderStage stage,
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
                   ->RegisterLibraryAndCacheFunction(library, name, stage);
               failure_callback->Release();
               callback(true);
             }];
}

// |ShaderLibrary|
void ShaderLibraryMTL::UnregisterFunction(std::string name, ShaderStage stage) {
  WriterLock lock(libraries_mutex_);

  ShaderKey key(name, stage);

  // Cache-first path: the cache, populated at RegisterFunction time, holds
  // the mapping from registration name to MTLLibrary. Scoped registration
  // names (e.g. `re:<library_id>:<entry>`) don't match any MSL function name,
  // so the library-iteration fallback below cannot find them.
  if (auto found = functions_.find(key); found != functions_.end()) {
    id<MTLLibrary> target_library =
        ShaderFunctionMTL::Cast(*found->second).library_;
    if (target_library) {
      [libraries_ removeObject:target_library];
    }
    functions_.erase(found);
    return;
  }

  // Fallback: look the function up in the libraries by its MSL name. Used
  // when the cache was not populated (e.g. for engine-bundled libraries that
  // were registered via the multi-library constructor rather than through
  // RegisterFunction).
  bool found_library = false;
  for (size_t i = [libraries_ count] - 1; i >= 0; i--) {
    id<MTLFunction> function =
        [libraries_[i] newFunctionWithName:@(name.data())];
    if (function) {
      [libraries_ removeObjectAtIndex:i];
      found_library = true;
      break;
    }
  }
  if (!found_library) {
    VALIDATION_LOG << "Library containing function " << name
                   << " was not found, so it couldn't be unregistered.";
  }
}

void ShaderLibraryMTL::RegisterLibraryAndCacheFunction(id<MTLLibrary> library,
                                                       const std::string& name,
                                                       ShaderStage stage) {
  WriterLock lock(libraries_mutex_);
  [libraries_ addObject:library];

  // Find the function in the newly compiled library matching the requested
  // stage and cache it under the registration name. Subsequent
  // `GetFunction(name, stage)` calls then resolve via the cache, which lets
  // namespaced registration names (e.g. `re:<library_id>:<entry>`) that don't
  // match any MSL function name still resolve to the right function.
  const MTLFunctionType expected = ToMTLFunctionType(stage);
  for (NSString* function_name in [library functionNames]) {
    id<MTLFunction> mtl_function = [library newFunctionWithName:function_name];
    if (mtl_function && mtl_function.functionType == expected) {
      ShaderKey key(name, stage);
      functions_[key] =
          std::shared_ptr<ShaderFunctionMTL>(new ShaderFunctionMTL(
              library_id_, mtl_function, library, name, stage));
      break;
    }
  }
}

}  // namespace impeller
