// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/toolkit/interop/playground_test.h"

#include "impeller/toolkit/interop/impeller.hpp"

#if IMPELLER_ENABLE_METAL
#include "impeller/toolkit/interop/backend/metal/context_mtl.h"
#include "impeller/toolkit/interop/backend/metal/surface_mtl.h"
#endif  // IMPELLER_ENABLE_METAL

#if IMPELLER_ENABLE_OPENGLES
#include "impeller/toolkit/interop/backend/gles/context_gles.h"
#include "impeller/toolkit/interop/backend/gles/surface_gles.h"
#endif  // IMPELLER_ENABLE_METAL

#if IMPELLER_ENABLE_VULKAN
#include "impeller/toolkit/interop/backend/vulkan/context_vk.h"
#include "impeller/toolkit/interop/backend/vulkan/surface_vk.h"
#endif  // IMPELLER_ENABLE_VULKAN

namespace IMPELLER_HPP_NAMESPACE {
ProcTable gGlobalProcTable;
}  // namespace IMPELLER_HPP_NAMESPACE

namespace impeller::interop::testing {

static void SetupImpellerHPPProcTableOnce() {
  static std::once_flag sOnceFlag;
  std::call_once(sOnceFlag, []() {
    std::map<std::string, void*> proc_map;
#define IMPELLER_HPP_PROC(name) \
  proc_map[#name] = reinterpret_cast<void*>(&name);
    IMPELLER_HPP_EACH_PROC(IMPELLER_HPP_PROC)
#undef IMPELLER_HPP_PROC
    hpp::gGlobalProcTable.Initialize(
        [&](auto name) { return proc_map.at(name); });
  });
}

PlaygroundTest::PlaygroundTest() {
  SetupImpellerHPPProcTableOnce();
}

PlaygroundTest::~PlaygroundTest() = default;

// |PlaygroundTest|
void PlaygroundTest::SetUp() {
  ::impeller::PlaygroundTest::SetUp();
}

// |PlaygroundTest|
void PlaygroundTest::TearDown() {
  ::impeller::PlaygroundTest::TearDown();
}

ScopedObject<Context> PlaygroundTest::CreateContext() const {
  switch (GetBackend()) {
    case PlaygroundBackend::kMetal:
      return Adopt<Context>(
          ImpellerContextCreateMetalNew(ImpellerGetVersion()));
    case PlaygroundBackend::kOpenGLES: {
      Playground::GLProcAddressResolver playground_gl_proc_address_callback =
          CreateGLProcAddressResolver();
      ImpellerProcAddressCallback gl_proc_address_callback =
          [](const char* proc_name, void* user_data) -> void* {
        return (*reinterpret_cast<Playground::GLProcAddressResolver*>(
            user_data))(proc_name);
      };
      return Adopt<Context>(ImpellerContextCreateOpenGLESNew(
          ImpellerGetVersion(), gl_proc_address_callback,
          &playground_gl_proc_address_callback));
    }
    case PlaygroundBackend::kVulkan:
      ImpellerContextVulkanSettings settings = {};
      struct UserData {
        Playground::VKProcAddressResolver resolver;
      } user_data;
      user_data.resolver = CreateVKProcAddressResolver();
      settings.user_data = &user_data;
      settings.enable_vulkan_validation = switches_.enable_vulkan_validation;
      settings.proc_address_callback = [](void* instance,         //
                                          const char* proc_name,  //
                                          void* user_data         //
                                          ) -> void* {
        auto resolver = reinterpret_cast<UserData*>(user_data)->resolver;
        if (resolver) {
          return resolver(instance, proc_name);
        } else {
          return nullptr;
        }
      };
      return Adopt<Context>(
          ImpellerContextCreateVulkanNew(ImpellerGetVersion(), &settings));
  }
  FML_UNREACHABLE();
}

static ScopedObject<Surface> CreateSharedSurface(
    PlaygroundBackend backend,
    Context& context,
    std::shared_ptr<impeller::Surface> shared_surface) {
  switch (backend) {
#if IMPELLER_ENABLE_METAL
    case PlaygroundBackend::kMetal:
      return Adopt<Surface>(new SurfaceMTL(context, std::move(shared_surface)));
#endif

#if IMPELLER_ENABLE_OPENGLES
    case PlaygroundBackend::kOpenGLES:
      return Adopt<Surface>(
          new SurfaceGLES(context, std::move(shared_surface)));
#endif

#if IMPELLER_ENABLE_VULKAN
    case PlaygroundBackend::kVulkan:
      return Adopt<Surface>(new SurfaceVK(context, std::move(shared_surface)));
#endif
    default:
      return nullptr;
  }
  FML_UNREACHABLE();
}

bool PlaygroundTest::OpenPlaygroundHere(InteropPlaygroundCallback callback) {
  auto interop_context = GetInteropContext();
  if (!interop_context) {
    return false;
  }
  return Playground::OpenPlaygroundHere([&](RenderTarget& target) -> bool {
    auto impeller_surface = std::make_shared<impeller::Surface>(target);
    auto surface = CreateSharedSurface(GetBackend(),                //
                                       *interop_context.Get(),      //
                                       std::move(impeller_surface)  //
    );
    if (!surface) {
      VALIDATION_LOG << "Could not wrap test surface as an interop surface.";
      return false;
    }
    return callback(interop_context, surface);
  });
}

static ScopedObject<Context> CreateSharedContext(
    PlaygroundBackend backend,
    std::shared_ptr<impeller::Context> shared_context) {
  switch (backend) {
#if IMPELLER_ENABLE_METAL
    case PlaygroundBackend::kMetal:
      return ContextMTL::Create(shared_context);
#endif
#if IMPELLER_ENABLE_OPENGLES
    case PlaygroundBackend::kOpenGLES:
      return ContextGLES::Create(std::move(shared_context));
#endif
#if IMPELLER_ENABLE_VULKAN
    case PlaygroundBackend::kVulkan:
      return ContextVK::Create(std::move(shared_context));
#endif
    default:
      return nullptr;
  }
  FML_UNREACHABLE();
}

ScopedObject<Context> PlaygroundTest::GetInteropContext() {
  if (interop_context_) {
    return interop_context_;
  }

  auto context = CreateSharedContext(GetBackend(), GetContext());
  if (!context) {
    return nullptr;
  }
  interop_context_ = std::move(context);
  return interop_context_;
}

hpp::Context PlaygroundTest::GetHPPContext() {
  auto c_context = GetInteropContext().GetC();
  ImpellerContextRetain(c_context);
  return hpp::Context{c_context, hpp::AdoptTag::kAdopt};
}

std::unique_ptr<hpp::Mapping> PlaygroundTest::OpenAssetAsHPPMapping(
    std::string asset_name) const {
  std::shared_ptr<fml::Mapping> data =
      OpenAssetAsMapping(std::move(asset_name));
  if (!data) {
    return nullptr;
  }
  return std::make_unique<hpp::Mapping>(data->GetMapping(),  //
                                        data->GetSize(),     //
                                        [data]() {}          //
  );
}

hpp::Texture PlaygroundTest::OpenAssetAsHPPTexture(std::string asset_name) {
  auto compressed_data = OpenAssetAsMapping(std::move(asset_name));
  if (!compressed_data) {
    return {nullptr, hpp::AdoptTag::kAdopt};
  }
  auto compressed_image =
      LoadFixtureImageCompressed(std::move(compressed_data));
  if (!compressed_image) {
    return {nullptr, hpp::AdoptTag::kAdopt};
  }
  auto decompressed_image = DecodeImageRGBA(compressed_image);
  if (!decompressed_image.has_value()) {
    return {nullptr, hpp::AdoptTag::kAdopt};
  }
  auto rgba_decompressed_image =
      std::make_shared<DecompressedImage>(decompressed_image->ConvertToRGBA());
  if (!rgba_decompressed_image || !rgba_decompressed_image->IsValid()) {
    return {nullptr, hpp::AdoptTag::kAdopt};
  }
  auto context = GetHPPContext();
  if (!context) {
    return {nullptr, hpp::AdoptTag::kAdopt};
  }

  auto rgba_mapping = std::make_unique<hpp::Mapping>(
      rgba_decompressed_image->GetAllocation()->GetMapping(),
      rgba_decompressed_image->GetAllocation()->GetSize(),
      [rgba_decompressed_image]() {});

  return hpp::Texture::WithContents(
      context,
      ImpellerTextureDescriptor{
          .pixel_format = kImpellerPixelFormatRGBA8888,
          .size = {rgba_decompressed_image->GetSize().width,
                   rgba_decompressed_image->GetSize().height},
          .mip_count = 1u,
      },
      std::move(rgba_mapping));
}

}  // namespace impeller::interop::testing
